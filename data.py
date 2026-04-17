import re
import streamlit as st
import gspread
import gspread.exceptions
import pandas as pd
from datetime import datetime
from google.oauth2.service_account import Credentials
from config import (
    SCOPES, SHEET_NAME,
    WORKSHEET_CATALOGO, WORKSHEET_VENTAS, WORKSHEET_COTIZACIONES,
    hoy_peru, fmt_precio
)


def log_error(contexto, error):
    log = st.session_state.setdefault("error_log", [])
    now = datetime.now().strftime("%H:%M:%S")
    log.append(f"[{now}] [{contexto}] {str(error)}")
    if len(log) > 50:
        st.session_state.error_log = log[-50:]


# ── Mejora 3: reconexión automática ──────────────────────────────────────────

def _limpiar_conexion():
    """Limpia el cache de conexiones para forzar una reconexión limpia."""
    get_cliente.clear()
    get_spreadsheet.clear()
    get_hoja.clear()


def _ejecutar_con_reintento(fn, contexto):
    """Ejecuta fn(). Si falla con APIError, reconecta y reintenta una vez."""
    try:
        return fn()
    except gspread.exceptions.APIError:
        log_error(contexto, "APIError — reconectando y reintentando...")
        _limpiar_conexion()
        return fn()  # propaga si vuelve a fallar


# ─────────────────────────────────────────────────────────────────────────────

@st.cache_resource
def get_cliente():
    try:
        creds = Credentials.from_service_account_info(
            st.secrets["gcp_service_account"], scopes=SCOPES
        )
        return gspread.authorize(creds)
    except Exception as e:
        log_error("get_cliente", e)
        st.error("Error de autenticación con Google. Verifica st.secrets.")
        raise


@st.cache_resource
def get_spreadsheet():
    try:
        return get_cliente().open(SHEET_NAME)
    except Exception as e:
        log_error("get_spreadsheet", e)
        raise


@st.cache_resource
def get_hoja(worksheet_name):
    try:
        return get_spreadsheet().worksheet(worksheet_name)
    except Exception as e:
        log_error(f"get_hoja({worksheet_name})", e)
        st.error(f"No se pudo conectar a la hoja: {worksheet_name}")
        raise


@st.cache_data(ttl=600)
def cargar_catalogo():
    try:
        def _fetch():
            hoja = get_hoja(WORKSHEET_CATALOGO)
            return hoja.get_all_records(value_render_option='UNFORMATTED_VALUE')

        datos = _ejecutar_con_reintento(_fetch, "cargar_catalogo")
        df = pd.DataFrame(datos)

        if not df.empty:
            # fila_sheet: número real de fila en la hoja (cabecera = fila 1)
            df["fila_sheet"] = range(2, len(df) + 2)
            cols_numericas = ['precio', 'costo', 'ml_disponibles', 'stock', 'Stock_ml']
            for col in cols_numericas:
                if col in df.columns:
                    df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0)
        return df
    except Exception as e:
        log_error("cargar_catalogo", e)
        return pd.DataFrame()


def limpiar_cache_catalogo():
    cargar_catalogo.clear()


@st.cache_data(ttl=120)
def cargar_ventas():
    try:
        def _fetch():
            hoja = get_hoja(WORKSHEET_VENTAS)
            return hoja.get_all_values()

        valores = _ejecutar_con_reintento(_fetch, "cargar_ventas")
        if not valores or len(valores) < 2:
            return pd.DataFrame()

        headers = valores[0]
        filas   = valores[1:]
        df = pd.DataFrame(filas, columns=headers)

        if not df.empty:
            if "Fecha" in df.columns:
                df["Fecha"] = pd.to_datetime(
                    df["Fecha"].astype(str).str.strip(),
                    dayfirst=False, errors="coerce"
                )

            cols_numericas = ['Precio_Cobrado', 'Ml_Vendido', 'precio',
                              'cantidad', 'total', 'ml']
            for col in cols_numericas:
                if col in df.columns:
                    df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0)

            df["fila_sheet"] = range(2, len(df) + 2)

            if "Estado" in df.columns:
                df = df[df["Estado"] != "Anulado"].reset_index(drop=True)
                df["fila_sheet"] = df["fila_sheet"].astype(int)

        return df
    except Exception as e:
        log_error("cargar_ventas", e)
        return pd.DataFrame()


def limpiar_cache_ventas():
    cargar_ventas.clear()


def guardar_venta(filas):
    try:
        def _write():
            get_hoja(WORKSHEET_VENTAS).append_rows(filas, value_input_option='USER_ENTERED')
        _ejecutar_con_reintento(_write, "guardar_venta")
        limpiar_cache_ventas()
    except Exception as e:
        log_error("guardar_venta", e)
        raise


def _extraer_ids_numericos(ids_col):
    ids_datos = ids_col[1:] if len(ids_col) > 1 else []
    ids_numericos = []
    for id_val in ids_datos:
        match = re.search(r'(\d+)', str(id_val))
        if match:
            ids_numericos.append(int(match.group(1)))
    return ids_numericos


def obtener_proximo_id():
    try:
        df = cargar_ventas()
        if df.empty or "ID_Compra" not in df.columns:
            return "V001"
        ids_numericos = _extraer_ids_numericos(df["ID_Compra"].tolist())
        if not ids_numericos:
            return "V001"
        return f"V{max(ids_numericos) + 1:03d}"
    except Exception as e:
        log_error("obtener_proximo_id", e)
        return "V001"


def marcar_pedido_entregado_batch(lista_filas, col_estado):
    try:
        peticiones = [
            {'range': gspread.utils.rowcol_to_a1(fila, col_estado), 'values': [['Entregado']]}
            for fila in lista_filas
        ]
        def _write():
            get_hoja(WORKSHEET_VENTAS).batch_update(peticiones)
        _ejecutar_con_reintento(_write, "marcar_entregado_batch")
        limpiar_cache_ventas()
    except Exception as e:
        log_error("marcar_entregado_batch", e)
        raise


@st.cache_data(ttl=120)
def cargar_cotizaciones():
    try:
        def _fetch():
            hoja = get_hoja(WORKSHEET_COTIZACIONES)
            return hoja.get_all_values()

        valores = _ejecutar_con_reintento(_fetch, "cargar_cotizaciones")
        if not valores or len(valores) < 2:
            return pd.DataFrame()
        headers = valores[0]
        filas = valores[1:]
        df = pd.DataFrame(filas, columns=headers)
        if not df.empty:
            # fila_sheet: número real de fila en la hoja (cabecera = fila 1)
            df["fila_sheet"] = range(2, len(df) + 2)
        if "Fecha" in df.columns:
            df["Fecha"] = pd.to_datetime(df["Fecha"].astype(str).str.strip(), errors="coerce")
        if "Total" in df.columns:
            df["Total"] = pd.to_numeric(df["Total"], errors="coerce").fillna(0)
        return df
    except Exception as e:
        log_error("cargar_cotizaciones", e)
        return pd.DataFrame()


def limpiar_cache_cotizaciones():
    cargar_cotizaciones.clear()


def actualizar_estado_cotizacion(id_cotizacion, nuevo_estado, fila_sheet=None):
    try:
        def _write():
            hoja = get_hoja(WORKSHEET_COTIZACIONES)
            if fila_sheet is not None:
                # Camino rápido: fila conocida, sin get_all_values()
                df_cot = cargar_cotizaciones()
                sheet_cols = [c for c in df_cot.columns if c != "fila_sheet"]
                if "Estado" not in sheet_cols:
                    log_error("actualizar_estado_cotizacion", "Falta columna Estado")
                    return
                col_estado = sheet_cols.index("Estado") + 1
                celda = gspread.utils.rowcol_to_a1(int(fila_sheet), col_estado)
                hoja.update(celda, [[nuevo_estado]])
            else:
                # Fallback: buscar fila por ID (comportamiento original)
                todos = hoja.get_all_values()
                if not todos or len(todos) < 2:
                    return
                headers = todos[0]
                if "ID_Cotizacion" not in headers or "Estado" not in headers:
                    log_error("actualizar_estado_cotizacion", "Faltan columnas ID_Cotizacion o Estado")
                    return
                col_id = headers.index("ID_Cotizacion")
                col_estado = headers.index("Estado") + 1
                for i, fila in enumerate(todos[1:], start=2):
                    if len(fila) > col_id and fila[col_id] == id_cotizacion:
                        celda = gspread.utils.rowcol_to_a1(i, col_estado)
                        hoja.update(celda, [[nuevo_estado]])
                        break

        _ejecutar_con_reintento(_write, "actualizar_estado_cotizacion")
        limpiar_cache_cotizaciones()
    except Exception as e:
        log_error("actualizar_estado_cotizacion", e)
        raise


def _obtener_proximo_id_cotizacion():
    try:
        df = cargar_cotizaciones()
        if df.empty or "ID_Cotizacion" not in df.columns:
            return "C001"
        ids_numericos = _extraer_ids_numericos(df["ID_Cotizacion"].tolist())
        if not ids_numericos:
            return "C001"
        return f"C{max(ids_numericos) + 1:03d}"
    except Exception as e:
        log_error("_obtener_proximo_id_cotizacion", e)
        return "C001"


def guardar_cotizacion(celular, cesta, total):
    try:
        id_cotizacion = _obtener_proximo_id_cotizacion()

        items_txt = " | ".join([
            f"{i['perfume']} {i['ml']}ml S/{fmt_precio(i['precio'])}"
            for i in cesta
        ])

        fila = [
            id_cotizacion,
            str(hoy_peru()),
            celular,
            items_txt,
            round(float(total), 2),
            "Enviado"
        ]

        def _write():
            get_hoja(WORKSHEET_COTIZACIONES).append_rows([fila], value_input_option='USER_ENTERED')
        _ejecutar_con_reintento(_write, "guardar_cotizacion")
        limpiar_cache_cotizaciones()
        return id_cotizacion
    except Exception as e:
        log_error("guardar_cotizacion", e)
        raise


def actualizar_stock_perfumes_batch(items_vendidos):
    if not items_vendidos:
        return
    try:
        # Usamos el df cacheado — evita un get_all_values() extra
        df_cat = cargar_catalogo()
        if df_cat.empty or "fila_sheet" not in df_cat.columns:
            log_error("actualizar_stock_batch", "Catálogo vacío o sin fila_sheet")
            return
        if "Stock_ml" not in df_cat.columns or "ID_Perfume" not in df_cat.columns:
            log_error("actualizar_stock_batch", "Faltan columnas ID_Perfume o Stock_ml en Catalogo")
            return

        # Posición de Stock_ml en la hoja (excluir fila_sheet, que es virtual)
        sheet_cols = [c for c in df_cat.columns if c != "fila_sheet"]
        col_stock = sheet_cols.index("Stock_ml") + 1  # 1-indexed

        ml_por_id = {}
        for item in items_vendidos:
            id_perf = str(item["id_perfume"])
            ml_por_id[id_perf] = ml_por_id.get(id_perf, 0) + float(item["ml"])

        peticiones = []
        for _, row in df_cat[df_cat["ID_Perfume"].astype(str).isin(ml_por_id)].iterrows():
            id_fila = str(row["ID_Perfume"])
            valor_actual = float(row["Stock_ml"]) if row["Stock_ml"] else 0.0
            nuevo_valor = max(0.0, valor_actual - ml_por_id[id_fila])
            fila_num = int(row["fila_sheet"])
            peticiones.append({
                "range": gspread.utils.rowcol_to_a1(fila_num, col_stock),
                "values": [[nuevo_valor]]
            })

        if peticiones:
            def _write():
                get_hoja(WORKSHEET_CATALOGO).batch_update(peticiones)
            _ejecutar_con_reintento(_write, "actualizar_stock_batch")

        limpiar_cache_catalogo()
    except Exception as e:
        log_error("actualizar_stock_batch", e)


def actualizar_ventas_multi_fila_batch(filas_cambios):
    try:
        peticiones = []
        for fila_sheet, cambios in filas_cambios:
            for col_num, valor in cambios.items():
                peticiones.append({
                    "range": gspread.utils.rowcol_to_a1(int(fila_sheet), int(col_num)),
                    "values": [[valor]]
                })
        if peticiones:
            def _write():
                get_hoja(WORKSHEET_VENTAS).batch_update(peticiones, value_input_option="USER_ENTERED")
            _ejecutar_con_reintento(_write, "actualizar_ventas_multi_fila_batch")
        limpiar_cache_ventas()
    except Exception as e:
        log_error("actualizar_ventas_multi_fila_batch", e)
        raise

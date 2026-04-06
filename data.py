import re
import streamlit as st
import gspread
import pandas as pd
from datetime import datetime
from google.oauth2.service_account import Credentials
from config import (
    SCOPES, SHEET_NAME,
    WORKSHEET_CATALOGO, WORKSHEET_VENTAS, WORKSHEET_COTIZACIONES,
    hoy_peru, fmt_precio
)


def log_error(contexto, error):
    print(f"[ERROR] {contexto}: {str(error)}")
    log = st.session_state.setdefault("error_log", [])
    now = datetime.now().strftime("%H:%M:%S")
    log.append(f"[{now}] [{contexto}] {str(error)}")
    if len(log) > 50:
        st.session_state.error_log = log[-50:]


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


def get_hoja(worksheet_name):
    try:
        return get_spreadsheet().worksheet(worksheet_name)
    except Exception as e:
        log_error(f"get_hoja({worksheet_name})", e)
        st.error(f"No se pudo conectar a la hoja: {worksheet_name}")
        raise


@st.cache_data(ttl=300)
def cargar_catalogo():
    try:
        hoja = get_hoja(WORKSHEET_CATALOGO)
        datos = hoja.get_all_records(value_render_option='UNFORMATTED_VALUE')
        df = pd.DataFrame(datos)

        if not df.empty:
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
        hoja = get_hoja(WORKSHEET_VENTAS)

        valores = hoja.get_all_values()
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
        hoja = get_hoja(WORKSHEET_VENTAS)
        hoja.append_rows(filas, value_input_option='USER_ENTERED')
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
        hoja = get_hoja(WORKSHEET_VENTAS)
        ids_numericos = _extraer_ids_numericos(hoja.col_values(1))
        if not ids_numericos:
            return "V001"
        return f"V{max(ids_numericos) + 1:03d}"
    except Exception as e:
        log_error("obtener_proximo_id", e)
        return "V001"


def marcar_pedido_entregado_batch(lista_filas, col_estado):
    try:
        hoja = get_hoja(WORKSHEET_VENTAS)
        peticiones = [
            {'range': gspread.utils.rowcol_to_a1(fila, col_estado), 'values': [['Entregado']]}
            for fila in lista_filas
        ]
        hoja.batch_update(peticiones)
        limpiar_cache_ventas()
    except Exception as e:
        log_error("marcar_entregado_batch", e)
        raise


def _obtener_proximo_id_cotizacion():
    try:
        hoja = get_hoja(WORKSHEET_COTIZACIONES)
        ids_numericos = _extraer_ids_numericos(hoja.col_values(1))
        if not ids_numericos:
            return "C001"
        return f"C{max(ids_numericos) + 1:03d}"
    except Exception as e:
        log_error("_obtener_proximo_id_cotizacion", e)
        return "C001"


def guardar_cotizacion(celular, cesta, total):
    try:
        hoja = get_hoja(WORKSHEET_COTIZACIONES)
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

        hoja.append_rows([fila], value_input_option='USER_ENTERED')
        return id_cotizacion
    except Exception as e:
        log_error("guardar_cotizacion", e)
        raise


def actualizar_stock_perfume(nombre_perfume, ml_restados):
    try:
        hoja = get_hoja(WORKSHEET_CATALOGO)
        todos = hoja.get_all_values()

        if not todos or len(todos) < 2:
            log_error("actualizar_stock", "Hoja Catalogo vacía o sin datos")
            return

        headers = todos[0]
        if "Stock_ml" not in headers or "Nombre" not in headers:
            log_error("actualizar_stock", "Faltan columnas Nombre o Stock_ml en Catalogo")
            return

        col_stock = headers.index("Stock_ml") + 1
        col_nombre = headers.index("Nombre")

        fila_objetivo = None
        for i, fila in enumerate(todos[1:], start=2):
            if len(fila) > col_nombre and fila[col_nombre] == nombre_perfume:
                fila_objetivo = i
                break

        if fila_objetivo is None:
            log_error("actualizar_stock", f"Perfume no encontrado: {nombre_perfume}")
            return

        valor_actual_str = todos[fila_objetivo - 1][col_stock - 1]
        valor_actual = float(valor_actual_str) if valor_actual_str else 0.0
        nuevo_valor = max(0.0, valor_actual - ml_restados)

        letra = gspread.utils.rowcol_to_a1(fila_objetivo, col_stock)
        hoja.batch_update([{"range": letra, "values": [[nuevo_valor]]}])

        limpiar_cache_catalogo()
    except Exception as e:
        log_error("actualizar_stock", e)


def actualizar_venta_batch(fila_sheet, cambios):
    try:
        hoja = get_hoja(WORKSHEET_VENTAS)
        peticiones = [
            {"range": gspread.utils.rowcol_to_a1(int(fila_sheet), int(col_num)), "values": [[valor]]}
            for col_num, valor in cambios.items()
        ]
        hoja.batch_update(peticiones, value_input_option="USER_ENTERED")
        limpiar_cache_ventas()
    except Exception as e:
        log_error("actualizar_venta_batch", e)
        raise
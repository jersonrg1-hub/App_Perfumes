import re
import streamlit as st
import gspread
import gspread.exceptions
import pandas as pd
from datetime import datetime, date as date_type, timedelta
from google.oauth2.service_account import Credentials
from tenacity import retry, wait_exponential, stop_after_attempt, retry_if_exception
from config import (
    SCOPES, SHEET_NAME,
    WORKSHEET_CATALOGO, WORKSHEET_VENTAS, WORKSHEET_COTIZACIONES,
    hoy_peru, fmt_precio, ItemCesta, DatosCliente
)
from costos import MERMA_PCT


def log_error(contexto: str, error: object) -> None:
    log = st.session_state.setdefault("error_log", [])
    now = datetime.now().strftime("%H:%M:%S")
    log.append(f"[{now}] [{contexto}] {str(error)}")
    if len(log) > 50:
        st.session_state.error_log = log[-50:]


def _limpiar_conexion() -> None:
    get_cliente.clear()
    get_spreadsheet.clear()
    get_hoja.clear()


def _es_rate_limit(exc: Exception) -> bool:
    return (
        isinstance(exc, gspread.exceptions.APIError)
        and getattr(getattr(exc, "response", None), "status_code", None) == 429
    )


def _ejecutar_con_reintento(fn, contexto: str):
    """Ejecuta fn() con resiliencia ante errores de la API de Google:
    - 429 Rate Limit: backoff exponencial (2s → 4s → 8s → ... hasta 5 intentos)
    - Otros errores de red/API: reconecta y reintenta una vez
    """
    @retry(
        retry=retry_if_exception(_es_rate_limit),
        wait=wait_exponential(multiplier=1, min=2, max=60),
        stop=stop_after_attempt(5),
        reraise=True,
    )
    def _intentar():
        return fn()

    try:
        return _intentar()
    except Exception as e:
        if _es_rate_limit(e):
            log_error(contexto, "Rate limit persistente tras 5 intentos con backoff")
            raise
        log_error(contexto, f"{type(e).__name__} — reconectando y reintentando...")
        _limpiar_conexion()
        return fn()


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


def _make_tag_set(valor_str) -> frozenset:
    """Normaliza una cadena CSV de etiquetas a un frozenset comparables con _extraer_valores."""
    if not valor_str or str(valor_str).strip().lower() in ("", "nan", "none"):
        return frozenset()
    return frozenset(
        v.strip().lower().capitalize()
        for v in str(valor_str).split(",")
        if v.strip()
    )


@st.cache_data(ttl=1800)
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

            # Columnas pre-computadas — se calculan una vez en cache, no en cada búsqueda
            if "Nombre" in df.columns:
                df["Nombre_lower"] = df["Nombre"].str.lower().fillna("")
            if "Marca" in df.columns:
                df["Marca_lower"] = df["Marca"].str.lower().fillna("")
                df["Marca_limpia"] = df["Marca"].str.strip().str.strip("*").str.strip()

            for _col in ["Notas", "Perfil_Olfativo", "ocasion", "estacion", "hora"]:
                if _col in df.columns:
                    df[f"{_col}_set"] = df[_col].apply(_make_tag_set)

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
            return hoja.get_all_records(value_render_option='UNFORMATTED_VALUE')

        datos = _ejecutar_con_reintento(_fetch, "cargar_ventas")
        if not datos:
            return pd.DataFrame()

        df = pd.DataFrame(datos)

        if not df.empty:
            if "Fecha" in df.columns:
                df["Fecha"] = df["Fecha"].apply(_parse_fecha)

            cols_numericas = ['Precio_Cobrado', 'Ml_Vendido', 'precio',
                              'cantidad', 'total', 'ml']
            for col in cols_numericas:
                if col in df.columns:
                    df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0)

            if "Celular" in df.columns:
                df["Celular"] = df["Celular"].astype(str)

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


def guardar_venta(filas: list[list]) -> None:
    try:
        def _write():
            get_hoja(WORKSHEET_VENTAS).append_rows(filas, value_input_option='USER_ENTERED')
        _ejecutar_con_reintento(_write, "guardar_venta")
        limpiar_cache_ventas()
    except Exception as e:
        log_error("guardar_venta", e)
        raise


def _parse_fecha(v):
    """Convierte valor de Google Sheets a Timestamp. Acepta serial numérico o string."""
    if v is None or v == "":
        return pd.NaT
    if isinstance(v, (int, float)):
        try:
            return pd.Timestamp(date_type(1899, 12, 30) + timedelta(days=int(v)))
        except Exception:
            return pd.NaT
    return pd.to_datetime(str(v).strip(), errors="coerce")


def _extraer_ids_numericos(ids_col):
    ids_numericos = []
    for id_val in ids_col:
        match = re.search(r'(\d+)', str(id_val))
        if match:
            ids_numericos.append(int(match.group(1)))
    return ids_numericos


def obtener_proximo_id() -> str:
    cargar_ventas.clear()
    df = cargar_ventas()
    if df.empty or "ID_Compra" not in df.columns:
        return "V001"
    ids_numericos = _extraer_ids_numericos(df["ID_Compra"].tolist())
    if not ids_numericos:
        return "V001"
    ids_set = set(ids_numericos)
    siguiente = max(ids_numericos) + 1
    while siguiente in ids_set:
        siguiente += 1
    return f"V{siguiente:03d}"


def marcar_pedido_entregado_batch(lista_filas: list[int], col_estado: int) -> None:
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
            return hoja.get_all_records(value_render_option='UNFORMATTED_VALUE')

        datos = _ejecutar_con_reintento(_fetch, "cargar_cotizaciones")
        if not datos:
            return pd.DataFrame()

        df = pd.DataFrame(datos)

        if not df.empty:
            df["fila_sheet"] = range(2, len(df) + 2)
        if "Fecha" in df.columns:
            df["Fecha"] = df["Fecha"].apply(_parse_fecha)
        if "Total" in df.columns:
            df["Total"] = pd.to_numeric(df["Total"], errors="coerce").fillna(0)
        return df
    except Exception as e:
        log_error("cargar_cotizaciones", e)
        return pd.DataFrame()


def limpiar_cache_cotizaciones():
    cargar_cotizaciones.clear()


def actualizar_estado_cotizacion(id_cotizacion: str, nuevo_estado: str, fila_sheet: int) -> None:
    try:
        # Calcular posición de columna ANTES de entrar al write (usa datos frescos)
        df_cot = cargar_cotizaciones()
        sheet_cols = [c for c in df_cot.columns if c != "fila_sheet"]
        if "Estado" not in sheet_cols:
            raise ValueError("Falta columna Estado en Cotizaciones")
        col_estado = sheet_cols.index("Estado") + 1
        celda = gspread.utils.rowcol_to_a1(int(fila_sheet), col_estado)

        def _write():
            get_hoja(WORKSHEET_COTIZACIONES).update(celda, [[nuevo_estado]])

        _ejecutar_con_reintento(_write, "actualizar_estado_cotizacion")
        limpiar_cache_cotizaciones()
    except Exception as e:
        log_error("actualizar_estado_cotizacion", e)
        raise


def _obtener_proximo_id_cotizacion():
    cargar_cotizaciones.clear()
    df = cargar_cotizaciones()
    if df.empty or "ID_Cotizacion" not in df.columns:
        return "C001"
    ids_numericos = _extraer_ids_numericos(df["ID_Cotizacion"].tolist())
    if not ids_numericos:
        return "C001"
    return f"C{max(ids_numericos) + 1:03d}"


def guardar_cotizacion(celular: str, cesta: list[ItemCesta], total: float) -> str:
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


def actualizar_stock_perfumes_batch(items_vendidos: list[ItemCesta]) -> None:
    if not items_vendidos:
        return
    try:
        # Siempre recargamos el catálogo fresco para que fila_sheet sea exacto
        limpiar_cache_catalogo()
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
            ml_con_merma = float(item["ml"]) * (1 + MERMA_PCT)
            ml_por_id[id_perf] = ml_por_id.get(id_perf, 0) + ml_con_merma

        peticiones = []
        for _, row in df_cat[df_cat["ID_Perfume"].astype(str).isin(ml_por_id)].iterrows():
            id_fila = str(row["ID_Perfume"])
            valor_actual = float(row["Stock_ml"]) if row["Stock_ml"] else 0.0
            ml_necesario = ml_por_id[id_fila]
            if valor_actual < ml_necesario:
                log_error("actualizar_stock_batch",
                          f"Stock insuficiente ID {id_fila}: disponible={valor_actual}ml, vendido={ml_necesario}ml (incl. merma {MERMA_PCT:.0%}) — se fija en 0")
            nuevo_valor = max(0.0, valor_actual - ml_necesario)
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
        raise


def actualizar_ventas_multi_fila_batch(filas_cambios: list[tuple[int, dict[int, object]]]) -> None:
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


def registrar_venta_completa(cesta: list[ItemCesta], cliente: DatosCliente) -> str:
    """Operación atómica: asigna ID, guarda filas en Sheets y descuenta stock.

    Retorna el id_compra asignado (ej. 'V042').
    El stock se intenta actualizar después de guardar; si falla, propaga
    StockUpdateError para que la UI pueda mostrar la advertencia sin perder la venta.
    """
    id_compra = obtener_proximo_id()

    filas = [
        [
            id_compra,
            cliente["fecha"],
            cliente["comprador"],
            cliente["celular"],
            str(item["id_perfume"]),
            str(item["ml"]),
            round(float(item["precio"]), 2),
            item["metodo"],
            cliente["tipo_envio"],
            cliente["direccion"],
            "Pendiente",
        ]
        for item in cesta
    ]

    guardar_venta(filas)

    try:
        actualizar_stock_perfumes_batch(cesta)
    except Exception as e:
        log_error("registrar_venta_completa/stock", e)
        raise StockUpdateError(id_compra, e)

    return id_compra


class StockUpdateError(Exception):
    """La venta se guardó correctamente pero el descuento de stock falló."""
    def __init__(self, id_compra: str, causa: Exception):
        self.id_compra = id_compra
        self.causa = causa
        super().__init__(str(causa))

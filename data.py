import streamlit as st
import gspread
import pandas as pd
from google.oauth2.service_account import Credentials
from config import (
    SCOPES, SHEET_NAME,
    WORKSHEET_CATALOGO, WORKSHEET_VENTAS
)


# ── Logger mejorado ──────────────────────────────────────────
def log_error(contexto, error):
    """Registra errores con contexto y nivel de severidad"""
    print(f"[ERROR] {contexto}: {str(error)}")
    log = st.session_state.setdefault("error_log", [])
    from datetime import datetime
    now = datetime.now().strftime("%H:%M:%S")
    log.append(f"[{now}] [{contexto}] {str(error)}")
    if len(log) > 50:
        st.session_state.error_log = log[-50:]


# ── Conexión central cacheada ──────────────────────────────
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


def get_hoja(worksheet_name):
    try:
        cliente = get_cliente()
        return cliente.open(SHEET_NAME).worksheet(worksheet_name)
    except Exception as e:
        log_error(f"get_hoja({worksheet_name})", e)
        st.error(f"No se pudo conectar a la hoja: {worksheet_name}")
        raise


# ── Catálogo ───────────────────────────────────────────────
@st.cache_data(ttl=600)  # TTL de 10 min
def cargar_catalogo():
    """Carga el catálogo y asegura tipos de datos numéricos"""
    try:
        hoja = get_hoja(WORKSHEET_CATALOGO)
        # value_render_option='UNFORMATTED_VALUE' ignora colores/formatos y vuela
        datos = hoja.get_all_records(value_render_option='UNFORMATTED_VALUE')
        df = pd.DataFrame(datos)

        if not df.empty:
            cols_numericas = ['precio', 'costo', 'ml_disponibles', 'stock']
            for col in cols_numericas:
                if col in df.columns:
                    df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0)
        return df
    except Exception as e:
        log_error("cargar_catalogo", e)
        return pd.DataFrame()


def limpiar_cache_catalogo():
    st.cache_data.clear()


# ── Ventas ─────────────────────────────────────────────────
@st.cache_data(ttl=600)
def cargar_ventas():
    """Carga ventas asegurando que los IDs se traten correctamente"""
    try:
        hoja = get_hoja(WORKSHEET_VENTAS)
        datos = hoja.get_all_records(value_render_option='UNFORMATTED_VALUE')
        if not datos:
            return pd.DataFrame()
        return pd.DataFrame(datos)
    except Exception as e:
        log_error("cargar_ventas", e)
        return pd.DataFrame()


def limpiar_cache_ventas():
    """Limpia SOLO el caché de las ventas, manteniendo el catálogo intacto en memoria"""
    cargar_ventas.clear()


def guardar_venta(filas):
    """
    Recibe una lista de listas (todas las ventas de la cesta)
    y las guarda en una sola petición.
    """
    try:
        hoja = get_hoja(WORKSHEET_VENTAS)
        hoja.append_rows(filas, value_input_option='USER_ENTERED')

        # Limpiamos SOLO las ventas para no destruir la velocidad del catálogo
        limpiar_cache_ventas()

    except Exception as e:
        log_error("guardar_venta", e)
        raise


def obtener_proximo_id():
    """
    Calcula el ID basándose en los datos ya cargados
    para evitar una consulta extra a la API.
    """
    df_ventas = cargar_ventas()
    if df_ventas.empty or 'ID_Compra' not in df_ventas.columns:
        return "V001"

    try:
        # Regex corregido para capturar números correctamente
        ids_numericos = df_ventas['ID_Compra'].str.extract(r'(\d+)').dropna().astype(int)
        if ids_numericos.empty:
            return "V001"
        max_id = int(ids_numericos.max())
        return f"V{max_id + 1:03d}"
    except Exception as e:
        log_error("obtener_proximo_id", e)
        return "V001"


def marcar_pedido_entregado_batch(lista_filas, col_estado):
    """
    Actualiza TODAS las filas de un pedido en una sola llamada a Google.
    Ideal para agrupar múltiples perfumes en una sola actualización.
    """
    try:
        hoja = get_hoja(WORKSHEET_VENTAS)

        peticiones = []
        for fila in lista_filas:
            letra_col = gspread.utils.rowcol_to_a1(fila, col_estado)
            peticiones.append({
                'range': letra_col,
                'values': [['Entregado']]
            })

        hoja.batch_update(peticiones)
        limpiar_cache_ventas()

    except Exception as e:
        log_error("marcar_entregado_batch", e)
        raise


def actualizar_stock_perfume(nombre_perfume, ml_restados):
    """
    Busca el perfume y resta los ML vendidos en el Excel del catálogo.
    """
    try:
        hoja = get_hoja(WORKSHEET_CATALOGO)
        celda = hoja.find(nombre_perfume)

        # OJO: Asegúrate que el stock esté en la columna 4 de tu Excel.
        col_ml = 4
        valor_actual = float(hoja.cell(celda.row, col_ml).value)
        nuevo_valor = max(0, valor_actual - ml_restados)
        hoja.update_cell(celda.row, col_ml, nuevo_valor)

        limpiar_cache_catalogo()
    except Exception as e:
        log_error("actualizar_stock", e)
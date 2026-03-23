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
    # Añadimos timestamp para saber CUÁNDO falló
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
@st.cache_data(ttl=600)  # Subimos a 10 min, el catálogo no cambia cada segundo
def cargar_catalogo():
    """Carga el catálogo y asegura tipos de datos numéricos"""
    try:
        hoja = get_hoja(WORKSHEET_CATALOGO)
        datos = hoja.get_all_records()
        df = pd.DataFrame(datos)

        # --- MEJORA: Limpieza de datos automática ---
        if not df.empty:
            # Aseguramos que columnas de precios/stock sean numéricas
            cols_numericas = ['precio', 'costo', 'ml_disponibles', 'stock']
            for col in cols_numericas:
                if col in df.columns:
                    df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0)
        return df
    except Exception as e:
        log_error("cargar_catalogo", e)
        return pd.DataFrame()


def limpiar_cache_catalogo():
    # Limpiamos todo si de verdad queremos un reseteo duro
    st.cache_data.clear()


# ── Ventas ─────────────────────────────────────────────────
@st.cache_data(ttl=600)  # CORRECCIÓN: ESTO FALTABA PARA QUE "limpiar_cache_ventas" FUNCIONARA
def cargar_ventas():
    """Carga ventas asegurando que los IDs se traten correctamente"""
    try:
        hoja = get_hoja(WORKSHEET_VENTAS)
        datos = hoja.get_all_records()
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
    CAMBIO CRÍTICO: Recibe una lista de listas (todas las ventas de la cesta)
    y las guarda en una sola petición.
    """
    try:
        hoja = get_hoja(WORKSHEET_VENTAS)
        # append_rows es 10 veces más rápido para múltiples registros que append_row
        hoja.append_rows(filas, value_input_option='USER_ENTERED')

        # CORRECCIÓN: Limpiamos SOLO las ventas, para no destruir la velocidad del catálogo
        limpiar_cache_ventas()

    except Exception as e:
        log_error("guardar_venta_batch", e)
        raise


def obtener_proximo_id():
    """
    MEJORA: Calcula el ID basándose en los datos ya cargados
    para evitar una consulta extra a la API.
    """
    df_ventas = cargar_ventas()
    if df_ventas.empty or 'ID_Compra' not in df_ventas.columns:
        return "V001"

    try:
        # CORRECCIÓN de error de tipeo en Regex r'(\+d)' -> r'(\d+)'
        ids_numericos = df_ventas['ID_Compra'].str.extract(r'(\d+)').dropna().astype(int)
        if ids_numericos.empty:
            return "V001"
        max_id = int(ids_numericos.max())
        return f"V{max_id + 1:03d}"
    except Exception as e:
        log_error("obtener_proximo_id", e)
        return "V001"


def actualizar_stock_perfume(nombre_perfume, ml_restados):
    """
    NUEVA FUNCIÓN: Es vital para que el negocio de tu hermana sea automático.
    Busca el perfume y resta los ML vendidos.
    """
    try:
        hoja = get_hoja(WORKSHEET_CATALOGO)
        celda = hoja.find(nombre_perfume)  # Busca el nombre
        # Asumiendo que ML está en la columna 4 (ajustar según tu Excel)
        col_ml = 4
        valor_actual = float(hoja.cell(celda.row, col_ml).value)
        nuevo_valor = max(0, valor_actual - ml_restados)
        hoja.update_cell(celda.row, col_ml, nuevo_valor)

        limpiar_cache_catalogo()  # Forzamos recarga para ver el stock actualizado
    except Exception as e:
        log_error("actualizar_stock", e)


def marcar_pedido_entregado_batch(lista_filas, col_estado):
    """
    Actualiza TODAS las filas de un pedido en una sola llamada a Google.
    Evita el bucle de conexiones lentas.
    """
    try:
        hoja = get_hoja(WORKSHEET_VENTAS)

        # Preparamos el paquete de datos para Google
        peticiones = []
        for fila in lista_filas:
            # Convierte fila=2, col=11 a formato "K2"
            letra_col = gspread.utils.rowcol_to_a1(fila, col_estado)
            peticiones.append({
                'range': letra_col,
                'values': [['Entregado']]
            })

        # Ejecuta TODAS las actualizaciones de un solo golpe (tarda ~1 segundo)
        hoja.batch_update(peticiones)

        # CRÍTICO: Limpiamos solo el caché de ventas
        limpiar_cache_ventas()

    except Exception as e:
        log_error("marcar_entregado_batch", e)
        raise
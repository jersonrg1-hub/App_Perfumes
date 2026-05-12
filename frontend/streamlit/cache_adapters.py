"""
frontend/streamlit/cache_adapters.py — Adaptadores de cache para Streamlit.

Decisión de arquitectura clave:
  - SheetsRepository (backend/) NO conoce Streamlit.
  - Este módulo es el ÚNICO lugar donde @st.cache_resource y @st.cache_data
    se aplican sobre el repositorio.
  - data.py (raíz) importa desde aquí para mantener compatibilidad con
    el código existente en tabs/ y estadisticas/.

Para FastAPI: NO usar este módulo. Instanciar SheetsRepository directamente
con credenciales de variables de entorno y manejar el caching con la
estrategia apropiada para el servidor (functools.lru_cache, redis, etc.).
"""
from datetime import datetime

import pandas as pd
import streamlit as st

from backend.repositories.sheets_repository import SheetsRepository, StockUpdateError
from backend.services.costos_service import MERMA_PCT
from backend.core.config import WORKSHEET_VENTAS


# ── Logging en session_state (específico de Streamlit) ───────────────────────

def log_error(contexto: str, error: object) -> None:
    """Registra errores en el log visible para debugging en Streamlit."""
    log = st.session_state.setdefault("error_log", [])
    now = datetime.now().strftime("%H:%M:%S")
    log.append(f"[{now}] [{contexto}] {str(error)}")
    if len(log) > 50:
        st.session_state.error_log = log[-50:]


# ── Singleton del repositorio ─────────────────────────────────────────────────

@st.cache_resource
def _get_repository() -> SheetsRepository:
    """
    Singleton de SheetsRepository por sesión de Streamlit.
    Usa las credenciales de st.secrets["gcp_service_account"].
    """
    try:
        return SheetsRepository(dict(st.secrets["gcp_service_account"]))
    except Exception as e:
        log_error("_get_repository", e)
        st.error("Error de autenticación con Google. Verifica st.secrets.")
        raise


def _limpiar_conexion() -> None:
    """Fuerza reconexión del repositorio en el próximo acceso."""
    _get_repository.clear()


# ── Lecturas con cache ────────────────────────────────────────────────────────

@st.cache_data(ttl=1800)
def cargar_catalogo() -> pd.DataFrame:
    try:
        return _get_repository().fetch_catalog()
    except Exception as e:
        log_error("cargar_catalogo", e)
        return pd.DataFrame()


def limpiar_cache_catalogo() -> None:
    cargar_catalogo.clear()


@st.cache_data(ttl=120)
def cargar_ventas() -> pd.DataFrame:
    try:
        return _get_repository().fetch_sales()
    except Exception as e:
        log_error("cargar_ventas", e)
        return pd.DataFrame()


def limpiar_cache_ventas() -> None:
    cargar_ventas.clear()


@st.cache_data(ttl=120)
def cargar_cotizaciones() -> pd.DataFrame:
    try:
        return _get_repository().fetch_quotes()
    except Exception as e:
        log_error("cargar_cotizaciones", e)
        return pd.DataFrame()


def limpiar_cache_cotizaciones() -> None:
    cargar_cotizaciones.clear()


# ── Escrituras ────────────────────────────────────────────────────────────────

def guardar_venta(filas: list[list]) -> None:
    try:
        _get_repository().append_sale_rows(filas)
        limpiar_cache_ventas()
    except Exception as e:
        log_error("guardar_venta", e)
        raise


def obtener_proximo_id() -> str:
    limpiar_cache_ventas()
    return _get_repository().get_next_sale_id()


def marcar_pedido_entregado_batch(lista_filas: list[int], col_estado: int) -> None:
    try:
        _get_repository().mark_sales_delivered_batch(lista_filas, col_estado)
        limpiar_cache_ventas()
    except Exception as e:
        log_error("marcar_pedido_entregado_batch", e)
        raise


def guardar_cotizacion(celular: str, cesta: list, total: float) -> str:
    try:
        id_cot = _get_repository().save_quote(celular, cesta, total)
        limpiar_cache_cotizaciones()
        return id_cot
    except Exception as e:
        log_error("guardar_cotizacion", e)
        raise


def actualizar_estado_cotizacion(
    id_cotizacion: str, nuevo_estado: str, fila_sheet: int
) -> None:
    try:
        df_cot = cargar_cotizaciones()
        sheet_cols = [c for c in df_cot.columns if c != "fila_sheet"]
        if "Estado" not in sheet_cols:
            raise ValueError("Falta columna Estado en Cotizaciones")
        col_estado = sheet_cols.index("Estado") + 1
        _get_repository().update_quote_status(nuevo_estado, fila_sheet, col_estado)
        limpiar_cache_cotizaciones()
    except Exception as e:
        log_error("actualizar_estado_cotizacion", e)
        raise


def actualizar_stock_perfumes_batch(items_vendidos: list) -> None:
    if not items_vendidos:
        return
    try:
        limpiar_cache_catalogo()
        _get_repository().update_stock_batch(items_vendidos, MERMA_PCT)
        limpiar_cache_catalogo()
    except Exception as e:
        log_error("actualizar_stock_perfumes_batch", e)
        raise


def actualizar_ventas_multi_fila_batch(
    filas_cambios: list[tuple[int, dict[int, object]]]
) -> None:
    try:
        _get_repository().update_sales_multi_batch(filas_cambios)
        limpiar_cache_ventas()
    except Exception as e:
        log_error("actualizar_ventas_multi_fila_batch", e)
        raise


def registrar_venta_completa(cesta: list, cliente: dict) -> str:
    """
    Registra una venta completa y actualiza el stock.
    Propaga StockUpdateError si la venta se guardó pero el stock falló.
    """
    try:
        id_compra = _get_repository().register_complete_sale(cesta, cliente, MERMA_PCT)
        limpiar_cache_ventas()
        limpiar_cache_catalogo()
        return id_compra
    except StockUpdateError:
        limpiar_cache_ventas()
        raise
    except Exception as e:
        log_error("registrar_venta_completa", e)
        raise

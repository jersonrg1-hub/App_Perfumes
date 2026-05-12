"""
data.py — Shim de compatibilidad. Fuente de verdad: frontend/streamlit/cache_adapters.py

Este módulo re-exporta desde los módulos del backend para que el código
existente en tabs/ y estadisticas/ siga funcionando sin cambios.

Decisión de arquitectura: data.py ya no contiene lógica — es una fachada.
- La lógica de red (gspread) vive en backend/repositories/sheets_repository.py
- El caching Streamlit vive en frontend/streamlit/cache_adapters.py
- StockUpdateError se define en backend/repositories/sheets_repository.py

Para FastAPI: importar SheetsRepository directamente. No usar este módulo.
"""
from frontend.streamlit.cache_adapters import (
    log_error,
    cargar_catalogo,
    limpiar_cache_catalogo,
    cargar_ventas,
    limpiar_cache_ventas,
    cargar_cotizaciones,
    limpiar_cache_cotizaciones,
    guardar_venta,
    obtener_proximo_id,
    marcar_pedido_entregado_batch,
    guardar_cotizacion,
    actualizar_estado_cotizacion,
    actualizar_stock_perfumes_batch,
    actualizar_ventas_multi_fila_batch,
    registrar_venta_completa,
)
from backend.repositories.sheets_repository import StockUpdateError

__all__ = [
    "log_error",
    "cargar_catalogo", "limpiar_cache_catalogo",
    "cargar_ventas", "limpiar_cache_ventas",
    "cargar_cotizaciones", "limpiar_cache_cotizaciones",
    "guardar_venta", "obtener_proximo_id",
    "marcar_pedido_entregado_batch",
    "guardar_cotizacion", "actualizar_estado_cotizacion",
    "actualizar_stock_perfumes_batch", "actualizar_ventas_multi_fila_batch",
    "registrar_venta_completa",
    "StockUpdateError",
]

"""
config.py — Shim de compatibilidad. Fuente de verdad: backend/core/config.py

Este módulo re-exporta todo desde backend/ para que el código existente
en tabs/, estadisticas/ y otros módulos siga funcionando sin cambios.

Para nuevo código: importar directamente desde backend.core.config,
backend.models.schemas y backend.utils.formatters.
"""
# Constantes y helpers de configuración
from backend.core.config import (
    SCOPES,
    SHEET_NAME,
    WORKSHEET_CATALOGO,
    WORKSHEET_VENTAS,
    WORKSHEET_COTIZACIONES,
    PRECIOS_COLUMNAS,
    ML_OPCIONES,
    METODOS_PAGO,
    TIPOS_ENVIO,
    COLUMNAS_REQUERIDAS,
    COLUMNAS_VENTAS,
    COL_ESTADO_NUM,
    STOCK_CRITICO,
    STOCK_BAJO,
    TZ_PERU,
    hoy_peru,
    fmt_fecha,
    fmt_precio,
)

# Modelos de datos (TypedDicts)
from backend.models.schemas import ItemCesta, DatosCliente

# Helpers HTML de stock (antes vivían aquí, ahora en backend/utils/formatters.py)
from backend.utils.formatters import stock_badge_html, stock_barra_html

__all__ = [
    # Sheets
    "SCOPES", "SHEET_NAME",
    "WORKSHEET_CATALOGO", "WORKSHEET_VENTAS", "WORKSHEET_COTIZACIONES",
    # Precios
    "PRECIOS_COLUMNAS", "ML_OPCIONES",
    # Opciones
    "METODOS_PAGO", "TIPOS_ENVIO",
    # Columnas
    "COLUMNAS_REQUERIDAS", "COLUMNAS_VENTAS", "COL_ESTADO_NUM",
    # Stock
    "STOCK_CRITICO", "STOCK_BAJO",
    # Tiempo
    "TZ_PERU", "hoy_peru",
    # Formatters
    "fmt_fecha", "fmt_precio",
    # Modelos
    "ItemCesta", "DatosCliente",
    # HTML stock
    "stock_badge_html", "stock_barra_html",
]

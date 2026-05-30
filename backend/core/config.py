"""
backend/core/config.py — Constantes y configuración global de la aplicación.

Este módulo NO tiene dependencias de Streamlit y puede ser usado directamente
por FastAPI. Contiene solo valores de configuración y funciones helpers puras.

Fuente de verdad: todo lo que estaba en el config.py raíz ahora vive aquí.
El config.py raíz es un shim de compatibilidad que re-exporta desde aquí.
"""
import pytz
import pandas as pd
from datetime import datetime

# ── Google Sheets ─────────────────────────────────────────────────────────────

SCOPES = [
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive",
]

SHEET_NAME = "PERFUMES PYTHON"
WORKSHEET_CATALOGO = "Catalogo"
WORKSHEET_VENTAS = "Ventas_Pendientes"
WORKSHEET_COTIZACIONES = "Cotizaciones"

# ── Precios y tamaños ─────────────────────────────────────────────────────────

PRECIOS_COLUMNAS: dict[str, str] = {
    "2 ml":  "Precio_2ml",
    "5 ml":  "Precio_5ml",
    "10 ml": "Precio_10ml",
}

ML_OPCIONES: list[int] = [int(k.replace(" ml", "")) for k in PRECIOS_COLUMNAS]

# ── Listas de opciones ────────────────────────────────────────────────────────

METODOS_PAGO: list[str] = ["Yape", "Plin", "Transferencia", "Tarjeta"]

TIPOS_ENVIO: list[str] = ["Shalom", "Motorizado", "Contraentrega"]

# ── Columnas de hojas de cálculo ──────────────────────────────────────────────

COLUMNAS_REQUERIDAS: list[str] = ["Marca", "Nombre"] + list(PRECIOS_COLUMNAS.values())

COLUMNAS_VENTAS: list[str] = [
    "ID_Compra", "Fecha", "Comprador", "Celular",
    "ID_Perfume", "Ml_Vendido", "Precio_Cobrado",
    "Metodo_Pago", "Tipo_Envio", "Direccion", "Distrito", "Estado",
]

# Posición 1-indexed de la columna "Estado" en COLUMNAS_VENTAS (para batch_update)
COL_ESTADO_NUM: int = COLUMNAS_VENTAS.index("Estado") + 1

# ── Stock ─────────────────────────────────────────────────────────────────────

STOCK_CRITICO: int = 10   # ml — muestra badge rojo
STOCK_BAJO: int = 20      # ml — muestra badge amarillo

# ── Zona horaria ──────────────────────────────────────────────────────────────

TZ_PERU = pytz.timezone("America/Lima")


def hoy_peru():
    """Retorna la fecha actual en zona horaria de Lima."""
    return datetime.now(TZ_PERU).date()


# ── Formatters puros ──────────────────────────────────────────────────────────

def fmt_fecha(fecha) -> str:
    """Formatea una fecha como 'DD/MM/YYYY'. Acepta str, Timestamp o date."""
    try:
        if isinstance(fecha, str):
            fecha = pd.to_datetime(fecha, errors="coerce")
        return fecha.strftime("%d/%m/%Y")
    except Exception:
        return str(fecha)


def fmt_precio(valor) -> str:
    """Formatea un valor numérico como precio con 2 decimales."""
    try:
        return f"{float(valor):.2f}"
    except Exception:
        return str(valor)

import pytz
import pandas as pd
from datetime import datetime
from typing import TypedDict


class ItemCesta(TypedDict):
    perfume: str
    marca: str
    id_perfume: str
    ml: int
    precio: float
    metodo: str

SCOPES = [
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive"
]

SHEET_NAME = "PERFUMES PYTHON"
WORKSHEET_CATALOGO = "Catalogo"
WORKSHEET_VENTAS = "Ventas_Pendientes"
WORKSHEET_COTIZACIONES = "Cotizaciones"

PRECIOS_COLUMNAS = {
    "2 ml":  "Precio_2ml",
    "5 ml":  "Precio_5ml",
    "10 ml": "Precio_10ml"
}

ML_OPCIONES = [int(k.replace(" ml", "")) for k in PRECIOS_COLUMNAS.keys()]

METODOS_PAGO = ["Efectivo", "Yape", "Plin", "Transferencia", "Tarjeta"]

TIPOS_ENVIO = ["Shalom", "Motorizado", "Contraentrega"]

COLUMNAS_REQUERIDAS = ["Marca", "Nombre"] + list(PRECIOS_COLUMNAS.values())

COLUMNAS_VENTAS = [
    "ID_Compra", "Fecha", "Comprador", "Celular",
    "ID_Perfume", "Ml_Vendido", "Precio_Cobrado",
    "Metodo_Pago", "Tipo_Envio", "Direccion", "Estado"
]

COL_ESTADO_NUM = COLUMNAS_VENTAS.index("Estado") + 1

TZ_PERU = pytz.timezone("America/Lima")


def hoy_peru():
    return datetime.now(TZ_PERU).date()


def fmt_fecha(fecha):
    try:
        if isinstance(fecha, str):
            fecha = pd.to_datetime(fecha, errors="coerce")
        return fecha.strftime("%d/%m/%Y")
    except Exception:
        return str(fecha)


def fmt_precio(valor):
    try:
        return f"{float(valor):.2f}"
    except Exception:
        return str(valor)


STOCK_CRITICO  = 10
STOCK_BAJO     = 20


def stock_badge_html(stock_ml, size="sm"):
    try:
        n = float(stock_ml)
    except (TypeError, ValueError):
        return ""
    if n <= 0:
        return ""

    if size == "lg":
        fs, pad = "0.85rem", "4px 12px"
    else:
        fs, pad = "0.7rem", "2px 8px"

    if n <= STOCK_CRITICO:
        bg, color, icono, label = "#fee2e2", "#991b1b", "🔴", f"{n:.0f}ml — crítico"
        extra_class = "stock-critico-badge"
    elif n <= STOCK_BAJO:
        bg, color, icono, label = "#fef9c3", "#854d0e", "🟡", f"{n:.0f}ml — bajo"
        extra_class = ""
    else:
        bg, color, icono, label = "#dcfce7", "#166534", "🟢", f"{n:.0f}ml"
        extra_class = ""

    return (
        f"<span class='{extra_class}' style='background:{bg}; color:{color}; font-size:{fs}; "
        f"padding:{pad}; border-radius:20px; font-weight:600; "
        f"display:inline-block; margin-left:4px;'>{icono} {label}</span>"
    )


def stock_barra_html(stock_ml, max_ml=100):
    try:
        n = float(stock_ml)
    except (TypeError, ValueError):
        return ""
    if n <= 0:
        return ""
    pct = min(100, int((n / max_ml) * 100))
    if n <= STOCK_CRITICO:
        color = "#ef4444"
    elif n <= STOCK_BAJO:
        color = "#eab308"
    else:
        color = "#22c55e"
    return (
        f"<div style='background:#f0e0d0; border-radius:4px; height:5px; "
        f"margin-top:4px; overflow:hidden;'>"
        f"<div style='width:{pct}%; height:100%; background:{color}; "
        f"border-radius:4px;'></div></div>"
        f"<div style='font-size:0.7rem; color:#a07850; text-align:right; "
        f"margin-top:2px;'>{n:.0f}ml</div>"
    )
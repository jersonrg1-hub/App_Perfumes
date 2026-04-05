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

import pytz
TZ_PERU = pytz.timezone("America/Lima")

def hoy_peru():
    """Devuelve la fecha de hoy en hora peruana, no del servidor."""
    from datetime import datetime
    return datetime.now(TZ_PERU).date()

def fmt_fecha(fecha):
    """Formatea fecha a dd/mm/aaaa para mostrar en pantalla."""
    try:
        import pandas as pd
        if isinstance(fecha, str):
            fecha = pd.to_datetime(fecha, errors="coerce")
        return fecha.strftime("%d/%m/%Y")
    except:
        return str(fecha)

def fmt_precio(valor):
    """Formatea un precio con 2 decimales. Ej: 10.9 → 10.90"""
    try:
        return f"{float(valor):.2f}"
    except:
        return str(valor)

STOCK_CRITICO  = 5
STOCK_BAJO     = 15

def stock_badge_html(stock_ml, size="sm"):
    """Devuelve un badge HTML de stock con color semáforo."""
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
    elif n <= STOCK_BAJO:
        bg, color, icono, label = "#fef9c3", "#854d0e", "🟡", f"{n:.0f}ml — bajo"
    else:
        bg, color, icono, label = "#dcfce7", "#166534", "🟢", f"{n:.0f}ml"

    return (
        f"<span style='background:{bg}; color:{color}; font-size:{fs}; "
        f"padding:{pad}; border-radius:20px; font-weight:600; "
        f"display:inline-block; margin-left:4px;'>{icono} {label}</span>"
    )

def stock_barra_html(stock_ml, max_ml=100):
    """Devuelve una barra visual de nivel de stock."""
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
# ── Scopes de Google ───────────────────────────────────────
SCOPES = [
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive"
]

# ── Nombres del Google Sheet ───────────────────────────────
SHEET_NAME = "PERFUMES PYTHON"
WORKSHEET_CATALOGO = "Catalogo"
WORKSHEET_VENTAS = "Ventas_Pendientes"

# ── Tamaños y columnas de precios ──────────────────────────
# ⚠️ Si agregas un tamaño aquí se actualiza todo automáticamente
PRECIOS_COLUMNAS = {
    "2 ml":  "Precio_2ml",
    "5 ml":  "Precio_5ml",
    "10 ml": "Precio_10ml"
}

# Derivado automáticamente de PRECIOS_COLUMNAS
ML_OPCIONES = [int(k.replace(" ml", "")) for k in PRECIOS_COLUMNAS.keys()]

# ── Métodos de pago ────────────────────────────────────────
METODOS_PAGO = ["Efectivo", "Yape", "Plin", "Transferencia", "Tarjeta"]

# ── Tipos de envío ─────────────────────────────────────────
TIPOS_ENVIO = ["Shalom", "Motorizado", "Contraentrega"]

# ── Columnas requeridas en el catálogo ─────────────────────
# Derivado automáticamente de PRECIOS_COLUMNAS
COLUMNAS_REQUERIDAS = ["Marca", "Nombre"] + list(PRECIOS_COLUMNAS.values())

# ── Columnas de Ventas_Pendientes ──────────────────────────
COLUMNAS_VENTAS = [
    "ID_Compra", "Fecha", "Comprador", "Celular",
    "ID_Perfume", "Ml_Vendido", "Precio_Cobrado",
    "Metodo_Pago", "Tipo_Envio", "Direccion", "Estado"
]

# ── Número de columna Estado en Sheets (base 1) ────────────
# ⚠️ IMPORTANTE: Si reordenas columnas en Ventas_Pendientes
# actualiza este número. Estado debe ser la columna 11.
COL_ESTADO_NUM = COLUMNAS_VENTAS.index("Estado") + 1

# ── Formato de precios ─────────────────────────────────────
def fmt_precio(valor):
    """Formatea un precio con 2 decimales. Ej: 10.9 → 10.90"""
    try:
        return f"{float(valor):.2f}"
    except:
        return str(valor)
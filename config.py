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
PRECIOS_COLUMNAS = {
    "2 ml":  "Precio_2ml",
    "5 ml":  "Precio_5ml",
    "10 ml": "Precio_10ml"
}

# ── Tamaños disponibles para venta ─────────────────────────
ML_OPCIONES = [2, 5, 10]

# ── Métodos de pago ────────────────────────────────────────
METODOS_PAGO = ["Efectivo", "Yape", "Plin", "Transferencia", "Tarjeta"]

# ── Tipos de envío ─────────────────────────────────────────
TIPOS_ENVIO = ["Shalom", "Motorizado", "Contraentrega"]

# ── Columnas requeridas en el catálogo ─────────────────────
COLUMNAS_REQUERIDAS = [
    "Marca", "Nombre", "Precio_2ml",
    "Precio_5ml", "Precio_10ml"
]

# ── Columnas de Ventas_Pendientes ──────────────────────────
COLUMNAS_VENTAS = [
    "ID_Compra", "Fecha", "Comprador", "Celular",
    "ID_Perfume", "Ml_Vendido", "Precio_Cobrado",
    "Metodo_Pago", "Tipo_Envio", "Direccion", "Estado"
]

# ── Número de columna Estado en Sheets (base 1) ────────────
COL_ESTADO_NUM = 11
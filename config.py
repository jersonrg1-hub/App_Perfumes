# ── Scopes de Google ───────────────────────────────────────
SCOPES = [
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive"
]

# ── Nombre del Google Sheet ────────────────────────────────
SHEET_NAME = "PERFUMES PYTHON"
WORKSHEET_NAME = "Catalogo"

# ── Tamaños disponibles y sus columnas en el sheet ─────────
PRECIOS_COLUMNAS = {
    "2 ml":  "Precio_2ml",
    "5 ml":  "Precio_5ml",
    "10 ml": "Precio_10ml"
}
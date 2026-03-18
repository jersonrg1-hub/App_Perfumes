# ── Costos de Viales por tamaño ─────────────────────────────
COSTO_VIALES = {
    2:  1.10,
    3:  1.07,
    5:  1.30,
    10: 1.40
}

# ── Tamaños disponibles en ML ────────────────────────────────
TAMANIOS_ML = [2, 3, 5, 10]

# ── Desglose de insumos de packaging ─────────────────────────
INSUMOS = {
    "Etiqueta":              0.16,
    "Jeringa":               0.03,
    "Adaptador de Jeringa":  1.00,
    "Cinta Teflón":          0.02,
    "Caja de Envío":         0.68,
    "Tarjeta Agradecimiento":0.07,
    "Sticker para Sellar":   0.40,
    "Viruta de Papel":       0.56,
    "Papel Burbuja":         0.10,
    "Caramelo":              0.28,
    "Guantes":               0.25,
    "Cinta Embalaje":        0.03,
    "Strech Film":           0.07,
}

# ── Costo total de packaging (suma de insumos) ───────────────
COSTO_PACKAGING = sum(INSUMOS.values())

# ── Parámetros de precio ─────────────────────────────────────
MERMA = 0.10             # 10% de merma en líquido
MARGEN_GANANCIA = 0.40   # 40% sobre precio de venta final

# ── Ajuste por medio de pago ─────────────────────────────────
# 1.00 = sin recargo | 1.05 = +5% tarjeta | etc.
AJUSTES_PAGO = {
    "Efectivo / Yape / Plin": 1.00,
    "Tarjeta (+ 5%)":         1.05,
}
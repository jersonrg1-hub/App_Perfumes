# ─────────────────────────────────────────────
#  COSTOS DE PRODUCCIÓN POR VENTA
#  Todos los valores están en SOLES (S/)
#  Editar estos valores cuando cambien los precios
# ─────────────────────────────────────────────

# Costo del vial según tamaño vendido
COSTO_VIAL = {
    2:  1.00,   # Vial 2ml
    3:  1.20,   # Vial 3ml
    5:  1.50,   # Vial 5ml
    10: 1.60,   # Vial 10ml
}

# Costo fijo de empaque por cada item vendido (S/)
# Incluye: etiqueta (0.16) + jeringa (0.03) + adaptador (0.05) + teflón (0.02)
#          + caja envío (0.68) + tarjeta (0.10) + sticker (0.40) + viruta (0.56)
#          + espuma (0.05) + caramelo (0.25) + guantes (0.20)
#          + cinta embalaje (0.03) + stretch film (0.07)
COSTO_EMPAQUE = 2.60


def costo_por_item(ml: int) -> float:
    """Costo total de un item vendido: vial + empaque."""
    return COSTO_VIAL.get(ml, 0.0) + COSTO_EMPAQUE

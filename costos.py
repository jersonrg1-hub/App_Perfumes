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
    """Costo de vial + empaque (sin contar el perfume en sí)."""
    return COSTO_VIAL.get(ml, 0.0) + COSTO_EMPAQUE


def costo_total_item(ml: int, costo_botella: float, ml_botella: float) -> float:
    """Costo total: vial + empaque + perfume proporcional."""
    costo_perf = (costo_botella / ml_botella * ml) if ml_botella > 0 else 0.0
    return costo_por_item(ml) + costo_perf


def construir_costo_ml_dict(df_catalogo) -> dict:
    """Devuelve {str(ID_Perfume): costo_por_ml} para todos los perfumes."""
    resultado = {}
    if df_catalogo is None or df_catalogo.empty:
        return resultado
    if not {"ID_Perfume", "Costo_Botella", "Ml_Botella"}.issubset(df_catalogo.columns):
        return resultado
    for _, row in df_catalogo.iterrows():
        try:
            cb = float(row["Costo_Botella"])
            mb = float(row["Ml_Botella"])
            if mb > 0:
                resultado[str(row["ID_Perfume"])] = cb / mb
        except (TypeError, ValueError):
            pass
    return resultado


def calcular_costo_ventas_df(df, df_catalogo) -> float:
    """Calcula el costo total de un DataFrame de ventas."""
    costo_ml_dict = construir_costo_ml_dict(df_catalogo)
    total = 0.0
    for _, row in df.iterrows():
        try:
            ml = int(row["Ml_Vendido"])
        except (TypeError, ValueError):
            continue
        costo_perf = costo_ml_dict.get(str(row.get("ID_Perfume", "")), 0.0) * ml
        total += costo_por_item(ml) + costo_perf
    return total

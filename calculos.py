from variables import COSTO_VIALES, COSTO_PACKAGING, MERMA, MARGEN_GANANCIA

def calcular_precio(costo_botella, ml_botella, ml_seleccionado, ajuste_pago=1.0):
    """
    Calcula el precio de venta de un decant.
    Retorna un diccionario con el desglose completo.
    """

    # 1. Costo por ML del perfume
    costo_ml = costo_botella / ml_botella

    # 2. ML reales con merma (10% extra)
    ml_con_merma = ml_seleccionado * (1 + MERMA)

    # 3. Costo del líquido
    subtotal_liquido = costo_ml * ml_con_merma

    # 4. Costo del vial según tamaño
    costo_vial = COSTO_VIALES.get(ml_seleccionado, 0)

    # 5. Costo total de producción
    costo_total = subtotal_liquido + costo_vial + COSTO_PACKAGING

    # 6. Precio final (margen sobre venta)
    precio_final = (costo_total / (1 - MARGEN_GANANCIA)) * ajuste_pago

    # 7. Ganancia neta
    ganancia_neta = precio_final - costo_total

    return {
        "costo_ml":          round(costo_ml, 2),
        "ml_con_merma":      round(ml_con_merma, 2),
        "subtotal_liquido":  round(subtotal_liquido, 2),
        "costo_vial":        round(costo_vial, 2),
        "costo_packaging":   round(COSTO_PACKAGING, 2),
        "costo_total":       round(costo_total, 2),
        "margen":            f"{MARGEN_GANANCIA*100:.0f}%",
        "precio_final":      round(precio_final, 2),
        "ganancia_neta":     round(ganancia_neta, 2),
    }
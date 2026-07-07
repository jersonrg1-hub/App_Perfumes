"""
backend/services/cotizacion_service.py — Lógica pura de descuento y total para cotizaciones.

Sin imports de Streamlit ni de Google Sheets. Funciones puras.
"""
from backend.core.config import DESCUENTO_COTIZACION_PCT


def precio_con_descuento(precio: float) -> float:
    """Aplica DESCUENTO_COTIZACION_PCT y redondea al décimo de sol más cercano."""
    return round(precio * (1 - DESCUENTO_COTIZACION_PCT) * 10) / 10


def aplicar_descuentos(items: list[dict]) -> list[dict]:
    """
    Retorna una copia de items con 'precio' reemplazado por el precio con
    descuento cuando el item trae con_descuento=True.
    """
    resultado = []
    for item in items:
        item = dict(item)
        if item.get("con_descuento"):
            item["precio"] = precio_con_descuento(item["precio"])
        resultado.append(item)
    return resultado


def calcular_total_cotizacion(items: list[dict]) -> float:
    """Suma los precios (ya con descuento aplicado) de los items."""
    return round(sum(item["precio"] for item in items), 2)

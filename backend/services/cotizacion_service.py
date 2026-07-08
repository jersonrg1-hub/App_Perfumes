"""
backend/services/cotizacion_service.py — Lógica pura de descuento y total para cotizaciones.

Sin imports de Streamlit ni de Google Sheets. Funciones puras.
"""
from backend.core.config import DESCUENTO_COTIZACION_PCT, fmt_precio


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


def construir_items_txt(items: list[dict]) -> str:
    """
    Serializa items a texto para la columna Items de la hoja Cotizaciones.

    Embebe el ID_Perfume real de cada item como sufijo "[#ID]" para que al
    convertir la cotización en venta no haga falta reconstruir el ID
    adivinando el perfume por nombre — con catálogos grandes, nombres
    parecidos o duplicados entre marcas hacían que ese matching por texto
    eligiera el perfume equivocado y descontara stock del ítem incorrecto.
    """
    return " | ".join(
        f"{i.get('marca', '')} {i['perfume']} {i['ml']}ml S/{fmt_precio(i['precio'])} [#{i['id_perfume']}]".strip()
        for i in items
    )

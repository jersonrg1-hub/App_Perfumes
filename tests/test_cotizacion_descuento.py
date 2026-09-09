"""
Tests de backend/services/cotizacion_service.py — descuento 10% por item.

precio_con_descuento() redondea half-away-from-zero (no el half-to-even de
round() de Python) para coincidir con Dart en el frontend
(`(p * 10).round() / 10.0`). El caso de riesgo es el empate exacto en .5
tras aplicar el 10% y multiplicar por 10 — ver docstring de la función.
"""
from backend.services.cotizacion_service import (
    aplicar_descuentos,
    calcular_total_cotizacion,
    precio_con_descuento,
)


def test_precio_con_descuento_caso_simple():
    assert precio_con_descuento(25.0) == 22.5


def test_precio_con_descuento_empate_exacto_redondea_arriba():
    """precio=4.50 -> *0.9 = 4.05 -> *10 = 40.5, empate exacto en .5.
    half-away-from-zero debe redondear a 41 (4.1), no a 40 (4.0) como
    haría el half-to-even de round() de Python."""
    assert precio_con_descuento(4.50) == 4.1


def test_aplicar_descuentos_solo_afecta_items_marcados():
    items = [
        {"precio": 25.0, "con_descuento": True},
        {"precio": 10.0, "con_descuento": False},
    ]
    resultado = aplicar_descuentos(items)
    assert resultado[0]["precio"] == 22.5
    assert resultado[1]["precio"] == 10.0


def test_aplicar_descuentos_no_muta_items_originales():
    items = [{"precio": 25.0, "con_descuento": True}]
    aplicar_descuentos(items)
    assert items[0]["precio"] == 25.0


def test_calcular_total_cotizacion_suma_precios_mixtos():
    items = aplicar_descuentos([
        {"precio": 25.0, "con_descuento": True},   # -> 22.5
        {"precio": 10.0, "con_descuento": False},  # -> 10.0
    ])
    assert calcular_total_cotizacion(items) == 32.5

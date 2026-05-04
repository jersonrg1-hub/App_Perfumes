"""
logic/ — Capa de lógica de negocio pura.

Sin dependencias de Streamlit. Todas las funciones son puras:
entrada de datos → resultado, sin efectos secundarios en session_state ni IO.
Testeable de forma aislada.
"""
from logic.venta import (
    filtrar_catalogo,
    precio_catalogo,
    construir_item,
    eliminar_item,
    calcular_total,
    buscar_cliente_previo,
    validar_paso_cliente,
)

__all__ = [
    "filtrar_catalogo",
    "precio_catalogo",
    "construir_item",
    "eliminar_item",
    "calcular_total",
    "buscar_cliente_previo",
    "validar_paso_cliente",
]

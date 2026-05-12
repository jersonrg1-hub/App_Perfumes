"""
logic/venta.py — Shim de compatibilidad. Fuente de verdad: backend/services/venta_service.py

Re-exporta todo para que el código existente siga funcionando sin cambios.
Para nuevo código: importar directamente desde backend.services.venta_service.
"""
from backend.services.venta_service import (
    filtrar_catalogo,
    precio_catalogo,
    construir_item,
    eliminar_item,
    calcular_total,
    buscar_cliente_previo,
    validar_paso_cliente,
)

__all__ = [
    "filtrar_catalogo", "precio_catalogo",
    "construir_item", "eliminar_item", "calcular_total",
    "buscar_cliente_previo", "validar_paso_cliente",
]

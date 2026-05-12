"""
costos.py — Shim de compatibilidad. Fuente de verdad: backend/services/costos_service.py

Re-exporta todo para que el código existente siga funcionando sin cambios.
Para nuevo código: importar directamente desde backend.services.costos_service.
"""
from backend.services.costos_service import (
    COSTO_VIAL,
    MERMA_PCT,
    COSTO_EMPAQUE,
    costo_por_item,
    costo_total_item,
    construir_costo_ml_dict,
    calcular_costo_ventas_df,
)

__all__ = [
    "COSTO_VIAL", "MERMA_PCT", "COSTO_EMPAQUE",
    "costo_por_item", "costo_total_item",
    "construir_costo_ml_dict", "calcular_costo_ventas_df",
]

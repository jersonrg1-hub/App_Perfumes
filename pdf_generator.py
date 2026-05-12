"""
pdf_generator.py — Shim de compatibilidad. Fuente de verdad: backend/services/pdf_service.py

Re-exporta todo para que el código existente siga funcionando sin cambios.
Para nuevo código: importar directamente desde backend.services.pdf_service.
"""
from backend.services.pdf_service import (
    exportar_pdf_ventas_hoy,
    exportar_pdf_ventas_mes,
    exportar_pdf_mes_especifico,
)

__all__ = [
    "exportar_pdf_ventas_hoy",
    "exportar_pdf_ventas_mes",
    "exportar_pdf_mes_especifico",
]

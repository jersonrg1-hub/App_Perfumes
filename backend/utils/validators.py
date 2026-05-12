"""
backend/utils/validators.py — Validaciones puras de datos.

Sin dependencias de Streamlit. Reutilizable desde FastAPI para validar
payloads de entrada en endpoints.

Fuente de verdad: validar_dataframe() extraída de errores.py.
"""
import pandas as pd
from backend.core.config import COLUMNAS_REQUERIDAS


def validar_dataframe(df: pd.DataFrame) -> list[str]:
    """
    Verifica que el DataFrame tenga todas las columnas requeridas.
    Retorna lista de columnas faltantes (vacía = DataFrame válido).
    """
    return [c for c in COLUMNAS_REQUERIDAS if c not in df.columns]


def validar_celular(celular: str) -> bool:
    """Retorna True si el celular tiene exactamente 9 dígitos."""
    return len(celular) == 9 and celular.isdigit()


def validar_ml(ml: int, opciones_validas: list[int]) -> bool:
    """Retorna True si el tamaño en ml es una opción válida."""
    return ml in opciones_validas

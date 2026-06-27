"""
backend/services/venta_service.py — Lógica pura de negocio para ventas.

Sin imports de Streamlit ni de Google Sheets. Todas las funciones son puras:
reciben datos, retornan resultados, no modifican estado global.
"""
import pandas as pd


def filtrar_catalogo(
    df: pd.DataFrame,
    texto: str = "",
    marca: str | None = None,
) -> pd.DataFrame:
    """
    Filtra el catálogo por texto libre (nombre o marca) y/o marca exacta.
    Usa las columnas pre-computadas *_lower si están disponibles (más rápido).
    """
    result = df
    if marca:
        result = result[result["Marca"] == marca]
    if texto.strip():
        t = texto.strip().lower()
        if "Nombre_lower" in result.columns:
            mask = (
                result["Nombre_lower"].str.contains(t, regex=False, na=False)
                | result["Marca_lower"].str.contains(t, regex=False, na=False)
            )
        else:
            mask = (
                result["Nombre"].str.contains(t, case=False, na=False, regex=False)
                | result["Marca"].str.contains(t, case=False, na=False, regex=False)
            )
        result = result[mask]
    return result


def precio_catalogo(perfume_row, ml: str) -> float | None:
    """
    Retorna el precio de catálogo para un tamaño, o None si no está configurado.
    Trata como "no configurado" los valores 0, "" y None.
    """
    col = f"Precio_{ml}ml"
    val = perfume_row.get(col)
    if val in (0, "", None):
        return None
    try:
        return float(val)
    except (TypeError, ValueError):
        return None

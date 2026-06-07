"""
backend/utils/formatters.py — Utilidades de formato para lookup de catálogo.
"""


def construir_catalogo_dict(df_catalogo) -> dict[str, str]:
    """Retorna {str(ID_Perfume): Nombre} para lookup O(1) desde ventas."""
    if df_catalogo is None or df_catalogo.empty:
        return {}
    return dict(zip(df_catalogo["ID_Perfume"].astype(str), df_catalogo["Nombre"]))


def nombre_por_id(catalogo_dict: dict, id_perfume) -> str:
    """Resuelve el nombre de un perfume a partir de su ID."""
    return catalogo_dict.get(str(id_perfume), f"ID: {id_perfume}")

"""Test de _serializar_catalogo agregando completos por id_perfume."""
import pandas as pd

from backend.api.routes.catalogo import _serializar_catalogo


def test_serializar_catalogo_adjunta_completos_por_id():
    df = pd.DataFrame([
        {"ID_Perfume": "5", "Marca": "Burberry", "Nombre": "Her edp",
         "Precio_2ml": 10, "Precio_5ml": 20, "Precio_10ml": 35, "Stock_ml": 40},
        {"ID_Perfume": "9", "Marca": "Dior", "Nombre": "Sauvage",
         "Precio_2ml": 12, "Precio_5ml": 25, "Precio_10ml": 40, "Stock_ml": 30},
    ])
    completos = {"5": [{"ml": 50, "precio": 340.0}, {"ml": 100, "precio": 460.0}]}

    filas = _serializar_catalogo(df, completos)

    assert filas[0]["completos"] == [{"ml": 50, "precio": 340.0}, {"ml": 100, "precio": 460.0}]
    assert filas[1]["completos"] == []

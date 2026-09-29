"""Tests de _serializar_catalogo agregando completos por id_perfume, y de que
un fallo al leer Precios_Completos no tumbe el catálogo con un 500 genérico."""
from unittest.mock import MagicMock, patch

import pandas as pd
import pytest
from fastapi import HTTPException

from backend.api.routes import catalogo as catalogo_route
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


def test_listar_catalogo_503_si_falla_completos_no_500_generico():
    """Si Catalogo se lee bien pero Precios_Completos falla, debe seguir el
    patrón 503 del resto del proyecto — no un 500 sin manejar."""
    repo = MagicMock()

    with patch.object(catalogo_route, "get_catalogo_cached", return_value=pd.DataFrame()), \
         patch.object(catalogo_route, "get_completos_cached", side_effect=RuntimeError("caido")):
        with pytest.raises(HTTPException) as exc_info:
            catalogo_route.listar_catalogo(limit=100, offset=0, repo=repo)

    assert exc_info.value.status_code == 503

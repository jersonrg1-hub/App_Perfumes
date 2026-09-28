"""Tests del cache de precios de completos en backend/api/dependencies.py."""
from unittest.mock import MagicMock

import pandas as pd

from backend.api import dependencies as deps


def test_get_completos_cached_agrupa_por_id_perfume():
    deps.invalidar_cache_completos()
    repo = MagicMock()
    repo.fetch_precios_completos.return_value = pd.DataFrame([
        {"ID_Perfume": "5", "Ml": 50, "Precio": 340.0},
        {"ID_Perfume": "5", "Ml": 100, "Precio": 460.0},
        {"ID_Perfume": "9", "Ml": 30, "Precio": 150.0},
    ])

    resultado = deps.get_completos_cached(repo)

    assert resultado["5"] == [{"ml": 50, "precio": 340.0}, {"ml": 100, "precio": 460.0}]
    assert resultado["9"] == [{"ml": 30, "precio": 150.0}]


def test_get_completos_cached_usa_cache_en_segunda_llamada():
    deps.invalidar_cache_completos()
    repo = MagicMock()
    repo.fetch_precios_completos.return_value = pd.DataFrame([
        {"ID_Perfume": "5", "Ml": 50, "Precio": 340.0},
    ])

    deps.get_completos_cached(repo)
    deps.get_completos_cached(repo)

    repo.fetch_precios_completos.assert_called_once()


def test_invalidar_cache_completos_fuerza_recarga():
    deps.invalidar_cache_completos()
    repo = MagicMock()
    repo.fetch_precios_completos.return_value = pd.DataFrame([
        {"ID_Perfume": "5", "Ml": 50, "Precio": 340.0},
    ])

    deps.get_completos_cached(repo)
    deps.invalidar_cache_completos()
    deps.get_completos_cached(repo)

    assert repo.fetch_precios_completos.call_count == 2

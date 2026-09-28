"""Tests de CompletoPrecio, PerfumeResponse.completos e ItemCestaAPI.ml libre."""
import pytest
from pydantic import ValidationError

from backend.api.models import CompletoPrecio, ItemCestaAPI, PerfumeResponse


def test_perfume_response_completos_default_vacio():
    p = PerfumeResponse(id_perfume="P001", marca="Dior", nombre="Sauvage")
    assert p.completos == []


def test_perfume_response_acepta_lista_de_completos():
    p = PerfumeResponse(
        id_perfume="P001", marca="Dior", nombre="Sauvage",
        completos=[{"ml": 100, "precio": 320.0}],
    )
    assert p.completos == [CompletoPrecio(ml=100, precio=320.0)]


def test_item_cesta_acepta_tamano_de_completo():
    item = ItemCestaAPI(
        perfume="Sauvage", marca="Dior", id_perfume="P001",
        ml=100, precio=320.0, metodo="Yape",
    )
    assert item.ml == 100


def test_item_cesta_sigue_aceptando_tamanos_de_decant():
    item = ItemCestaAPI(
        perfume="Sauvage", marca="Dior", id_perfume="P001",
        ml=5, precio=25.0, metodo="Yape",
    )
    assert item.ml == 5


def test_item_cesta_rechaza_ml_fuera_de_rango():
    with pytest.raises(ValidationError):
        ItemCestaAPI(
            perfume="Sauvage", marca="Dior", id_perfume="P001",
            ml=500, precio=320.0, metodo="Yape",
        )

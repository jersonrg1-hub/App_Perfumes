"""Tests del campo alias opcional en modelos de request/response."""
from backend.api.models import (
    VentaRequest, CotizacionRequest,
    VentaResponse, CotizacionResponse, ClientePrevioResponse,
)


def _venta_kwargs(**overrides):
    base = dict(
        comprador="Juan", celular="987654321", direccion="Av. Test 123",
        tipo_envio="Shalom", fecha="2026-08-02", items=[{
            "perfume": "Sauvage", "marca": "Dior", "id_perfume": "P001",
            "ml": 5, "precio": 25.0, "metodo": "Yape",
        }],
    )
    base.update(overrides)
    return base


def test_venta_request_alias_es_opcional_y_default_none():
    req = VentaRequest(**_venta_kwargs())
    assert req.alias is None


def test_venta_request_acepta_alias_explicito():
    req = VentaRequest(**_venta_kwargs(alias="perfutecalima"))
    assert req.alias == "perfutecalima"


def test_cotizacion_request_alias_es_opcional():
    req = CotizacionRequest(
        celular="987654321",
        items=[{
            "perfume": "Sauvage", "marca": "Dior", "id_perfume": "P001",
            "ml": 5, "precio": 25.0, "metodo": "Yape",
        }],
    )
    assert req.alias is None


def test_venta_response_alias_es_opcional():
    resp = VentaResponse(id_compra="V001", comprador="Juan",
                          celular="987654321", id_perfume="P001")
    assert resp.alias is None


def test_cotizacion_response_alias_es_opcional():
    resp = CotizacionResponse(id_cotizacion="C001", celular="987654321")
    assert resp.alias is None


def test_cliente_previo_response_alias_default_vacio():
    resp = ClientePrevioResponse(
        comprador="Juan", direccion="Av. Test", tipo_envio="Shalom",
        metodo_pago="Yape", total_compras=1,
    )
    assert resp.alias is None

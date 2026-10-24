import pandas as pd

from backend.api.routes.estadisticas import _tipos_envio


def _por_tipo(resultado):
    return {r["tipo"]: r for r in resultado}


def test_una_venta_con_varios_decants_cuenta_como_una():
    df = pd.DataFrame([
        {"ID_Compra": "V001", "Tipo_Envio": "Shalom", "Precio_Cobrado": 10.0},
        {"ID_Compra": "V001", "Tipo_Envio": "Shalom", "Precio_Cobrado": 20.0},
        {"ID_Compra": "V001", "Tipo_Envio": "Shalom", "Precio_Cobrado": 30.0},
        {"ID_Compra": "V001", "Tipo_Envio": "Shalom", "Precio_Cobrado": 40.0},
    ])
    r = _por_tipo(_tipos_envio(df))
    assert r["Shalom"]["cantidad"] == 1
    assert r["Shalom"]["total"] == 100.0


def test_cuenta_ventas_distintas_por_tipo():
    df = pd.DataFrame([
        {"ID_Compra": "V001", "Tipo_Envio": "Shalom",     "Precio_Cobrado": 10.0},
        {"ID_Compra": "V001", "Tipo_Envio": "Shalom",     "Precio_Cobrado": 15.0},
        {"ID_Compra": "V002", "Tipo_Envio": "Shalom",     "Precio_Cobrado": 20.0},
        {"ID_Compra": "V003", "Tipo_Envio": "Motorizado", "Precio_Cobrado": 25.0},
        {"ID_Compra": "V003", "Tipo_Envio": "Motorizado", "Precio_Cobrado": 5.0},
    ])
    r = _por_tipo(_tipos_envio(df))
    assert r["Shalom"]["cantidad"] == 2
    assert r["Shalom"]["total"] == 45.0
    assert r["Motorizado"]["cantidad"] == 1
    assert r["Motorizado"]["total"] == 30.0


def test_tipo_vacio_se_omite():
    df = pd.DataFrame([
        {"ID_Compra": "V001", "Tipo_Envio": "",       "Precio_Cobrado": 10.0},
        {"ID_Compra": "V002", "Tipo_Envio": "Shalom", "Precio_Cobrado": 10.0},
    ])
    assert list(_por_tipo(_tipos_envio(df))) == ["Shalom"]

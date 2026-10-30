import pandas as pd

from backend.api.routes.estadisticas import _compute_historico, _top_por_tipo


def _df(filas):
    base = {"ID_Compra": "V001", "Estado": "Entregado", "Fecha": "2026-10-05", "Celular": "999"}
    return pd.DataFrame([{**base, **f} for f in filas])


def _ids(lista):
    return [r["id_perfume"] for r in lista]


def test_separa_decants_de_completos_del_mismo_perfume():
    df = _df([
        {"ID_Perfume": "1", "Ml_Vendido": 10,  "Precio_Cobrado": 30.0},
        {"ID_Perfume": "1", "Ml_Vendido": 100, "Precio_Cobrado": 300.0},
        {"ID_Perfume": "2", "Ml_Vendido": 5,   "Precio_Cobrado": 15.0},
    ])
    decants, completos = _top_por_tipo(df, n=10)
    assert _ids(decants) == ["1", "2"]
    assert decants[0]["total_ml"] == 10
    assert decants[0]["total_soles"] == 30.0
    assert _ids(completos) == ["1"]
    assert completos[0]["total_ml"] == 100
    assert completos[0]["cantidad"] == 1


def test_completos_ordenados_por_unidades_no_por_ml():
    df = _df([
        {"ID_Perfume": "1", "Ml_Vendido": 200, "Precio_Cobrado": 500.0},
        {"ID_Perfume": "2", "Ml_Vendido": 50,  "Precio_Cobrado": 150.0},
        {"ID_Perfume": "2", "Ml_Vendido": 50,  "Precio_Cobrado": 150.0},
    ])
    _, completos = _top_por_tipo(df, n=10)
    assert _ids(completos) == ["2", "1"]


def test_sin_completos_devuelve_lista_vacia():
    df = _df([{"ID_Perfume": "1", "Ml_Vendido": 2, "Precio_Cobrado": 8.0}])
    decants, completos = _top_por_tipo(df, n=10)
    assert _ids(decants) == ["1"]
    assert completos == []


def test_historico_por_mes_trae_ambas_listas():
    df = _df([
        {"ID_Perfume": "1", "Ml_Vendido": 10,  "Precio_Cobrado": 30.0},
        {"ID_Perfume": "3", "Ml_Vendido": 100, "Precio_Cobrado": 300.0},
    ])
    mes = _compute_historico(df)["por_mes"][0]
    assert _ids(mes["top_decants"]) == ["1"]
    assert _ids(mes["top_completos"]) == ["3"]

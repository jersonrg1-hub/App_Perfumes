"""Tests de escritura del campo alias en Cotizaciones y Ventas_Pendientes."""
from unittest.mock import MagicMock, patch

from backend.repositories.sheets_repository import SheetsRepository


def _repo_fake():
    """SheetsRepository con _ejecutar_con_reintento pass-through y
    _get_worksheet mockeado — no toca la red."""
    repo = SheetsRepository.__new__(SheetsRepository)
    repo._worksheets = {}
    repo._client = None
    repo._spreadsheet = None
    repo._credentials_info = {}
    return repo


def test_save_quote_incluye_alias_como_septima_columna():
    repo = _repo_fake()
    ws = MagicMock()
    ws.col_values.return_value = ["ID_Cotizacion"]  # sin IDs previos -> C001

    with patch.object(repo, "_get_worksheet", return_value=ws), \
         patch.object(repo, "_ejecutar_con_reintento", side_effect=lambda fn, ctx: fn()):
        id_cot = repo.save_quote(
            celular="987654321",
            items=[{"marca": "Dior", "perfume": "Sauvage", "id_perfume": "P001",
                     "ml": 5, "precio": 25.0}],
            total=25.0,
            alias="perfutecalima",
        )

    assert id_cot == "C001"
    fila = ws.append_rows.call_args[0][0][0]
    assert fila[2] == "987654321"       # Celular sigue en posición 3
    assert fila[6] == "perfutecalima"   # alias en posición 7 (columna G)


def test_save_quote_sin_alias_escribe_string_vacio():
    repo = _repo_fake()
    ws = MagicMock()
    ws.col_values.return_value = ["ID_Cotizacion"]

    with patch.object(repo, "_get_worksheet", return_value=ws), \
         patch.object(repo, "_ejecutar_con_reintento", side_effect=lambda fn, ctx: fn()):
        repo.save_quote(
            celular="987654321",
            items=[{"marca": "Dior", "perfume": "Sauvage", "id_perfume": "P001",
                     "ml": 5, "precio": 25.0}],
            total=25.0,
        )

    fila = ws.append_rows.call_args[0][0][0]
    assert fila[6] == ""


def test_register_complete_sale_incluye_alias_en_cada_fila():
    repo = _repo_fake()
    ws = MagicMock()
    ws.col_values.return_value = ["ID_Compra"]  # sin IDs previos -> V001

    cesta = [
        {"id_perfume": "P001", "ml": 5, "precio": 25.0, "metodo": "Yape"},
        {"id_perfume": "P002", "ml": 2, "precio": 10.0, "metodo": "Plin"},
    ]
    cliente = {
        "fecha": "2026-08-02", "comprador": "juan perez", "celular": "987654321",
        "direccion": "av test 123", "distrito": "surco", "tipo_envio": "Shalom",
        "alias": "perfutecalima",
    }

    with patch.object(repo, "_get_worksheet", return_value=ws), \
         patch.object(repo, "_ejecutar_con_reintento", side_effect=lambda fn, ctx: fn()), \
         patch.object(repo, "fetch_catalog", return_value=MagicMock(empty=True)):
        try:
            repo.register_complete_sale(cesta, cliente, merma_pct=0.04)
        except Exception:
            pass  # el fallo esperado es en update_stock_batch (catálogo vacío mockeado)

    filas = ws.append_rows.call_args[0][0]
    assert len(filas) == 2
    assert filas[0][12] == "perfutecalima"  # alias en posición 13 (columna M)
    assert filas[1][12] == "perfutecalima"


def test_register_complete_sale_sin_alias_escribe_string_vacio():
    repo = _repo_fake()
    ws = MagicMock()
    ws.col_values.return_value = ["ID_Compra"]

    cesta = [{"id_perfume": "P001", "ml": 5, "precio": 25.0, "metodo": "Yape"}]
    cliente = {
        "fecha": "2026-08-02", "comprador": "juan perez", "celular": "987654321",
        "direccion": "av test 123", "distrito": "surco", "tipo_envio": "Shalom",
    }

    with patch.object(repo, "_get_worksheet", return_value=ws), \
         patch.object(repo, "_ejecutar_con_reintento", side_effect=lambda fn, ctx: fn()), \
         patch.object(repo, "fetch_catalog", return_value=MagicMock(empty=True)):
        try:
            repo.register_complete_sale(cesta, cliente, merma_pct=0.04)
        except Exception:
            pass

    filas = ws.append_rows.call_args[0][0]
    assert filas[0][12] == ""

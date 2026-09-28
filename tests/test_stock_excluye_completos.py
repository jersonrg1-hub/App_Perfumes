"""Regresión: ventas/anulaciones de completos (ml fuera de ML_OPCIONES) no
deben tocar Stock_ml — ese pool es exclusivo de los decants (2/5/10 ml)."""
from unittest.mock import MagicMock, patch

from backend.repositories.sheets_repository import SheetsRepository


def _repo_fake():
    repo = SheetsRepository.__new__(SheetsRepository)
    repo._worksheets = {}
    repo._client = None
    repo._spreadsheet = None
    repo._credentials_info = {}
    return repo


def test_register_complete_sale_excluye_completos_del_descuento_stock():
    repo = _repo_fake()
    ws = MagicMock()
    ws.col_values.return_value = ["ID_Compra"]  # sin IDs previos -> V001

    cesta = [
        {"id_perfume": "P001", "ml": 5, "precio": 25.0, "metodo": "Yape"},    # decant
        {"id_perfume": "P002", "ml": 100, "precio": 320.0, "metodo": "Yape"},  # completo
    ]
    cliente = {
        "fecha": "2026-09-28", "comprador": "juan perez", "celular": "987654321",
        "direccion": "av test 123", "distrito": "surco", "tipo_envio": "Shalom",
    }

    with patch.object(repo, "_get_worksheet", return_value=ws), \
         patch.object(repo, "_ejecutar_con_reintento", side_effect=lambda fn, ctx: fn()), \
         patch.object(repo, "fetch_catalog", return_value=MagicMock(empty=True)), \
         patch.object(repo, "update_stock_batch") as mock_update:
        repo.register_complete_sale(cesta, cliente, merma_pct=0.04)

    cesta_pasada_a_stock = mock_update.call_args[0][0]
    assert len(cesta_pasada_a_stock) == 1
    assert cesta_pasada_a_stock[0]["id_perfume"] == "P001"

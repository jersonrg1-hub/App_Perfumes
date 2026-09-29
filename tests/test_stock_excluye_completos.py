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


def test_register_complete_sale_cesta_100pct_completos_no_toca_catalogo():
    """Sin items decant, ni siquiera debe llamarse fetch_catalog ni
    update_stock_batch — evita latencia y un StockUpdateError falso si
    ese fetch fallara para una venta que nunca necesitó tocar stock."""
    repo = _repo_fake()
    ws = MagicMock()
    ws.col_values.return_value = ["ID_Compra"]

    cesta = [{"id_perfume": "P002", "ml": 100, "precio": 320.0, "metodo": "Yape"}]
    cliente = {
        "fecha": "2026-09-28", "comprador": "juan perez", "celular": "987654321",
        "direccion": "av test 123", "distrito": "surco", "tipo_envio": "Shalom",
    }

    with patch.object(repo, "_get_worksheet", return_value=ws), \
         patch.object(repo, "_ejecutar_con_reintento", side_effect=lambda fn, ctx: fn()), \
         patch.object(repo, "fetch_catalog") as mock_fetch, \
         patch.object(repo, "update_stock_batch") as mock_update:
        id_compra = repo.register_complete_sale(cesta, cliente, merma_pct=0.04)

    assert id_compra == "V001"
    mock_fetch.assert_not_called()
    mock_update.assert_not_called()


from backend.api.models import EstadoVentaUpdate
from backend.api.routes import ventas as ventas_route


def test_anular_venta_excluye_completos_del_restock():
    repo = MagicMock()
    repo.get_sale_rows_batch.return_value = {
        10: {"ID_Perfume": "P001", "Ml_Vendido": "5", "Estado": "Pendiente"},
        11: {"ID_Perfume": "P002", "Ml_Vendido": "100", "Estado": "Pendiente"},
    }
    repo.fetch_catalog.return_value = MagicMock(empty=True)

    body = EstadoVentaUpdate(nuevo_estado="Anulado", filas_sheet=[10, 11])

    with patch.object(ventas_route, "invalidar_cache_ventas"), \
         patch.object(ventas_route, "invalidar_cache_catalogo"), \
         patch.object(ventas_route._estadisticas_mod, "_invalidar_cache_stats"), \
         patch.object(ventas_route._estadisticas_mod, "_invalidar_cache_clientes"):
        ventas_route.actualizar_estado_venta("V001", body, repo=repo)

    items_anulados = repo.restore_stock_batch.call_args[0][0]
    assert len(items_anulados) == 1
    assert items_anulados[0]["id_perfume"] == "P001"


def test_anular_venta_con_ml_vendido_corrupto_no_lanza():
    """Ml_Vendido corrupto (edición manual en Sheets) no debe tumbar el
    endpoint con un 500 después de que Estado=Anulado ya se escribió."""
    repo = MagicMock()
    repo.get_sale_rows_batch.return_value = {
        10: {"ID_Perfume": "P001", "Ml_Vendido": "texto_invalido", "Estado": "Pendiente"},
    }
    repo.fetch_catalog.return_value = MagicMock(empty=True)

    body = EstadoVentaUpdate(nuevo_estado="Anulado", filas_sheet=[10])

    with patch.object(ventas_route, "invalidar_cache_ventas"), \
         patch.object(ventas_route, "invalidar_cache_catalogo"), \
         patch.object(ventas_route._estadisticas_mod, "_invalidar_cache_stats"), \
         patch.object(ventas_route._estadisticas_mod, "_invalidar_cache_clientes"):
        resultado = ventas_route.actualizar_estado_venta("V001", body, repo=repo)

    assert resultado == {"id_venta": "V001", "estado": "Anulado"}
    repo.restore_stock_batch.assert_not_called()

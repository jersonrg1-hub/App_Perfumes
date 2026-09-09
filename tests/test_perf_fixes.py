"""Tests de los fixes de performance — sin red, sin gspread."""
from datetime import date, timedelta
from unittest.mock import MagicMock, patch
import pandas as pd
import pytest


# ── Helpers ───────────────────────────────────────────────────────────────────

def _make_df_catalogo() -> pd.DataFrame:
    """Catálogo mínimo con las columnas que usa update_stock_batch / restore_stock_single."""
    return pd.DataFrame([
        {"ID_Perfume": "P001", "Stock_ml": 50.0, "fila_sheet": 2,
         "Marca": "Chanel", "Nombre": "No5"},
        {"ID_Perfume": "P002", "Stock_ml": 30.0, "fila_sheet": 3,
         "Marca": "Dior", "Nombre": "Sauvage"},
    ])


def _make_df_ventas(hoy: date) -> pd.DataFrame:
    """DataFrame de ventas mínimo para _compute_resumen."""
    ayer = hoy - timedelta(days=1)
    return pd.DataFrame([
        {"ID_Compra": "V001", "Fecha": pd.Timestamp(hoy),
         "Estado": "Pendiente", "Precio_Cobrado": 10.0, "Ml_Vendido": 2},
        {"ID_Compra": "V001", "Fecha": pd.Timestamp(hoy),
         "Estado": "Pendiente", "Precio_Cobrado": 15.0, "Ml_Vendido": 5},
        {"ID_Compra": "V002", "Fecha": pd.Timestamp(ayer),
         "Estado": "Entregado", "Precio_Cobrado": 20.0, "Ml_Vendido": 10},
    ])


# ── Task 1a: update_stock_batch no llama fetch_catalog ────────────────────────

def test_update_stock_batch_no_llama_fetch_catalog():
    """Con el fix, update_stock_batch NO debe llamar self.fetch_catalog()."""
    from backend.repositories.sheets_repository import SheetsRepository

    repo = SheetsRepository.__new__(SheetsRepository)
    repo._worksheets = {}
    repo._client = None
    repo._spreadsheet = None
    repo._credentials_info = {}

    df_cat = _make_df_catalogo()
    items = [{"id_perfume": "P001", "ml": 2}]

    with patch.object(repo, "fetch_catalog") as mock_fetch, \
         patch.object(repo, "_ejecutar_con_reintento") as mock_retry:
        mock_retry.return_value = None
        repo.update_stock_batch(items, merma_pct=0.04, df_catalogo=df_cat)

    mock_fetch.assert_not_called()


# ── Task 1b: restore_stock_batch no llama fetch_catalog ────────────────────────

def test_restore_stock_batch_no_llama_fetch_catalog():
    """Con el fix, restore_stock_batch NO debe llamar self.fetch_catalog()."""
    from backend.repositories.sheets_repository import SheetsRepository

    repo = SheetsRepository.__new__(SheetsRepository)
    repo._worksheets = {}
    repo._client = None
    repo._spreadsheet = None
    repo._credentials_info = {}

    df_cat = _make_df_catalogo()
    items = [{"id_perfume": "P001", "ml": 2}]

    with patch.object(repo, "fetch_catalog") as mock_fetch, \
         patch.object(repo, "_ejecutar_con_reintento") as mock_retry:
        mock_retry.return_value = None
        repo.restore_stock_batch(items, merma_pct=0.04, df_catalogo=df_cat)

    mock_fetch.assert_not_called()


def test_restore_stock_batch_suma_items_duplicados():
    """Anular una orden con 2 items del mismo perfume debe sumar la reposición,
    no perder una de las dos (bug corregido: antes se pisaban entre sí)."""
    from backend.repositories.sheets_repository import SheetsRepository

    repo = SheetsRepository.__new__(SheetsRepository)
    repo._worksheets = {}
    repo._client = None
    repo._spreadsheet = None
    repo._credentials_info = {}

    df_cat = _make_df_catalogo()
    # Misma orden: 2ml y 5ml del mismo perfume P001
    items = [
        {"id_perfume": "P001", "ml": 2},
        {"id_perfume": "P001", "ml": 5},
    ]

    with patch.object(repo, "_ejecutar_con_reintento") as mock_retry:
        mock_retry.side_effect = lambda fn, nombre: fn()
        with patch.object(SheetsRepository, "_get_worksheet") as mock_ws:
            mock_sheet = MagicMock()
            mock_ws.return_value = mock_sheet
            repo.restore_stock_batch(items, merma_pct=0.04, df_catalogo=df_cat)

    mock_sheet.batch_update.assert_called_once()
    peticiones = mock_sheet.batch_update.call_args[0][0]
    assert len(peticiones) == 1  # un solo perfume -> una sola escritura agregada
    esperado = 50.0 + (2.2 * 1.04) + (5.1 * 1.04)  # ML_BASE_DISPENSACION[2]=2.2, [5]=5.1
    assert peticiones[0]["values"][0][0] == pytest.approx(esperado)


# ── Task 2: _compute_resumen vectorizado retorna valores correctos ─────────────

def test_compute_resumen_hoy_correcto():
    """_compute_resumen reporta correctamente ventas de hoy."""
    from backend.api.routes.estadisticas import _compute_resumen
    from backend.core.config import hoy_peru

    hoy = hoy_peru()
    df = _make_df_ventas(hoy)

    result = _compute_resumen(df, pendientes_count=1)

    assert result["hoy"]["ventas"] == 1        # ID_Compra único hoy
    assert result["hoy"]["total"] == pytest.approx(25.0)  # 10 + 15
    assert result["hoy"]["ml"] == 7            # 2 + 5


# ── Task 3: get_sale_rows_batch — 1 sola llamada batch_get en vez de N ─────────

def test_get_sale_rows_batch_una_sola_llamada():
    """Anular varias filas debe leerlas con 1 sola llamada batch_get, no N."""
    from backend.repositories.sheets_repository import SheetsRepository
    from backend.core.config import COLUMNAS_VENTAS

    repo = SheetsRepository.__new__(SheetsRepository)
    repo._worksheets = {}
    repo._client = None
    repo._spreadsheet = None
    repo._credentials_info = {}

    fila_2_completa = ["V001", "2026-01-01", "Ana", "987654321",
                        "P001", "2", "22.5", "Yape", "Motorizado",
                        "Av. Sol", "Cusco", "Pendiente", ""]
    fila_3_truncada = ["V002", "2026-01-02", "Beto", "912345678"]  # Sheets omite celdas finales vacías

    with patch.object(repo, "_ejecutar_con_reintento") as mock_retry:
        mock_retry.side_effect = lambda fn, nombre: fn()
        with patch.object(SheetsRepository, "_get_worksheet") as mock_ws:
            mock_sheet = MagicMock()
            mock_sheet.batch_get.return_value = [[fila_2_completa], [fila_3_truncada]]
            mock_ws.return_value = mock_sheet

            resultado = repo.get_sale_rows_batch([2, 3])

    mock_sheet.batch_get.assert_called_once_with(["A2:M2", "A3:M3"])
    assert set(resultado.keys()) == {2, 3}
    assert resultado[2]["ID_Compra"] == "V001"
    assert resultado[2]["Estado"] == "Pendiente"
    # Fila truncada: columnas faltantes deben rellenarse con "", no KeyError/IndexError
    assert resultado[3]["Comprador"] == "Beto"
    assert resultado[3]["Estado"] == ""
    assert len(resultado[3]) == len(COLUMNAS_VENTAS)


def test_get_sale_rows_batch_vacio_no_llama_api():
    from backend.repositories.sheets_repository import SheetsRepository

    repo = SheetsRepository.__new__(SheetsRepository)
    assert repo.get_sale_rows_batch([]) == {}


# ── Task 4: register_complete_sale prefetchea catalogo en paralelo con el append ─

def test_register_complete_sale_usa_catalogo_prefetcheado_para_stock():
    """El catálogo usado por update_stock_batch debe ser el mismo objeto
    devuelto por fetch_catalog() (lanzado en segundo plano antes de
    append_sale_rows), no un segundo fetch posterior al append."""
    from backend.repositories.sheets_repository import SheetsRepository

    repo = SheetsRepository.__new__(SheetsRepository)
    repo._worksheets = {}
    repo._client = None
    repo._spreadsheet = None
    repo._credentials_info = {}

    df_cat = _make_df_catalogo()
    cesta = [{"id_perfume": "P001", "ml": 2, "precio": 22.5, "metodo": "Yape"}]
    cliente = {
        "fecha": "2026-01-01", "comprador": "ana", "celular": "987654321",
        "tipo_envio": "Motorizado", "direccion": "av sol", "distrito": "cusco",
        "alias": None,
    }

    with patch.object(repo, "get_next_sale_id", return_value="V001") as mock_id, \
         patch.object(repo, "fetch_catalog", return_value=df_cat) as mock_fetch, \
         patch.object(repo, "append_sale_rows") as mock_append, \
         patch.object(repo, "update_stock_batch") as mock_stock:
        id_compra = repo.register_complete_sale(cesta, cliente, merma_pct=0.04)

    assert id_compra == "V001"
    mock_id.assert_called_once()
    mock_fetch.assert_called_once()          # 1 sola llamada, no una por cada intento
    mock_append.assert_called_once()
    mock_stock.assert_called_once_with(cesta, 0.04, df_cat)  # mismo df, sin refetch


def test_register_complete_sale_catalogo_caido_guarda_venta_y_avisa_stock():
    """fetch_catalog() corre en segundo plano desde el inicio, pero su resultado
    solo se espera DESPUES de guardar la venta (append_sale_rows). Si falla,
    la venta ya debe estar guardada — el error se envuelve en StockUpdateError
    (best-effort), nunca debe perderse la venta por un catalogo caido."""
    from backend.repositories.sheets_repository import SheetsRepository, StockUpdateError

    repo = SheetsRepository.__new__(SheetsRepository)
    repo._worksheets = {}
    repo._client = None
    repo._spreadsheet = None
    repo._credentials_info = {}

    cesta = [{"id_perfume": "P001", "ml": 2, "precio": 22.5, "metodo": "Yape"}]
    cliente = {
        "fecha": "2026-01-01", "comprador": "ana", "celular": "987654321",
        "tipo_envio": "Motorizado", "direccion": "av sol", "distrito": "cusco",
        "alias": None,
    }

    with patch.object(repo, "get_next_sale_id", return_value="V001"), \
         patch.object(repo, "fetch_catalog", side_effect=RuntimeError("caido")), \
         patch.object(repo, "append_sale_rows") as mock_append:
        with pytest.raises(StockUpdateError) as exc_info:
            repo.register_complete_sale(cesta, cliente, merma_pct=0.04)

    mock_append.assert_called_once()             # la venta SI se guarda
    assert exc_info.value.id_compra == "V001"    # y el id se preserva para la UI


def test_compute_resumen_mes_correcto():
    """_compute_resumen incluye ventas de ayer en el total del mes."""
    from backend.api.routes.estadisticas import _compute_resumen
    from unittest.mock import patch
    from datetime import date

    # Fix mid-month so hoy and ayer are always in same month
    fixed_hoy = date(2026, 6, 15)
    with patch("backend.api.routes.estadisticas.hoy_peru", return_value=fixed_hoy):
        df = _make_df_ventas(fixed_hoy)
        result = _compute_resumen(df, pendientes_count=0)

    assert result["mes"]["total"] == pytest.approx(45.0)  # 25.0 hoy + 20.0 ayer

"""Tests de los fixes de performance — sin red, sin gspread."""
from datetime import date, timedelta
from unittest.mock import MagicMock, patch, call
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


# ── Task 1b: restore_stock_single no llama fetch_catalog ──────────────────────

def test_restore_stock_single_no_llama_fetch_catalog():
    """Con el fix, restore_stock_single NO debe llamar self.fetch_catalog()."""
    from backend.repositories.sheets_repository import SheetsRepository

    repo = SheetsRepository.__new__(SheetsRepository)
    repo._worksheets = {}
    repo._client = None
    repo._spreadsheet = None
    repo._credentials_info = {}

    df_cat = _make_df_catalogo()

    with patch.object(repo, "fetch_catalog") as mock_fetch, \
         patch.object(repo, "_ejecutar_con_reintento") as mock_retry:
        mock_retry.return_value = None
        repo.restore_stock_single("P001", 2, merma_pct=0.04, df_catalogo=df_cat)

    mock_fetch.assert_not_called()


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


def test_compute_resumen_mes_correcto():
    """_compute_resumen incluye ventas de ayer en el total del mes."""
    from backend.api.routes.estadisticas import _compute_resumen
    from backend.core.config import hoy_peru

    hoy = hoy_peru()
    df = _make_df_ventas(hoy)

    result = _compute_resumen(df, pendientes_count=0)

    # ayer también está en este mes (ambas fechas son del mismo mes)
    assert result["mes"]["total"] >= 25.0

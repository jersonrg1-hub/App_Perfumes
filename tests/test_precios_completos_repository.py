"""Tests de SheetsRepository.fetch_precios_completos()."""
from unittest.mock import MagicMock, patch

from backend.repositories.sheets_repository import SheetsRepository


def _repo_fake():
    repo = SheetsRepository.__new__(SheetsRepository)
    repo._worksheets = {}
    repo._client = None
    repo._spreadsheet = None
    repo._credentials_info = {}
    return repo


def test_fetch_precios_completos_descarta_filas_sin_id_perfume():
    repo = _repo_fake()
    ws = MagicMock()
    ws.get_all_records.return_value = [
        {"ID_Perfume": "5", "Marca": "Burberry", "Nombre": "Her edp", "Ml": 50, "Precio": 340},
        {"ID_Perfume": "5", "Marca": "Burberry", "Nombre": "Her edp", "Ml": 100, "Precio": 460},
        {"ID_Perfume": "", "Marca": "#N/A", "Nombre": "#N/A", "Ml": "", "Precio": ""},
    ]

    with patch.object(repo, "_get_worksheet", return_value=ws), \
         patch.object(repo, "_ejecutar_con_reintento", side_effect=lambda fn, ctx: fn()):
        df = repo.fetch_precios_completos()

    assert len(df) == 2
    assert df.iloc[0]["ID_Perfume"] == "5"
    assert int(df.iloc[0]["Ml"]) == 50
    assert float(df.iloc[1]["Precio"]) == 460.0


def test_fetch_precios_completos_hoja_vacia_retorna_dataframe_vacio():
    repo = _repo_fake()
    ws = MagicMock()
    ws.get_all_records.return_value = []

    with patch.object(repo, "_get_worksheet", return_value=ws), \
         patch.object(repo, "_ejecutar_con_reintento", side_effect=lambda fn, ctx: fn()):
        df = repo.fetch_precios_completos()

    assert df.empty

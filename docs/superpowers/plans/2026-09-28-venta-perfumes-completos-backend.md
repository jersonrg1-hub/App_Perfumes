# Venta de Perfumes Completos (Backend) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Backend soporta vender frascos completos (tamaños libres, hasta 3 por perfume) leyendo precios de una hoja nueva `Precios_Completos`, exponiéndolos en el catálogo, y sin que ventas/anulaciones de completos corrompan el `Stock_ml` de los decants.

**Architecture:** Nuevo método de lectura en `SheetsRepository` (`fetch_precios_completos`), cache TTL 30 min separado del cache de catálogo, campo `completos` agregado a `PerfumeResponse`, `ItemCestaAPI.ml` generalizado de `Literal[2,5,10]` a `int` con rango, y un filtro por `ml in ML_OPCIONES` en los dos puntos donde se escribe `Stock_ml` (venta nueva y anulación) para excluir ítems completos.

**Tech Stack:** FastAPI, Pydantic v2, pandas, gspread, pytest (mocks con `unittest.mock`).

**Spec de referencia:** `docs/superpowers/specs/2026-09-28-venta-perfumes-completos-backend-design.md`

Todos los comandos de este plan se ejecutan desde `pythonProject/` (raíz del backend). La hoja `Precios_Completos` en Google Sheets ya existe y fue verificada manualmente — este plan no la crea, solo la lee.

---

### Task 1: Constante de la hoja en config

**Files:**
- Modify: `backend/core/config.py:22-24`

- [ ] **Step 1: Editar `backend/core/config.py`**

Ubicar el bloque:
```python
SHEET_NAME = "PERFUMES PYTHON"
WORKSHEET_CATALOGO = "Catalogo"
WORKSHEET_VENTAS = "Ventas_Pendientes"
WORKSHEET_COTIZACIONES = "Cotizaciones"
```
Reemplazar por:
```python
SHEET_NAME = "PERFUMES PYTHON"
WORKSHEET_CATALOGO = "Catalogo"
WORKSHEET_VENTAS = "Ventas_Pendientes"
WORKSHEET_COTIZACIONES = "Cotizaciones"
WORKSHEET_PRECIOS_COMPLETOS = "Precios_Completos"
```

- [ ] **Step 2: Verificar que importa sin errores**

Run: `python -c "from backend.core.config import WORKSHEET_PRECIOS_COMPLETOS; print(WORKSHEET_PRECIOS_COMPLETOS)"`
Expected: imprime `Precios_Completos`

- [ ] **Step 3: Commit**

```bash
git add backend/core/config.py
git commit -m "feat(backend): agrega constante de hoja Precios_Completos"
```

---

### Task 2: Lectura de la hoja `Precios_Completos`

**Files:**
- Modify: `backend/repositories/sheets_repository.py` (import en línea 28-32, nuevo método tras `fetch_quotes`, línea ~263)
- Test: `tests/test_precios_completos_repository.py`

- [ ] **Step 1: Escribir el test que falla**

Crear `tests/test_precios_completos_repository.py`:
```python
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
```

- [ ] **Step 2: Correr el test y confirmar que falla**

Run: `python -m pytest tests/test_precios_completos_repository.py -v`
Expected: FAIL con `AttributeError: 'SheetsRepository' object has no attribute 'fetch_precios_completos'`

- [ ] **Step 3: Implementar `fetch_precios_completos`**

En `backend/repositories/sheets_repository.py`, agregar `WORKSHEET_PRECIOS_COMPLETOS` al import existente (línea 28-32):
```python
from backend.core.config import (
    SCOPES, SHEET_NAME,
    WORKSHEET_CATALOGO, WORKSHEET_VENTAS, WORKSHEET_COTIZACIONES,
    WORKSHEET_PRECIOS_COMPLETOS,
    hoy_peru, fmt_precio, ML_BASE_DISPENSACION, ML_OPCIONES, COLUMNAS_VENTAS,
)
```
(nota: `ML_OPCIONES` se agrega aquí también porque lo usa el Task 3 de este mismo archivo.)

Justo después de `fetch_quotes` (termina en la línea `return df`, antes de `# ── IDs correlativos ──...`), agregar:
```python
    def fetch_precios_completos(self) -> pd.DataFrame:
        """
        Carga precios de frascos completos desde Precios_Completos.
        Descarta filas sin ID_Perfume (arrastre de fórmulas más allá de los
        datos, que en Marca/Nombre produce #N/A pero en ID_Perfume queda vacío).
        Columnas resultantes: ID_Perfume (str), Ml (int), Precio (float).
        """
        def _fetch():
            return self._get_worksheet(WORKSHEET_PRECIOS_COMPLETOS).get_all_records(
                value_render_option="UNFORMATTED_VALUE"
            )

        datos = self._ejecutar_con_reintento(_fetch, "fetch_precios_completos")
        if not datos:
            return pd.DataFrame(columns=["ID_Perfume", "Ml", "Precio"])

        df = pd.DataFrame(datos)
        df = df[df["ID_Perfume"].astype(str).str.strip() != ""]
        df["ID_Perfume"] = df["ID_Perfume"].astype(str)
        df["Ml"] = pd.to_numeric(df["Ml"], errors="coerce")
        df["Precio"] = pd.to_numeric(df["Precio"], errors="coerce")
        df = df.dropna(subset=["Ml", "Precio"]).reset_index(drop=True)
        return df
```

- [ ] **Step 4: Correr el test y confirmar que pasa**

Run: `python -m pytest tests/test_precios_completos_repository.py -v`
Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add backend/repositories/sheets_repository.py tests/test_precios_completos_repository.py
git commit -m "feat(backend): lee precios de completos desde hoja Precios_Completos"
```

---

### Task 3: Fix crítico — venta nueva no debe descontar Stock_ml por ítems completos

**Files:**
- Modify: `backend/repositories/sheets_repository.py:577-582` (dentro de `register_complete_sale`)
- Test: `tests/test_stock_excluye_completos.py`

- [ ] **Step 1: Escribir el test que falla**

Crear `tests/test_stock_excluye_completos.py`:
```python
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
```

- [ ] **Step 2: Correr el test y confirmar que falla**

Run: `python -m pytest tests/test_stock_excluye_completos.py -v`
Expected: FAIL — `assert 2 == 1` (hoy se pasa la cesta completa, sin filtrar)

- [ ] **Step 3: Implementar el filtro**

En `backend/repositories/sheets_repository.py`, dentro de `register_complete_sale`, ubicar:
```python
        try:
            df_cat = cat_future.result()
            self.update_stock_batch(cesta, merma_pct, df_cat)
        except Exception as e:
            logger.error(f"[register_complete_sale/stock] {type(e).__name__}: {e}")
            raise StockUpdateError(id_compra, e)
```
Reemplazar por:
```python
        try:
            df_cat = cat_future.result()
            cesta_decant = [item for item in cesta if int(item["ml"]) in ML_OPCIONES]
            self.update_stock_batch(cesta_decant, merma_pct, df_cat)
        except Exception as e:
            logger.error(f"[register_complete_sale/stock] {type(e).__name__}: {e}")
            raise StockUpdateError(id_compra, e)
```
(`ML_OPCIONES` ya quedó importado en el Task 2.)

- [ ] **Step 4: Correr el test y confirmar que pasa**

Run: `python -m pytest tests/test_stock_excluye_completos.py -v`
Expected: PASS

- [ ] **Step 5: Correr también los tests de alias (mismo archivo tocado) para confirmar que no rompiste nada**

Run: `python -m pytest tests/test_alias_repository.py -v`
Expected: PASS (4 tests, sin cambios de comportamiento para cestas 100% decant)

- [ ] **Step 6: Commit**

```bash
git add backend/repositories/sheets_repository.py tests/test_stock_excluye_completos.py
git commit -m "fix(backend): venta de completos ya no descuenta Stock_ml de decants"
```

---

### Task 4: Fix crítico — anular venta no debe reponer Stock_ml por ítems completos

**Files:**
- Modify: `backend/api/routes/ventas.py:45` (import), `backend/api/routes/ventas.py:316-318`
- Test: `tests/test_stock_excluye_completos.py` (agregar caso)

- [ ] **Step 1: Agregar el test que falla**

En `tests/test_stock_excluye_completos.py`, agregar al final:
```python
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
```

- [ ] **Step 2: Correr el test y confirmar que falla**

Run: `python -m pytest tests/test_stock_excluye_completos.py::test_anular_venta_excluye_completos_del_restock -v`
Expected: FAIL — `assert 2 == 1` (hoy `filas_para_restock` incluye cualquier fila con `ID_Perfume` y `Ml_Vendido`, sin distinguir completos)

- [ ] **Step 3: Implementar el filtro**

En `backend/api/routes/ventas.py:45`, cambiar:
```python
from backend.core.config import COL_ESTADO_NUM, COL_ESTADO_COT
```
por:
```python
from backend.core.config import COL_ESTADO_NUM, COL_ESTADO_COT, ML_OPCIONES
```

Luego, en la línea 316-318, ubicar:
```python
            filas_para_restock = [
                f for f in filas_actuales if f.get("ID_Perfume") and f.get("Ml_Vendido")
            ]
```
Reemplazar por:
```python
            filas_para_restock = [
                f for f in filas_actuales
                if f.get("ID_Perfume") and f.get("Ml_Vendido")
                and int(float(f["Ml_Vendido"])) in ML_OPCIONES
            ]
```

- [ ] **Step 4: Correr el test y confirmar que pasa**

Run: `python -m pytest tests/test_stock_excluye_completos.py -v`
Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add backend/api/routes/ventas.py tests/test_stock_excluye_completos.py
git commit -m "fix(backend): anular venta de completos ya no repone Stock_ml de decants"
```

---

### Task 5: Cache de precios de completos

**Files:**
- Modify: `backend/api/dependencies.py` (nuevo bloque tras `get_ventas_cached`/`invalidar_cache_catalogo`, cerca de línea 100-125)
- Test: `tests/test_completos_cache.py`

- [ ] **Step 1: Escribir el test que falla**

Crear `tests/test_completos_cache.py`:
```python
"""Tests del cache de precios de completos en backend/api/dependencies.py."""
from unittest.mock import MagicMock

import pandas as pd

from backend.api import dependencies as deps


def test_get_completos_cached_agrupa_por_id_perfume():
    deps.invalidar_cache_completos()
    repo = MagicMock()
    repo.fetch_precios_completos.return_value = pd.DataFrame([
        {"ID_Perfume": "5", "Ml": 50, "Precio": 340.0},
        {"ID_Perfume": "5", "Ml": 100, "Precio": 460.0},
        {"ID_Perfume": "9", "Ml": 30, "Precio": 150.0},
    ])

    resultado = deps.get_completos_cached(repo)

    assert resultado["5"] == [{"ml": 50, "precio": 340.0}, {"ml": 100, "precio": 460.0}]
    assert resultado["9"] == [{"ml": 30, "precio": 150.0}]


def test_get_completos_cached_usa_cache_en_segunda_llamada():
    deps.invalidar_cache_completos()
    repo = MagicMock()
    repo.fetch_precios_completos.return_value = pd.DataFrame([
        {"ID_Perfume": "5", "Ml": 50, "Precio": 340.0},
    ])

    deps.get_completos_cached(repo)
    deps.get_completos_cached(repo)

    repo.fetch_precios_completos.assert_called_once()


def test_invalidar_cache_completos_fuerza_recarga():
    deps.invalidar_cache_completos()
    repo = MagicMock()
    repo.fetch_precios_completos.return_value = pd.DataFrame([
        {"ID_Perfume": "5", "Ml": 50, "Precio": 340.0},
    ])

    deps.get_completos_cached(repo)
    deps.invalidar_cache_completos()
    deps.get_completos_cached(repo)

    assert repo.fetch_precios_completos.call_count == 2
```

- [ ] **Step 2: Correr el test y confirmar que falla**

Run: `python -m pytest tests/test_completos_cache.py -v`
Expected: FAIL con `AttributeError: module 'backend.api.dependencies' has no attribute 'invalidar_cache_completos'`

- [ ] **Step 3: Implementar el cache**

En `backend/api/dependencies.py`, ubicar el bloque de caches (línea 78-81):
```python
_cache_catalogo:     TTLCache = TTLCache(maxsize=1, ttl=1800)  # 30 min
_cache_ventas:       TTLCache = TTLCache(maxsize=1, ttl=300)   # 5 min (300 s)
_cache_cotizaciones: TTLCache = TTLCache(maxsize=1, ttl=300)   # 5 min (300 s)
_lock = threading.Lock()
_K = "df"
```
Agregar una línea:
```python
_cache_catalogo:     TTLCache = TTLCache(maxsize=1, ttl=1800)  # 30 min
_cache_ventas:       TTLCache = TTLCache(maxsize=1, ttl=300)   # 5 min (300 s)
_cache_cotizaciones: TTLCache = TTLCache(maxsize=1, ttl=300)   # 5 min (300 s)
_cache_completos:    TTLCache = TTLCache(maxsize=1, ttl=1800)  # 30 min, igual que catalogo
_lock = threading.Lock()
_K = "df"
```

Justo después de `invalidar_cache_catalogo` (línea 114-118), agregar:
```python
def get_completos_cached(repo: SheetsRepository) -> dict[str, list[dict]]:
    """
    Precios de completos agrupados por id_perfume, desde cache (TTL 30 min).
    Retorna {"5": [{"ml": 50, "precio": 340.0}, ...], ...} — perfumes sin
    completos simplemente no aparecen como clave.
    """
    with _lock:
        try:
            return _cache_completos[_K]
        except KeyError:
            df = repo.fetch_precios_completos()
            agrupado: dict[str, list[dict]] = {}
            for _, row in df.iterrows():
                agrupado.setdefault(str(row["ID_Perfume"]), []).append(
                    {"ml": int(row["Ml"]), "precio": float(row["Precio"])}
                )
            _cache_completos[_K] = agrupado
            logger.debug("Cache completos recargado desde Sheets")
            return agrupado


def invalidar_cache_completos() -> None:
    """Llamar junto con invalidar_cache_catalogo tras editar Precios_Completos."""
    with _lock:
        _cache_completos.clear()
    logger.debug("Cache completos invalidado")
```

- [ ] **Step 4: Correr el test y confirmar que pasa**

Run: `python -m pytest tests/test_completos_cache.py -v`
Expected: PASS (3 tests)

- [ ] **Step 5: Commit**

```bash
git add backend/api/dependencies.py tests/test_completos_cache.py
git commit -m "feat(backend): cache TTL 30 min para precios de completos"
```

---

### Task 6: Modelos Pydantic — `CompletoPrecio` y `ml` libre en `ItemCestaAPI`

**Files:**
- Modify: `backend/api/models.py:16` (import), `:43-64` (`PerfumeResponse`), `:162-172` (`ItemCestaAPI`)
- Test: `tests/test_models_completos.py`

- [ ] **Step 1: Escribir el test que falla**

Crear `tests/test_models_completos.py`:
```python
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
```

- [ ] **Step 2: Correr el test y confirmar que falla**

Run: `python -m pytest tests/test_models_completos.py -v`
Expected: FAIL — `ImportError: cannot import name 'CompletoPrecio'`

- [ ] **Step 3: Implementar los cambios en `backend/api/models.py`**

Cambiar el import de la línea 16 de:
```python
from typing import Generic, Literal, Optional, TypeVar
```
a:
```python
from typing import Generic, Optional, TypeVar
```

Agregar `CompletoPrecio` justo antes de `PerfumeResponse` (línea 43):
```python
class CompletoPrecio(BaseModel):
    """Un tamaño de frasco completo disponible para un perfume, con su precio."""
    ml: int
    precio: float
```

En `PerfumeResponse`, agregar el campo `completos` al final de la clase (tras `palabra_clave`, línea 63):
```python
    palabra_clave: Optional[str] = None
    completos: list[CompletoPrecio] = []
```

En `ItemCestaAPI` (línea 167), cambiar:
```python
    ml: Literal[2, 5, 10] = Field(..., description="Tamaño en ml: 2, 5 o 10")
```
por:
```python
    ml: int = Field(
        ..., gt=0, le=300,
        description="Tamaño en ml: 2/5/10 (decant) o tamaño libre de completo (ej. 50, 100)",
    )
```

- [ ] **Step 4: Correr el test y confirmar que pasa**

Run: `python -m pytest tests/test_models_completos.py -v`
Expected: PASS (5 tests)

- [ ] **Step 5: Correr toda la suite de tests para descartar regresiones por el cambio de `Literal` a `int`**

Run: `python -m pytest tests/ -v`
Expected: PASS todos (el cambio de tipo es más permisivo, no debería romper nada existente)

- [ ] **Step 6: Commit**

```bash
git add backend/api/models.py tests/test_models_completos.py
git commit -m "feat(backend): agrega CompletoPrecio y generaliza ItemCestaAPI.ml"
```

---

### Task 7: Exponer completos en las respuestas de catálogo

**Files:**
- Modify: `backend/api/routes/catalogo.py` (imports línea 24-33, `_serializar_catalogo` línea 67-70, endpoints `listar_catalogo`/`buscar_perfumes`/`obtener_perfume`/`invalidar_catalogo`)
- Test: `tests/test_catalogo_completos.py`

- [ ] **Step 1: Escribir el test que falla**

Crear `tests/test_catalogo_completos.py`:
```python
"""Test de _serializar_catalogo agregando completos por id_perfume."""
import pandas as pd

from backend.api.routes.catalogo import _serializar_catalogo


def test_serializar_catalogo_adjunta_completos_por_id():
    df = pd.DataFrame([
        {"ID_Perfume": "5", "Marca": "Burberry", "Nombre": "Her edp",
         "Precio_2ml": 10, "Precio_5ml": 20, "Precio_10ml": 35, "Stock_ml": 40},
        {"ID_Perfume": "9", "Marca": "Dior", "Nombre": "Sauvage",
         "Precio_2ml": 12, "Precio_5ml": 25, "Precio_10ml": 40, "Stock_ml": 30},
    ])
    completos = {"5": [{"ml": 50, "precio": 340.0}, {"ml": 100, "precio": 460.0}]}

    filas = _serializar_catalogo(df, completos)

    assert filas[0]["completos"] == [{"ml": 50, "precio": 340.0}, {"ml": 100, "precio": 460.0}]
    assert filas[1]["completos"] == []
```

- [ ] **Step 2: Correr el test y confirmar que falla**

Run: `python -m pytest tests/test_catalogo_completos.py -v`
Expected: FAIL — `TypeError: _serializar_catalogo() takes 1 positional argument but 2 were given`

- [ ] **Step 3: Implementar en `backend/api/routes/catalogo.py`**

Cambiar el import de dependencies (línea 24-33) de:
```python
from backend.api.dependencies import (
    get_repo,
    get_catalogo_cached,
    get_image_url,
    df_to_json_list,
    paginate_df,
    invalidar_cache_catalogo,
    verify_api_key,
    stock_lock,
)
```
a:
```python
from backend.api.dependencies import (
    get_repo,
    get_catalogo_cached,
    get_completos_cached,
    get_image_url,
    df_to_json_list,
    paginate_df,
    invalidar_cache_catalogo,
    invalidar_cache_completos,
    verify_api_key,
    stock_lock,
)
```

Cambiar `_serializar_catalogo` (línea 67-70) de:
```python
def _serializar_catalogo(df) -> list[dict]:
    """Serializa DataFrame de catálogo a lista con snake_case + image_url."""
    rows = df_to_json_list(df, cols=_COLS, snake=True)
    return [_a_perfume_response(r) for r in rows]
```
a:
```python
def _serializar_catalogo(df, completos_por_id: dict) -> list[dict]:
    """Serializa DataFrame de catálogo a lista con snake_case + image_url + completos."""
    rows = df_to_json_list(df, cols=_COLS, snake=True)
    resultado = []
    for row in rows:
        row = _a_perfume_response(row)
        row["completos"] = completos_por_id.get(str(row.get("id_perfume") or ""), [])
        resultado.append(row)
    return resultado
```

En `listar_catalogo`, cambiar:
```python
    try:
        df = get_catalogo_cached(repo)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Error al cargar catalogo: {e}")

    return paginate_df(df, _serializar_catalogo, limit, offset)
```
a:
```python
    try:
        df = get_catalogo_cached(repo)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Error al cargar catalogo: {e}")

    completos = get_completos_cached(repo)
    return paginate_df(df, lambda pagina: _serializar_catalogo(pagina, completos), limit, offset)
```

En `invalidar_catalogo`, cambiar:
```python
def invalidar_catalogo():
    """
    Limpia el cache de catálogo (TTL 30 min) para que la próxima lectura
    traiga datos frescos de Sheets. Usado por el botón reload de Flutter
    tras editar precios/perfumes directamente en Sheets.
    """
    invalidar_cache_catalogo()
    return {"detail": "Cache de catalogo invalidado"}
```
a:
```python
def invalidar_catalogo():
    """
    Limpia el cache de catálogo y de completos (TTL 30 min) para que la
    próxima lectura traiga datos frescos de Sheets. Usado por el botón
    reload de Flutter tras editar precios/perfumes directamente en Sheets.
    """
    invalidar_cache_catalogo()
    invalidar_cache_completos()
    return {"detail": "Cache de catalogo invalidado"}
```

En `buscar_perfumes`, cambiar:
```python
    resultado = filtrar_catalogo(df, texto=q, marca=marca or "")
    return paginate_df(resultado, _serializar_catalogo, limit, offset)
```
a:
```python
    resultado = filtrar_catalogo(df, texto=q, marca=marca or "")
    completos = get_completos_cached(repo)
    return paginate_df(resultado, lambda pagina: _serializar_catalogo(pagina, completos), limit, offset)
```

En `obtener_perfume`, cambiar:
```python
    fila = df[df["ID_Perfume"].astype(str) == str(id_perfume)]
    if fila.empty:
        raise HTTPException(
            status_code=404,
            detail=f"Perfume '{id_perfume}' no encontrado en el catalogo",
        )

    return _serializar_catalogo(fila)[0]
```
a:
```python
    fila = df[df["ID_Perfume"].astype(str) == str(id_perfume)]
    if fila.empty:
        raise HTTPException(
            status_code=404,
            detail=f"Perfume '{id_perfume}' no encontrado en el catalogo",
        )

    completos = get_completos_cached(repo)
    return _serializar_catalogo(fila, completos)[0]
```

- [ ] **Step 4: Correr el test y confirmar que pasa**

Run: `python -m pytest tests/test_catalogo_completos.py -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add backend/api/routes/catalogo.py tests/test_catalogo_completos.py
git commit -m "feat(backend): expone precios de completos en respuestas de catalogo"
```

---

### Task 8: Suite completa + verificación manual contra Sheets real

**Files:** ninguno (solo verificación)

- [ ] **Step 1: Correr toda la suite de tests**

Run: `python -m pytest tests/ -v`
Expected: PASS todos (suma de los tests existentes + los 12 nuevos de este plan)

- [ ] **Step 2: Levantar el servidor local**

Run: `uvicorn backend.api.main:app --reload` (desde `pythonProject/`)
Expected: arranca sin errores en `http://127.0.0.1:8000`

- [ ] **Step 3: Verificar `GET /api/v1/catalogo/{id}` para un perfume con completos**

Usar el ID real que ya tiene filas en `Precios_Completos` (ID 5, Burberry Her edp, según la hoja verificada durante el diseño).

Run: `curl http://127.0.0.1:8000/api/v1/catalogo/5`
Expected: el JSON de respuesta incluye:
```json
"completos": [
  {"ml": 100, "precio": 460.0},
  {"ml": 50, "precio": 340.0}
]
```
(el orden depende del orden de filas en la hoja, no importa cuál salga primero)

- [ ] **Step 4: Verificar que un perfume sin completos devuelve lista vacía**

Run: `curl http://127.0.0.1:8000/api/v1/catalogo/{cualquier_otro_id}`
Expected: `"completos": []`

- [ ] **Step 5: Verificar invalidación end-to-end**

Editar manualmente el precio de una fila en `Precios_Completos` en el spreadsheet real, luego:

Run: `curl -X POST http://127.0.0.1:8000/api/v1/catalogo/invalidar -H "X-API-Key: <tu API_KEY>"`
Run: `curl http://127.0.0.1:8000/api/v1/catalogo/5`
Expected: el nuevo precio aparece en `completos` sin reiniciar el servidor.

Ningún commit en esta tarea — es verificación pura.

---

## Fuera de alcance (recordatorio del spec)

- Stock/cantidad de completos.
- Costeo/márgenes de completos en `costos_service.py` y estadísticas.
- UI de Flutter para elegir tamaño completo — spec aparte, no cubierto aquí.
- Validación backend de que un `ml` puntual sea uno de los configurados para ese perfume específico.

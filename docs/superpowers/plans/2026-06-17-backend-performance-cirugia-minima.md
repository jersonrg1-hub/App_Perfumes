# Backend Performance — Cirugía Mínima Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminar una llamada gspread redundante por venta y vectorizar filtros de fecha en estadísticas, sin cambiar TTLs ni lógica de frescura.

**Architecture:** `update_stock_batch()` y `restore_stock_single()` reciben el DataFrame del catálogo como parámetro en vez de fetchearlo internamente. El caller en `register_complete_sale()` lo fetcha una sola vez; el caller en `ventas.py` lo obtiene del TTL cache. Los filtros de fecha en `estadisticas.py` pasan de `.apply(lambda)` a máscaras vectorizadas con `pd.to_datetime`.

**Tech Stack:** Python 3.13, pandas, FastAPI, pytest 9.1.0 — pytest se corre con `pythonProject/.venv_n/Scripts/python.exe -m pytest`

---

## Files Modified

| File | Change |
|---|---|
| `pythonProject/backend/repositories/sheets_repository.py` | `update_stock_batch()` y `restore_stock_single()` aceptan `df_catalogo: pd.DataFrame`; `register_complete_sale()` fetcha una vez y pasa DF |
| `pythonProject/backend/api/routes/ventas.py` | Importar `get_catalogo_cached`, obtener df_cat en anulación y pasarlo a `restore_stock_single()` |
| `pythonProject/backend/api/routes/estadisticas.py` | Reemplazar 3 usos de `.apply(lambda d: bool(d) and ...)` por máscaras vectorizadas |
| `pythonProject/tests/test_perf_fixes.py` | Tests nuevos (crear) |

---

## Task 1: Tests base — verificar comportamiento actual

**Files:**
- Create: `pythonProject/tests/__init__.py`
- Create: `pythonProject/tests/test_perf_fixes.py`

- [ ] **Step 1: Crear `tests/__init__.py` vacío**

```bash
# Desde pythonProject/
echo. > tests\__init__.py
```

- [ ] **Step 2: Crear `tests/test_perf_fixes.py` con tests de lógica pura**

```python
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
```

- [ ] **Step 3: Correr tests — verificar que FALLAN (aún no está el fix)**

```
c:\Users\Jerson\Desktop\PERFUMERIA_PYTHON\pythonProject\.venv_n\Scripts\python.exe -m pytest tests/test_perf_fixes.py::test_update_stock_batch_no_llama_fetch_catalog tests/test_perf_fixes.py::test_restore_stock_single_no_llama_fetch_catalog -v
```

Esperado: `FAILED` — `TypeError: update_stock_batch() got an unexpected keyword argument 'df_catalogo'`

---

## Task 2: Fix `update_stock_batch()` — eliminar fetch interno

**Files:**
- Modify: `pythonProject/backend/repositories/sheets_repository.py:317-358` (firma + body)
- Modify: `pythonProject/backend/repositories/sheets_repository.py:453-461` (`register_complete_sale` pasa df_cat)

- [ ] **Step 1: Cambiar firma y body de `update_stock_batch()`**

En [sheets_repository.py:317](pythonProject/backend/repositories/sheets_repository.py#L317), reemplazar:

```python
def update_stock_batch(self, items_vendidos: list[dict], merma_pct: float) -> None:
    """
    Descuenta stock en batch considerando merma.

    Requiere que el catálogo ya esté cargado FRESCO (sin cache) para
    que fila_sheet sea exacto. El caller debe limpiar el cache antes de llamar.
    """
    df_cat = self.fetch_catalog()
```

Por:

```python
def update_stock_batch(
    self, items_vendidos: list[dict], merma_pct: float, df_catalogo: pd.DataFrame
) -> None:
    """Descuenta stock en batch considerando merma. Caller provee df_catalogo."""
    df_cat = df_catalogo
```

El resto del método (líneas 325-357) queda idéntico.

- [ ] **Step 2: Actualizar `register_complete_sale()` para fetchar catálogo una vez**

En [sheets_repository.py:453-461](pythonProject/backend/repositories/sheets_repository.py#L453), reemplazar:

```python
        self.append_sale_rows(filas)

        try:
            self.update_stock_batch(cesta, merma_pct)
```

Por:

```python
        self.append_sale_rows(filas)

        df_cat = self.fetch_catalog()
        try:
            self.update_stock_batch(cesta, merma_pct, df_cat)
```

- [ ] **Step 3: Correr test para `update_stock_batch`**

```
c:\Users\Jerson\Desktop\PERFUMERIA_PYTHON\pythonProject\.venv_n\Scripts\python.exe -m pytest tests/test_perf_fixes.py::test_update_stock_batch_no_llama_fetch_catalog -v
```

Esperado: `PASSED`

- [ ] **Step 4: Commit**

```bash
git add pythonProject/backend/repositories/sheets_repository.py pythonProject/tests/
git commit -m "perf: update_stock_batch recibe df_catalogo — elimina fetch doble en POST /venta"
```

---

## Task 3: Fix `restore_stock_single()` — usar catálogo cacheado

**Files:**
- Modify: `pythonProject/backend/repositories/sheets_repository.py:375-401`
- Modify: `pythonProject/backend/api/routes/ventas.py:246-253`

- [ ] **Step 1: Cambiar firma y body de `restore_stock_single()`**

En [sheets_repository.py:375](pythonProject/backend/repositories/sheets_repository.py#L375), reemplazar:

```python
    def restore_stock_single(self, id_perfume: str, ml_vendido, merma_pct: float) -> None:
        """
        Repone el stock de un perfume al anular una venta — inverso de update_stock_batch.
        Aplica la misma lógica de merma/ml_base (via _ml_con_merma) para que el stock
        vuelva al valor previo exacto.
        """
        df_cat = self.fetch_catalog()
```

Por:

```python
    def restore_stock_single(
        self, id_perfume: str, ml_vendido, merma_pct: float, df_catalogo: pd.DataFrame
    ) -> None:
        """Repone stock al anular una venta — inverso de update_stock_batch. Caller provee df_catalogo."""
        df_cat = df_catalogo
```

El resto del método (líneas 383-401) queda idéntico.

- [ ] **Step 2: Actualizar caller en `ventas.py` para pasar df_cat cacheado**

En [ventas.py:22-30](pythonProject/backend/api/routes/ventas.py#L22), agregar `get_catalogo_cached` al import:

```python
from backend.api.dependencies import (
    get_repo,
    get_ventas_cached,
    get_catalogo_cached,
    invalidar_cache_catalogo,
    invalidar_cache_ventas,
    verify_api_key,
    df_to_json_list,
    paginate_df,
)
```

En [ventas.py:246-253](pythonProject/backend/api/routes/ventas.py#L246), reemplazar:

```python
    if fila_para_restock:
        try:
            repo.restore_stock_single(
                fila_para_restock["ID_Perfume"], fila_para_restock["Ml_Vendido"], MERMA_PCT
            )
            invalidar_cache_catalogo()
        except Exception as e:
            logger.error(f"[anular_venta/restock] {type(e).__name__}: {e}")
```

Por:

```python
    if fila_para_restock:
        try:
            df_cat = get_catalogo_cached(repo)
            repo.restore_stock_single(
                fila_para_restock["ID_Perfume"], fila_para_restock["Ml_Vendido"], MERMA_PCT,
                df_catalogo=df_cat,
            )
            invalidar_cache_catalogo()
        except Exception as e:
            logger.error(f"[anular_venta/restock] {type(e).__name__}: {e}")
```

- [ ] **Step 3: Correr test para `restore_stock_single`**

```
c:\Users\Jerson\Desktop\PERFUMERIA_PYTHON\pythonProject\.venv_n\Scripts\python.exe -m pytest tests/test_perf_fixes.py::test_restore_stock_single_no_llama_fetch_catalog -v
```

Esperado: `PASSED`

- [ ] **Step 4: Commit**

```bash
git add pythonProject/backend/repositories/sheets_repository.py pythonProject/backend/api/routes/ventas.py
git commit -m "perf: restore_stock_single recibe df_catalogo — usa TTL cache en anulaciones"
```

---

## Task 4: Vectorizar filtros de fecha en `_compute_resumen()`

**Files:**
- Modify: `pythonProject/backend/api/routes/estadisticas.py:33-71`

- [ ] **Step 1: Correr tests de estadísticas — verificar que PASAN antes del cambio**

```
c:\Users\Jerson\Desktop\PERFUMERIA_PYTHON\pythonProject\.venv_n\Scripts\python.exe -m pytest tests/test_perf_fixes.py::test_compute_resumen_hoy_correcto tests/test_perf_fixes.py::test_compute_resumen_mes_correcto -v
```

Esperado: `PASSED` (la lógica ya es correcta, solo optimizamos la implementación)

- [ ] **Step 2: Reemplazar `.apply(lambda)` en `_compute_resumen()` con máscaras vectorizadas**

En [estadisticas.py:37-71](pythonProject/backend/api/routes/estadisticas.py#L37), reemplazar el bloque completo:

```python
    df = df.copy()
    df["_fecha"] = pd.to_datetime(df["Fecha"], errors="coerce").dt.date

    entregadas = df[df["Estado"].isin(["Entregado", "Pendiente"])]

    hoy: date = hoy_peru()  # retorna date, sin .date()

    hoy_df = entregadas[entregadas["_fecha"] == hoy]
    mes_df = entregadas[entregadas["_fecha"].apply(
        lambda d: bool(d) and d.year == hoy.year and d.month == hoy.month
    )]
    prev = (hoy.replace(day=1) - timedelta(days=1))
    mes_prev_df = entregadas[entregadas["_fecha"].apply(
        lambda d: bool(d) and d.year == prev.year and d.month == prev.month
    )]

    # Semanal (lunes a domingo de la semana actual)
    inicio_semana = hoy - timedelta(days=hoy.weekday())
    semanal = []
    for i in range(7):
        dia = inicio_semana + timedelta(days=i)
        dia_df = entregadas[entregadas["_fecha"] == dia]
        semanal.append({
            "fecha": dia.isoformat(),
            "ordenes": int(dia_df["ID_Compra"].nunique()) if "ID_Compra" in dia_df.columns else 0,
            "total": float(dia_df["Precio_Cobrado"].sum()) if "Precio_Cobrado" in dia_df.columns else 0.0,
            "ml": int(dia_df["Ml_Vendido"].sum()) if "Ml_Vendido" in dia_df.columns else 0,
        })

    # Semana anterior para variación
    inicio_ant = inicio_semana - timedelta(days=7)
    fin_ant = inicio_semana - timedelta(days=1)
    sem_ant_df = entregadas[entregadas["_fecha"].apply(
        lambda d: bool(d) and inicio_ant <= d <= fin_ant
    )]
```

Por:

```python
    df = df.copy()
    df["_fecha"] = pd.to_datetime(df["Fecha"], errors="coerce").dt.date

    entregadas = df[df["Estado"].isin(["Entregado", "Pendiente"])]

    hoy: date = hoy_peru()  # retorna date, sin .date()

    # Convertir _fecha a Timestamps una vez para comparaciones vectorizadas
    _fechas_ts = pd.to_datetime(entregadas["_fecha"], errors="coerce")
    _valid = _fechas_ts.notna()

    hoy_df = entregadas[_valid & (_fechas_ts.dt.date == hoy)]
    prev = hoy.replace(day=1) - timedelta(days=1)
    mes_df = entregadas[
        _valid & (_fechas_ts.dt.year == hoy.year) & (_fechas_ts.dt.month == hoy.month)
    ]
    mes_prev_df = entregadas[
        _valid & (_fechas_ts.dt.year == prev.year) & (_fechas_ts.dt.month == prev.month)
    ]

    # Semanal (lunes a domingo de la semana actual)
    inicio_semana = hoy - timedelta(days=hoy.weekday())
    semanal = []
    for i in range(7):
        dia = inicio_semana + timedelta(days=i)
        dia_df = entregadas[_valid & (_fechas_ts.dt.date == dia)]
        semanal.append({
            "fecha": dia.isoformat(),
            "ordenes": int(dia_df["ID_Compra"].nunique()) if "ID_Compra" in dia_df.columns else 0,
            "total": float(dia_df["Precio_Cobrado"].sum()) if "Precio_Cobrado" in dia_df.columns else 0.0,
            "ml": int(dia_df["Ml_Vendido"].sum()) if "Ml_Vendido" in dia_df.columns else 0,
        })

    # Semana anterior para variación
    inicio_ant = inicio_semana - timedelta(days=7)
    fin_ant = inicio_semana - timedelta(days=1)
    sem_ant_df = entregadas[
        _valid & (_fechas_ts.dt.date >= inicio_ant) & (_fechas_ts.dt.date <= fin_ant)
    ]
```

- [ ] **Step 3: Correr tests de estadísticas — verificar que siguen PASANDO**

```
c:\Users\Jerson\Desktop\PERFUMERIA_PYTHON\pythonProject\.venv_n\Scripts\python.exe -m pytest tests/test_perf_fixes.py::test_compute_resumen_hoy_correcto tests/test_perf_fixes.py::test_compute_resumen_mes_correcto -v
```

Esperado: `PASSED`

- [ ] **Step 4: Commit**

```bash
git add pythonProject/backend/api/routes/estadisticas.py
git commit -m "perf: vectorizar filtros de fecha en _compute_resumen — elimina .apply(lambda) x3"
```

---

## Task 5: Correr todos los tests y verificar importaciones

- [ ] **Step 1: Correr suite completa**

```
c:\Users\Jerson\Desktop\PERFUMERIA_PYTHON\pythonProject\.venv_n\Scripts\python.exe -m pytest tests/test_perf_fixes.py -v
```

Esperado:
```
tests/test_perf_fixes.py::test_update_stock_batch_no_llama_fetch_catalog PASSED
tests/test_perf_fixes.py::test_restore_stock_single_no_llama_fetch_catalog PASSED
tests/test_perf_fixes.py::test_compute_resumen_hoy_correcto PASSED
tests/test_perf_fixes.py::test_compute_resumen_mes_correcto PASSED
4 passed
```

- [ ] **Step 2: Verificar que el módulo backend importa sin errores**

```
c:\Users\Jerson\Desktop\PERFUMERIA_PYTHON\pythonProject\.venv_n\Scripts\python.exe -c "from backend.api.routes import ventas, estadisticas; from backend.repositories.sheets_repository import SheetsRepository; print('OK')"
```

Esperado: `OK`

- [ ] **Step 3: Commit final si hay archivos sin commitear**

```bash
git add -A
git status
# Solo commitear si hay cambios pendientes
git commit -m "test: suite de perf fixes — 4 tests verificando fix double-fetch y vectorización"
```

---

## Resumen de impacto esperado

| Operación | Antes | Después |
|---|---|---|
| POST /venta | 2 gspread reads (catalogo) | 1 gspread read |
| PUT /estado Anulado | 1 gspread read fresco (ignora cache 30m) | 0 gspread reads extra (usa TTL cache) |
| GET /estadisticas/resumen | 3x `.apply(lambda)` Python loop | 3x máscaras NumPy vectorizadas |

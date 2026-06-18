# Design: Backend Performance — Cirugía Mínima

**Date:** 2026-06-17  
**Status:** Approved  
**Scope:** `pythonProject/backend/`

## Problem

Three pain points reported by user:
- A) POST /venta feels slow
- B) GET /ventas and /cotizaciones feel slow
- D) Estadísticas slow to appear

Root causes identified via code analysis:

| # | Bug/Inefficiency | File | Impact |
|---|---|---|---|
| 1 | `update_stock_batch()` fetches catalog fresh internally, ignoring cache | `repositories/sheets_repository.py` | 1 extra gspread read per sale |
| 2 | `restore_stock_single()` also fetches catalog fresh on anulación path | `repositories/sheets_repository.py` | 1 extra gspread read per anulación |
| 3 | `get_resumen()` uses `.apply(lambda)` on date column 7+ times | `api/routes/estadisticas.py` | Python loop per row, slow on large DFs |
| 4 | `get_clientes()` uses `.apply(lambda)` on date column 2 times | `api/routes/estadisticas.py` | Same issue |

## Out of Scope

- Cache TTLs: unchanged (30m catálogo, 5m ventas/cotizaciones/stats)
- Cache invalidation logic: unchanged (POST/PUT still invalidate immediately)
- Serialization passes: not touched (Opción 2 work)
- Async writes: not touched (Opción 3 work)
- Any changes to freshness guarantees

## Fix 1 — Eliminate double-fetch in writes

**Files:** `repositories/sheets_repository.py`, `api/routes/ventas.py`

### Change to `update_stock_batch()`

```python
# BEFORE
def update_stock_batch(self, items_vendidos: list[dict]) -> None:
    df_cat = self.fetch_catalog()  # fresh gspread read — wrong

# AFTER
def update_stock_batch(self, items_vendidos: list[dict], df_catalogo: pd.DataFrame) -> None:
    df_cat = df_catalogo  # caller passes cached DF
```

### Change to `restore_stock_single()`

```python
# BEFORE
def restore_stock_single(self, id_perfume: str, ml_a_restaurar: float) -> None:
    df_cat = self.fetch_catalog()  # fresh gspread read — wrong

# AFTER
def restore_stock_single(self, id_perfume: str, ml_a_restaurar: float, df_catalogo: pd.DataFrame) -> None:
    df_cat = df_catalogo  # caller passes cached DF
```

### Change in caller (`ventas.py`)

In the POST /venta route and PUT /estado route, before calling `update_stock_batch()` or `restore_stock_single()`, obtain the cached catalog via `repo.fetch_catalog()` (which hits TTLCache if warm) and pass it in.

```python
# In POST /venta handler, before calling update_stock_batch:
df_cat = repo.fetch_catalog()  # hits cache (TTL=30m), no gspread call
repo.update_stock_batch(items_vendidos, df_catalogo=df_cat)

# In PUT /estado anulación path:
df_cat = repo.fetch_catalog()  # hits cache
repo.restore_stock_single(id_perfume, ml, df_catalogo=df_cat)
```

**Result:** POST /venta goes from 2 gspread reads to 1. Anulación same improvement.

## Fix 2 — Vectorize date filtering in estadísticas

**File:** `api/routes/estadisticas.py`

### Pattern

Convert the `Fecha` column to a date Series once per `get_resumen()` / `get_clientes()` call, then use vectorized boolean masks for all filters.

```python
# At top of get_resumen(), after loading df_ventas:
fechas = pd.to_datetime(df_ventas["Fecha"], utc=True).dt.tz_convert(TZ_PERU).dt.date
hoy = datetime.now(TZ_PERU).date()

# All masks become vectorized:
mask_hoy = fechas == hoy
mask_semana = (fechas >= inicio_semana) & (fechas <= hoy)
mask_mes = (fechas >= inicio_mes) & (fechas <= hoy)
# etc.
```

Replace every `.apply(lambda r: r["Fecha"]..., axis=1)` occurrence with the pre-computed `fechas` Series comparison.

**Result:** O(n) Python loop → vectorized NumPy operation. Faster on any DataFrame size; benefit compounds with 5m cache TTL since `get_resumen()` runs at most once per 5 minutes.

## Freshness Guarantee (unchanged)

- POST /venta → invalidates ventas cache + catálogo cache + stats cache immediately
- PUT /estado → invalidates ventas cache + stats cache immediately
- All TTLs unchanged
- No write is deferred or batched

## Files to Modify

1. `pythonProject/backend/repositories/sheets_repository.py` — change signatures of `update_stock_batch()` and `restore_stock_single()`
2. `pythonProject/backend/api/routes/ventas.py` — update callers to pass `df_catalogo`
3. `pythonProject/backend/api/routes/estadisticas.py` — vectorize date ops in `get_resumen()` and `get_clientes()`

## Success Criteria

- POST /venta triggers exactly 1 gspread catalog read (not 2)
- PUT /estado anulación triggers exactly 1 gspread catalog read (not 2)
- `get_resumen()` contains zero `.apply(lambda)` calls on the Fecha column
- Cache invalidation behavior identical to before

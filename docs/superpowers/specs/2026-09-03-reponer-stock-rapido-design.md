# Reponer stock rápido — Tab Stock (Análisis)

## Objetivo

Desde el sub-tab Stock (`analisis_tab.dart`), permitir ajustar `Stock_ml` de un
perfume sin salir de la app ni editar Google Sheets directamente.

## Backend (`pythonProject/backend`)

### Endpoint

`PUT /api/v1/catalogo/{id_perfume}/stock` — protegido con `X-API-Key`.

Body (`AjusteStockRequest` en `backend/api/models.py`):
```python
class AjusteStockRequest(BaseModel):
    ml_delta: float  # != 0; positivo = agregar, negativo = quitar
```

Response:
```json
{"id_perfume": "P001", "stock_ml_nuevo": 45.0}
```

Errores:
- 404 si `id_perfume` no existe en catálogo
- 422 si `ml_delta == 0` (validación Pydantic)
- 503 si falla lectura/escritura Sheets

### Repositorio

`SheetsRepository.add_stock(id_perfume: str, ml_delta: float) -> float`

- Reutiliza `fetch_catalog()` para ubicar `fila_sheet` y columna `Stock_ml`
  (mismo cálculo de índice de columna que `update_stock_batch`).
- `nuevo_valor = max(0.0, stock_actual + ml_delta)` — clamp a 0, igual criterio
  que `update_stock_batch` cuando el descuento supera el stock disponible.
- Si `stock_actual + ml_delta < 0`, loggear warning (no bloquea).
- Escribe la celda única con `gspread.utils.rowcol_to_a1` + `worksheet.update()`,
  mismo patrón que `update_quote_status`.
- Si `id_perfume` no está en el catálogo, lanzar `ValueError` → el route la
  traduce a 404.

### Route (`backend/api/routes/catalogo.py`)

- Nuevo endpoint, `dependencies=[Depends(verify_api_key)]`.
- Tras escritura exitosa: `invalidar_cache_catalogo()` (mismo helper que usa
  `/catalogo/invalidar`), para que el próximo GET refleje el nuevo stock.

## Frontend (`perfuteca_flutter`)

### Trigger

`_StockRow` en `analisis_tab.dart` gana `GestureDetector` con `onLongPress`
que abre un modal (`showDialog`).

### Modal — `_ReponerStockDialog`

- Header: nombre + marca del perfume, stock actual (ej. "Stock actual: 12 ml").
- Toggle segmentado (`SegmentedButton<bool>` o dos `ChoiceChip`): **Agregar** /
  **Quitar**.
- `TextField` numérico (`keyboardType: TextInputType.number`, solo positivo,
  validación: no vacío, > 0).
- Botones: Cancelar / Confirmar.
- Al confirmar:
  - `ml_delta = toggle == Agregar ? valor : -valor`
  - Si `toggle == Quitar` y `valor > stockActual`: bloquear con mensaje
    inline ("no puede quitar más del stock actual") — evita mandar un delta
    que el backend igual clampearía a 0 sin avisar.
  - Loading state en botón Confirmar mientras la request está en curso.
  - Éxito: cerrar modal, `SnackBar` "Stock actualizado a X ml",
    `ref.read(catalogoProvider.notifier).refresh()`.
  - Error: `SnackBar` rojo con el mensaje de error, modal permanece abierto.

### Repositorio (`lib/repositories/catalogo_repository.dart` o equivalente)

Nuevo método:
```dart
Future<double> ajustarStock(String idPerfume, double mlDelta);
```
Llama `PUT /api/v1/catalogo/{id}/stock`, header `X-API-Key` (ya lo agrega el
interceptor existente), retorna `stock_ml_nuevo` de la respuesta.

## Fuera de alcance (YAGNI)

- Historial/auditoría de quién repuso y cuándo.
- Notificaciones push al llegar a stock crítico.
- Edición de otros campos del catálogo (precio, notas, etc.) desde este modal.

## Testing

- Backend: test unitario de `add_stock` (clamp a 0, ID no encontrado → 404,
  delta positivo/negativo).
- Frontend: verificar manualmente en emulador — long-press, agregar, quitar,
  quitar más que el stock (bloqueo inline), error de red (mensaje visible).

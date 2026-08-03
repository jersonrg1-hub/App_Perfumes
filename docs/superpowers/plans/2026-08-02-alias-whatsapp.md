# Alias de WhatsApp opcional — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permitir guardar un alias de WhatsApp (username, ej. `@perfutecalima`) opcional junto al celular en Cotizaciones y Ventas_Pendientes, y usarlo para abrir chats de WhatsApp (`wa.me/<alias>`) en vez del número cuando esté disponible.

**Architecture:** Alias es un campo string opcional aditivo en modelos backend (Pydantic) y frontend (Freezed), una columna extra en cada hoja de Sheets (leída/escrita por header, sin tocar la lógica de fetch), y dos funciones puras nuevas en `whatsapp_launcher.dart` (`resolverDestinoWhatsApp`, `lineaContacto`) que centralizan la decisión alias-vs-celular tanto para el deep-link como para el texto de los mensajes.

**Tech Stack:** FastAPI + Pydantic + gspread (backend), Flutter + Riverpod + Freezed (frontend), pytest (backend tests), flutter_test (frontend tests).

---

## Pre-requisito manual (usuario)

Antes de correr las pruebas de integración manual: agregar columna `alias` en la
hoja `Ventas_Pendientes` de Google Sheets, en la posición `M` (después de
`Estado`). La hoja `Cotizaciones` ya tiene la columna `alias` en `G` (según
captura del usuario). Sin esta columna, `register_complete_sale` seguirá
funcionando (el valor de alias simplemente no se guarda en ningún lado
visible), así que este paso no bloquea el desarrollo, solo la verificación
manual de Ventas.

---

## Backend

### Task 1: Config — columna `alias` en `COLUMNAS_VENTAS`

**Files:**
- Modify: `pythonProject/backend/core/config.py:50-57`

- [ ] **Step 1: Editar `COLUMNAS_VENTAS`**

```python
COLUMNAS_VENTAS: list[str] = [
    "ID_Compra", "Fecha", "Comprador", "Celular",
    "ID_Perfume", "Ml_Vendido", "Precio_Cobrado",
    "Metodo_Pago", "Tipo_Envio", "Direccion", "Distrito", "Estado",
    "alias",
]
```

- [ ] **Step 2: Verificar que `COL_ESTADO_NUM` no cambió**

`COL_ESTADO_NUM = COLUMNAS_VENTAS.index("Estado") + 1` sigue devolviendo `12`
porque `"alias"` se agregó al final, después de `"Estado"`. No hace falta
tocar esa línea.

- [ ] **Step 3: Commit**

```bash
cd pythonProject
git add backend/core/config.py
git commit -m "feat(config): agregar columna alias a Ventas_Pendientes"
```

---

### Task 2: Modelos Pydantic — campo `alias` opcional

**Files:**
- Modify: `pythonProject/backend/api/models.py`

- [ ] **Step 1: Escribir test de que `alias` es opcional en los requests**

Crear `pythonProject/tests/test_alias_models.py`:

```python
"""Tests del campo alias opcional en modelos de request/response."""
from backend.api.models import (
    VentaRequest, CotizacionRequest,
    VentaResponse, CotizacionResponse, ClientePrevioResponse,
)


def _venta_kwargs(**overrides):
    base = dict(
        comprador="Juan", celular="987654321", direccion="Av. Test 123",
        tipo_envio="Shalom", fecha="2026-08-02", items=[{
            "perfume": "Sauvage", "marca": "Dior", "id_perfume": "P001",
            "ml": 5, "precio": 25.0, "metodo": "Yape",
        }],
    )
    base.update(overrides)
    return base


def test_venta_request_alias_es_opcional_y_default_none():
    req = VentaRequest(**_venta_kwargs())
    assert req.alias is None


def test_venta_request_acepta_alias_explicito():
    req = VentaRequest(**_venta_kwargs(alias="perfutecalima"))
    assert req.alias == "perfutecalima"


def test_cotizacion_request_alias_es_opcional():
    req = CotizacionRequest(
        celular="987654321",
        items=[{
            "perfume": "Sauvage", "marca": "Dior", "id_perfume": "P001",
            "ml": 5, "precio": 25.0, "metodo": "Yape",
        }],
    )
    assert req.alias is None


def test_venta_response_alias_es_opcional():
    resp = VentaResponse(id_compra="V001", comprador="Juan",
                          celular="987654321", id_perfume="P001")
    assert resp.alias is None


def test_cotizacion_response_alias_es_opcional():
    resp = CotizacionResponse(id_cotizacion="C001", celular="987654321")
    assert resp.alias is None


def test_cliente_previo_response_alias_default_vacio():
    resp = ClientePrevioResponse(
        comprador="Juan", direccion="Av. Test", tipo_envio="Shalom",
        metodo_pago="Yape", total_compras=1,
    )
    assert resp.alias is None
```

- [ ] **Step 2: Correr los tests y verificar que fallan**

```bash
cd pythonProject
python -m pytest tests/test_alias_models.py -v
```

Expected: `FAIL` — `TypeError` o `AttributeError`, `alias` no existe todavía en
ninguno de los modelos.

- [ ] **Step 3: Agregar el campo `alias` a los modelos**

En `backend/api/models.py`, agregar `alias: Optional[str] = None` a estas
clases (una línea cada una, después del último campo existente de cada una):

```python
class VentaResponse(BaseModel):
    ...
    estado: Optional[str] = None
    fila_sheet: Optional[int] = None
    alias: Optional[str] = None          # NUEVO
```

```python
class ClientePrevioResponse(BaseModel):
    ...
    total_compras: int
    alias: Optional[str] = None          # NUEVO
```

```python
class CotizacionResponse(BaseModel):
    ...
    estado: Optional[str] = None
    fila_sheet: Optional[int] = None
    alias: Optional[str] = None          # NUEVO
```

```python
class VentaRequest(BaseModel):
    ...
    items: list[ItemCestaAPI] = Field(..., min_length=1)
    alias: Optional[str] = None          # NUEVO
```

```python
class CotizacionRequest(BaseModel):
    ...
    items: list[ItemCestaAPI] = Field(..., min_length=1)
    alias: Optional[str] = None          # NUEVO
```

- [ ] **Step 4: Correr los tests y verificar que pasan**

```bash
cd pythonProject
python -m pytest tests/test_alias_models.py -v
```

Expected: `6 passed`

- [ ] **Step 5: Commit**

```bash
cd pythonProject
git add backend/api/models.py tests/test_alias_models.py
git commit -m "feat(models): agregar campo alias opcional a requests y responses"
```

---

### Task 3: Repositorio — `save_quote` guarda alias

**Files:**
- Modify: `pythonProject/backend/repositories/sheets_repository.py:296-313`
- Test: `pythonProject/tests/test_alias_repository.py`

- [ ] **Step 1: Escribir el test (fila con y sin alias)**

Crear `pythonProject/tests/test_alias_repository.py`:

```python
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
```

- [ ] **Step 2: Correr los tests y verificar que fallan**

```bash
cd pythonProject
python -m pytest tests/test_alias_repository.py -v
```

Expected: `FAIL` — `TypeError: save_quote() got an unexpected keyword argument 'alias'`

- [ ] **Step 3: Implementar el parámetro `alias` en `save_quote`**

En `backend/repositories/sheets_repository.py`, reemplazar el método:

```python
def save_quote(
    self, celular: str, items: list[dict], total: float, alias: str | None = None,
) -> str:
    """Guarda una cotización y retorna el ID asignado."""
    id_cotizacion = self.get_next_quote_id()
    items_txt = construir_items_txt(items)
    fila = [
        id_cotizacion,
        str(hoy_peru()),
        celular,
        items_txt,
        round(float(total), 2),
        "Enviado",
        alias or "",
    ]
    def _write():
        self._get_worksheet(WORKSHEET_COTIZACIONES).append_rows(
            [fila], value_input_option="USER_ENTERED"
        )
    self._ejecutar_con_reintento(_write, "save_quote")
    return id_cotizacion
```

- [ ] **Step 4: Correr los tests y verificar que pasan**

```bash
cd pythonProject
python -m pytest tests/test_alias_repository.py -v
```

Expected: `2 passed`

- [ ] **Step 5: Commit**

```bash
cd pythonProject
git add backend/repositories/sheets_repository.py tests/test_alias_repository.py
git commit -m "feat(repo): save_quote guarda alias opcional en columna G"
```

---

### Task 4: Repositorio — `register_complete_sale` guarda alias

**Files:**
- Modify: `pythonProject/backend/repositories/sheets_repository.py:414-454`
- Test: `pythonProject/tests/test_alias_repository.py` (agregar casos)

- [ ] **Step 1: Agregar tests al archivo existente**

Agregar al final de `pythonProject/tests/test_alias_repository.py`:

```python
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
```

- [ ] **Step 2: Correr los tests y verificar que fallan**

```bash
cd pythonProject
python -m pytest tests/test_alias_repository.py -v -k register_complete_sale
```

Expected: `FAIL` — `IndexError: list index out of range` (la fila solo tiene 12
elementos, no hay índice 12).

- [ ] **Step 3: Agregar `alias` a la fila en `register_complete_sale`**

En `backend/repositories/sheets_repository.py`, dentro de `register_complete_sale`:

```python
filas = [
    [
        id_compra,
        cliente["fecha"],
        cliente["comprador"].strip().title(),
        cliente["celular"],
        str(item["id_perfume"]),
        str(item["ml"]),
        round(float(item["precio"]), 2),
        item["metodo"],
        cliente["tipo_envio"],
        cliente["direccion"].strip().title(),
        (cliente.get("distrito") or "").strip().title(),
        "Pendiente",
        cliente.get("alias") or "",
    ]
    for item in cesta
]
```

- [ ] **Step 4: Correr los tests y verificar que pasan**

```bash
cd pythonProject
python -m pytest tests/test_alias_repository.py -v
```

Expected: `4 passed`

- [ ] **Step 5: Correr toda la suite de tests backend para verificar que nada se rompió**

```bash
cd pythonProject
python -m pytest tests/ -v
```

Expected: todos los tests pasan (los 2 archivos previos + los 2 nuevos).

- [ ] **Step 6: Commit**

```bash
cd pythonProject
git add backend/repositories/sheets_repository.py tests/test_alias_repository.py
git commit -m "feat(repo): register_complete_sale guarda alias opcional en columna M"
```

---

### Task 5: Rutas — pasar `alias` en POST y devolverlo en GET

**Files:**
- Modify: `pythonProject/backend/api/routes/cotizaciones.py:112-129, 172`
- Modify: `pythonProject/backend/api/routes/ventas.py:144-152`

- [ ] **Step 1: `cotizaciones.py` — pasar `body.alias` a `save_quote`**

```python
def guardar_cotizacion(
    body: CotizacionRequest,
    repo: SheetsRepository = Depends(get_repo),
):
    items = aplicar_descuentos([item.model_dump() for item in body.items])
    total = calcular_total_cotizacion(items)
    try:
        id_cot = repo.save_quote(body.celular, items, total, alias=body.alias)
        invalidar_cache_cotizaciones()
        return CotizacionRegistrada(id_cotizacion=id_cot)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al guardar cotizacion: {e}")
```

- [ ] **Step 2: `cotizaciones.py` — incluir `alias` en la serialización de listados**

```python
_COLS_FIJAS = ["ID_Cotizacion", "Fecha", "Celular", "Total", "Estado", "alias"]
```

- [ ] **Step 3: `ventas.py` — incluir `alias` en `ClientePrevioResponse`**

En `ventas_por_cliente`:

```python
    ultimo = historial.iloc[-1]
    resumen = ClientePrevioResponse(
        comprador=str(ultimo.get("Comprador", "") or ""),
        direccion=str(ultimo.get("Direccion", "") or ""),
        distrito=str(ultimo.get("Distrito", "") or ""),
        tipo_envio=str(ultimo.get("Tipo_Envio", "") or ""),
        metodo_pago=str(ultimo.get("Metodo_Pago", "") or ""),
        total_compras=len(historial),
        alias=str(ultimo.get("alias", "") or "") or None,
    )
```

- [ ] **Step 4: Correr toda la suite de tests backend**

```bash
cd pythonProject
python -m pytest tests/ -v
```

Expected: todos pasan (no se agregaron tests nuevos en este task — es wiring
directo ya cubierto por Task 2-4; verificar manualmente con `curl` en Step 5
del checklist final del plan).

- [ ] **Step 5: Commit**

```bash
cd pythonProject
git add backend/api/routes/cotizaciones.py backend/api/routes/ventas.py
git commit -m "feat(routes): exponer alias en POST/GET de ventas y cotizaciones"
```

---

## Frontend

### Task 6: Modelos Freezed — campo `alias`

**Files:**
- Modify: `perfuteca_flutter/lib/models/venta.dart`
- Modify: `perfuteca_flutter/lib/models/cotizacion.dart`

- [ ] **Step 1: Agregar `alias` a `VentaResponse` y `ClientePrevio`**

En `lib/models/venta.dart`:

```dart
@freezed
class VentaResponse with _$VentaResponse {
  const factory VentaResponse({
    @JsonKey(name: 'id_compra',      fromJson: _strOrEmpty)       @Default('') String  idCompra,
    @JsonKey(name: 'fila_sheet',     fromJson: _toInt)            @Default(0)  int     filaSheet,
    @JsonKey(                        fromJson: _toStrNullable)                 String? fecha,
    @JsonKey(                        fromJson: _toStrNullable)                 String? comprador,
    @JsonKey(                        fromJson: _toStrNullable)                 String? celular,
    @JsonKey(name: 'id_perfume',     fromJson: _toStrNullable)                String? idPerfume,
    @JsonKey(name: 'ml_vendido',     fromJson: _toIntNullable)                int?    mlVendido,
    @JsonKey(name: 'precio_cobrado', fromJson: _toDoubleNullable)             double? precioCobrado,
    @JsonKey(name: 'metodo_pago',    fromJson: _toStrNullable)                String? metodoPago,
    @JsonKey(name: 'tipo_envio',     fromJson: _toStrNullable)                String? tipoEnvio,
    @JsonKey(                        fromJson: _toStrNullable)                 String? direccion,
    @JsonKey(                        fromJson: _toStrNullable)                 String? distrito,
    @JsonKey(                        fromJson: _toStrNullable)                 String? estado,
    @JsonKey(                        fromJson: _toStrNullable)                 String? alias,
  }) = _VentaResponse;

  factory VentaResponse.fromJson(Map<String, dynamic> json) =>
      _$VentaResponseFromJson(json);
}

@freezed
class ClientePrevio with _$ClientePrevio {
  const factory ClientePrevio({
    required String comprador,
    required String direccion,
    @Default('') String distrito,
    @JsonKey(name: 'tipo_envio')                        required String tipoEnvio,
    @JsonKey(name: 'metodo_pago')                       required String metodoPago,
    @JsonKey(name: 'total_compras', fromJson: _toInt)   @Default(0) int totalCompras,
    @JsonKey(                       fromJson: _toStrNullable)       String? alias,
  }) = _ClientePrevio;

  factory ClientePrevio.fromJson(Map<String, dynamic> json) =>
      _$ClientePrevioFromJson(json);
}
```

- [ ] **Step 2: Agregar `alias` a `CotizacionResponse`**

En `lib/models/cotizacion.dart`:

```dart
@freezed
class CotizacionResponse with _$CotizacionResponse {
  const factory CotizacionResponse({
    @JsonKey(name: 'id_cotizacion', fromJson: _strOrEmpty) @Default('') String idCotizacion,
    @JsonKey(fromJson: _strOrEmpty)                        @Default('') String celular,
    String? fecha,
    String? items,
    @JsonKey(fromJson: _toDoubleNullable) double? total,
    String? estado,
    @JsonKey(name: 'fila_sheet', fromJson: _toInt) @Default(0) int filaSheet,
    String? alias,
  }) = _CotizacionResponse;

  factory CotizacionResponse.fromJson(Map<String, dynamic> json) =>
      _$CotizacionResponseFromJson(json);
}
```

- [ ] **Step 3: Regenerar los archivos `.freezed.dart` y `.g.dart`**

```bash
cd perfuteca_flutter
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: `Succeeded after ...` sin errores, archivos `venta.freezed.dart`,
`venta.g.dart`, `cotizacion.freezed.dart`, `cotizacion.g.dart` modificados.

- [ ] **Step 4: Verificar que el proyecto analiza limpio**

```bash
cd perfuteca_flutter
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
cd perfuteca_flutter
git add lib/models/venta.dart lib/models/venta.freezed.dart lib/models/venta.g.dart \
        lib/models/cotizacion.dart lib/models/cotizacion.freezed.dart lib/models/cotizacion.g.dart
git commit -m "feat(models): agregar campo alias opcional a VentaResponse, ClientePrevio y CotizacionResponse"
```

---

### Task 7: Repositorios HTTP — enviar `alias` al backend

**Files:**
- Modify: `perfuteca_flutter/lib/repositories/ventas_repository.dart:85-113`
- Modify: `perfuteca_flutter/lib/repositories/cotizaciones_repository.dart:69-87`

- [ ] **Step 1: `ventas_repository.dart` — agregar parámetro `alias`**

```dart
  Future<VentaRegistrada> registrarVenta({
    required String comprador,
    required String celular,
    required String direccion,
    required String tipoEnvio,
    required String fecha,
    required List<Map<String, dynamic>> items,
    String distrito = '',
    String? alias,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiConstants.ventas,
        data: {
          'comprador':  comprador,
          'celular':    celular,
          'direccion':  direccion,
          if (distrito.isNotEmpty) 'distrito': distrito,
          'tipo_envio': tipoEnvio,
          'fecha':      fecha,
          'items':      items,
          if (alias != null && alias.trim().isNotEmpty) 'alias': alias.trim(),
        },
      );
      return VentaRegistrada.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (_) {
      throw const ParseException();
    }
  }
```

- [ ] **Step 2: `cotizaciones_repository.dart` — agregar parámetro `alias`**

```dart
  Future<CotizacionRegistrada> guardarCotizacion({
    required String celular,
    required List<Map<String, dynamic>> items,
    String? alias,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiConstants.cotizaciones,
        data: {
          'celular': celular,
          'items':   items,
          if (alias != null && alias.trim().isNotEmpty) 'alias': alias.trim(),
        },
      );
      return CotizacionRegistrada.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (_) {
      throw const ParseException();
    }
  }
```

- [ ] **Step 3: `flutter analyze`**

```bash
cd perfuteca_flutter
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
cd perfuteca_flutter
git add lib/repositories/ventas_repository.dart lib/repositories/cotizaciones_repository.dart
git commit -m "feat(repos): enviar alias opcional al registrar venta y cotizacion"
```

---

### Task 8: `whatsapp_launcher.dart` — helpers puros + soporte alias

**Files:**
- Modify: `perfuteca_flutter/lib/core/utils/whatsapp_launcher.dart`
- Test: `perfuteca_flutter/test/whatsapp_launcher_test.dart`

- [ ] **Step 1: Escribir el test de los helpers puros**

Crear `perfuteca_flutter/test/whatsapp_launcher_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:perfuteca/core/utils/whatsapp_launcher.dart';

void main() {
  group('resolverDestinoWhatsApp', () {
    test('usa alias sin prefijo cuando esta presente', () {
      expect(
        resolverDestinoWhatsApp(celular: '987654321', alias: 'perfutecalima'),
        'perfutecalima',
      );
    });

    test('quita un @ inicial del alias', () {
      expect(
        resolverDestinoWhatsApp(celular: '987654321', alias: '@perfutecalima'),
        'perfutecalima',
      );
    });

    test('cae a celular con prefijo 51 cuando no hay alias', () {
      expect(
        resolverDestinoWhatsApp(celular: '987654321', alias: null),
        '51987654321',
      );
    });

    test('no duplica el prefijo 51 si el celular ya lo tiene', () {
      expect(
        resolverDestinoWhatsApp(celular: '51987654321', alias: null),
        '51987654321',
      );
    });

    test('alias vacio o solo espacios se trata como ausente', () {
      expect(
        resolverDestinoWhatsApp(celular: '987654321', alias: '   '),
        '51987654321',
      );
    });

    test('celular null y sin alias retorna string vacio (selector de chat)', () {
      expect(
        resolverDestinoWhatsApp(celular: null, alias: null),
        '',
      );
    });
  });

  group('lineaContacto', () {
    test('celular y alias juntos cuando hay alias', () {
      expect(
        lineaContacto('987654321', 'perfutecalima'),
        '987654321 (@perfutecalima)',
      );
    });

    test('normaliza el @ inicial del alias para no duplicarlo', () {
      expect(
        lineaContacto('987654321', '@perfutecalima'),
        '987654321 (@perfutecalima)',
      );
    });

    test('solo celular cuando no hay alias', () {
      expect(lineaContacto('987654321', null), '987654321');
    });

    test('solo celular cuando alias es string vacio', () {
      expect(lineaContacto('987654321', ''), '987654321');
    });
  });
}
```

- [ ] **Step 2: Correr el test y verificar que falla**

```bash
cd perfuteca_flutter
flutter test test/whatsapp_launcher_test.dart
```

Expected: `FAIL` — `resolverDestinoWhatsApp` y `lineaContacto` no existen
todavía (error de compilación).

- [ ] **Step 3: Reescribir `whatsapp_launcher.dart` con los helpers y soporte de alias**

```dart
import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';

const _paqueteWhatsappBusiness = 'com.whatsapp.w4b';

/// Quita un '@' inicial si el usuario lo tipeó al guardar el alias.
String _normalizarAlias(String alias) =>
    alias.startsWith('@') ? alias.substring(1) : alias;

/// Resuelve el destino para el deep-link de wa.me.
///
/// Si [alias] tiene contenido (ignorando espacios) se usa tal cual
/// (WhatsApp resuelve `wa.me/<alias>` directo, sin prefijo de país).
/// Si no, cae al comportamiento con [celular]: agrega prefijo `51` si
/// falta. Si ambos son null/vacíos retorna '' (selector de chat).
String resolverDestinoWhatsApp({String? celular, String? alias}) {
  final aliasLimpio = alias?.trim() ?? '';
  if (aliasLimpio.isNotEmpty) return _normalizarAlias(aliasLimpio);

  if (celular == null || celular.isEmpty) return '';
  return celular.startsWith('51') ? celular : '51$celular';
}

/// Línea de contacto para mensajes de texto: celular + alias juntos si
/// hay alias, o solo celular si no.
String lineaContacto(String celular, String? alias) {
  final aliasLimpio = alias?.trim() ?? '';
  if (aliasLimpio.isEmpty) return celular;
  return '$celular (@${_normalizarAlias(aliasLimpio)})';
}

/// Abre WhatsApp Business con [mensaje] ya listo para enviar.
///
/// Si se pasa [alias] (no vacío), abre el chat directo con ese alias
/// (`wa.me/<alias>`). Si no, y se pasa [celular], abre el chat directo con
/// ese número (prefijo `51` agregado automáticamente si falta). Si ambos
/// son null, abre el selector de chat/grupo de WhatsApp (para enviar a la
/// comunidad).
///
/// Si WhatsApp Business no está instalado, cae a `wa.me` normal (WhatsApp
/// estándar o selector del sistema si hay varias apps).
Future<void> abrirWhatsAppBusiness({
  String? celular,
  String? alias,
  required String mensaje,
}) async {
  final texto = Uri.encodeComponent(mensaje);
  final destino = resolverDestinoWhatsApp(celular: celular, alias: alias);
  final url = 'https://wa.me/$destino?text=$texto';

  try {
    final intent = AndroidIntent(
      action: 'action_view',
      package: _paqueteWhatsappBusiness,
      data: url,
    );
    await intent.launch();
  } catch (_) {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}
```

- [ ] **Step 4: Correr el test y verificar que pasa**

```bash
cd perfuteca_flutter
flutter test test/whatsapp_launcher_test.dart
```

Expected: `All tests passed!` (10 tests)

- [ ] **Step 5: Commit**

```bash
cd perfuteca_flutter
git add lib/core/utils/whatsapp_launcher.dart test/whatsapp_launcher_test.dart
git commit -m "feat(whatsapp): soportar alias en deep-link y texto de mensajes"
```

---

### Task 9: `nueva_venta_provider.dart` — estado y autocompletar de alias

**Files:**
- Modify: `perfuteca_flutter/lib/features/ventas/providers/nueva_venta_provider.dart`
- Test: `perfuteca_flutter/test/nueva_venta_alias_test.dart`

- [ ] **Step 1: Escribir el test**

Crear `perfuteca_flutter/test/nueva_venta_alias_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfuteca/features/ventas/providers/nueva_venta_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('setAlias actualiza el estado', () {
    final notifier = container.read(nuevaVentaProvider.notifier);
    notifier.setAlias('perfutecalima');
    expect(container.read(nuevaVentaProvider).alias, 'perfutecalima');
  });

  test('reset limpia el alias', () {
    final notifier = container.read(nuevaVentaProvider.notifier);
    notifier.setAlias('perfutecalima');
    notifier.reset();
    expect(container.read(nuevaVentaProvider).alias, '');
  });
}
```

- [ ] **Step 2: Correr el test y verificar que falla**

```bash
cd perfuteca_flutter
flutter test test/nueva_venta_alias_test.dart
```

Expected: `FAIL` — `setAlias` no existe / `alias` no es un getter de
`NuevaVentaState` (error de compilación).

- [ ] **Step 3: Agregar `alias` al estado, `copyWith`, `setAlias`, autocompletar y envío**

En `perfuteca_flutter/lib/features/ventas/providers/nueva_venta_provider.dart`,
constructor de `NuevaVentaState`:

```dart
class NuevaVentaState {
  const NuevaVentaState({
    this.paso           = 1,
    this.comprador      = '',
    this.celular        = '',
    this.alias          = '',
    this.direccion      = '',
    this.distrito       = '',
    this.tipoEnvio      = '',
    this.metodoPago     = 'Yape',
    this.fecha          = '',
    this.cesta          = const [],
    this.clientePrevio,
    this.buscandoCliente = false,
    this.registrando     = false,
    this.ventaRegistrada,
    this.error,
    this.refCotizacion,
    this.refItems,
  });

  final int               paso;
  final String            comprador;
  final String            celular;
  final String            alias;
  final String            direccion;
  ...
```

(el resto de los campos existentes queda igual, solo se inserta `alias`
después de `celular`).

`copyWith`:

```dart
  NuevaVentaState copyWith({
    int?              paso,
    String?           comprador,
    String?           celular,
    String?           alias,
    String?           direccion,
    ...
  }) => NuevaVentaState(
    paso:             paso            ?? this.paso,
    comprador:        comprador       ?? this.comprador,
    celular:          celular         ?? this.celular,
    alias:            alias           ?? this.alias,
    direccion:        direccion       ?? this.direccion,
    ...
```

Notifier — agregar el setter y autocompletar en `_buscarCliente`:

```dart
  void setCelular(String v) {
    state = state.copyWith(celular: v, clearCliente: true);
    if (v.length == 9) _buscarCliente(v);
  }

  void setAlias(String v) => state = state.copyWith(alias: v);

  Future<void> _buscarCliente(String celular) async {
    state = state.copyWith(buscandoCliente: true);
    try {
      final cliente = await _repo.getClientePrevio(celular);
      if (cliente != null) {
        state = state.copyWith(
          buscandoCliente: false,
          clientePrevio:   cliente,
          comprador:  state.comprador.trim().isEmpty  ? cliente.comprador  : state.comprador,
          direccion:  state.direccion.trim().isEmpty  ? cliente.direccion  : state.direccion,
          distrito:   state.distrito.trim().isEmpty   ? cliente.distrito   : state.distrito,
          tipoEnvio:  state.tipoEnvio.isEmpty         ? cliente.tipoEnvio  : state.tipoEnvio,
          metodoPago: cliente.metodoPago,
          alias:      state.alias.trim().isEmpty ? (cliente.alias ?? '') : state.alias,
        );
      } else {
        state = state.copyWith(buscandoCliente: false);
      }
    } catch (_) {
      state = state.copyWith(buscandoCliente: false);
    }
  }
```

`registrarVenta` — enviar el alias:

```dart
  Future<void> registrarVenta() async {
    state = state.copyWith(registrando: true, clearError: true);
    try {
      final registrada = await _repo.registrarVenta(
        comprador: state.comprador,
        celular:   state.celular,
        direccion: state.direccion,
        distrito:  state.distrito,
        tipoEnvio: state.tipoEnvio,
        fecha:     state.fecha,
        items:     state.cesta.map((i) => i.toApiMap()).toList(),
        alias:     state.alias,
      );
      ...
```

- [ ] **Step 4: Correr el test y verificar que pasa**

```bash
cd perfuteca_flutter
flutter test test/nueva_venta_alias_test.dart
```

Expected: `All tests passed!` (2 tests)

- [ ] **Step 5: `flutter analyze`**

```bash
cd perfuteca_flutter
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
cd perfuteca_flutter
git add lib/features/ventas/providers/nueva_venta_provider.dart test/nueva_venta_alias_test.dart
git commit -m "feat(ventas): estado y autocompletar de alias en nueva venta"
```

---

### Task 10: `nueva_cotizacion_provider.dart` — estado de alias

**Files:**
- Modify: `perfuteca_flutter/lib/features/cotizaciones/providers/nueva_cotizacion_provider.dart`
- Test: `perfuteca_flutter/test/nueva_cotizacion_alias_test.dart`

- [ ] **Step 1: Escribir el test**

Crear `perfuteca_flutter/test/nueva_cotizacion_alias_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfuteca/features/cotizaciones/providers/nueva_cotizacion_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('setAlias actualiza el estado sin afectar paso1Valido', () {
    final notifier = container.read(nuevaCotizacionProvider.notifier);
    notifier.setCelular('987654321');
    notifier.setAlias('perfutecalima');

    final state = container.read(nuevaCotizacionProvider);
    expect(state.alias, 'perfutecalima');
    expect(state.paso1Valido, isTrue); // alias no es requisito
  });

  test('reset limpia el alias', () {
    final notifier = container.read(nuevaCotizacionProvider.notifier);
    notifier.setAlias('perfutecalima');
    notifier.reset();
    expect(container.read(nuevaCotizacionProvider).alias, '');
  });
}
```

- [ ] **Step 2: Correr el test y verificar que falla**

```bash
cd perfuteca_flutter
flutter test test/nueva_cotizacion_alias_test.dart
```

Expected: `FAIL` — `setAlias`/`alias` no existen (error de compilación).

- [ ] **Step 3: Agregar `alias` al estado, `copyWith`, `setAlias` y `guardar()`**

```dart
class NuevaCotizacionState {
  const NuevaCotizacionState({
    this.paso                = 1,
    this.celular             = '',
    this.alias               = '',
    this.cesta               = const [],
    this.conDelivery         = false,
    this.indicesConDescuento = const {},
    this.registrando         = false,
    this.registrada,
    this.error,
  });

  final int                   paso;
  final String                celular;
  final String                alias;
  final List<ItemCesta>       cesta;
  ...
```

```dart
  NuevaCotizacionState copyWith({
    int?                  paso,
    String?               celular,
    String?               alias,
    List<ItemCesta>?      cesta,
    ...
  }) => NuevaCotizacionState(
    paso:                paso                ?? this.paso,
    celular:             celular             ?? this.celular,
    alias:               alias               ?? this.alias,
    cesta:               cesta               ?? this.cesta,
    ...
```

```dart
  void setCelular(String v)    => state = state.copyWith(celular: v);
  void setAlias(String v)      => state = state.copyWith(alias: v);
```

```dart
  Future<void> guardar() async {
    state = state.copyWith(registrando: true, clearError: true);
    try {
      final registrada = await _repo.guardarCotizacion(
        celular: state.celular,
        alias:   state.alias,
        items:   state.cesta.asMap().entries.map((e) =>
            e.value.toApiMap(conDescuento: state.itemConDescuento(e.key))).toList(),
      );
      ...
```

- [ ] **Step 4: Correr el test y verificar que pasa**

```bash
cd perfuteca_flutter
flutter test test/nueva_cotizacion_alias_test.dart
```

Expected: `All tests passed!` (2 tests)

- [ ] **Step 5: Correr toda la suite de tests de provider existentes (regresión)**

```bash
cd perfuteca_flutter
flutter test test/nueva_cotizacion_descuento_test.dart
```

Expected: todos pasan sin cambios.

- [ ] **Step 6: Commit**

```bash
cd perfuteca_flutter
git add lib/features/cotizaciones/providers/nueva_cotizacion_provider.dart test/nueva_cotizacion_alias_test.dart
git commit -m "feat(cotizaciones): estado de alias en nueva cotizacion"
```

---

### Task 11: `nueva_venta_screen.dart` — campo UI + envío WhatsApp con alias

**Files:**
- Modify: `perfuteca_flutter/lib/features/ventas/screens/nueva_venta_screen.dart`

- [ ] **Step 1: Agregar controller de alias en `_Paso1State`**

```dart
class _Paso1State extends ConsumerState<_Paso1> {
  final _celularCtrl   = TextEditingController();
  final _aliasCtrl     = TextEditingController();
  final _compradorCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _distritoCtrl  = TextEditingController();

  @override
  void dispose() {
    _celularCtrl.dispose();
    _aliasCtrl.dispose();
    _compradorCtrl.dispose();
    _direccionCtrl.dispose();
    _distritoCtrl.dispose();
    super.dispose();
  }
```

- [ ] **Step 2: Sincronizar el controller con el estado**

```dart
    if (_celularCtrl.text != state.celular)     _celularCtrl.text   = state.celular;
    if (_aliasCtrl.text != state.alias)         _aliasCtrl.text     = state.alias;
    if (_compradorCtrl.text != state.comprador) _compradorCtrl.text = state.comprador;
```

- [ ] **Step 3: Agregar el input debajo del campo Celular**

Inmediatamente después del bloque `TextField` de Celular (después del banner
de cliente frecuente, antes de `const SizedBox(height: AppSpacing.sm);` que
precede a "Nombre"):

```dart
          // Banner cliente frecuente
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: state.clientePrevio != null
                ? _ClienteBanner(cliente: state.clientePrevio!)
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Alias WhatsApp (opcional) ──────────────────────────────────
          _Label('Alias WhatsApp (opcional)', Icons.alternate_email_rounded),
          TextField(
            controller: _aliasCtrl,
            decoration: _inputDecor(hint: '@perfutecalima'),
            onChanged: notifier.setAlias,
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Nombre ──────────────────────────────────────────────────────
          _Label('Nombre del comprador', Icons.person_outline_rounded),
```

(se borra el `const SizedBox(height: AppSpacing.sm);` duplicado que ya
existía antes de "Nombre" — queda solo el que ahora separa el nuevo campo).

- [ ] **Step 4: Pasar `alias` a `_TicketExito`**

```dart
        child: _TicketExito(
          idCompra:   ventaRegistrada.idCompra,
          warning:    ventaRegistrada.warning,
          celular:    state.celular,
          alias:      state.alias,
          comprador:  state.comprador,
          tipoEnvio:  state.tipoEnvio,
          direccion:  state.direccion,
```

- [ ] **Step 5: Agregar el campo `alias` a la clase `_TicketExito`**

```dart
class _TicketExito extends StatelessWidget {
  const _TicketExito({
    required this.idCompra,
    required this.celular,
    required this.alias,
    required this.comprador,
    required this.tipoEnvio,
    required this.direccion,
    required this.metodoPago,
    required this.total,
    required this.cesta,
    required this.onNueva,
    this.warning,
  });
  final String       idCompra;
  final String?      warning;
  final String       celular;
  final String       alias;
  final String       comprador;
```

- [ ] **Step 6: Usar `alias` en el deep-link y el texto del mensaje al cliente**

```dart
              onPressed: () => _abrirWhatsApp(context, celular, alias, idCompra, total),
```

```dart
  Future<void> _abrirWhatsApp(
      BuildContext context, String cel, String alias, String id, double total) async {
    const sep = '────────────────────';
    ...
    final msg =
      '🌸 *Perfuteca — Pedido $id*\n'
      '$sep\n'
      '👤 *Comprador:* $comprador\n'
      '📱 *Celular:* ${lineaContacto(cel, alias)}\n'
      '🚚 *Envío:* $tipoEnvio'
      '$dirLinea\n'
      '$sep\n'
      '🛍️ *Tu pedido:*\n'
      '$itemsTexto\n'
      '$sep\n'
      '📦 Tu pedido estará siendo enviado el *$fechaEnvio*.\n\n'
      '_¡Gracias por tu compra! 💛_';
    try {
      await abrirWhatsAppBusiness(celular: cel, alias: alias, mensaje: msg);
    } catch (_) {
```

- [ ] **Step 7: Usar `lineaContacto` en el mensaje de comunidad**

```dart
    final msg =
      '📦 *Perfuteca — Pedido Nuevo $id*\n$sep\n'
      '👤 *Cliente:* $comprador\n'
      '📱 *Celular:* ${lineaContacto(celular, alias)}\n'
      '🚚 *Envío:* $tipoEnvio$dirLinea\n'
      '$sep\n'
      '🌸 *Perfumes:*\n$itemsLineas\n'
      '$sep\n'
      '💰 *Total: S/ ${total.toStringAsFixed(2)}*\n'
      '💳 *Pago:* $pago';
```

- [ ] **Step 8: Agregar el import de `lineaContacto`**

Verificar que `whatsapp_launcher.dart` ya está importado (lo está, para
`abrirWhatsAppBusiness`) — `lineaContacto` viene del mismo archivo, sin
imports nuevos.

- [ ] **Step 9: `flutter analyze`**

```bash
cd perfuteca_flutter
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 10: Commit**

```bash
cd perfuteca_flutter
git add lib/features/ventas/screens/nueva_venta_screen.dart
git commit -m "feat(ventas): campo alias en formulario y envio WhatsApp con alias"
```

---

### Task 12: `nueva_cotizacion_screen.dart` — campo UI + envío WhatsApp con alias

**Files:**
- Modify: `perfuteca_flutter/lib/features/cotizaciones/screens/nueva_cotizacion_screen.dart`

- [ ] **Step 1: Agregar controller de alias en `_Paso1State`**

```dart
class _Paso1State extends ConsumerState<_Paso1> {
  late final TextEditingController _celCtrl;
  late final TextEditingController _aliasCtrl;

  @override
  void initState() {
    super.initState();
    _celCtrl = TextEditingController(
      text: ref.read(nuevaCotizacionProvider).celular,
    );
    _aliasCtrl = TextEditingController(
      text: ref.read(nuevaCotizacionProvider).alias,
    );
  }

  @override
  void dispose() {
    _celCtrl.dispose();
    _aliasCtrl.dispose();
    super.dispose();
  }
```

- [ ] **Step 2: Agregar el input debajo del campo Celular**

Después del `TextFormField` de celular (antes de
`const SizedBox(height: AppSpacing.xl);` que precede al botón Continuar):

```dart
            onChanged: (v) => _onCelularChanged(v, notifier),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Alias WhatsApp (opcional)',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _aliasCtrl,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18),
              hintText: '@perfutecalima',
              filled: true,
              fillColor: AppColors.primaryPale,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(color: AppColors.primaryLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            onChanged: notifier.setAlias,
          ),
          const SizedBox(height: AppSpacing.xl),
```

(el `SizedBox` de `AppSpacing.xl` que ya existía antes del botón Continuar se
reemplaza por este bloque completo — queda uno solo, al final, antes del
botón).

- [ ] **Step 3: Pasar `alias` a `_TicketExito` (cotización)**

```dart
              _TicketExito(
                      idCotizacion: state.registrada!.idCotizacion,
                      celular:      state.celular,
                      alias:        state.alias,
                      total:        state.totalConDelivery,
                      cesta:        state.cesta,
                      conDelivery:         state.conDelivery,
```

- [ ] **Step 4: Agregar el campo `alias` a la clase `_TicketExito`**

```dart
class _TicketExito extends StatefulWidget {
  const _TicketExito({
    required this.idCotizacion,
    required this.celular,
    required this.alias,
    required this.total,
    required this.cesta,
    required this.conDelivery,
```

y su declaración de campo (junto a `final String celular;` existente):

```dart
  final String  celular;
  final String? alias;
```

- [ ] **Step 5: Usar `alias` en el deep-link del mensaje al cliente**

```dart
    final numero = widget.celular.replaceAll(RegExp(r'\D'), '');
    try {
      await abrirWhatsAppBusiness(celular: numero, alias: widget.alias, mensaje: texto);
    } catch (_) {}
```

- [ ] **Step 6: `flutter analyze`**

```bash
cd perfuteca_flutter
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
cd perfuteca_flutter
git add lib/features/cotizaciones/screens/nueva_cotizacion_screen.dart
git commit -m "feat(cotizaciones): campo alias en formulario y envio WhatsApp con alias"
```

---

### Task 13: `cotizacion_convertir_card.dart` — propagar alias al convertir a venta

**Files:**
- Modify: `perfuteca_flutter/lib/features/cotizaciones/widgets/cotizacion_convertir_card.dart`

- [ ] **Step 1: Pasar `alias` al registrar la venta**

En los dos call sites de `registrarVenta` (líneas ~167 y ~456 según el
árbol actual — buscar `ventasRepositoryProvider).registrarVenta(` y el
widget `NuevaVentaState`/similar que arma el request):

```dart
      await ref.read(ventasRepositoryProvider).registrarVenta(
        comprador: _compradorCtrl.text.trim(),
        celular:   widget.cotizacion.celular,
        alias:     widget.cotizacion.alias,
        direccion: _direccionCtrl.text.trim(),
        distrito:  _distritoCtrl.text.trim(),
```

- [ ] **Step 2: Pasar `alias` a `_CartaExito`**

```dart
        child: _CartaExito(
          idVenta:      _idVenta ?? '',
          idCotizacion: widget.cotizacion.idCotizacion,
          comprador:    _compradorCtrl.text.trim(),
          celular:      widget.cotizacion.celular,
          alias:        widget.cotizacion.alias,
          tipoEnvio:    _tipoEnvio,
          direccion:    _direccionCtrl.text.trim(),
```

- [ ] **Step 3: Agregar el campo `alias` a `_CartaExito`**

```dart
class _CartaExito extends StatelessWidget {
  const _CartaExito({
    required this.idVenta,
    required this.idCotizacion,
    required this.comprador,
    required this.celular,
    this.alias,
    required this.tipoEnvio,
    required this.direccion,
    required this.distrito,
    required this.metodoPago,
    required this.itemsStr,
    required this.cesta,
    required this.total,
    required this.sincronizando,
    required this.estadoSincOk,
    required this.onReintentarSinc,
  });
  final String         idVenta;
  final String         idCotizacion;
  final String         comprador;
  final String         celular;
  final String?        alias;
  final String         tipoEnvio;
```

- [ ] **Step 4: Usar `lineaContacto` en el mensaje de comunidad**

```dart
    final texto =
        '📦 *Perfuteca — Pedido $idVenta*\n$sep\n'
        '👤 *Cliente:* $comprador\n📱 *Celular:* ${lineaContacto(celular, alias)}\n'
        '🚚 *Envío:* $tipoEnvio$dirLinea$distLinea\n$sep\n'
        '🌸 *Perfumes:*\n$itemsLineas\n$sep\n'
        '💰 *Total: S/ ${total.toStringAsFixed(2)}*\n'
        '💳 *Pago:* $metodoPago';
```

- [ ] **Step 5: `flutter analyze`**

```bash
cd perfuteca_flutter
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
cd perfuteca_flutter
git add lib/features/cotizaciones/widgets/cotizacion_convertir_card.dart
git commit -m "feat(cotizaciones): propagar alias al convertir cotizacion a venta"
```

---

### Task 14: `pendientes_screen.dart` — mostrar alias en mensaje de comunidad

**Files:**
- Modify: `perfuteca_flutter/lib/features/ventas/screens/pendientes_screen.dart`

- [ ] **Step 1: Agregar getter `alias` a `_Orden`**

```dart
  String? get comprador  => items.first.comprador;
  String? get celular    => items.first.celular;
  String? get alias      => items.first.alias;
  String? get direccion  => items.first.direccion;
```

- [ ] **Step 2: Usar `lineaContacto` en el mensaje de comunidad**

```dart
    final msg =
      '📦 *Perfuteca — Pedido ${orden.idCompra}*\n$sep\n'
      '👤 *Cliente:* ${orden.comprador ?? '—'}\n'
      '📱 *Celular:* ${orden.celular != null ? lineaContacto(orden.celular!, orden.alias) : '—'}\n'
      '🚚 *Envío:* ${orden.tipoEnvio ?? '—'}$dirLinea$distLinea\n'
      '$sep\n'
      '🌸 *Perfumes:*\n$itemsLineas\n'
      '$sep\n'
      '💰 *Total: S/ ${orden.total.toStringAsFixed(2)}*\n'
      '💳 *Pago:* ${orden.metodoPago ?? '—'}';
```

- [ ] **Step 3: `flutter analyze`**

```bash
cd perfuteca_flutter
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
cd perfuteca_flutter
git add lib/features/ventas/screens/pendientes_screen.dart
git commit -m "feat(ventas): mostrar alias en mensaje de pendientes a comunidad"
```

---

### Task 15: Verificación final end-to-end

**Files:** ninguno (solo comandos y smoke test manual)

- [ ] **Step 1: Suite completa backend**

```bash
cd pythonProject
python -m pytest tests/ -v
```

Expected: todos los tests pasan (incluye los 3 archivos nuevos/editados de
este plan más los 2 preexistentes).

- [ ] **Step 2: Suite completa Flutter**

```bash
cd perfuteca_flutter
flutter test
```

Expected: todos los tests pasan (incluye los 4 archivos nuevos de este plan
más los preexistentes en `test/`).

- [ ] **Step 3: Analyze completo**

```bash
cd perfuteca_flutter
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 4: Smoke test manual — nueva venta sin alias**

Levantar backend local, correr app en emulador/dispositivo. Crear venta sin
llenar el campo alias. Confirmar: WhatsApp abre `wa.me/51<celular>` como
antes (comportamiento sin regresión).

- [ ] **Step 5: Smoke test manual — nueva venta con alias**

Crear venta llenando alias (ej. `@perfutecalima`, o `perfutecalima` sin
arroba). Confirmar:
- Botón "WhatsApp a [cliente]" abre `wa.me/perfutecalima` (sin `51`, sin el
  `@`).
- El texto del mensaje muestra `📱 *Celular:* 987654321 (@perfutecalima)`.
- Botón "Enviar pedido a comunidad" muestra la misma línea de contacto.

- [ ] **Step 6: Smoke test manual — nueva cotización con alias, convertir a venta**

Crear cotización con alias, marcarla "Aceptada", convertir a venta desde
`cotizacion_convertir_card`. Confirmar que el alias se propaga a la venta
resultante y aparece en el mensaje de comunidad de la conversión.

- [ ] **Step 7: Smoke test manual — cliente recurrente autocompleta alias**

Con el mismo celular de una venta anterior que tenía alias guardado, iniciar
una venta nueva. Confirmar que el campo alias se autocompleta (sin pisar si
el usuario ya escribió algo antes de que la búsqueda responda).

- [ ] **Step 8: Verificar columna `alias` en Google Sheets**

Abrir la hoja `Ventas_Pendientes` (después de agregar la columna `M`
manualmente, ver pre-requisito al inicio del plan) y `Cotizaciones`,
confirmar que las filas nuevas escriben el alias en la columna correcta y
las filas sin alias quedan con celda vacía (no `None`/`null` como texto).

---

## Self-Review

**Cobertura del spec:**
- Sheets (columna alias en ambas hojas) → Task 1, pre-requisito manual, Step 8 final.
- Modelos backend request/response → Task 2.
- `save_quote` con alias → Task 3.
- `register_complete_sale` con alias → Task 4.
- Rutas exponen alias en POST/GET, incluyendo autocompletar por historial → Task 5.
- Modelos Freezed frontend → Task 6.
- Repos HTTP envían alias → Task 7.
- `whatsapp_launcher.dart` deep-link + texto con alias → Task 8.
- Provider venta: estado, autocompletar, envío → Task 9.
- Provider cotización: estado, envío → Task 10.
- UI nueva venta: campo + envío WhatsApp (cliente y comunidad) → Task 11.
- UI nueva cotización: campo + envío WhatsApp → Task 12.
- Convertir cotización → venta propaga alias → Task 13.
- Pendientes muestra alias en mensaje comunidad → Task 14.
- Decisiones confirmadas (prioridad alias, campo siempre visible, formato
  "celular (@alias)") → aplicadas en Tasks 8, 11, 12, 13, 14.
- Testing (backend pytest, Flutter build+smoke) → Tasks 2-4, 8-10 (automatizado) + Task 15 (smoke manual).

Sin gaps identificados.

**Placeholders:** ninguno — todo el código de cada step está completo y es
el código real a escribir, no descripciones.

**Consistencia de tipos/firmas:**
- `resolverDestinoWhatsApp({String? celular, String? alias})` y
  `lineaContacto(String celular, String? alias)` — firmas usadas igual en
  Tasks 8, 11, 12, 13, 14.
- `abrirWhatsAppBusiness({String? celular, String? alias, required String mensaje})`
  — firma consistente en Tasks 8, 11, 12.
- `VentasRepository.registrarVenta(..., String? alias)` y
  `CotizacionesRepository.guardarCotizacion(..., String? alias)` — firmas
  usadas igual en Tasks 9, 10, 13.
- `NuevaVentaState.alias` / `NuevaCotizacionState.alias` (`String`, default
  `''`) — consistente entre estado, `copyWith`, provider tests y consumo en
  screens.
- `VentaResponse.alias`, `ClientePrevio.alias`, `CotizacionResponse.alias`
  (`String?`) — consistente entre Task 6 y su consumo en Tasks 9, 13, 14.

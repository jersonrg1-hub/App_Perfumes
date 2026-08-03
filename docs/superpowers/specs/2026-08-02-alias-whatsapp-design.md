# Alias de WhatsApp opcional — Diseño

**Fecha:** 2026-08-02
**Estado:** Aprobado, listo para plan de implementación

## Problema

WhatsApp ahora permite usernames/alias públicos (`wa.me/<alias>`) en vez de número
de teléfono. Algunos clientes usan alias y ya no comparten el número, por lo que
el flujo actual de Perfuteca (que arma `wa.me/51<celular>`) no puede contactarlos.

## Objetivo

Guardar un alias de WhatsApp opcional junto al celular en `Cotizaciones` y
`Ventas_Pendientes`. Al enviar por WhatsApp, si hay alias se usa
`wa.me/<alias>`; si no, cae al comportamiento actual con celular. Celular sigue
siendo obligatorio en los formularios (identidad primaria del cliente,
historial/autocompletar); alias es aditivo y 100% opcional.

## Alcance

- Backend: modelos, repositorio, rutas de `ventas` y `cotizaciones`.
- Google Sheets: nueva columna `alias` en ambas hojas.
- Flutter: formularios de nueva venta / nueva cotización, autocompletar por
  historial, envío por WhatsApp (deep-link + texto de mensajes) en los 4 flujos
  existentes (venta cliente, venta comunidad, convertir cotización, pendientes).

Fuera de alcance: búsqueda de cliente por alias (`/cliente/{alias}`), edición
retroactiva de registros ya guardados, validación de formato/unicidad del alias
(WhatsApp ya la garantiza).

## Google Sheets

- `Cotizaciones`: columna `G` = `alias` (ya agregada por el usuario).
- `Ventas_Pendientes`: agregar columna `M` = `alias`, después de `Estado`.
- Ambas quedan al final de sus hojas respectivas → escrituras posicionales
  existentes no se rompen si alias va vacío (el string vacío se escribe
  explícitamente en esa posición).

## Backend

### `backend/api/models.py`
- `VentaRequest.alias: Optional[str] = None`
- `CotizacionRequest.alias: Optional[str] = None`
- `VentaResponse.alias: Optional[str] = None`
- `CotizacionResponse.alias: Optional[str] = None`
- `ClientePrevioResponse.alias: Optional[str] = None`

### `backend/core/config.py`
- `COLUMNAS_VENTAS` agrega `"alias"` como último elemento. `COL_ESTADO_NUM`
  sigue calculándose por `.index("Estado")`, no se ve afectado por el orden
  (alias va después de Estado).

### `backend/repositories/sheets_repository.py`
- `save_quote(celular, items, total, alias=None)` — agrega
  `alias or ""` como 7ª columna de la fila.
- `register_complete_sale` — agrega `cliente.get("alias") or ""` como 13ª
  columna de cada fila de `filas`.
- `fetch_quotes` / `fetch_sales` no requieren cambios: `get_all_records()` lee
  por header, así que la columna `alias` aparece automática en el DataFrame
  una vez agregada en Sheets.

### `backend/api/routes/cotizaciones.py`
- `guardar_cotizacion`: pasa `body.alias` a `repo.save_quote(...)`.
- `_COLS_FIJAS` agrega `"alias"` para que `_serializar_cotizaciones` lo
  incluya en las respuestas de listado.
- `cotizaciones_por_cliente`: sin cambio de lógica, el campo llega solo al
  incluirse en `_COLS_FIJAS`.

### `backend/api/routes/ventas.py`
- `registrar_venta`: `cliente = body.model_dump(exclude={"items"})` ya
  incluye `alias` automáticamente (viene de `VentaRequest`).
- `ventas_por_cliente`: agrega `alias` al `ClientePrevioResponse` construido
  desde el último registro del historial (`ultimo.get("alias", "") or ""`),
  para autocompletar en Flutter.
- Listados (`listar_ventas`, `listar_pendientes`) usan `df_to_json_list` sin
  columnas fijas explícitas → alias aparece solo si está en el DataFrame, sin
  cambios de código.

## Flutter

### Modelos (`lib/models/venta.dart` o equivalente de cotización)
- `ClientePrevio.alias`, item/estado de venta y cotización: campo `alias`
  opcional (`String?`), default `null`/vacío.

### Providers
- `nueva_venta_provider.dart`:
  - `NuevaVentaState.alias` (`String`, default `''`).
  - `setAlias(String v)` en el notifier.
  - `_buscarCliente`: autocompleta `alias` desde `clientePrevio.alias` solo
    si el campo local está vacío (mismo patrón que `direccion`/`distrito`).
  - `registrarVenta()`: incluye `alias: state.alias` en el payload a
    `_repo.registrarVenta(...)`.
- Provider de cotización (`nueva_cotizacion_provider` o el que aplique):
  mismo patrón — estado, setter, autocompletar, envío en el guardado.

### Pantallas — campo de formulario
- `nueva_venta_screen.dart` y `nueva_cotizacion_screen.dart`: input opcional
  "Alias WhatsApp (opcional)" debajo del campo Celular, siempre visible.

### Envío WhatsApp — deep link
- `core/utils/whatsapp_launcher.dart`:
  - `abrirWhatsAppBusiness` gana parámetro opcional `alias`.
  - Si `alias != null && alias.trim().isNotEmpty` → `destino = alias` (sin
    prefijo `51`, sin filtrar solo-dígitos).
  - Si no, cae al comportamiento actual con `celular`.
- Los 4 call sites que hoy pasan `celular` (venta cliente, venta comunidad ya
  no pasa celular hoy — ver abajo, convertir cotización, pendientes) pasan
  también `alias` cuando esté disponible en su estado/modelo.

### Envío WhatsApp — texto del mensaje
- Nuevo helper `String lineaContacto(String celular, String? alias)` en
  `whatsapp_launcher.dart`:
  - Normaliza alias quitando un `@` inicial si el usuario lo tipeó (evita
    `@@alias`).
  - Retorna `"$celular (@$aliasNormalizado)"` si hay alias, si no `celular`
    solo.
- Se usa para reemplazar la línea `📱 *Celular:* $celular` en:
  - `nueva_venta_screen.dart:1568` (confirmación al cliente)
  - `nueva_venta_screen.dart:1611` (mensaje a comunidad)
  - `cotizacion_convertir_card.dart:728`
  - `pendientes_screen.dart:404`
- El mensaje de cotización al cliente (`nueva_cotizacion_screen.dart:1328-1333`)
  no incluye celular en el texto — sin cambio ahí, solo el deep-link target
  usa alias/celular según corresponda.

## Decisiones confirmadas con el usuario

1. **Prioridad de envío:** si hay alias guardado, siempre se usa para el
   deep-link (`wa.me/<alias>`). No se pregunta cada vez.
2. **Ubicación del campo:** input de alias siempre visible junto al celular
   en los formularios, no colapsado.
3. **Formato de mensaje:** cuando hay alias, la línea de contacto muestra
   celular y alias juntos — `📱 *Celular:* 987654321 (@alias)` — nunca solo
   uno de los dos si ambos existen.

## Testing

- Backend (pytest): `save_quote` y `register_complete_sale` con y sin alias;
  verificar que la columna queda vacía (no `None`/`null`) cuando no se manda.
- Flutter: build (`flutter analyze` + `flutter build apk --debug`) y smoke
  test manual de los 4 flujos de envío WhatsApp, con y sin alias guardado,
  confirmando que el deep-link abre el chat correcto y el texto del mensaje
  muestra el formato esperado.

## Riesgos / notas

- `append_rows` de gspread escribe solo hasta la última columna con valor en
  la lista pasada; como alias siempre se incluye explícitamente en la fila
  (aunque sea `""`), no hay riesgo de desalineación de columnas en escrituras
  futuras.
- Si WhatsApp deprecara o cambiara el formato `wa.me/<username>` en el futuro,
  el único punto de cambio es `whatsapp_launcher.dart`.

# Descuento 10% por item — Nueva Cotización (Paso 3)

## Contexto

En `nueva_cotizacion_screen.dart` (Paso 3 — Confirmar), el switch "Descuento 10%" aplica el descuento a TODOS los perfumes de la cesta o a NINGUNO — es un flag global (`NuevaCotizacionState.conDescuento: bool`). El usuario necesita aplicar el 10% solo a algunos perfumes de la cesta, no siempre a todos.

## 1. Modelo de datos (`nueva_cotizacion_provider.dart`)

- Reemplazar `final bool conDescuento` por `final Set<int> indicesConDescuento` (default `const {}`), donde cada `int` es el índice del item en `cesta` que tiene el 10% aplicado.
- `conDescuento` pasa a ser un getter calculado: `cesta.isNotEmpty && indicesConDescuento.length == cesta.length` — true solo cuando TODOS los items están seleccionados. Se usa para el estado visual del switch "seleccionar todos".
- Nuevo getter `algunDescuento => indicesConDescuento.isNotEmpty` — true si hay al menos un item con descuento (parcial o total). Controla si se muestra cualquier UI relacionada a descuento (precio tachado, línea de ahorro en el total).
- Nuevo método `bool itemConDescuento(int index) => indicesConDescuento.contains(index)`.
- `precioEfectivo(double precio)` se reemplaza por `double precioEfectivoIndex(int index, double precio) => itemConDescuento(index) ? _round10(precio * 0.90) : precio`.
- `subtotalDescuento` recorre `cesta.asMap().entries` y usa `precioEfectivoIndex(entry.key, entry.value.precio)` en vez de `precioEfectivo(item.precio)`.
- `ahorro` no cambia de fórmula (`subtotalOriginal - subtotalDescuento`), pero ahora refleja solo los items seleccionados.
- `copyWith` gana parámetro `Set<int>? indicesConDescuento` (reemplaza al de `bool? conDescuento`). Como `Set` es un tipo de referencia, pasar `{}` literal es válido y no colisiona con el patrón `??` existente — no se necesita flag de "clear" especial.

### Notifier

- `toggleDescuento()`: si `state.conDescuento` (todos ya seleccionados) → vacía el set (`{}`). Si no → selecciona todos los índices (`{for (var i = 0; i < state.cesta.length; i++) i}`).
- Nuevo `toggleItemDescuento(int index)`: agrega o quita `index` del set (copia mutable, no mutar el set existente in-place).
- `quitarItem(int index)` se actualiza para reindexar el set al remover un item: los índices mayores al removido bajan en 1, y el índice removido se descarta del set.
- `guardar()`: el payload que se envía al backend usa `state.precioEfectivoIndex(entry.key, entry.value.precio)` por item, igual que hoy pero indexado.

## 2. UI — Paso 3 (`nueva_cotizacion_screen.dart`)

- `_Paso3` pasa de `ConsumerWidget` a `ConsumerStatefulWidget` para sostener un bool local `_modoSeleccion` (puramente de UI, no se persiste en el provider — mismo patrón que `_cestaExpandida` en otras pantallas del proyecto).
- Botón "Elegir productos" (cuando `!_modoSeleccion`) / "Listo" (cuando `_modoSeleccion`) ubicado junto al switch "Descuento 10%". Tocarlo alterna `_modoSeleccion`.
- Mientras `_modoSeleccion == true`, cada fila de item en la lista de la cesta (sección "Perfumes cotizados") muestra un chip pequeño "10%" tappeable a un costado. Tocarlo llama a `notifier.toggleItemDescuento(index)`. El item seleccionado se resalta (borde/fondo, mismo lenguaje visual que las cards seleccionadas en Pendientes — `AppColors.primary` de borde, `AppColors.primaryPale` de fondo).
- La línea de precio "antes → después" por item (hoy condicionada a `state.conDescuento` global) pasa a condicionarse a `state.itemConDescuento(index)` — se muestra independientemente de si los demás items tienen descuento o no.
- El switch "Descuento 10%" se mantiene como shortcut "seleccionar todos": `value: state.conDescuento`, `onChanged: (_) => notifier.toggleDescuento()`. Su subtítulo usa `state.algunDescuento` para decidir si mostrar "ahorras S/ X" o el texto por defecto.
- La caja de "Total" al final (`SUBTOTAL` tachado + línea `DESCUENTO -10%`) cambia su condición de `state.conDescuento` a `state.algunDescuento`, para que se muestre apenas haya algún item con descuento, no solo cuando todos lo tienen.

## 3. Ticket de WhatsApp (`_TicketExito`)

- El parámetro `required bool conDescuento` se reemplaza por `required Set<int> indicesConDescuento`.
- En `_abrirWhatsApp()`, el cálculo por item (`precioDesc`, `precioLine`) usa `indicesConDescuento.contains(idx)` en vez de `widget.conDescuento` para decidir si ese perfume específico se muestra con precio tachado/descuento en el mensaje.
- La línea de resumen `descuentoLine` ("🎉 Descuento 10%...") se muestra si `indicesConDescuento.isNotEmpty` en vez de `widget.conDescuento`.
- En el `build()` de la screen que construye `_TicketExito` (línea ~88), se pasa `indicesConDescuento: state.indicesConDescuento` en vez de `conDescuento: state.conDescuento`.

## Fuera de scope

- No se modifica el modelo `ItemCesta` compartido (usado también por Ventas) — el set de índices vive solo en `NuevaCotizacionState`, específico de este flujo de cotizaciones.
- No se modifica el backend/Sheets — el payload de items ya se envía con el precio final por item; ahora simplemente puede haber una mezcla de precios con/sin descuento dentro de la misma cotización, lo cual el backend ya soporta (no hay validación de "todos al mismo precio").
- No se agrega un resumen tipo "3 de 5 productos con descuento" — el precio tachado por item ya comunica cuáles tienen descuento.

## Testing

- Provider: `toggleDescuento()` selecciona/limpia todos los índices según estado actual; `toggleItemDescuento()` agrega/quita un índice individual; `quitarItem()` reindexa el set correctamente (caso: descuento en item 2, se borra item 0 → el descuento debe quedar en item 1 tras el shift); `subtotalDescuento`/`ahorro` calculan correctamente con selección parcial.
- UI: entrar a modo selección y tocar un item activa su descuento y lo resalta; el switch "seleccionar todos" refleja correctamente cuando hay selección parcial (debe verse OFF, no en estado intermedio) vs todos seleccionados (ON); la caja de total muestra el desglose de descuento con selección parcial.

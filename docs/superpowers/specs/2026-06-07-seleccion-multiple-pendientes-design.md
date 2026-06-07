# Selección múltiple en Pendientes

**Fecha:** 2026-06-07
**Feature:** Marcar múltiples pedidos como entregados desde la pantalla de Pendientes

---

## Problema

Actualmente cada pedido pendiente se marca como entregado de forma individual. Con varios pedidos del mismo día, el flujo es lento.

## Solución

Modo de selección múltiple activado por long-press. AppBar contextual con botón "Entregar (N)". Ejecución en paralelo.

---

## Archivo afectado

`perfuteca_flutter/lib/features/ventas/screens/pendientes_screen.dart`

---

## Cambios de estado

`PendientesScreen` pasa de `ConsumerWidget` a `ConsumerStatefulWidget`:

```dart
Set<String> _seleccionados = {};
bool get _modoSeleccion => _seleccionados.isNotEmpty;
```

---

## Comportamiento

### Activar modo selección
- Long-press en cualquier `_OrdenCard` → agrega `idCompra` a `_seleccionados`
- Card seleccionada muestra: fondo `primaryPale`, borde `primary`, checkbox `Icons.check_circle_rounded` en esquina superior derecha

### En modo selección
- Tap en card → toggle (agregar/quitar de `_seleccionados`)
- Long-press adicional → ignorado

### AppBar contextual (cuando `_modoSeleccion == true`)
```
[✕ Cancelar]   "N seleccionados"   [Entregar (N)]
```
- `✕` → limpia `_seleccionados`, vuelve al AppBar normal
- `Entregar (N)` → ejecuta entrega masiva

### Ejecución de entrega masiva
1. Agrega todos los `idCompra` seleccionados a `_pendientesRemovidosProvider` (remoción optimista inmediata)
2. `Future.wait(seleccionados.map(...)` — llama `estadoVentaProvider.notifier.actualizar()` para cada orden en paralelo
3. Limpia `_seleccionados`
4. `ScaffoldMessenger.showSnackBar("N pedidos marcados como entregados")`
5. Si falla alguna: SnackBar de error, las órdenes fallidas vuelven a aparecer (revalida `pendientesProvider`)

---

## Componentes modificados

### `PendientesScreen` → `ConsumerStatefulWidget`
- Agrega estado `_seleccionados`
- Lógica `_marcarEntregados()` async
- Construye AppBar normal o contextual según `_modoSeleccion`

### `_OrdenCard`
- Recibe parámetros: `bool seleccionado`, `bool modoSeleccion`, `VoidCallback onLongPress`, `VoidCallback? onTap`
- Overlay visual cuando `seleccionado == true`

---

## Criterios de éxito

- Long-press activa modo selección y selecciona esa card
- Tap en modo selección toggle la card correctamente
- AppBar contextual muestra contador correcto
- Todas las órdenes seleccionadas se marcan en paralelo
- Remoción optimista inmediata (no espera respuesta API)
- SnackBar de confirmación tras éxito
- Cancelar limpia selección completamente

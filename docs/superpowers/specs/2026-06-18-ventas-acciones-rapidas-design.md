# Acciones rápidas — Tab Ventas (Pendientes + Cotizaciones)

## Contexto

Tab Ventas (Hoy / Cotización / Pendientes) es el más usado de la app. De 4 direcciones de mejora exploradas (dashboard de métricas, navegación entre sub-tabs, jerarquía visual de cards, acciones rápidas), se priorizó **acciones rápidas**: reducir taps en los dos flujos repetitivos diarios — marcar pedidos entregados y convertir cotizaciones a venta.

## 1. Pendientes — swipe actions

**Hoy:** cada `_OrdenCard` (`pendientes_screen.dart`) muestra dos botones full-width fijos al pie ("Anular" outline + "Marcar entregado" filled), siempre visibles salvo en modo selección múltiple.

**Cambio:** envolver `_OrdenCard` en un widget swipeable (`Dismissible` o paquete `flutter_slidable`):
- Swipe derecha → fondo verde, acción "Entregar". Dispara el mismo diálogo de confirmación que existe hoy (`_confirmarEntregado`).
- Swipe izquierda → fondo rojo, acción "Anular". Dispara `_confirmarAnular` existente.
- Quitar los botones full-width del cuerpo de la card — la card se acorta.
- El swipe solo está activo cuando `modoSeleccion == false`. En modo selección (long-press), el gesto de swipe se desactiva para no chocar con el tap de selección.
- La lógica de estado (`_cambiarEstado`, optimistic update, `_pendientesRemovidosProvider`) no cambia — solo cambia el trigger visual.
- Si se usa `Dismissible`, `confirmDismiss` debe esperar el resultado del diálogo y devolver `false` si se cancela (para que la card vuelva a su lugar en vez de desaparecer).

## 2. Cotizaciones — quick convert 1-tap

**Hoy:** al expandir una `_CotizacionCard` (`cotizaciones_hoy_screen.dart`), `_cargarDatosCliente()` busca el cliente por celular. Si lo encuentra, precarga nombre/dirección/distrito/tipoEnvio/metodoPago — pero el usuario igual ve el formulario completo y debe tocar "Revisar pedido" antes de llegar a `_ConfirmacionInline`.

**Cambio:** si tras `_cargarDatosCliente()` el cliente existe y los 3 campos requeridos por `_checkForm()` están completos (`comprador`, `direccion`, `tipoEnvio` no vacíos) y `_clienteNuevo == false`, saltar directo a `_confirmando = true` (mostrar `_ConfirmacionInline`) en vez de mostrar el form de edición primero.
- Si falta cualquier dato (cliente nuevo o incompleto), comportamiento actual sin cambios: muestra form primero.
- El botón "Editar" en `_ConfirmacionInline` ya existe y permite volver al form (`onEditar: () => setState(() => _confirmando = false)`) — sigue funcionando igual, da salida si el usuario quiere ajustar algo antes de confirmar.
- No se toca la lógica de `_registrar()` ni las invalidaciones de providers.

## Fuera de scope

- Dashboard de métricas globales arriba de los sub-tabs.
- Mejoras de navegación entre sub-tabs (badges, contadores).
- Jerarquía visual / densidad de las cards (más allá de acortar la card de Pendientes por quitar botones).
- Batch-convert de múltiples cotizaciones a la vez.

## Testing

- Pendientes: swipe en ambas direcciones dispara diálogo correcto; cancelar diálogo no remueve la card; confirmar sí actualiza estado (igual que hoy); swipe deshabilitado en modo selección.
- Cotizaciones: cliente con datos completos → salta a confirmación directo; cliente nuevo o incompleto → muestra form; "Editar" desde confirmación regresa al form con datos intactos.

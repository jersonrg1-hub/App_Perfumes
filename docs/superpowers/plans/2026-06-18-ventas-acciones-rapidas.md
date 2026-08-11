# Acciones Rápidas — Tab Ventas Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reducir taps en los dos flujos diarios más usados del tab Ventas — marcar pedidos pendientes como entregados/anulados via swipe, y saltar el formulario al convertir una cotización a venta cuando el cliente ya tiene todos los datos completos.

**Architecture:** Dos cambios independientes y aislados, cada uno en su propio archivo de screen. Pendientes: envolver la card existente en `Dismissible` (sin dependencias nuevas) y quitar los botones full-width de Anular/Entregar. Cotizaciones: extraer una función pura `clienteListoParaConfirmar` y usarla para decidir si saltar directo a la vista de confirmación.

**Tech Stack:** Flutter, Riverpod, flutter_test (sin paquetes nuevos).

---

### Task 1: Swipe actions en Pendientes

**Files:**
- Modify: `perfuteca_flutter/lib/features/ventas/screens/pendientes_screen.dart:326-753` (clase `_OrdenCardState`)
- Test: `perfuteca_flutter/test/pendientes_swipe_test.dart` (crear)

- [ ] **Step 1: Escribir el test que falla**

Crear `perfuteca_flutter/test/pendientes_swipe_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/features/ventas/providers/ventas_provider.dart';
import 'package:perfuteca/features/ventas/screens/pendientes_screen.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/models/venta.dart';

VentaResponse _ventaDePrueba() => const VentaResponse(
      idCompra: 'V001',
      filaSheet: 2,
      fecha: '2026-06-18',
      comprador: 'María G.',
      celular: '987654321',
      idPerfume: '1',
      mlVendido: 5,
      precioCobrado: 45.0,
      metodoPago: 'Yape',
      tipoEnvio: 'Shalom',
      direccion: 'Jr. Test 123',
      distrito: 'Lima',
      estado: 'Pendiente',
    );

Widget _app() => ProviderScope(
      overrides: [
        pendientesProvider.overrideWith((ref) async => [_ventaDePrueba()]),
        perfumesMapProvider.overrideWith((ref) async => <String, Perfume>{}),
      ],
      child: const MaterialApp(home: Scaffold(body: PendientesScreen())),
    );

void main() {
  testWidgets('swipe derecha muestra dialogo de confirmar entrega, cancelar mantiene la card',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('#V001'), findsOneWidget);

    await tester.drag(find.text('#V001'), const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(find.text('Confirmar entrega'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('#V001'), findsOneWidget);
  });

  testWidgets('en modo seleccion (long press) el swipe no dispara dialogo', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.longPress(find.text('#V001'));
    await tester.pumpAndSettle();

    await tester.drag(find.text('#V001'), const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(find.text('Confirmar entrega'), findsNothing);
  });
}
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `cd perfuteca_flutter && flutter test test/pendientes_swipe_test.dart`
Expected: FAIL — el primer test no encuentra el texto "Confirmar entrega" porque hoy el swipe no dispara ninguna acción (las cards no son `Dismissible`).

- [ ] **Step 3: Implementar el swipe**

En `pendientes_screen.dart`, reemplazar el método `build` de `_OrdenCardState` (líneas 457-753) por:

```dart
  @override
  Widget build(BuildContext context) {
    final orden = widget.orden;

    final content = GestureDetector(
      onLongPress: widget.onLongPress,
      onTap: widget.modoSeleccion ? widget.onTapSeleccion : null,
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: widget.seleccionado
                  ? AppColors.primaryPale
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: widget.seleccionado
                    ? AppColors.primary
                    : AppColors.primaryLight,
                width: widget.seleccionado ? 2 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: 4,
                    offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryPale,
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.radiusMd)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '#${orden.idCompra}',
                                  style: AppTextStyles.priceLabel.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${orden.items.length} ítem${orden.items.length != 1 ? 's' : ''}',
                                    style: AppTextStyles.priceLabel.copyWith(
                                        color: AppColors.primaryDark),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              orden.comprador ?? '—',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (orden.celular != null)
                              Text(orden.celular!,
                                  style: AppTextStyles.bodySmall),
                            if (orden.fecha != null) ...[
                              const SizedBox(height: 3),
                              _FechaAgeBadge(fecha: orden.fecha!),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        'S/ ${orden.total.toStringAsFixed(2)}',
                        style: AppTextStyles.price.copyWith(
                          fontSize: 20,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Lista de ítems ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                  child: Column(
                    children: orden.items.map((item) {
                      final normId = item.idPerfume != null
                          ? (double.tryParse(item.idPerfume!)?.toInt().toString()
                              ?? item.idPerfume!)
                          : null;
                      final perfume = normId != null
                          ? widget.perfumesMap[normId]
                          : null;
                      final nombre = perfume != null
                          ? '${perfume.nombre} (${perfume.marca})'
                          : (item.idPerfume != null
                              ? 'Perfume #${item.idPerfume}'
                              : '—');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 6, height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                '$nombre  ·  ${item.mlVendido ?? '?'} ml',
                                style: AppTextStyles.body.copyWith(
                                    color: AppColors.textSecondary),
                              ),
                            ),
                            Text(
                              'S/ ${(item.precioCobrado ?? 0).toStringAsFixed(2)}',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Divider(height: AppSpacing.md),
                ),

                // ── Info logística ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _InfoChip(
                            icon: Icons.local_shipping_outlined,
                            label: orden.tipoEnvio ?? '—',
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _InfoChip(
                            icon: Icons.payment_outlined,
                            label: orden.metodoPago ?? '—',
                            color: AppColors.goldLight,
                            textColor: AppColors.gold,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs + 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              orden.direccion ?? '—',
                              style: AppTextStyles.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (orden.distrito?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            const Icon(Icons.map_outlined,
                                size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                orden.distrito!,
                                style: AppTextStyles.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Enviar a comunidad (las acciones de entregar/anular pasan a swipe) ──
                if (!widget.modoSeleccion)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _enviarComunidad,
                        icon: const Icon(Icons.groups_rounded, size: 16),
                        label: const Text('Enviar pedido a comunidad'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.whatsappDark,
                          side: const BorderSide(
                              color: AppColors.whatsappDark),
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Checkbox de selección
          if (widget.seleccionado)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.modoSeleccion) return content;

    return Dismissible(
      key: ValueKey('pendiente-${orden.idCompra}'),
      background: const _SwipeBackground(
        color: AppColors.success,
        icon: Icons.check_circle_outline_rounded,
        label: 'Entregar',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: const _SwipeBackground(
        color: AppColors.error,
        icon: Icons.cancel_outlined,
        label: 'Anular',
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _confirmarEntregado();
        } else {
          await _confirmarAnular();
        }
        return false;
      },
      child: content,
    );
  }
```

Agregar la clase `_SwipeBackground` justo después del cierre de `_OrdenCardState` (antes de `class _InfoChip`):

```dart
// ── Fondo revelado al hacer swipe ─────────────────────────────────────────────

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignment,
  });
  final Color     color;
  final IconData  icon;
  final String    label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
```

- [ ] **Step 4: Correr el test y verificar que pasa**

Run: `cd perfuteca_flutter && flutter test test/pendientes_swipe_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add perfuteca_flutter/lib/features/ventas/screens/pendientes_screen.dart perfuteca_flutter/test/pendientes_swipe_test.dart
git commit -m "feat: swipe para entregar/anular en pendientes, quita botones full-width"
```

---

### Task 2: Quick-convert 1-tap en Cotizaciones

**Files:**
- Modify: `perfuteca_flutter/lib/features/ventas/screens/cotizaciones_hoy_screen.dart:287-325` (método `_cargarDatosCliente`)
- Test: `perfuteca_flutter/test/cotizaciones_quick_convert_test.dart` (crear)

- [ ] **Step 1: Escribir el test que falla**

Crear `perfuteca_flutter/test/cotizaciones_quick_convert_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:perfuteca/features/ventas/screens/cotizaciones_hoy_screen.dart';

void main() {
  group('clienteListoParaConfirmar', () {
    test('true cuando comprador, direccion y tipoEnvio estan completos', () {
      expect(
        clienteListoParaConfirmar(
          comprador: 'María G.',
          direccion: 'Jr. Test 123',
          tipoEnvio: 'Shalom',
        ),
        isTrue,
      );
    });

    test('false cuando falta direccion (solo espacios)', () {
      expect(
        clienteListoParaConfirmar(
          comprador: 'María G.',
          direccion: '   ',
          tipoEnvio: 'Shalom',
        ),
        isFalse,
      );
    });

    test('false cuando falta tipoEnvio', () {
      expect(
        clienteListoParaConfirmar(
          comprador: 'María G.',
          direccion: 'Jr. Test 123',
          tipoEnvio: '',
        ),
        isFalse,
      );
    });

    test('false cuando falta comprador', () {
      expect(
        clienteListoParaConfirmar(
          comprador: '',
          direccion: 'Jr. Test 123',
          tipoEnvio: 'Shalom',
        ),
        isFalse,
      );
    });
  });
}
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `cd perfuteca_flutter && flutter test test/cotizaciones_quick_convert_test.dart`
Expected: FAIL — error de compilación, `clienteListoParaConfirmar` no existe todavía en `cotizaciones_hoy_screen.dart`.

- [ ] **Step 3: Implementar la función y usarla**

En `cotizaciones_hoy_screen.dart`, agregar esta función de nivel superior justo antes de `class CotizacionesHoyScreen` (línea 35):

```dart
// ── Decide si se puede saltar el formulario e ir directo a confirmar ──────────

bool clienteListoParaConfirmar({
  required String comprador,
  required String direccion,
  required String tipoEnvio,
}) {
  return comprador.trim().isNotEmpty &&
      direccion.trim().isNotEmpty &&
      tipoEnvio.isNotEmpty;
}
```

Reemplazar el método `_cargarDatosCliente` (líneas 287-325) por:

```dart
  Future<void> _cargarDatosCliente() async {
    final celular = widget.cotizacion.celular;
    if (celular.isEmpty) return;
    setState(() { _buscandoCliente = true; _clienteNuevo = false; });
    try {
      final cliente =
          await ref.read(ventasRepositoryProvider).getClientePrevio(celular);
      if (cliente != null && mounted) {
        setState(() {
          if (_compradorCtrl.text.trim().isEmpty) {
            _compradorCtrl.text = cliente.comprador;
          }
          if (_direccionCtrl.text.trim().isEmpty) {
            _direccionCtrl.text = cliente.direccion;
          }
          if (_distritoCtrl.text.trim().isEmpty && cliente.distrito.isNotEmpty) {
            _distritoCtrl.text = cliente.distrito;
          }
          if (_tipoEnvio.isEmpty) _tipoEnvio = cliente.tipoEnvio;
          _metodoPago = cliente.metodoPago;
          // Cliente conocido + datos completos → salta el form, va directo a confirmar
          if (clienteListoParaConfirmar(
            comprador: _compradorCtrl.text,
            direccion: _direccionCtrl.text,
            tipoEnvio: _tipoEnvio,
          )) {
            _confirmando = true;
          }
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_botonKey.currentContext != null) {
            Scrollable.ensureVisible(
              _botonKey.currentContext!,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
            );
          }
        });
      } else if (mounted) {
        setState(() => _clienteNuevo = true);
      }
    } catch (_) {
      // Silencioso — el usuario puede llenar manualmente
    } finally {
      if (mounted) setState(() => _buscandoCliente = false);
    }
  }
```

- [ ] **Step 4: Correr el test y verificar que pasa**

Run: `cd perfuteca_flutter && flutter test test/cotizaciones_quick_convert_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add perfuteca_flutter/lib/features/ventas/screens/cotizaciones_hoy_screen.dart perfuteca_flutter/test/cotizaciones_quick_convert_test.dart
git commit -m "feat: saltar form de cotizacion a venta cuando cliente ya tiene datos completos"
```

---

### Task 3: Verificación manual en la app

**Files:** ninguno (solo verificación, sin cambios de código)

- [ ] **Step 1: Correr la suite completa**

Run: `cd perfuteca_flutter && flutter test`
Expected: todos los tests pasan, incluyendo los nuevos de Task 1 y Task 2 y el `test/widget_test.dart` existente.

- [ ] **Step 2: Levantar la app y probar Pendientes**

Run: `cd perfuteca_flutter && flutter run` (elegir un dispositivo/emulador conectado)

En la app: ir a Ventas → Pendientes. Verificar:
- Las cards ya no muestran los botones "Anular"/"Marcar entregado" al pie.
- Swipe a la derecha sobre una card revela fondo verde "Entregar" y al soltar abre el diálogo de confirmación existente.
- Swipe a la izquierda revela fondo rojo "Anular" y abre su diálogo.
- Confirmar el diálogo sí actualiza el estado (la orden desaparece de la lista, igual que antes).
- Long-press para entrar en modo selección múltiple sigue funcionando y el swipe queda desactivado mientras se está en ese modo.

- [ ] **Step 3: Probar Cotizaciones**

En la app: ir a Ventas → Cotización (sub-tab "Hoy"). Registrar primero una venta de prueba con un celular conocido (para que quede como cliente con datos completos), luego crear una cotización nueva con ese mismo celular.

Verificar:
- Al tocar la cotización de un cliente con datos completos (nombre + dirección + tipo de envío ya guardados), la card salta directo a la vista de confirmación (sin mostrar el formulario de "Completa los datos").
- El botón "Editar" en la confirmación regresa al formulario con los datos ya cargados, sin perder nada.
- Al tocar una cotización de un cliente nuevo (celular sin historial), se sigue mostrando el formulario primero, como antes.

- [ ] **Step 4: Confirmar y cerrar**

Si todo lo anterior se ve correcto, no se necesita ningún commit adicional — este task es solo de verificación.

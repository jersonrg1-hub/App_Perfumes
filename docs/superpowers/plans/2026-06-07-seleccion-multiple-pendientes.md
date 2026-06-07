# Selección múltiple en Pendientes — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permitir long-press en una orden pendiente para entrar en modo selección múltiple y marcar varias órdenes como entregadas en paralelo con una barra flotante inferior.

**Architecture:** `PendientesScreen` pasa de `ConsumerWidget` a `ConsumerStatefulWidget` con `Set<String> _seleccionados`. Cuando hay selección, un `Stack` muestra `_BarraSeleccion` (barra flotante inferior) sobre la lista. `_OrdenCard` y `_ListaOrdenes` reciben props de selección para mostrar overlay visual. Nota: la pantalla vive en `TabBarView` de `VentasScreen` sin Scaffold propio — se usa barra flotante en lugar de AppBar contextual.

**Tech Stack:** Flutter, Riverpod, Material 3, archivo único `pendientes_screen.dart`

---

## File Map

| File | Action |
|------|--------|
| `perfuteca_flutter/lib/features/ventas/screens/pendientes_screen.dart` | Modify — todos los cambios en un solo archivo |

---

### Task 1: Agregar `_BarraSeleccion` widget

**Files:**
- Modify: `perfuteca_flutter/lib/features/ventas/screens/pendientes_screen.dart`

- [ ] **Step 1: Agregar `_BarraSeleccion` al final del archivo** (antes de `_PendientesShimmer`)

Insertar después de `_ErrorView` y antes de `_AnimatedListItem`:

```dart
// ── Barra flotante de selección múltiple ──────────────────────────────────────

class _BarraSeleccion extends StatelessWidget {
  const _BarraSeleccion({
    required this.count,
    required this.onEntregar,
    required this.onCancelar,
  });
  final int          count;
  final VoidCallback onEntregar;
  final VoidCallback onCancelar;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      border: Border.all(color: AppColors.primaryLight),
      boxShadow: const [
        BoxShadow(
          color: AppColors.shadowColor,
          blurRadius: 12,
          offset: Offset(0, -2),
        ),
      ],
    ),
    child: Row(
      children: [
        IconButton(
          onPressed: onCancelar,
          icon: const Icon(Icons.close_rounded),
          color: AppColors.textMuted,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            '$count seleccionado${count != 1 ? "s" : ""}',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: onEntregar,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.success,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          ),
          icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
          label: Text('Entregar ($count)'),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 2: Verificar que compila**

```
flutter analyze lib/features/ventas/screens/pendientes_screen.dart
```
Esperado: sin errores nuevos.

---

### Task 2: Actualizar `_OrdenCard` para aceptar props de selección

**Files:**
- Modify: `perfuteca_flutter/lib/features/ventas/screens/pendientes_screen.dart`

- [ ] **Step 1: Agregar params a `_OrdenCard`**

Reemplazar la declaración de `_OrdenCard`:

```dart
class _OrdenCard extends ConsumerStatefulWidget {
  const _OrdenCard({
    required this.orden,
    required this.perfumesMap,
    required this.seleccionado,
    required this.modoSeleccion,
    required this.onLongPress,
    required this.onTapSeleccion,
  });
  final _Orden               orden;
  final Map<String, Perfume> perfumesMap;
  final bool                 seleccionado;
  final bool                 modoSeleccion;
  final VoidCallback         onLongPress;
  final VoidCallback         onTapSeleccion;

  @override
  ConsumerState<_OrdenCard> createState() => _OrdenCardState();
}
```

- [ ] **Step 2: Modificar `_OrdenCard.build()` para visual de selección**

Reemplazar el `return Container(...)` en `build()` por:

```dart
@override
Widget build(BuildContext context) {
  final orden = widget.orden;

  return GestureDetector(
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

              // ── Acciones (ocultas en modo selección) ──────────
              if (!widget.modoSeleccion)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      SizedBox(
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
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _confirmarAnular,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.md),
                            ),
                            icon: const Icon(Icons.cancel_outlined, size: 16),
                            label: const Text('Anular'),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _confirmarEntregado,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.success,
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.md),
                              ),
                              icon: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 16),
                              label: const Text('Marcar entregado'),
                            ),
                          ),
                        ],
                      ),
                    ],
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
}
```

- [ ] **Step 3: Verificar que compila**

```
flutter analyze lib/features/ventas/screens/pendientes_screen.dart
```
Esperado: sin errores nuevos.

---

### Task 3: Actualizar `_ListaOrdenes` para pasar props de selección

**Files:**
- Modify: `perfuteca_flutter/lib/features/ventas/screens/pendientes_screen.dart`

- [ ] **Step 1: Agregar campos a `_ListaOrdenes`**

Reemplazar la clase `_ListaOrdenes`:

```dart
class _ListaOrdenes extends StatelessWidget {
  const _ListaOrdenes({
    required this.ordenes,
    required this.perfumesMap,
    required this.onRefresh,
    required this.seleccionados,
    required this.onLongPress,
    required this.onToggle,
  });
  final List<_Orden>            ordenes;
  final Map<String, Perfume>    perfumesMap;
  final Future<void> Function() onRefresh;
  final Set<String>             seleccionados;
  final void Function(String)   onLongPress;
  final void Function(String)   onToggle;

  @override
  Widget build(BuildContext context) {
    final totalPendiente = ordenes.fold(0.0, (s, o) => s + o.total);

    return Column(
      children: [
        _ResumenBanner(cantidad: ordenes.length, total: totalPendiente),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              itemCount: ordenes.length,
              itemBuilder: (_, i) => _AnimatedListItem(
                index: i,
                child: _OrdenCard(
                  orden:           ordenes[i],
                  perfumesMap:     perfumesMap,
                  seleccionado:    seleccionados.contains(ordenes[i].idCompra),
                  modoSeleccion:   seleccionados.isNotEmpty,
                  onLongPress:     () => onLongPress(ordenes[i].idCompra),
                  onTapSeleccion:  () => onToggle(ordenes[i].idCompra),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verificar que compila**

```
flutter analyze lib/features/ventas/screens/pendientes_screen.dart
```
Esperado: error en `PendientesScreen` porque `_ListaOrdenes` ahora requiere nuevos parámetros. Se resuelve en Task 4.

---

### Task 4: Convertir `PendientesScreen` a `ConsumerStatefulWidget`

**Files:**
- Modify: `perfuteca_flutter/lib/features/ventas/screens/pendientes_screen.dart`

- [ ] **Step 1: Reemplazar `PendientesScreen`**

Reemplazar desde `class PendientesScreen extends ConsumerWidget` hasta el cierre de la clase:

```dart
class PendientesScreen extends ConsumerStatefulWidget {
  const PendientesScreen({super.key});

  @override
  ConsumerState<PendientesScreen> createState() => _PendientesScreenState();
}

class _PendientesScreenState extends ConsumerState<PendientesScreen> {
  Set<String>  _seleccionados   = {};
  List<_Orden> _ordenesActuales = [];

  bool get _modoSeleccion => _seleccionados.isNotEmpty;

  void _iniciarSeleccion(String idCompra) {
    setState(() => _seleccionados = {idCompra});
  }

  void _toggleSeleccion(String idCompra) {
    setState(() {
      if (_seleccionados.contains(idCompra)) {
        _seleccionados = Set.from(_seleccionados)..remove(idCompra);
      } else {
        _seleccionados = {..._seleccionados, idCompra};
      }
    });
  }

  void _cancelarSeleccion() {
    setState(() => _seleccionados = {});
  }

  Future<void> _marcarSeleccionadosEntregados() async {
    final seleccionados = Set<String>.from(_seleccionados);
    final ordenes = _ordenesActuales
        .where((o) => seleccionados.contains(o.idCompra))
        .toList();

    _cancelarSeleccion();

    // Optimista: ocultar inmediatamente
    ref
        .read(_pendientesRemovidosProvider.notifier)
        .update((s) => {...s, ...seleccionados});

    // Ejecutar en paralelo
    await Future.wait(
      ordenes.map(
        (orden) => ref.read(estadoVentaProvider.notifier).actualizar(
              idVenta:     orden.idCompra,
              nuevoEstado: 'Entregado',
              filasSheet:  orden.filas,
            ),
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${seleccionados.length} pedido${seleccionados.length != 1 ? "s" : ""} '
            'marcado${seleccionados.length != 1 ? "s" : ""} como entregado${seleccionados.length != 1 ? "s" : ""}',
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async       = ref.watch(pendientesProvider);
    final perfumesMap = ref.watch(perfumesMapProvider).valueOrNull ?? {};
    final removidos   = ref.watch(_pendientesRemovidosProvider);

    return async.when(
      loading: () => const _PendientesShimmer(),
      error: (e, _) => _ErrorView(
        mensaje: e.toString(),
        onRetry: () {
          ref.read(_pendientesRemovidosProvider.notifier).state = const {};
          ref.invalidate(pendientesProvider);
        },
      ),
      data: (ventas) {
        Future<void> onRefresh() async {
          ref.read(_pendientesRemovidosProvider.notifier).state = const {};
          ref.invalidate(pendientesProvider);
          await ref.read(pendientesProvider.future);
        }

        final ordenes = _agrupar(ventas)
            .where((o) => !removidos.contains(o.idCompra))
            .toList();

        _ordenesActuales = ordenes;

        if (ordenes.isEmpty) {
          return RefreshIndicator(
              onRefresh: onRefresh, child: const _EmptyView());
        }

        return Stack(
          children: [
            _ListaOrdenes(
              ordenes:      ordenes,
              perfumesMap:  perfumesMap,
              onRefresh:    onRefresh,
              seleccionados: _seleccionados,
              onLongPress:  _iniciarSeleccion,
              onToggle:     _toggleSeleccion,
            ),
            if (_modoSeleccion)
              Positioned(
                bottom: AppSpacing.lg,
                left:   AppSpacing.lg,
                right:  AppSpacing.lg,
                child: _BarraSeleccion(
                  count:      _seleccionados.length,
                  onEntregar: _marcarSeleccionadosEntregados,
                  onCancelar: _cancelarSeleccion,
                ),
              ),
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 2: Verificar que compila sin errores**

```
flutter analyze lib/features/ventas/screens/pendientes_screen.dart
```
Esperado: 0 errores, 0 warnings.

- [ ] **Step 3: Correr la app y probar manualmente**

```powershell
.\run.ps1
```

Verificar:
1. Long-press en una orden → card se colorea de primaryPale con borde primary y ✓ verde
2. Tap en otra card → se selecciona también
3. Tap en card seleccionada → se deselecciona
4. Barra inferior aparece con count correcto y botón "Entregar (N)"
5. Botones "Marcar entregado" / "Anular" desaparecen en modo selección
6. Botón "Entregar (N)" marca todas como entregadas (desaparecen) + SnackBar verde
7. Botón ✕ cancela selección sin efectos
8. Long-press + entregar 1 orden → funciona igual que antes (no regresión)

- [ ] **Step 4: Commit**

```bash
git add perfuteca_flutter/lib/features/ventas/screens/pendientes_screen.dart
git commit -m "feat(flutter): selección múltiple en pendientes con barra flotante

- Long-press activa modo selección, tap togglea cards
- Barra flotante inferior muestra count + botón Entregar (N)
- Acciones individuales se ocultan en modo selección
- Entrega en paralelo con Future.wait + remoción optimista
- SnackBar de confirmación con conteo

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

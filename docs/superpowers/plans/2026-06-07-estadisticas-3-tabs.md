# Estadísticas 3 Tabs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reducir la pantalla de Estadísticas de 6 tabs a 3 (Resumen / Histórico / Más), donde "Más" es un menú de lista que navega internamente a Ventas, Clientes, Stock y Cotizaciones.

**Architecture:** `estadisticas_screen.dart` cambia `TabController(length: 6)` → `length: 3` y agrega `_MasTab` (un `ConsumerStatefulWidget` con estado `String? _seccion` que alterna entre menú y pantalla detalle). `resumen_tab.dart` agrega una fila compacta de métricas de hoy al inicio del ListView.

**Tech Stack:** Flutter, Riverpod, Material 3 — un solo archivo principal modificado, un archivo secundario.

---

## File Map

| File | Action |
|------|--------|
| `perfuteca_flutter/lib/features/estadisticas/screens/estadisticas_screen.dart` | Modify — cambiar length, tabs, TabBarView children; agregar `_MasTab` y `_MenuMas` |
| `perfuteca_flutter/lib/features/estadisticas/screens/resumen_tab.dart` | Modify — agregar `_HoyStrip` al inicio de `_ResumenBody` |

---

### Task 1: Reducir a 3 tabs y agregar `_MasTab`

**Files:**
- Modify: `perfuteca_flutter/lib/features/estadisticas/screens/estadisticas_screen.dart`

- [ ] **Step 1: Cambiar `TabController(length: 6)` → `length: 3`**

En `initState()`, reemplazar:
```dart
_tab = TabController(length: 6, vsync: this);
```
por:
```dart
_tab = TabController(length: 3, vsync: this);
```

- [ ] **Step 2: Reemplazar los 6 tabs del `TabBar` por 3**

Reemplazar el bloque `tabs: const [...]` completo:
```dart
tabs: const [
  Tab(
    icon: Icon(Icons.dashboard_rounded, size: 18),
    text: 'Resumen',
    iconMargin: EdgeInsets.only(bottom: 2),
  ),
  Tab(
    icon: Icon(Icons.history_rounded, size: 18),
    text: 'Histórico',
    iconMargin: EdgeInsets.only(bottom: 2),
  ),
  Tab(
    icon: Icon(Icons.more_horiz_rounded, size: 18),
    text: 'Más',
    iconMargin: EdgeInsets.only(bottom: 2),
  ),
],
```

- [ ] **Step 3: Reemplazar los 6 children del `TabBarView` por 3**

Reemplazar el bloque `children: const [...]`:
```dart
children: const [
  ResumenTab(),
  HistoricoTab(),
  _MasTab(),
],
```

- [ ] **Step 4: Agregar `_MasTab` y `_MenuMas` al final del archivo**

Insertar antes del cierre del archivo (después de la última clase):

```dart
// ── Tab "Más" — menú de navegación interna ─────────────────────────────────────

class _MasTab extends ConsumerStatefulWidget {
  const _MasTab({super.key});

  @override
  ConsumerState<_MasTab> createState() => _MasTabState();
}

class _MasTabState extends ConsumerState<_MasTab> {
  String? _seccion;

  String _titulo(String seccion) => switch (seccion) {
    'ventas'       => 'Ventas',
    'clientes'     => 'Clientes',
    'stock'        => 'Stock',
    'cotizaciones' => 'Cotizaciones',
    _              => seccion,
  };

  Widget _pantalla(String seccion) => switch (seccion) {
    'ventas'       => const VentasTab(),
    'clientes'     => const ClientesTab(),
    'stock'        => const AnalisisTab(),
    'cotizaciones' => const CotizacionesTab(),
    _              => const SizedBox.shrink(),
  };

  @override
  Widget build(BuildContext context) {
    if (_seccion != null) {
      return Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _seccion = null),
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppColors.textPrimary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _titulo(_seccion!),
                  style: AppTextStyles.heading2.copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _pantalla(_seccion!)),
        ],
      );
    }

    return _MenuMas(onSelect: (s) => setState(() => _seccion = s));
  }
}

class _MenuMas extends StatelessWidget {
  const _MenuMas({required this.onSelect});
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    const items = [
      (icon: Icons.receipt_long_rounded,  label: 'Ventas',       key: 'ventas'),
      (icon: Icons.group_rounded,         label: 'Clientes',     key: 'clientes'),
      (icon: Icons.inventory_2_rounded,   label: 'Stock',        key: 'stock'),
      (icon: Icons.request_quote_rounded, label: 'Cotizaciones', key: 'cotizaciones'),
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 56),
      itemBuilder: (_, i) => ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryPale,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(items[i].icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          items[i].label,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: const Icon(
            Icons.chevron_right_rounded, color: AppColors.textMuted),
        onTap: () => onSelect(items[i].key),
      ),
    );
  }
}
```

- [ ] **Step 5: Verificar que compila**

```
flutter analyze perfuteca_flutter/lib/features/estadisticas/screens/estadisticas_screen.dart
```
Esperado: 0 errores.

---

### Task 2: Agregar fila compacta "Hoy" al inicio de ResumenTab

**Files:**
- Modify: `perfuteca_flutter/lib/features/estadisticas/screens/resumen_tab.dart`

- [ ] **Step 1: Agregar `_HoyStrip` widget al final del archivo**

Insertar antes de la última clase (o al final del archivo):

```dart
// ── Strip compacto con métricas de hoy ────────────────────────────────────────

class _HoyStrip extends StatelessWidget {
  const _HoyStrip({
    required this.total,
    required this.ordenes,
    required this.pendientes,
  });
  final double total;
  final int    ordenes;
  final int    pendientes;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      border: Border.all(color: AppColors.primaryLight),
      boxShadow: const [
        BoxShadow(
          color:      AppColors.shadowColor,
          blurRadius: 4,
          offset:     Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        _StripMetric(
          label: 'HOY',
          valor: 'S/ ${total.toStringAsFixed(0)}',
          color: AppColors.primaryDark,
        ),
        _StripDivider(),
        _StripMetric(
          label: 'ÓRDENES',
          valor: '$ordenes',
          color: AppColors.textPrimary,
        ),
        _StripDivider(),
        _StripMetric(
          label: 'PENDIENTES',
          valor: '$pendientes',
          color: pendientes > 0 ? AppColors.warning : AppColors.stockOk,
        ),
      ],
    ),
  );
}

class _StripMetric extends StatelessWidget {
  const _StripMetric({
    required this.label,
    required this.valor,
    required this.color,
  });
  final String label;
  final String valor;
  final Color  color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          valor,
          style: AppTextStyles.price.copyWith(
            fontSize: 16,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.priceLabel.copyWith(fontSize: 9),
        ),
      ],
    ),
  );
}

class _StripDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 28,
    color: AppColors.primaryLight,
    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
  );
}
```

- [ ] **Step 2: Usar `_HoyStrip` en `_ResumenBody.build()`**

En `_ResumenBody.build()`, localizar el inicio del `ListView` (línea `return ListView(`...) y agregar `_HoyStrip` como **primer hijo** del ListView, antes del bloque `// ── Hoy`:

```dart
return ListView(
  padding: const EdgeInsets.all(AppSpacing.md),
  children: [
    // ── Strip compacto de hoy ─────────────────────────────────────────────
    _HoyStrip(
      total:      s.totalHoy,
      ordenes:    s.ventasHoy,
      pendientes: s.pendientesCount,
    ),

    // ── Hoy — primero, es lo que más importa ─────────────────────────────
    _SeccionLabel('Hoy · ${_diaLabel(now)}', icono: Icons.wb_sunny_rounded),
    // ... resto sin cambios
```

- [ ] **Step 3: Verificar que compila**

```
flutter analyze perfuteca_flutter/lib/features/estadisticas/screens/resumen_tab.dart
```
Esperado: 0 errores.

---

### Task 3: Commit final

- [ ] **Step 1: Verificar analyze global**

```
flutter analyze perfuteca_flutter/lib/features/estadisticas/
```
Esperado: 0 errores, 0 warnings.

- [ ] **Step 2: Commit**

```bash
git add perfuteca_flutter/lib/features/estadisticas/screens/estadisticas_screen.dart
git add perfuteca_flutter/lib/features/estadisticas/screens/resumen_tab.dart
git commit -m "feat(flutter): estadísticas 3 tabs — Resumen/Histórico/Más

- TabController length 6 → 3
- Tab 'Más': menú de lista con Ventas, Clientes, Stock, Cotizaciones
- Navegación interna en Más: tap ítem → pantalla, ← → menú
- ResumenTab: strip compacto 'Hoy' con total S/, órdenes, pendientes

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

# Cotizaciones de Hoy — Rediseño Visual Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rediseñar visualmente la pantalla Ventas › Cotizaciones de Hoy (Flutter) con estilo "status-first": métricas en mini-tarjetas por categoría con count-up, pill de estado prominente en cada card, micro-animaciones spring en chips/botón, y tipografía/spacing refinados en el resumen de confirmación. Sin cambios de lógica de negocio.

**Architecture:** Cambios acotados a 2 archivos existentes — `cotizaciones_hoy_screen.dart` (métricas) y `cotizacion_convertir_card.dart` (pill de estado, chips, botón, resumen). Se extraen widgets internos nuevos (`_MetricaCard`, `_EstadoPill`) sin tocar la estructura de providers/repositorios.

**Tech Stack:** Flutter + Riverpod, `flutter_test` para widget tests, sin paquetes nuevos — solo `TweenAnimationBuilder`, `AnimatedScale`, `AnimatedContainer` nativos.

---

## Spec → Tarea

| Spec | Tarea |
|---|---|
| 1. Métricas en mini-tarjetas + count-up | Task 1 |
| 2. Pill de estado en header de card | Task 2 |
| 3. Chips con scale-spring | Task 3 |
| 4. Botón "Revisar pedido" icon shift | Task 4 |
| 5. `_ConfirmacionInline` spacing/tipografía | Task 5 |
| Riesgo: verificar `cotizaciones_tab.dart` (Estadísticas) no rompe | Task 6 (manual, sin código) |

---

## Task 1: Métricas en mini-tarjetas con count-up

**Files:**
- Modify: `perfuteca_flutter/lib/features/ventas/screens/cotizaciones_hoy_screen.dart:97-185` (clases `_MetricasHoyRow` y `_MetricaItem`)
- Test: `perfuteca_flutter/test/cotizaciones_hoy_metricas_test.dart` (nuevo)

- [ ] **Step 1: Escribir el test que falla**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfuteca/features/ventas/screens/cotizaciones_hoy_screen.dart';

void main() {
  testWidgets('MetricasHoyGrid muestra 3 tarjetas separadas con valores finales correctos',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MetricasHoyGrid(total: 248.0, pendientes: 3, convertidas: 2),
        ),
      ),
    );

    // Deja correr el count-up hasta el final
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('metrica-total')), findsOneWidget);
    expect(find.byKey(const Key('metrica-pendientes')), findsOneWidget);
    expect(find.byKey(const Key('metrica-convertidas')), findsOneWidget);

    expect(find.text('S/ 248.00'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Correr test y verificar que falla**

Run: `cd perfuteca_flutter && flutter test test/cotizaciones_hoy_metricas_test.dart`
Expected: FAIL — `MetricasHoyGrid` no existe (la clase actual se llama `_MetricasHoyRow` y es privada).

- [ ] **Step 3: Implementar `MetricasHoyGrid`**

Reemplazar el bloque completo de `_MetricasHoyRow` y `_MetricaItem`
(`cotizaciones_hoy_screen.dart:97-185`) por:

```dart
// ── Métricas del día — grid de mini-tarjetas ──────────────────────────────────

class MetricasHoyGrid extends StatelessWidget {
  const MetricasHoyGrid({
    super.key,
    required this.total,
    required this.pendientes,
    required this.convertidas,
  });
  final double total;
  final int    pendientes;
  final int    convertidas;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _MetricaCard(
              key: const Key('metrica-total'),
              label: 'TOTAL HOY',
              valueText: 'S/ ${total.toStringAsFixed(2)}',
              numericValue: total,
              isMoney: true,
              background: AppColors.surface,
              borderColor: AppColors.primary,
              valueColor: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _MetricaCard(
              key: const Key('metrica-pendientes'),
              label: 'PENDIENTES',
              valueText: '$pendientes',
              numericValue: pendientes.toDouble(),
              isMoney: false,
              background: pendientes > 0
                  ? AppColors.warningSurface
                  : AppColors.surface,
              borderColor: pendientes > 0
                  ? AppColors.warning
                  : AppColors.primaryLight,
              valueColor:
                  pendientes > 0 ? AppColors.warning : AppColors.textFaint,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _MetricaCard(
              key: const Key('metrica-convertidas'),
              label: 'CONVERTIDAS',
              valueText: '$convertidas',
              numericValue: convertidas.toDouble(),
              isMoney: false,
              background: convertidas > 0
                  ? AppColors.successSurface
                  : AppColors.surface,
              borderColor:
                  convertidas > 0 ? AppColors.stockOk : AppColors.primaryLight,
              valueColor:
                  convertidas > 0 ? AppColors.stockOk : AppColors.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricaCard extends StatelessWidget {
  const _MetricaCard({
    super.key,
    required this.label,
    required this.valueText,
    required this.numericValue,
    required this.isMoney,
    required this.background,
    required this.borderColor,
    required this.valueColor,
  });
  final String label;
  final String valueText;
  final double numericValue;
  final bool   isMoney;
  final Color  background;
  final Color  borderColor;
  final Color  valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.notasLabel.copyWith(
              color: AppColors.textFaint,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: numericValue),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isMoney
                    ? 'S/ ${v.toStringAsFixed(2)}'
                    : v.round().toString(),
                style: TextStyle(
                  fontSize:   isMoney ? 22 : 20,
                  fontWeight: FontWeight.w800,
                  color:      valueColor,
                ),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

Actualizar el `itemBuilder` en `CotizacionesHoyScreen.build` (línea ~71-78)
para usar el nuevo widget en lugar de `_MetricasHoyRow`:

```dart
                  if (i == 0) {
                    final convertidas = lista
                        .where((c) => c.estado?.toLowerCase().startsWith('aceptad') == true)
                        .length;
                    final pendientes = lista.length - convertidas;
                    final totalS = lista.fold(0.0, (s, c) => s + (c.total ?? 0));
                    return _AnimatedListItem(
                      index: 0,
                      child: MetricasHoyGrid(
                        total:       totalS,
                        pendientes:  pendientes,
                        convertidas: convertidas,
                      ),
                    );
                  }
```

- [ ] **Step 4: Correr test y verificar que pasa**

Run: `cd perfuteca_flutter && flutter test test/cotizaciones_hoy_metricas_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add perfuteca_flutter/lib/features/ventas/screens/cotizaciones_hoy_screen.dart perfuteca_flutter/test/cotizaciones_hoy_metricas_test.dart
git commit -m "feat: rediseñar métricas de Cotizaciones de Hoy en mini-tarjetas con count-up"
```

---

## Task 2: Pill de estado prominente en header de card

**Files:**
- Modify: `perfuteca_flutter/lib/features/cotizaciones/widgets/cotizacion_convertir_card.dart:282-339` (Row del header dentro de `_CotizacionConvertirCardState.build`)
- Test: `perfuteca_flutter/test/cotizacion_estado_pill_test.dart` (nuevo)

- [ ] **Step 1: Escribir el test que falla**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfuteca/features/cotizaciones/widgets/cotizacion_convertir_card.dart';

void main() {
  testWidgets('EstadoPill muestra "Esperando" cuando no está aceptada',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: EstadoPill(aceptada: false)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Esperando'), findsOneWidget);
  });

  testWidgets('EstadoPill muestra "Aceptada" cuando está aceptada',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: EstadoPill(aceptada: true)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aceptada'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Correr test y verificar que falla**

Run: `cd perfuteca_flutter && flutter test test/cotizacion_estado_pill_test.dart`
Expected: FAIL — `EstadoPill` no existe.

- [ ] **Step 3: Implementar `EstadoPill` y conectarla en el header**

Agregar la clase nueva al final de `cotizacion_convertir_card.dart`
(junto a las demás clases privadas de widgets, ej. después de `_FieldLabel`):

```dart
// ── Pill de estado (esperando / aceptada) ─────────────────────────────────────

class EstadoPill extends StatelessWidget {
  const EstadoPill({super.key, required this.aceptada});
  final bool aceptada;

  @override
  Widget build(BuildContext context) {
    final color      = aceptada ? AppColors.stockOk : AppColors.gold;
    final background = aceptada ? AppColors.successSurface : AppColors.goldLight;
    final icon       = aceptada ? Icons.check_circle_rounded : Icons.schedule_rounded;
    final label      = aceptada ? 'Aceptada' : 'Esperando';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.priceLabel.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

Reemplazar el `Row` del header (líneas 282-339, dentro del `Column` de la
cabecera tappeable) para que el badge ID quede a la izquierda y el nuevo
pill sustituya al ícono+rotación que estaba pegado al total:

```dart
                      Row(children: [
                        // Badge ID
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPale,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            widget.cotizacion.idCotizacion,
                            style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Celular
                        if (widget.cotizacion.celular.isNotEmpty) ...[
                          const Icon(Icons.phone_outlined,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: AppSpacing.xs),
                          Text(widget.cotizacion.celular,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textSecondary)),
                        ],
                        const Spacer(),
                        EstadoPill(aceptada: esAceptada),
                      ]),
                      const SizedBox(height: AppSpacing.xs + 2),
                      Row(children: [
                        const Spacer(),
                        // Total
                        if (widget.cotizacion.total != null)
                          Text(
                            'S/ ${widget.cotizacion.total!.toStringAsFixed(2)}',
                            style: AppTextStyles.price.copyWith(
                                fontSize: 14, color: AppColors.primaryDark),
                          ),
                        const SizedBox(width: AppSpacing.xs),
                        if (!esAceptada)
                          AnimatedRotation(
                            turns: _expandido ? 0.5 : 0,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 20,
                                color: AppColors.textMuted),
                          ),
                      ]),
```

Esto quita el ícono `check_circle_rounded` que iba *dentro* del badge ID
(ya no es necesario — el pill nuevo cubre esa señal) y mantiene el resto
del bloque de "Perfumes de la cotización" y "Hint cuando está colapsado"
sin cambios (lo que sigue en el código original después de la línea 339
sigue igual — solo se reemplaza el `Row` de cabecera por los dos `Row`
de arriba).

Quitar también el bloque "Hint cuando está colapsado" que mostraba
`'Aceptada · convertida en venta'` / `'Toca para convertir a venta'` con
icono — queda redundante con el pill nuevo. Localizar en el archivo:

```dart
                      // Hint cuando está colapsado
                      if (!_expandido) ...[
                        const SizedBox(height: AppSpacing.sm),
                        if (esAceptada)
                          Row(children: [
                            const Icon(Icons.check_circle_rounded,
                                size: 12, color: AppColors.stockOk),
                            const SizedBox(width: 4),
                            Text('Aceptada · convertida en venta',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.stockOk,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11)),
                          ])
                        else
                          Row(children: [
                            const Icon(Icons.sell_outlined,
                                size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text('Toca para convertir a venta',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11)),
                          ]),
                      ],
```

Reemplazar por una versión que solo muestra el hint de acción cuando NO
está aceptada (el estado aceptado ya lo comunica el pill):

```dart
                      // Hint cuando está colapsado
                      if (!_expandido && !esAceptada) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Row(children: [
                          const Icon(Icons.sell_outlined,
                              size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('Toca para convertir a venta',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11)),
                        ]),
                      ],
```

- [ ] **Step 4: Correr test y verificar que pasa**

Run: `cd perfuteca_flutter && flutter test test/cotizacion_estado_pill_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add perfuteca_flutter/lib/features/cotizaciones/widgets/cotizacion_convertir_card.dart perfuteca_flutter/test/cotizacion_estado_pill_test.dart
git commit -m "feat: agregar pill de estado prominente en card de cotización"
```

---

## Task 3: Chips con scale-spring al seleccionar

**Files:**
- Modify: `perfuteca_flutter/lib/features/cotizaciones/widgets/cotizacion_convertir_card.dart:895-955` (clase `_Chips`)
- Test: `perfuteca_flutter/test/cotizacion_chips_test.dart` (nuevo)

- [ ] **Step 1: Escribir el test que falla**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfuteca/features/cotizaciones/widgets/cotizacion_convertir_card.dart';

void main() {
  testWidgets('Chips invoca onSelect con la opción tocada',
      (tester) async {
    String? seleccionado;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Chips(
            opciones: const ['Shalom', 'Motorizado'],
            valor: 'Shalom',
            onSelect: (v) => seleccionado = v,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Motorizado'));
    await tester.pumpAndSettle();

    expect(seleccionado, 'Motorizado');
  });
}
```

- [ ] **Step 2: Correr test y verificar que falla**

Run: `cd perfuteca_flutter && flutter test test/cotizacion_chips_test.dart`
Expected: FAIL — `Chips` no existe (la clase actual es privada `_Chips`).

- [ ] **Step 3: Renombrar `_Chips` a `Chips` y agregar pulse de escala**

Reemplazar la clase completa `_Chips` (líneas 895-955) por:

```dart
class Chips extends StatefulWidget {
  const Chips({
    super.key,
    required this.opciones,
    required this.valor,
    required this.onSelect,
  });
  final List<String>         opciones;
  final String               valor;
  final ValueChanged<String> onSelect;

  @override
  State<Chips> createState() => _ChipsState();
}

class _ChipsState extends State<Chips> {
  String? _pulsando;

  void _onTap(String op) {
    setState(() => _pulsando = op);
    widget.onSelect(op);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _pulsando = null);
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: widget.opciones.map((op) {
            final sel    = widget.valor == op;
            final radius = BorderRadius.circular(AppSpacing.radiusSm);
            return Semantics(
              button: true,
              label: op,
              selected: sel,
              child: TweenAnimationBuilder<double>(
                tween: Tween(
                    begin: 1.0, end: _pulsando == op ? 1.08 : 1.0),
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : AppColors.surface,
                    borderRadius: radius,
                    border: Border.all(
                      color: sel ? AppColors.primary : AppColors.primaryLight,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => _onTap(op),
                    borderRadius: radius,
                    splashColor: sel
                        ? AppColors.primaryDark.withValues(alpha: 0.25)
                        : AppColors.primaryLight,
                    highlightColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      child: Text(op,
                          style: TextStyle(
                              fontSize:   12,
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: sel
                                  ? AppColors.background
                                  : AppColors.textSecondary)),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
}
```

Actualizar los 2 usos existentes de `_Chips(` dentro del mismo archivo
(líneas ~503 y ~513) a `Chips(`:

```dart
                              _Chips(
```
→
```dart
                              Chips(
```

(aplicar en ambos lugares: tipo de envío y método de pago).

- [ ] **Step 4: Correr test y verificar que pasa**

Run: `cd perfuteca_flutter && flutter test test/cotizacion_chips_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add perfuteca_flutter/lib/features/cotizaciones/widgets/cotizacion_convertir_card.dart perfuteca_flutter/test/cotizacion_chips_test.dart
git commit -m "feat: animar chips de envío/pago con scale-pulse al seleccionar"
```

---

## Task 4: Botón "Revisar pedido" con desplazamiento de ícono en press

**Files:**
- Modify: `perfuteca_flutter/lib/features/cotizaciones/widgets/cotizacion_convertir_card.dart:541-554`
- Test: `perfuteca_flutter/test/cotizacion_boton_revisar_test.dart` (nuevo)

- [ ] **Step 1: Escribir el test que falla**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfuteca/features/cotizaciones/widgets/cotizacion_convertir_card.dart';

void main() {
  testWidgets('BotonRevisarPedido invoca onPressed al tocar', (tester) async {
    var presionado = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BotonRevisarPedido(
            habilitado: true,
            onPressed: () => presionado = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Revisar pedido'));
    await tester.pumpAndSettle();

    expect(presionado, isTrue);
  });

  testWidgets('BotonRevisarPedido no invoca onPressed si está deshabilitado',
      (tester) async {
    var presionado = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BotonRevisarPedido(
            habilitado: false,
            onPressed: () => presionado = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Revisar pedido'));
    await tester.pumpAndSettle();

    expect(presionado, isFalse);
  });
}
```

- [ ] **Step 2: Correr test y verificar que falla**

Run: `cd perfuteca_flutter && flutter test test/cotizacion_boton_revisar_test.dart`
Expected: FAIL — `BotonRevisarPedido` no existe.

- [ ] **Step 3: Implementar `BotonRevisarPedido` y conectarlo**

Agregar la clase nueva (junto a `EstadoPill`):

```dart
// ── Botón "Revisar pedido" con micro-shift de ícono en press ─────────────────

class BotonRevisarPedido extends StatefulWidget {
  const BotonRevisarPedido({
    super.key,
    required this.habilitado,
    required this.onPressed,
  });
  final bool         habilitado;
  final VoidCallback onPressed;

  @override
  State<BotonRevisarPedido> createState() => _BotonRevisarPedidoState();
}

class _BotonRevisarPedidoState extends State<BotonRevisarPedido> {
  bool _presionando = false;

  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: widget.habilitado ? widget.onPressed : null,
        onLongPress: null,
        style: FilledButton.styleFrom(padding: EdgeInsets.zero),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _presionando = true),
          onTapUp: (_) => setState(() => _presionando = false),
          onTapCancel: () => setState(() => _presionando = false),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Revisar pedido'),
                const SizedBox(width: 6),
                AnimatedSlide(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOutCubic,
                  offset: _presionando ? const Offset(0.3, 0) : Offset.zero,
                  child: const Icon(Icons.arrow_forward_rounded, size: 16),
                ),
              ],
            ),
          ),
        ),
      );
}
```

Reemplazar el `Expanded(child: FilledButton.icon(...))` actual
(líneas 541-554) por:

```dart
                                  Expanded(
                                    child: BotonRevisarPedido(
                                      habilitado: formValido && !_registrando,
                                      onPressed: () =>
                                          setState(() => _confirmando = true),
                                    ),
                                  ),
```

- [ ] **Step 4: Correr test y verificar que pasa**

Run: `cd perfuteca_flutter && flutter test test/cotizacion_boton_revisar_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add perfuteca_flutter/lib/features/cotizaciones/widgets/cotizacion_convertir_card.dart perfuteca_flutter/test/cotizacion_boton_revisar_test.dart
git commit -m "feat: agregar micro-animación de ícono en botón Revisar pedido"
```

---

## Task 5: Refinar `_ResumenFila` (jerarquía tipográfica del resumen)

**Files:**
- Modify: `perfuteca_flutter/lib/features/cotizaciones/widgets/cotizacion_convertir_card.dart:1009-1036`
- Test: `perfuteca_flutter/test/cotizacion_resumen_fila_test.dart` (nuevo)

- [ ] **Step 1: Escribir el test que falla**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfuteca/features/cotizaciones/widgets/cotizacion_convertir_card.dart';

void main() {
  testWidgets('ResumenFila muestra label y valor', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResumenFila('Cliente', 'Ana Torres'),
        ),
      ),
    );
    expect(find.text('CLIENTE'), findsOneWidget);
    expect(find.text('Ana Torres'), findsOneWidget);
  });

  testWidgets('ResumenFila muestra "—" cuando el valor está vacío',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ResumenFila('Distrito', '')),
      ),
    );
    expect(find.text('—'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Correr test y verificar que falla**

Run: `cd perfuteca_flutter && flutter test test/cotizacion_resumen_fila_test.dart`
Expected: FAIL — `ResumenFila` no existe (clase actual privada `_ResumenFila`,
y label se muestra en minúscula/normal, no en mayúsculas).

- [ ] **Step 3: Renombrar e implementar jerarquía tipográfica**

Reemplazar la clase `_ResumenFila` (líneas 1009-1036) por:

```dart
class ResumenFila extends StatelessWidget {
  const ResumenFila(this.label, this.valor, {super.key});
  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 76,
              child: Text(
                label.toUpperCase(),
                style: AppTextStyles.notasLabel.copyWith(
                  color: AppColors.textFaint,
                  letterSpacing: 0.6,
                  fontSize: 10,
                ),
              ),
            ),
            Expanded(
              child: Text(
                valor.isNotEmpty ? valor : '—',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
}
```

Actualizar los 6 usos de `_ResumenFila(` dentro de `_ConfirmacionInline`
(líneas ~614-619) a `ResumenFila(`.

- [ ] **Step 4: Correr test y verificar que pasa**

Run: `cd perfuteca_flutter && flutter test test/cotizacion_resumen_fila_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add perfuteca_flutter/lib/features/cotizaciones/widgets/cotizacion_convertir_card.dart perfuteca_flutter/test/cotizacion_resumen_fila_test.dart
git commit -m "refactor: refinar jerarquía tipográfica del resumen de confirmación"
```

---

## Task 6: Verificación manual — pantalla compartida en Estadísticas

**Files:** ninguno (solo verificación, sin cambios de código)

- [ ] **Step 1: Correr la app**

Run: `cd perfuteca_flutter && flutter run -d <device>`

- [ ] **Step 2: Navegar a Ventas › Cotizaciones de Hoy**

Verificar visualmente:
- Las 3 mini-tarjetas de métricas animan el conteo al entrar a la pantalla.
- Cada card de cotización muestra el pill "Esperando" o "Aceptada" arriba
  a la derecha del header.
- Al expandir una card no aceptada, los chips de envío/pago hacen un pulso
  de escala al tocarlos.
- El botón "Revisar pedido" desplaza el ícono al mantenerlo presionado.
- El resumen de confirmación (`_ConfirmacionInline`) se ve con labels en
  mayúscula sutil y valores en negrita.

- [ ] **Step 3: Navegar a Estadísticas › tab Cotizaciones**

Verificar que `cotizacion_tab.dart` (que reutiliza `CotizacionConvertirCard`)
se sigue viendo correctamente con los mismos cambios — sin overflow de
texto, sin recortes de pill, sin solapamientos.

- [ ] **Step 4: Si algo se ve roto en Estadísticas**

Anotar el problema específico (overflow, color, recorte) — no es parte de
este plan corregirlo automáticamente; reportar al usuario antes de hacer
cambios fuera del alcance acordado.

---

## Notas finales

- No se agregan paquetes nuevos al `pubspec.yaml`.
- Todas las clases nuevas (`MetricasHoyGrid`, `EstadoPill`, `Chips`,
  `BotonRevisarPedido`, `ResumenFila`) quedan públicas porque los tests de
  widget viven en `test/` (paquete separado) y necesitan importarlas.
- Después de la Task 5, correr la suite completa una vez:
  `cd perfuteca_flutter && flutter test` — debe quedar todo en verde,
  incluyendo `nueva_cotizacion_descuento_test.dart` y `widget_test.dart`
  preexistentes (no deben romperse por estos cambios).

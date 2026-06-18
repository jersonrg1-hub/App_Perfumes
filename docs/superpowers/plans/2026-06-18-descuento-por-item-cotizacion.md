# Descuento 10% por item — Cotizaciones Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permitir aplicar el descuento del 10% a solo algunos perfumes de una cotización, no obligatoriamente a todos.

**Architecture:** El flag global `conDescuento: bool` del provider se reemplaza por un `Set<int> indicesConDescuento` (índices de la cesta con descuento). El switch existente se conserva como shortcut "seleccionar todos". La UI del Paso 3 gana un modo de selección por item (botón "Elegir productos") con un chip "10%" tappeable por perfume.

**Tech Stack:** Flutter, Riverpod (`Notifier`/`ProviderContainer`), flutter_test.

---

### Task 1: Provider — descuento por índice

**Files:**
- Modify: `perfuteca_flutter/lib/features/cotizaciones/providers/nueva_cotizacion_provider.dart` (archivo completo, 143 líneas)
- Test: `perfuteca_flutter/test/nueva_cotizacion_descuento_test.dart` (crear)

- [ ] **Step 1: Escribir el test que falla**

Crear `perfuteca_flutter/test/nueva_cotizacion_descuento_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfuteca/features/cotizaciones/providers/nueva_cotizacion_provider.dart';
import 'package:perfuteca/models/perfume.dart';

Perfume _perfume(String id, String nombre, double precio5ml) => Perfume(
      idPerfume: id,
      marca: 'MarcaTest',
      nombre: nombre,
      precio5ml: precio5ml,
    );

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('toggleItemDescuento aplica el 10% solo a ese item', () {
    final notifier = container.read(nuevaCotizacionProvider.notifier);
    notifier.agregarItem(_perfume('1', 'A', 25.0), 5);
    notifier.agregarItem(_perfume('2', 'B', 30.0), 5);
    notifier.agregarItem(_perfume('3', 'C', 45.0), 5);

    notifier.toggleItemDescuento(0);

    final state = container.read(nuevaCotizacionProvider);
    expect(state.itemConDescuento(0), isTrue);
    expect(state.itemConDescuento(1), isFalse);
    expect(state.itemConDescuento(2), isFalse);
    expect(state.algunDescuento, isTrue);
    expect(state.conDescuento, isFalse); // no estan TODOS seleccionados
    expect(state.ahorro, closeTo(2.5, 0.001)); // 25 - round10(25*0.9) = 25 - 22.5
    expect(state.subtotalDescuento, closeTo(22.5 + 30.0 + 45.0, 0.001));
  });

  test('toggleDescuento selecciona todos, y al volver a togglear limpia todos', () {
    final notifier = container.read(nuevaCotizacionProvider.notifier);
    notifier.agregarItem(_perfume('1', 'A', 25.0), 5);
    notifier.agregarItem(_perfume('2', 'B', 30.0), 5);

    notifier.toggleDescuento();
    var state = container.read(nuevaCotizacionProvider);
    expect(state.conDescuento, isTrue);
    expect(state.itemConDescuento(0), isTrue);
    expect(state.itemConDescuento(1), isTrue);

    notifier.toggleDescuento();
    state = container.read(nuevaCotizacionProvider);
    expect(state.conDescuento, isFalse);
    expect(state.algunDescuento, isFalse);
  });

  test('quitarItem reindexa el set de descuento correctamente', () {
    final notifier = container.read(nuevaCotizacionProvider.notifier);
    notifier.agregarItem(_perfume('1', 'A', 25.0), 5); // index 0
    notifier.agregarItem(_perfume('2', 'B', 30.0), 5); // index 1
    notifier.agregarItem(_perfume('3', 'C', 45.0), 5); // index 2

    notifier.toggleItemDescuento(1); // descuento en B (index 1)
    notifier.quitarItem(0); // se borra A

    final state = container.read(nuevaCotizacionProvider);
    // B ahora es index 0, debe seguir con descuento
    expect(state.cesta.length, 2);
    expect(state.cesta[0].perfume.idPerfume, '2');
    expect(state.itemConDescuento(0), isTrue);
    expect(state.itemConDescuento(1), isFalse);
  });
}
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `cd perfuteca_flutter && flutter test test/nueva_cotizacion_descuento_test.dart`
Expected: FAIL — error de compilación, `itemConDescuento`, `algunDescuento` y `toggleItemDescuento` no existen todavía en el provider (hoy solo existe `conDescuento: bool`).

- [ ] **Step 3: Reescribir el provider**

Reemplazar el contenido completo de `perfuteca_flutter/lib/features/cotizaciones/providers/nueva_cotizacion_provider.dart` por:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/models/cotizacion.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/models/venta.dart';
import 'package:perfuteca/repositories/cotizaciones_repository.dart';

double _round10(double p) => (p * 10).round() / 10.0;

class NuevaCotizacionState {
  const NuevaCotizacionState({
    this.paso                = 1,
    this.celular             = '',
    this.cesta               = const [],
    this.conDelivery         = false,
    this.indicesConDescuento = const {},
    this.registrando         = false,
    this.registrada,
    this.error,
  });

  final int                   paso;
  final String                celular;
  final List<ItemCesta>       cesta;
  final bool                  conDelivery;
  final Set<int>               indicesConDescuento;
  final bool                  registrando;
  final CotizacionRegistrada? registrada;
  final String?               error;

  static const double costoDelivery = 10.0;

  // True solo si TODOS los items de la cesta tienen descuento — estado del switch "seleccionar todos"
  bool get conDescuento =>
      cesta.isNotEmpty && indicesConDescuento.length == cesta.length;

  // True si AL MENOS un item tiene descuento (parcial o total)
  bool get algunDescuento => indicesConDescuento.isNotEmpty;

  bool itemConDescuento(int index) => indicesConDescuento.contains(index);

  // Precio efectivo de un item según si ESE item tiene descuento
  double precioEfectivoIndex(int index, double precio) =>
      itemConDescuento(index) ? _round10(precio * 0.90) : precio;

  // Subtotal SIN descuento (precios originales)
  double get subtotalOriginal => cesta.fold(0.0, (s, i) => s + i.precio);

  // Subtotal CON descuento aplicado solo a los items seleccionados
  double get subtotalDescuento => cesta.asMap().entries.fold(
      0.0, (s, e) => s + precioEfectivoIndex(e.key, e.value.precio));

  // Ahorro total = diferencia entre subtotales
  double get ahorro => subtotalOriginal - subtotalDescuento;

  // Backward-compat: subtotal = working subtotal (discounted when applicable)
  double get subtotal => subtotalDescuento;

  // lo que se guarda en Sheets (sin delivery)
  double get total => subtotalDescuento;

  // Backward-compat: totalConDelivery uses discounted base
  double get totalConDelivery => subtotalDescuento + (conDelivery ? costoDelivery : 0);

  bool get paso1Valido => celular.length == 9;
  bool get cestaValida => cesta.isNotEmpty;

  NuevaCotizacionState copyWith({
    int?                  paso,
    String?               celular,
    List<ItemCesta>?      cesta,
    bool?                 conDelivery,
    Set<int>?             indicesConDescuento,
    bool?                 registrando,
    CotizacionRegistrada? registrada,
    String?               error,
    bool                  clearError      = false,
    bool                  clearRegistrada = false,
  }) => NuevaCotizacionState(
    paso:                paso                ?? this.paso,
    celular:             celular             ?? this.celular,
    cesta:               cesta               ?? this.cesta,
    conDelivery:         conDelivery         ?? this.conDelivery,
    indicesConDescuento: indicesConDescuento ?? this.indicesConDescuento,
    registrando:         registrando         ?? this.registrando,
    registrada:          clearRegistrada ? null : (registrada ?? this.registrada),
    error:               clearError   ? null : (error        ?? this.error),
  );
}

class NuevaCotizacionNotifier extends Notifier<NuevaCotizacionState> {
  @override
  NuevaCotizacionState build() => const NuevaCotizacionState();

  CotizacionesRepository get _repo =>
      ref.read(cotizacionesRepositoryProvider);

  void setCelular(String v)    => state = state.copyWith(celular: v);
  void irPaso(int p)           => state = state.copyWith(paso: p, clearError: true);
  void toggleDelivery()        => state = state.copyWith(conDelivery: !state.conDelivery);

  // Shortcut "seleccionar todos": si ya estan todos seleccionados, limpia; si no, selecciona todos
  void toggleDescuento() {
    if (state.conDescuento) {
      state = state.copyWith(indicesConDescuento: {});
    } else {
      state = state.copyWith(
        indicesConDescuento: {for (var i = 0; i < state.cesta.length; i++) i},
      );
    }
  }

  void toggleItemDescuento(int index) {
    final nuevos = Set<int>.from(state.indicesConDescuento);
    if (nuevos.contains(index)) {
      nuevos.remove(index);
    } else {
      nuevos.add(index);
    }
    state = state.copyWith(indicesConDescuento: nuevos);
  }

  void agregarItem(Perfume perfume, int ml) {
    final precio = switch (ml) {
      2  => perfume.precio2ml,
      5  => perfume.precio5ml,
      10 => perfume.precio10ml,
      _  => null,
    };
    if (precio == null) return;

    final item = ItemCesta(
      perfume: perfume,
      ml:      ml,
      precio:  precio,
      metodo:  'Cotización',
    );
    state = state.copyWith(cesta: [...state.cesta, item]);
  }

  void quitarItem(int index) {
    final nuevaCesta = List<ItemCesta>.from(state.cesta)..removeAt(index);
    final nuevosIndices = state.indicesConDescuento
        .where((i) => i != index)
        .map((i) => i > index ? i - 1 : i)
        .toSet();
    state = state.copyWith(cesta: nuevaCesta, indicesConDescuento: nuevosIndices);
  }

  Future<void> guardar() async {
    state = state.copyWith(registrando: true, clearError: true);
    try {
      final registrada = await _repo.guardarCotizacion(
        celular: state.celular,
        items:   state.cesta.asMap().entries.map((e) => {
          ...e.value.toApiMap(),
          'precio': state.precioEfectivoIndex(e.key, e.value.precio),
        }).toList(),
        total:   state.subtotalDescuento,
      );
      state = state.copyWith(
        registrando: false,
        registrada:  registrada,
        paso:        3,
      );
    } catch (e) {
      state = state.copyWith(registrando: false, error: e.toString());
    }
  }

  void reset() => state = const NuevaCotizacionState();
}

final nuevaCotizacionProvider =
    NotifierProvider<NuevaCotizacionNotifier, NuevaCotizacionState>(
        NuevaCotizacionNotifier.new);
```

- [ ] **Step 4: Correr el test y verificar que pasa**

Run: `cd perfuteca_flutter && flutter test test/nueva_cotizacion_descuento_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add perfuteca_flutter/lib/features/cotizaciones/providers/nueva_cotizacion_provider.dart perfuteca_flutter/test/nueva_cotizacion_descuento_test.dart
git commit -m "feat: descuento 10% por item en cotizaciones (provider)"
```

---

### Task 2: UI — Paso 3 con selección por item

**Files:**
- Modify: `perfuteca_flutter/lib/features/cotizaciones/screens/nueva_cotizacion_screen.dart` (líneas 81-88, 758-1184)

- [ ] **Step 1: Convertir `_Paso3` a `ConsumerStatefulWidget` y agregar el botón "Elegir productos"**

Reemplazar la declaración de la clase (línea 758-766):

```dart
class _Paso3 extends ConsumerStatefulWidget {
  const _Paso3({required this.onAnterior, required this.onGuardar});
  final VoidCallback onAnterior;
  final VoidCallback onGuardar;

  @override
  ConsumerState<_Paso3> createState() => _Paso3State();
}

class _Paso3State extends ConsumerState<_Paso3> {
  bool _modoSeleccion = false;

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(nuevaCotizacionProvider);
    final notifier = ref.read(nuevaCotizacionProvider.notifier);
```

(El resto del método `build` sigue igual hasta el bloque "Perfumes cotizados" — ver Step 2.)

Reemplazar las líneas 798-803 (`'Perfumes cotizados'` + `SizedBox`) por:

```dart
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Perfumes cotizados',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: () => setState(() => _modoSeleccion = !_modoSeleccion),
                child: Text(_modoSeleccion ? 'Listo' : 'Elegir productos'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
```

- [ ] **Step 2: Reemplazar el bloque de items de la cesta con el chip "10%" por item**

Reemplazar las líneas 806-872 (el `...state.cesta.asMap().entries.map((e) { ... })` completo) por:

```dart
          // Items de la cesta
          ...state.cesta.asMap().entries.map((e) {
            final seleccionado = state.itemConDescuento(e.key);
            return Dismissible(
              key: ValueKey('${e.value.perfume.idPerfume}_${e.value.ml}_${e.key}'),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => notifier.quitarItem(e.key),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: AppSpacing.lg),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.delete_rounded, color: AppColors.error, size: 20),
                    SizedBox(width: 4),
                    Text('Eliminar',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        )),
                    SizedBox(width: AppSpacing.sm),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ItemCestaCard(
                          item:           e.value,
                          index:          e.key,
                          onQuitar:       () => notifier.quitarItem(e.key),
                          nombreFontSize: 15,
                          marcaFontSize:  12,
                        ),
                      ),
                      if (_modoSeleccion) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _DescuentoChip(
                          seleccionado: seleccionado,
                          onTap: () => notifier.toggleItemDescuento(e.key),
                        ),
                      ],
                    ],
                  ),
                  if (seleccionado)
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: AppSpacing.sm, right: AppSpacing.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'S/ ${_fmtPrecio(e.value.precio)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMuted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '→  S/ ${_fmtPrecio(state.precioEfectivoIndex(e.key, e.value.precio))}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }),
```

- [ ] **Step 3: Agregar el widget `_DescuentoChip`**

Agregar esta clase nueva justo después del cierre de la clase `_Paso3State` (después de la llave que cierra `build` y la clase, antes de la sección `// ── Ticket de éxito`):

```dart
// ── Chip de descuento por item ───────────────────────────────────────────────

class _DescuentoChip extends StatelessWidget {
  const _DescuentoChip({required this.seleccionado, required this.onTap});
  final bool         seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: _kFast,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: 6),
          decoration: BoxDecoration(
            color: seleccionado ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: seleccionado ? AppColors.primary : AppColors.primaryLight,
              width: seleccionado ? 1.5 : 1,
            ),
          ),
          child: Text(
            '10%',
            style: AppTextStyles.priceLabel.copyWith(
              color: seleccionado ? Colors.white : AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
}
```

- [ ] **Step 4: Actualizar el subtítulo del switch "Descuento 10%" para usar `algunDescuento`**

En el bloque del switch (busca `'Descuento 10%'`), reemplazar el `Text` del subtítulo:

```dart
                            Text(
                              state.algunDescuento
                                  ? 'ahorras S/ ${state.ahorro.toStringAsFixed(2)}'
                                  : 'aplica 10% sobre cada perfume',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: state.algunDescuento
                                    ? AppColors.success
                                    : AppColors.textMuted,
                              ),
                            ),
```

(Antes ambas condiciones usaban `state.conDescuento` — el `value`/`onChanged` del `Switch` que está justo debajo NO cambia, sigue usando `state.conDescuento` y `notifier.toggleDescuento()`.)

- [ ] **Step 5: Actualizar la caja de "Total" para mostrar el desglose con selección parcial**

En el bloque `// Total` (Container con `AppColors.primaryDark`), reemplazar las 3 ocurrencias de `state.conDescuento` por `state.algunDescuento`:

```dart
                    Text(
                      state.algunDescuento
                          ? 'S/ ${state.subtotalOriginal.toStringAsFixed(2)}'
                          : 'S/ ${state.subtotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: state.algunDescuento ? TextDecoration.lineThrough : null,
                        decorationColor: Colors.white54,
                      ),
                    ),
                  ],
                ),
                if (state.algunDescuento) ...[
```

(El resto del bloque "DESCUENTO -10%" que sigue dentro de ese `if` no cambia.)

- [ ] **Step 6: Actualizar `_TicketExito` para usar el set de índices**

Reemplazar el parámetro del widget (busca `class _TicketExito`):

```dart
class _TicketExito extends StatefulWidget {
  const _TicketExito({
    required this.idCotizacion,
    required this.celular,
    required this.total,
    required this.cesta,
    required this.conDelivery,
    required this.indicesConDescuento,
    required this.onNueva,
  });
  final String          idCotizacion;
  final String          celular;
  final double          total;
  final List<ItemCesta> cesta;
  final bool            conDelivery;
  final Set<int>        indicesConDescuento;
  final VoidCallback    onNueva;
```

Dentro de `_abrirWhatsApp()`, reemplazar el cálculo por item y la línea de resumen:

```dart
  Future<void> _abrirWhatsApp() async {
    const sep = '────────────────────';
    final bloques = <String>[];
    for (var idx = 0; idx < widget.cesta.length; idx++) {
      final i = widget.cesta[idx];
      final nombreCompleto = '${i.perfume.marca} ${i.perfume.nombre}'.trim();
      final tieneDescuento = widget.indicesConDescuento.contains(idx);
      final precioDesc = _round10(i.precio * 0.90);
      final precioLine = tieneDescuento
          ? '~S/ ${i.precio.toStringAsFixed(2)}~  *S/ ${precioDesc.toStringAsFixed(2)}*'
          : '*S/ ${i.precio.toStringAsFixed(2)}*';
      bloques.add(
        '*${idx + 1}.* 🌸 *$nombreCompleto*\n'
        '     📏 ${i.ml}ml  ·  💰 $precioLine',
      );
    }
    final subtotalOriginal =
        widget.cesta.fold(0.0, (s, i) => s + i.precio);
    final descuentoLine = widget.indicesConDescuento.isNotEmpty
        ? '🎉 *Descuento 10%* (precio regular S/ ${subtotalOriginal.toStringAsFixed(2)})\n'
        : '';
```

(El resto de `_abrirWhatsApp` y el resto de `_TicketExito` no cambia.)

- [ ] **Step 7: Actualizar el call site donde se construye `_TicketExito`**

En el `build()` de `_NuevaCotizacionScreenState` (alrededor de la línea 82-93), reemplazar el parámetro:

```dart
              state.registrada != null
                  ? _TicketExito(
                      idCotizacion:        state.registrada!.idCotizacion,
                      celular:             state.celular,
                      total:               state.totalConDelivery,
                      cesta:               state.cesta,
                      conDelivery:         state.conDelivery,
                      indicesConDescuento: state.indicesConDescuento,
                      onNueva:      () {
                        ref.read(nuevaCotizacionProvider.notifier).reset();
                        _irA(1);
                      },
                    )
                  : _Paso3(
```

- [ ] **Step 8: Verificar que el proyecto compila y los análisis pasan**

Run: `cd perfuteca_flutter && flutter analyze lib/features/cotizaciones/screens/nueva_cotizacion_screen.dart`
Expected: "No issues found!"

Run: `cd perfuteca_flutter && flutter test`
Expected: todos los tests pasan (incluye los 3 nuevos de Task 1 y los tests existentes de otras features — ninguno debería romperse, ya que `nueva_cotizacion_screen.dart` no tiene tests propios todavía).

- [ ] **Step 9: Commit**

```bash
git add perfuteca_flutter/lib/features/cotizaciones/screens/nueva_cotizacion_screen.dart
git commit -m "feat: UI de seleccion de descuento por item en Paso 3 de cotizaciones"
```

---

### Task 3: Verificación manual en la app

**Files:** ninguno (solo verificación, sin cambios de código)

No se escribe un test de widget automatizado para el wizard completo de cotizaciones porque `NuevaCotizacionScreen` controla la navegación entre pasos con un `PageController` que solo salta de página ante transiciones reales de `state.paso` (no al pre-cargar un estado en paso 3 directamente) — reproducir eso en un test requeriría simular el flujo completo de 3 pasos (teléfono → agregar perfumes → confirmar), lo cual no es parte de este cambio. La lógica de negocio (cálculo de descuento por índice) ya está cubierta por los tests de Task 1.

- [ ] **Step 1: Correr la suite completa**

Run: `cd perfuteca_flutter && flutter test`
Expected: todos los tests pasan.

- [ ] **Step 2: Levantar la app y probar el flujo completo**

Run: `cd perfuteca_flutter && flutter run`

En la app: ir a Cotizaciones → Nueva cotización. Completar Paso 1 (celular) y Paso 2 (agregar 3 perfumes distintos). En Paso 3:

- Tocar "Elegir productos" — debe aparecer un chip "10%" junto a cada perfume.
- Tocar el chip de un solo perfume — ese chip se pinta (fondo color primary), aparece la línea de precio tachado→descuento SOLO en ese perfume, y la caja de Total muestra el desglose "SUBTOTAL" tachado + "DESCUENTO -10%" con el monto correcto (no el 10% de todo, solo de ese perfume).
- El switch "Descuento 10%" debe verse APAGADO (porque no están todos seleccionados).
- Tocar el switch "Descuento 10%" — debe seleccionar TODOS los perfumes (todos los chips se pintan), y al tocarlo de nuevo debe limpiar todos.
- Tocar "Listo" — los chips desaparecen pero el descuento aplicado se mantiene (la línea de precio tachado sigue visible en los perfumes seleccionados).
- Enviar la cotización y abrir el mensaje de WhatsApp — verificar que solo los perfumes con descuento muestran precio tachado en el mensaje, y que el total coincide con lo mostrado en la app.

- [ ] **Step 3: Confirmar y cerrar**

Si todo lo anterior se ve correcto, no se necesita ningún commit adicional — este task es solo de verificación.

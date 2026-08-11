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

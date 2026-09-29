import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfuteca/features/cotizaciones/providers/nueva_cotizacion_provider.dart';
import 'package:perfuteca/models/perfume.dart';

Perfume _perfumeConCompleto(String id, String nombre, {double? precio5ml}) =>
    Perfume(
      idPerfume: id,
      marca: 'MarcaTest',
      nombre: nombre,
      precio5ml: precio5ml,
      completos: const [
        CompletoPerfume(ml: 50, precio: 340.0),
        CompletoPerfume(ml: 100, precio: 460.0),
      ],
    );

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('agregarItem resuelve precio desde completos cuando ml no es decant', () {
    final notifier = container.read(nuevaCotizacionProvider.notifier);
    notifier.agregarItem(_perfumeConCompleto('1', 'A'), 100);

    final state = container.read(nuevaCotizacionProvider);
    expect(state.cesta.length, 1);
    expect(state.cesta[0].ml, 100);
    expect(state.cesta[0].precio, 460.0);
    expect(state.cesta[0].esCompleto, isTrue);
  });

  test('agregarItem con ml sin match en decant ni completos no agrega nada', () {
    final notifier = container.read(nuevaCotizacionProvider.notifier);
    notifier.agregarItem(_perfumeConCompleto('1', 'A'), 30);

    final state = container.read(nuevaCotizacionProvider);
    expect(state.cesta, isEmpty);
  });

  test('toggleItemDescuento no hace nada sobre un item completo', () {
    final notifier = container.read(nuevaCotizacionProvider.notifier);
    notifier.agregarItem(_perfumeConCompleto('1', 'A'), 50);

    notifier.toggleItemDescuento(0);

    final state = container.read(nuevaCotizacionProvider);
    expect(state.itemConDescuento(0), isFalse);
    expect(state.algunDescuento, isFalse);
    expect(state.subtotalDescuento, 340.0); // precio de lista, sin descontar
  });

  test('toggleDescuento (seleccionar todos) excluye los items completos '
      'y sigue pudiendo des-seleccionar todos después', () {
    final notifier = container.read(nuevaCotizacionProvider.notifier);
    notifier.agregarItem(_perfumeConCompleto('1', 'A'), 50); // completo, index 0
    notifier.agregarItem(
      _perfumeConCompleto('2', 'B', precio5ml: 25.0),
      5,
    ); // decant, index 1

    notifier.toggleDescuento();

    var state = container.read(nuevaCotizacionProvider);
    expect(state.itemConDescuento(0), isFalse); // completo, nunca entra
    expect(state.itemConDescuento(1), isTrue); // decant, sí entra
    // conDescuento compara contra los items ELEGIBLES (sin completos), no
    // contra cesta.length — si comparara contra cesta.length, con un
    // completo en la cesta nunca llegaría a true y el switch "seleccionar
    // todos" quedaría trabado para siempre en "seleccionar" sin poder
    // volver a "limpiar todos" (bug real detectado y corregido acá).
    expect(state.conDescuento, isTrue);

    // Debe poder volver a limpiar todos con un segundo toggle — antes del
    // fix, este segundo toggle recalculaba el mismo set en vez de limpiarlo.
    notifier.toggleDescuento();
    state = container.read(nuevaCotizacionProvider);
    expect(state.algunDescuento, isFalse);
    expect(state.itemConDescuento(1), isFalse);
  });

  test('decant sigue resolviendo por precio2ml/5ml/10ml aunque el perfume tenga completos', () {
    final notifier = container.read(nuevaCotizacionProvider.notifier);
    notifier.agregarItem(_perfumeConCompleto('1', 'A', precio5ml: 25.0), 5);

    final state = container.read(nuevaCotizacionProvider);
    expect(state.cesta[0].precio, 25.0);
    expect(state.cesta[0].esCompleto, isFalse);
  });
}

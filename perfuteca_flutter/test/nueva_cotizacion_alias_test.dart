import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfuteca/features/cotizaciones/providers/nueva_cotizacion_provider.dart';
import 'package:perfuteca/models/cotizacion.dart';
import 'package:perfuteca/models/perfume.dart';

Perfume _perfume(String id, String nombre, double precio5ml) => Perfume(
      idPerfume: id,
      marca: 'MarcaTest',
      nombre: nombre,
      precio5ml: precio5ml,
    );

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('setAlias actualiza el estado sin afectar paso1Valido', () {
    final notifier = container.read(nuevaCotizacionProvider.notifier);
    notifier.setCelular('987654321');
    notifier.setAlias('perfutecalima');

    final state = container.read(nuevaCotizacionProvider);
    expect(state.alias, 'perfutecalima');
    expect(state.paso1Valido, isTrue); // alias no es requisito
  });

  test('reset limpia el alias', () {
    final notifier = container.read(nuevaCotizacionProvider.notifier);
    notifier.setAlias('perfutecalima');
    notifier.reset();
    expect(container.read(nuevaCotizacionProvider).alias, '');
  });

  test('setModo a alias limpia el celular ya escrito', () {
    final notifier = container.read(nuevaCotizacionProvider.notifier);
    notifier.setCelular('987654321');
    notifier.setModo('alias');

    final state = container.read(nuevaCotizacionProvider);
    expect(state.modo, 'alias');
    expect(state.celular, '');
  });

  test('setModo a celular limpia el alias ya escrito', () {
    final notifier = container.read(nuevaCotizacionProvider.notifier);
    notifier.setModo('alias');
    notifier.setAlias('perfutecalima');
    notifier.setModo('celular');

    final state = container.read(nuevaCotizacionProvider);
    expect(state.modo, 'celular');
    expect(state.alias, '');
  });

  test('paso1Valido en modo alias requiere alias no vacio, celular no importa', () {
    final notifier = container.read(nuevaCotizacionProvider.notifier);
    notifier.setModo('alias');
    expect(container.read(nuevaCotizacionProvider).paso1Valido, isFalse);
    notifier.setAlias('perfutecalima');
    expect(container.read(nuevaCotizacionProvider).paso1Valido, isTrue);
  });

  test('modo por defecto es celular', () {
    expect(container.read(nuevaCotizacionProvider).modo, 'celular');
  });

  test('irPaso sin cotizacion registrada no afecta la cesta', () {
    final notifier = container.read(nuevaCotizacionProvider.notifier);
    notifier.agregarItem(_perfume('1', 'A', 25.0), 5);
    notifier.irPaso(2);
    expect(container.read(nuevaCotizacionProvider).cesta, isNotEmpty);
  });

  test(
      'irPaso tras una cotizacion ya registrada limpia cesta/descuento/delivery '
      'pero conserva celular y alias', () {
    final notifier = container.read(nuevaCotizacionProvider.notifier);
    notifier.setCelular('987654321');
    notifier.agregarItem(_perfume('1', 'A', 25.0), 5);
    notifier.toggleDescuento();
    notifier.toggleDelivery();
    // Simula que la cotizacion ya se guardo (como despues de "Confirmar
    // cotizacion" sin tocar "Nueva cotizacion") — es el escenario del bug:
    // volver a navegar debe empezar una cotizacion nueva, no arrastrar
    // los perfumes/descuento de la anterior.
    notifier.state = notifier.state.copyWith(
      registrada: const CotizacionRegistrada(idCotizacion: 'C001'),
    );

    notifier.irPaso(2);

    final state = container.read(nuevaCotizacionProvider);
    expect(state.registrada, isNull);
    expect(state.cesta, isEmpty);
    expect(state.conDelivery, isFalse);
    expect(state.indicesConDescuento, isEmpty);
    expect(state.celular, '987654321');
    expect(state.paso, 2);
  });
}

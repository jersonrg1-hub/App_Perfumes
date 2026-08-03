import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfuteca/features/cotizaciones/providers/nueva_cotizacion_provider.dart';

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
}

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
}

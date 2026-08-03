import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfuteca/features/ventas/providers/nueva_venta_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('setAlias actualiza el estado', () {
    final notifier = container.read(nuevaVentaProvider.notifier);
    notifier.setAlias('perfutecalima');
    expect(container.read(nuevaVentaProvider).alias, 'perfutecalima');
  });

  test('reset limpia el alias', () {
    final notifier = container.read(nuevaVentaProvider.notifier);
    notifier.setAlias('perfutecalima');
    notifier.reset();
    expect(container.read(nuevaVentaProvider).alias, '');
  });
}

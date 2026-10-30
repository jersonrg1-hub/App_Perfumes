import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfuteca/features/cotizaciones/providers/nueva_cotizacion_provider.dart';
import 'package:perfuteca/models/perfume.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  NuevaCotizacionNotifier notifier() =>
      container.read(nuevaCotizacionProvider.notifier);
  NuevaCotizacionState state() => container.read(nuevaCotizacionProvider);

  void agregarPerfume() => notifier().agregarItem(
        const Perfume(
            idPerfume: 'P1', marca: 'M', nombre: 'N', precio5ml: 50),
        5,
      );

  test('por defecto sin delivery y monto 10', () {
    agregarPerfume();
    expect(state().conDelivery, isFalse);
    expect(state().montoDelivery, 10.0);
    expect(state().costoDelivery, 0);
    expect(state().totalConDelivery, 50.0);
  });

  test('toggleDelivery suma S/ 10 por defecto', () {
    agregarPerfume();
    notifier().toggleDelivery();
    expect(state().costoDelivery, 10.0);
    expect(state().totalConDelivery, 60.0);
  });

  test('setMontoDelivery(12) activa delivery y suma S/ 12', () {
    agregarPerfume();
    notifier().setMontoDelivery(12.0);
    expect(state().conDelivery, isTrue);
    expect(state().costoDelivery, 12.0);
    expect(state().totalConDelivery, 62.0);
  });

  test('apagar delivery conserva el monto elegido pero no lo suma', () {
    agregarPerfume();
    notifier().setMontoDelivery(12.0);
    notifier().toggleDelivery();
    expect(state().costoDelivery, 0);
    expect(state().totalConDelivery, 50.0);
    notifier().toggleDelivery();
    expect(state().costoDelivery, 12.0);
  });

  test('total guardado en Sheets nunca incluye delivery', () {
    agregarPerfume();
    notifier().setMontoDelivery(12.0);
    expect(state().total, 50.0);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/features/ventas/providers/ventas_provider.dart';
import 'package:perfuteca/features/ventas/screens/pendientes_screen.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/models/venta.dart';

VentaResponse _ventaDePrueba() => const VentaResponse(
      idCompra: 'V001',
      filaSheet: 2,
      fecha: '2026-06-18',
      comprador: 'María G.',
      celular: '987654321',
      idPerfume: '1',
      mlVendido: 5,
      precioCobrado: 45.0,
      metodoPago: 'Yape',
      tipoEnvio: 'Shalom',
      direccion: 'Jr. Test 123',
      distrito: 'Lima',
      estado: 'Pendiente',
    );

Widget _app() => ProviderScope(
      overrides: [
        pendientesProvider.overrideWith((ref) async => [_ventaDePrueba()]),
        perfumesMapProvider.overrideWith((ref) async => <String, Perfume>{}),
      ],
      child: const MaterialApp(home: Scaffold(body: PendientesScreen())),
    );

void main() {
  testWidgets('swipe derecha muestra dialogo de confirmar entrega, cancelar mantiene la card',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('#V001'), findsOneWidget);

    await tester.drag(find.text('#V001'), const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Confirmar entrega'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('#V001'), findsOneWidget);
  });

  testWidgets('en modo seleccion (long press) el swipe no dispara dialogo', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.longPress(find.text('#V001'));
    await tester.pumpAndSettle();

    await tester.drag(find.text('#V001'), const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Confirmar entrega'), findsNothing);
  });
}

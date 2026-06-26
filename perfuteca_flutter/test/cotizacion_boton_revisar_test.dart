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

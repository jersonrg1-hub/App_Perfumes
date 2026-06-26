import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfuteca/features/cotizaciones/widgets/cotizacion_convertir_card.dart';

void main() {
  testWidgets('EstadoPill muestra "Esperando" cuando no está aceptada',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: EstadoPill(aceptada: false)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Esperando'), findsOneWidget);
  });

  testWidgets('EstadoPill muestra "Aceptada" cuando está aceptada',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: EstadoPill(aceptada: true)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aceptada'), findsOneWidget);
  });
}

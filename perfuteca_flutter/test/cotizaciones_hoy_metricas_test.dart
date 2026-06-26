import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfuteca/features/ventas/screens/cotizaciones_hoy_screen.dart';

void main() {
  testWidgets('MetricasHoyGrid muestra 3 tarjetas separadas con valores finales correctos',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MetricasHoyGrid(total: 248.0, pendientes: 3, convertidas: 2),
        ),
      ),
    );

    // Deja correr el count-up hasta el final
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('metrica-total')), findsOneWidget);
    expect(find.byKey(const Key('metrica-pendientes')), findsOneWidget);
    expect(find.byKey(const Key('metrica-convertidas')), findsOneWidget);

    expect(find.text('S/ 248.00'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfuteca/features/cotizaciones/widgets/cotizacion_convertir_card.dart';

void main() {
  testWidgets('Chips invoca onSelect con la opción tocada',
      (tester) async {
    String? seleccionado;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Chips(
            opciones: const ['Shalom', 'Motorizado'],
            valor: 'Shalom',
            onSelect: (v) => seleccionado = v,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Motorizado'));
    await tester.pumpAndSettle();

    expect(seleccionado, 'Motorizado');
  });
}

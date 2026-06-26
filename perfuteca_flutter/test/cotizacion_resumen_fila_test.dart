import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfuteca/features/cotizaciones/widgets/cotizacion_convertir_card.dart';

void main() {
  testWidgets('ResumenFila muestra label y valor', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResumenFila('Cliente', 'Ana Torres'),
        ),
      ),
    );
    expect(find.text('CLIENTE'), findsOneWidget);
    expect(find.text('Ana Torres'), findsOneWidget);
  });

  testWidgets('ResumenFila muestra "—" cuando el valor está vacío',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ResumenFila('Distrito', '')),
      ),
    );
    expect(find.text('—'), findsOneWidget);
  });
}

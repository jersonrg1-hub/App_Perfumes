import 'package:flutter_test/flutter_test.dart';
import 'package:perfuteca/features/ventas/screens/cotizaciones_hoy_screen.dart';

void main() {
  group('clienteListoParaConfirmar', () {
    test('true cuando comprador, direccion y tipoEnvio estan completos', () {
      expect(
        clienteListoParaConfirmar(
          comprador: 'María G.',
          direccion: 'Jr. Test 123',
          tipoEnvio: 'Shalom',
        ),
        isTrue,
      );
    });

    test('false cuando falta direccion (solo espacios)', () {
      expect(
        clienteListoParaConfirmar(
          comprador: 'María G.',
          direccion: '   ',
          tipoEnvio: 'Shalom',
        ),
        isFalse,
      );
    });

    test('false cuando falta tipoEnvio', () {
      expect(
        clienteListoParaConfirmar(
          comprador: 'María G.',
          direccion: 'Jr. Test 123',
          tipoEnvio: '',
        ),
        isFalse,
      );
    });

    test('false cuando falta comprador', () {
      expect(
        clienteListoParaConfirmar(
          comprador: '',
          direccion: 'Jr. Test 123',
          tipoEnvio: 'Shalom',
        ),
        isFalse,
      );
    });
  });
}

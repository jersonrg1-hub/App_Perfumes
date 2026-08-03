import 'package:flutter_test/flutter_test.dart';
import 'package:perfuteca/core/utils/whatsapp_launcher.dart';

void main() {
  group('resolverDestinoWhatsApp', () {
    test('usa alias sin prefijo cuando esta presente', () {
      expect(
        resolverDestinoWhatsApp(celular: '987654321', alias: 'perfutecalima'),
        'perfutecalima',
      );
    });

    test('quita un @ inicial del alias', () {
      expect(
        resolverDestinoWhatsApp(celular: '987654321', alias: '@perfutecalima'),
        'perfutecalima',
      );
    });

    test('cae a celular con prefijo 51 cuando no hay alias', () {
      expect(
        resolverDestinoWhatsApp(celular: '987654321', alias: null),
        '51987654321',
      );
    });

    test('no duplica el prefijo 51 si el celular ya lo tiene', () {
      expect(
        resolverDestinoWhatsApp(celular: '51987654321', alias: null),
        '51987654321',
      );
    });

    test('alias vacio o solo espacios se trata como ausente', () {
      expect(
        resolverDestinoWhatsApp(celular: '987654321', alias: '   '),
        '51987654321',
      );
    });

    test('celular null y sin alias retorna string vacio (selector de chat)', () {
      expect(
        resolverDestinoWhatsApp(celular: null, alias: null),
        '',
      );
    });
  });

  group('lineaContacto', () {
    test('celular y alias juntos cuando hay alias', () {
      expect(
        lineaContacto('987654321', 'perfutecalima'),
        '987654321 (@perfutecalima)',
      );
    });

    test('normaliza el @ inicial del alias para no duplicarlo', () {
      expect(
        lineaContacto('987654321', '@perfutecalima'),
        '987654321 (@perfutecalima)',
      );
    });

    test('solo celular cuando no hay alias', () {
      expect(lineaContacto('987654321', null), '987654321');
    });

    test('solo celular cuando alias es string vacio', () {
      expect(lineaContacto('987654321', ''), '987654321');
    });
  });
}

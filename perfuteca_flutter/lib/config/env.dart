/// Configuración de entorno.
/// Pasar en tiempo de compilación:
///   flutter run  --dart-define=BASE_URL=https://... --dart-define=API_KEY=xxx
///   flutter build apk --dart-define=BASE_URL=... --dart-define=API_KEY=xxx
abstract class Env {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://app-perfuteca.onrender.com',
  );

  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: 'e9f169776a1ebc48498d3dd983f33aa08cdd6104b4eb8ed22268b8104d60227e',
  );

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout    = Duration(seconds: 15);

  static const int maxRetries = 2;
}

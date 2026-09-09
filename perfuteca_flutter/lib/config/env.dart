/// Configuración de entorno.
/// Pasar en tiempo de compilación:
///   flutter run  --dart-define=BASE_URL=https://... --dart-define=API_KEY=xxx
///   flutter build apk --dart-define=BASE_URL=... --dart-define=API_KEY=xxx
abstract class Env {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://app-perfuteca.onrender.com',
  );

  static const String apiKey = String.fromEnvironment('API_KEY');

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout    = Duration(seconds: 15);

  static const int maxRetries = 2;

  /// Detecta builds sin --dart-define=API_KEY (asserts se eliminan en release,
  /// solo protege debug/profile).
  static bool get hasApiKey {
    assert(apiKey.isNotEmpty, 'Falta --dart-define=API_KEY en el build');
    return apiKey.isNotEmpty;
  }
}

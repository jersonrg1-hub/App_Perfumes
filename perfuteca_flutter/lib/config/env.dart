/// Configuración de entorno.
/// Cambia baseUrl a tu URL de Render antes de compilar.
abstract class Env {
  /// URL base de la API en Render (sin trailing slash).
  /// Ejemplo: "https://perfuteca-api.onrender.com"
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://app-perfuteca.onrender.com',
  );

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout    = Duration(seconds: 30);

  /// Número de reintentos automáticos ante errores de red.
  static const int maxRetries = 2;
}

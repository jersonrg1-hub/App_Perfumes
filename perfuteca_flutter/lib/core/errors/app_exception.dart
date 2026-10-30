/// Jerarquía de errores de la app.
/// Cada capa lanza AppException; la UI decide cómo mostrarlos.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Error de red (sin internet, timeout, conexión rechazada).
class NetworkException extends AppException {
  const NetworkException([super.message = 'Sin conexión. Verifica tu internet.']);
}

/// El servidor respondió con un status >= 400.
class ServerException extends AppException {
  const ServerException(super.message, {this.statusCode});
  final int? statusCode;
}

/// Recurso no encontrado (404).
class NotFoundException extends AppException {
  const NotFoundException([super.message = 'No encontrado.']);
}

/// No autorizado (401) — API key inválida o ausente.
class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'No autorizado.']);
}

/// Fallo al parsear la respuesta JSON.
class ParseException extends AppException {
  const ParseException([super.message = 'Error al procesar la respuesta del servidor.']);
}

/// Error de validación local (formularios, etc.).
class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// Error desconocido / inesperado.
class UnknownException extends AppException {
  const UnknownException([super.message = 'Error inesperado. Intenta nuevamente.']);
}

/// Extrae un mensaje de usuario de cualquier error capturado.
/// AppException expone su .message; cualquier otro tipo usa [fallback]
/// (por defecto, e.toString()).
String appErrorMessage(Object e, [String? fallback]) =>
    e is AppException ? e.message : (fallback ?? e.toString());

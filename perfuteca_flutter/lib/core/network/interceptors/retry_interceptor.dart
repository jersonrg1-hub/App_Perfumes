import 'package:dio/dio.dart';
import 'package:perfuteca/config/env.dart';

/// Reintenta automáticamente ante errores de conexión y timeouts.
/// No reintenta errores 4xx (son errores del cliente, no transitorios).
class RetryInterceptor extends Interceptor {
  RetryInterceptor(this._dio);

  final Dio _dio;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final shouldRetry = _isRetryable(err);
    final attempt = (err.requestOptions.extra['_retryCount'] as int?) ?? 0;

    if (shouldRetry && attempt < Env.maxRetries) {
      err.requestOptions.extra['_retryCount'] = attempt + 1;
      await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      try {
        final response = await _dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (_) {}
    }
    handler.next(err);
  }

  // POST no se reintenta: crea recursos (venta, cotización) y no es
  // idempotente. Si el timeout ocurre porque el backend sigue escribiendo
  // en Google Sheets (lento), reintentar duplica el registro aunque la
  // escritura original sí haya terminado en el servidor.
  bool _isRetryable(DioException e) =>
      e.requestOptions.method.toUpperCase() != 'POST' &&
      (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError);
}

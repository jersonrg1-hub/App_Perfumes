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

  bool _isRetryable(DioException e) =>
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.connectionError;
}

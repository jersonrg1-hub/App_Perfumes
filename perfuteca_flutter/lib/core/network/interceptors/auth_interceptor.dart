import 'package:dio/dio.dart';

/// Inyecta X-API-Key en endpoints que lo requieren.
/// Actualmente solo ventas y cotizaciones necesitan autenticación.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._apiKey);

  final String _apiKey;

  static const _protectedPaths = ['/api/v1/ventas', '/api/v1/cotizaciones'];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final needsAuth = _protectedPaths.any((p) => options.path.startsWith(p));
    if (needsAuth && _apiKey.isNotEmpty) {
      options.headers['X-API-Key'] = _apiKey;
    }
    handler.next(options);
  }
}

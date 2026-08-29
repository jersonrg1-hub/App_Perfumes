import 'package:dio/dio.dart';

/// Inyecta X-API-Key en endpoints que lo requieren.
/// Protegidos: ventas, cotizaciones, estadisticas, catalogo/invalidar.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._apiKey);

  final String _apiKey;

  static const _protectedPaths = ['/api/v1/ventas', '/api/v1/cotizaciones', '/api/v1/estadisticas'];
  static const _protectedExact = ['/api/v1/catalogo/invalidar'];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final needsAuth = _protectedPaths.any((p) => options.path.startsWith(p)) ||
        _protectedExact.contains(options.path);
    if (needsAuth && _apiKey.isNotEmpty) {
      options.headers['X-API-Key'] = _apiKey;
    }
    handler.next(options);
  }
}

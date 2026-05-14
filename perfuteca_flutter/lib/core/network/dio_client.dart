import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/config/env.dart';
import 'package:perfuteca/core/errors/app_exception.dart';
import 'package:perfuteca/core/network/interceptors/auth_interceptor.dart';
import 'package:perfuteca/core/network/interceptors/logging_interceptor.dart';
import 'package:perfuteca/core/network/interceptors/retry_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.baseUrl,
      connectTimeout: Env.connectTimeout,
      receiveTimeout: Env.receiveTimeout,
      sendTimeout: Env.sendTimeout,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ),
  );

  dio.interceptors.addAll([
    LoggingInterceptor(),
    AuthInterceptor('e9f169776a1ebc48498d3dd983f33aa08cdd6104b4eb8ed22268b8104d60227e'),
    RetryInterceptor(dio),
  ]);

  return dio;
});

/// Convierte DioException en AppException tipada.
AppException mapDioError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.connectionError:
      return const NetworkException();
    case DioExceptionType.badResponse:
      final status = e.response?.statusCode;
      final detail = _extractDetail(e.response);
      if (status == 401) return UnauthorizedException(detail);
      if (status == 404) return NotFoundException(detail);
      return ServerException(detail, statusCode: status);
    default:
      return const UnknownException();
  }
}

String _extractDetail(Response? r) {
  if (r == null) return 'Error del servidor.';
  try {
    return (r.data as Map<String, dynamic>)['detail']?.toString() ??
        'Error ${r.statusCode}';
  } catch (_) {
    return 'Error ${r.statusCode ?? "desconocido"}';
  }
}

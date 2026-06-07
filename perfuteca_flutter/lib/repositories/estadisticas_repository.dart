import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/core/constants/api_constants.dart';
import 'package:perfuteca/core/errors/app_exception.dart';
import 'package:perfuteca/core/network/cache_config.dart';
import 'package:perfuteca/core/network/dio_client.dart';

final estadisticasRepositoryProvider = Provider<EstadisticasRepository>((ref) {
  return EstadisticasRepository(
    ref.watch(dioProvider),
    ref.watch(cacheHelperProvider),
  );
});

class EstadisticasRepository {
  EstadisticasRepository(this._dio, this._cache);
  final Dio         _dio;
  final CacheHelper _cache;

  Future<Map<String, dynamic>> getResumen() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiConstants.estadisticasResumen,
        options: _cache.cacheFor(const Duration(minutes: 2)),
      );
      return res.data!;
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (_) {
      throw const ParseException();
    }
  }

  Future<List<Map<String, dynamic>>> getClientes({
    int limit = 500,
    int offset = 0,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiConstants.estadisticasClientes,
        queryParameters: {'limit': limit, 'offset': offset},
        options: _cache.noCache,
      );
      return (res.data!['items'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (_) {
      throw const ParseException();
    }
  }
}

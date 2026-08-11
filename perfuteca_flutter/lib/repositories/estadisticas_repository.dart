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
        options: _cache.noCache,
      );
      return res.data!;
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (_) {
      throw const ParseException();
    }
  }

  Future<Map<String, dynamic>> getHistorico() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiConstants.estadisticasHistorico,
        options: _cache.noCache,
      );
      return res.data!;
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (_) {
      throw const ParseException();
    }
  }

  Future<Map<String, dynamic>> getClientesPagina({
    int limit = 500,
    int offset = 0,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiConstants.estadisticasClientes,
        queryParameters: {'limit': limit, 'offset': offset},
        options: _cache.noCache,
      );
      return res.data!;
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (_) {
      throw const ParseException();
    }
  }

  // Trae todas las páginas — el endpoint cappea a 500 por 'limit', así que
  // itera hasta agotar 'has_more' en vez de leer una sola página, de lo
  // contrario clientes con menor total_gastado (los que caen fuera de los
  // primeros 500, orden desc del backend) desaparecían de la lista/búsqueda.
  Future<List<Map<String, dynamic>>> getClientes() async {
    final clientes = <Map<String, dynamic>>[];
    var offset = 0;
    while (true) {
      final pagina = await getClientesPagina(limit: 500, offset: offset);
      final items  = (pagina['items'] as List).cast<Map<String, dynamic>>();
      clientes.addAll(items);
      if (pagina['has_more'] != true) break;
      offset += items.length;
    }
    return clientes;
  }
}

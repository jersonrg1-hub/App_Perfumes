import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/core/constants/api_constants.dart';
import 'package:perfuteca/core/errors/app_exception.dart';
import 'package:perfuteca/core/network/cache_config.dart';
import 'package:perfuteca/core/network/dio_client.dart';
import 'package:perfuteca/models/paginated.dart';
import 'package:perfuteca/models/perfume.dart';

final catalogoRepositoryProvider = Provider<CatalogoRepository>((ref) {
  return CatalogoRepository(
    ref.watch(dioProvider),
    ref.watch(cacheHelperProvider),
  );
});

class CatalogoRepository {
  CatalogoRepository(this._dio, this._cache);

  final Dio         _dio;
  final CacheHelper _cache;

  Future<Paginated<Perfume>> getCatalogo({
    int limit = 100,
    int offset = 0,
    bool bypassCache = false,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiConstants.catalogo,
        queryParameters: {'limit': limit, 'offset': offset},
        options: bypassCache
            ? _cache.noCache
            : _cache.cacheFor(const Duration(hours: 6)),
      );
      return Paginated.fromJson(res.data!, (e) => Perfume.fromJson(e as Map<String, dynamic>));
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (_) {
      throw const ParseException();
    }
  }

  Future<Paginated<Perfume>> buscar({
    String q = '',
    String? marca,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiConstants.catalogoBuscar,
        queryParameters: {
          'q': q,
          if (marca != null && marca.isNotEmpty) 'marca': marca,
          'limit': limit,
          'offset': offset,
        },
        options: _cache.cacheFor(const Duration(minutes: 30)),
      );
      return Paginated.fromJson(res.data!, (e) => Perfume.fromJson(e as Map<String, dynamic>));
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (_) {
      throw const ParseException();
    }
  }

  Future<List<String>> getMarcas() async {
    try {
      final res = await _dio.get<List<dynamic>>(
        ApiConstants.catalogoMarcas,
        options: _cache.cacheFor(const Duration(hours: 12)),
      );
      return res.data!.cast<String>();
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (_) {
      throw const ParseException();
    }
  }

  /// Invalida el cache de catálogo en el backend (30 min TTL) para forzar
  /// que la próxima lectura traiga datos frescos de Google Sheets.
  Future<void> invalidarCache() async {
    try {
      await _dio.post(ApiConstants.catalogoInvalidar);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Perfume> getDetalle(String idPerfume) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiConstants.catalogoDetalle(idPerfume),
        options: _cache.cacheFor(const Duration(hours: 1)),
      );
      return Perfume.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (_) {
      throw const ParseException();
    }
  }
}

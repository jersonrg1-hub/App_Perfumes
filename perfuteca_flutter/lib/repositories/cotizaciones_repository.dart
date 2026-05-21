import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/core/constants/api_constants.dart';
import 'package:perfuteca/core/errors/app_exception.dart';
import 'package:perfuteca/core/network/cache_config.dart';
import 'package:perfuteca/core/network/dio_client.dart';
import 'package:perfuteca/models/cotizacion.dart';
import 'package:perfuteca/models/paginated.dart';

final cotizacionesRepositoryProvider = Provider<CotizacionesRepository>((ref) {
  return CotizacionesRepository(
    ref.watch(dioProvider),
    ref.watch(cacheHelperProvider),
  );
});

class CotizacionesRepository {
  CotizacionesRepository(this._dio, this._cache);
  final Dio         _dio;
  final CacheHelper _cache;

  Future<Paginated<CotizacionResponse>> getCotizaciones({
    int limit = 100,
    int offset = 0,
    String? estado,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiConstants.cotizaciones,
        queryParameters: {
          'limit':  limit,
          'offset': offset,
          if (estado != null) 'estado': estado,
        },
        options: _cache.cacheFor(const Duration(minutes: 3)),
      );
      return Paginated.fromJson(
        res.data!,
        (e) => CotizacionResponse.fromJson(e as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (_) {
      throw const ParseException();
    }
  }

  Future<void> actualizarEstado({
    required String idCotizacion,
    required String nuevoEstado,
  }) async {
    try {
      await _dio.put<dynamic>(
        '${ApiConstants.cotizaciones}$idCotizacion',
        data: {'nuevo_estado': nuevoEstado},
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (_) {
      throw const ParseException();
    }
  }

  Future<CotizacionRegistrada> guardarCotizacion({
    required String celular,
    required List<Map<String, dynamic>> items,
    required double total,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiConstants.cotizaciones,
        data: {
          'celular': celular,
          'items':   items,
          'total':   total,
        },
      );
      return CotizacionRegistrada.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (_) {
      throw const ParseException();
    }
  }
}

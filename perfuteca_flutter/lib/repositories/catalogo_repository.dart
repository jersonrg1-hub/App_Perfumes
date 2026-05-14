import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/core/constants/api_constants.dart';
import 'package:perfuteca/core/errors/app_exception.dart';
import 'package:perfuteca/core/network/dio_client.dart';
import 'package:perfuteca/models/paginated.dart';
import 'package:perfuteca/models/perfume.dart';

final catalogoRepositoryProvider = Provider<CatalogoRepository>((ref) {
  return CatalogoRepository(ref.watch(dioProvider));
});

class CatalogoRepository {
  CatalogoRepository(this._dio);

  final Dio _dio;

  Future<Paginated<Perfume>> getCatalogo({
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiConstants.catalogo,
        queryParameters: {'limit': limit, 'offset': offset},
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
      final res = await _dio.get<List<dynamic>>(ApiConstants.catalogoMarcas);
      return res.data!.cast<String>();
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (_) {
      throw const ParseException();
    }
  }

  Future<Perfume> getDetalle(String idPerfume) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiConstants.catalogoDetalle(idPerfume),
      );
      return Perfume.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (_) {
      throw const ParseException();
    }
  }
}

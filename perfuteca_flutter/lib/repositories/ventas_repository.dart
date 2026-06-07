import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/core/constants/api_constants.dart';
import 'package:perfuteca/core/errors/app_exception.dart';
import 'package:perfuteca/core/network/cache_config.dart';
import 'package:perfuteca/core/network/dio_client.dart';
import 'package:perfuteca/models/paginated.dart';
import 'package:perfuteca/models/venta.dart';

final ventasRepositoryProvider = Provider<VentasRepository>((ref) {
  return VentasRepository(
    ref.watch(dioProvider),
    ref.watch(cacheHelperProvider),
  );
});

class VentasRepository {
  VentasRepository(this._dio, this._cache);
  final Dio         _dio;
  final CacheHelper _cache;

  // Historial: 5 min de caché para stats; bypassCache=true para vistas que
  // deben reflejar cambios de estado de inmediato (ej: tab historial).
  Future<Paginated<VentaResponse>> getVentas({
    int limit = 50,
    int offset = 0,
    String? estado,
    bool bypassCache = false,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiConstants.ventas,
        queryParameters: {
          'limit': limit,
          'offset': offset,
          if (estado != null) 'estado': estado,
        },
        options: bypassCache
            ? _cache.noCache
            : _cache.cacheFor(const Duration(minutes: 5)),
      );
      return Paginated.fromJson(
        res.data!,
        (e) => VentaResponse.fromJson(e as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (_) {
      throw const ParseException();
    }
  }

  // Pendientes: siempre frescos — sin caché
  Future<List<VentaResponse>> getPendientes() async {
    try {
      final res = await _dio.get<List<dynamic>>(
        ApiConstants.ventasPendientes,
        options: _cache.noCache,
      );
      return res.data!
          .map((e) => VentaResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (_) {
      throw const ParseException();
    }
  }

  Future<ClientePrevio?> getClientePrevio(String celular) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiConstants.ventasCliente(celular),
      );
      final data = res.data!;
      if (data['resumen'] == null) return null;
      return ClientePrevio.fromJson(data['resumen'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (_) {
      throw const ParseException();
    }
  }

  Future<VentaRegistrada> registrarVenta({
    required String comprador,
    required String celular,
    required String direccion,
    required String tipoEnvio,
    required String fecha,
    required List<Map<String, dynamic>> items,
    String distrito = '',
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiConstants.ventas,
        data: {
          'comprador':  comprador,
          'celular':    celular,
          'direccion':  direccion,
          if (distrito.isNotEmpty) 'distrito': distrito,
          'tipo_envio': tipoEnvio,
          'fecha':      fecha,
          'items':      items,
        },
      );
      return VentaRegistrada.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (_) {
      throw const ParseException();
    }
  }

  Future<void> actualizarEstadoOrden({
    required String idVenta,
    required String nuevoEstado,
    required List<int> filasSheet,
  }) async {
    try {
      await Future.wait(
        filasSheet.map((fila) => _dio.put<dynamic>(
          ApiConstants.ventaEstado(idVenta),
          data: {'nuevo_estado': nuevoEstado, 'fila_sheet': fila},
        )),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

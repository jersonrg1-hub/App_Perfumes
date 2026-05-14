import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/core/constants/api_constants.dart';
import 'package:perfuteca/core/errors/app_exception.dart';
import 'package:perfuteca/core/network/dio_client.dart';
import 'package:perfuteca/models/paginated.dart';
import 'package:perfuteca/models/venta.dart';

final ventasRepositoryProvider = Provider<VentasRepository>((ref) {
  return VentasRepository(ref.watch(dioProvider));
});

class VentasRepository {
  VentasRepository(this._dio);
  final Dio _dio;

  Future<Paginated<VentaResponse>> getVentas({
    int limit = 50,
    int offset = 0,
    String? estado,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiConstants.ventas,
        queryParameters: {
          'limit': limit,
          'offset': offset,
          if (estado != null) 'estado': estado,
        },
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

  Future<List<VentaResponse>> getPendientes() async {
    try {
      final res = await _dio.get<List<dynamic>>(
        '${ApiConstants.ventas}pendientes',
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
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiConstants.ventas,
        data: {
          'comprador':  comprador,
          'celular':    celular,
          'direccion':  direccion,
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

  // Actualiza el estado de todas las filas de una orden (una venta puede tener varios ítems)
  Future<void> actualizarEstadoOrden({
    required String idVenta,
    required String nuevoEstado,
    required List<int> filasSheet,
  }) async {
    try {
      for (final fila in filasSheet) {
        await _dio.put<dynamic>(
          ApiConstants.ventaEstado(idVenta),
          data: {'nuevo_estado': nuevoEstado, 'fila_sheet': fila},
        );
      }
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

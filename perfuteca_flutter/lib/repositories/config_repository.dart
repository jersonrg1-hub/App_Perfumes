import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/core/constants/api_constants.dart';
import 'package:perfuteca/core/errors/app_exception.dart';
import 'package:perfuteca/core/network/dio_client.dart';
import 'package:perfuteca/models/app_config_model.dart';

final configRepositoryProvider = Provider<ConfigRepository>((ref) {
  return ConfigRepository(ref.watch(dioProvider));
});

// Config del backend (umbrales de stock, métodos de pago, etc.) — una sola
// llamada por sesión. Si falla (sin red al arrancar), cae a defaults locales
// para no romper la UI.
final appConfigProvider = FutureProvider<AppConfigModel>((ref) async {
  ref.keepAlive();
  try {
    return await ref.watch(configRepositoryProvider).getConfig();
  } catch (_) {
    return AppConfigModel.defaults();
  }
});

class ConfigRepository {
  ConfigRepository(this._dio);

  final Dio _dio;

  Future<AppConfigModel> getConfig() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(ApiConstants.config);
      return AppConfigModel.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (_) {
      throw const ParseException();
    }
  }
}

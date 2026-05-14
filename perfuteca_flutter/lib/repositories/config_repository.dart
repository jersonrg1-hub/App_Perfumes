import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/core/constants/api_constants.dart';
import 'package:perfuteca/core/errors/app_exception.dart';
import 'package:perfuteca/core/network/dio_client.dart';
import 'package:perfuteca/models/app_config_model.dart';

final configRepositoryProvider = Provider<ConfigRepository>((ref) {
  return ConfigRepository(ref.watch(dioProvider));
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

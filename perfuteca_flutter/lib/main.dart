import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:perfuteca/app.dart';
import 'package:perfuteca/config/env.dart';
import 'package:perfuteca/core/constants/api_constants.dart';
import 'package:perfuteca/core/network/cache_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Despierta Render en segundo plano mientras carga la UI
  unawaited(_warmUpApi());

  // Necesario para DateFormat con patrones en español (ej. "Martes 18 de Agosto")
  await initializeDateFormatting('es');

  final cacheDir = await getApplicationDocumentsDirectory();

  runApp(
    ProviderScope(
      overrides: [
        cacheDirPathProvider.overrideWithValue(cacheDir.path),
      ],
      child: const PerfutecaApp(),
    ),
  );
}

// Ping silencioso al API para que Render despierte antes de que el usuario
// llegue a la primera pantalla de datos.
Future<void> _warmUpApi() async {
  try {
    await Dio().get<dynamic>(
      '${Env.baseUrl}${ApiConstants.health}',
      options: Options(
        sendTimeout:    const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Accept': 'application/json'},
      ),
    );
  } catch (_) {
    // Silencioso — si falla no importa, el resto de la app maneja sus errores
  }
}

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Overridden en main() con la ruta real del dispositivo.
final cacheDirPathProvider = Provider<String>(
  (ref) => throw UnimplementedError('cacheDirPathProvider must be overridden'),
);

final cacheStoreProvider = Provider<CacheStore>((ref) {
  final dir = ref.watch(cacheDirPathProvider);
  return FileCacheStore('$dir/api_cache');
});

// ── Helper: envuelve el store para generar Options por TTL ────────────────────

class CacheHelper {
  const CacheHelper(this._store);
  final CacheStore _store;

  // Usa caché si está vigente; si expiró o falla la red, usa la versión guardada.
  Options cacheFor(Duration maxStale) => CacheOptions(
    store:                _store,
    policy:               CachePolicy.forceCache,
    hitCacheOnErrorExcept: [401, 403],
    maxStale:             maxStale,
    priority:             CachePriority.normal,
  ).toOptions();

  // Nunca guarda ni usa caché — para endpoints que deben estar siempre frescos.
  Options get noCache => CacheOptions(
    store:  _store,
    policy: CachePolicy.noCache,
  ).toOptions();
}

final cacheHelperProvider = Provider<CacheHelper>((ref) {
  return CacheHelper(ref.watch(cacheStoreProvider));
});

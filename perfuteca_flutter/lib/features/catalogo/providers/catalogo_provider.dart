import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/repositories/catalogo_repository.dart';

// ── Estado del catálogo con infinite scroll ───────────────────────────────────

class CatalogoState {
  const CatalogoState({
    this.perfumes = const [],
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
  });

  final List<Perfume> perfumes;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;
  final bool hasMore;

  CatalogoState copyWith({
    List<Perfume>? perfumes,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
    bool? hasMore,
  }) => CatalogoState(
    perfumes:      perfumes      ?? this.perfumes,
    total:         total         ?? this.total,
    isLoading:     isLoading     ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    error:         clearError ? null : (error ?? this.error),
    hasMore:       hasMore       ?? this.hasMore,
  );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class CatalogoNotifier extends Notifier<CatalogoState> {
  static const _pageSize = 50;

  @override
  CatalogoState build() {
    // Carga inicial al construirse el provider.
    Future.microtask(load);
    return const CatalogoState(isLoading: true);
  }

  CatalogoRepository get _repo => ref.read(catalogoRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await _repo.getCatalogo(limit: _pageSize, offset: 0, bypassCache: true);
      state = CatalogoState(
        perfumes: page.items,
        total:    page.total,
        hasMore:  page.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      // bypassCache: true — igual que load(). Sin esto, páginas 2+ quedaban
      // cacheadas 6h (cache_config.dart), así que precio/stock editados en
      // un perfume fuera de la primera página podían tardar hasta 6h en
      // reflejarse al armar o convertir una cotización.
      final page = await _repo.getCatalogo(
        limit:  _pageSize,
        offset: state.perfumes.length,
        bypassCache: true,
      );
      state = state.copyWith(
        perfumes:      [...state.perfumes, ...page.items],
        total:         page.total,
        hasMore:       page.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  Future<void> refresh() => load();

  /// Carga todas las páginas restantes (usado por selectores que necesitan
  /// el catálogo completo para buscar/filtrar, ej. nueva cotización).
  Future<void> loadAll() async {
    while (state.isLoading || state.isLoadingMore) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    // loadMore() no baja hasMore cuando falla — sin este chequeo, un error
    // de red (offline, backend caído) deja hasMore=true para siempre y este
    // while reintenta sin límite ni espera, martillando el backend.
    while (state.hasMore && state.error == null) {
      await loadMore();
    }
  }
}

final catalogoProvider = NotifierProvider<CatalogoNotifier, CatalogoState>(
  CatalogoNotifier.new,
);

// ── Marcas ────────────────────────────────────────────────────────────────────

final marcasProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(catalogoRepositoryProvider).getMarcas();
});

// ── Detalle de perfume (por ID) ───────────────────────────────────────────────

final perfumeDetalleProvider = FutureProvider.family<Perfume, String>((ref, id) {
  return ref.watch(catalogoRepositoryProvider).getDetalle(id);
});

// ── Mapa completo id → Perfume (para lookup en ventas/historial) ──────────────
// Normaliza el id a entero ("10.0" → "10") para que coincida con el id de ventas.

String normalizeId(String id) {
  final n = double.tryParse(id);
  return n != null ? n.toInt().toString() : id;
}

final perfumesMapProvider = FutureProvider<Map<String, Perfume>>((ref) async {
  final repo = ref.watch(catalogoRepositoryProvider);
  // bypassCache: true — el cache HTTP de 6h (cache_config.dart) puede quedar
  // desactualizado si se agregan perfumes nuevos al catálogo; sin esto,
  // perfumes con ID reciente no resuelven nombre en ventas/estadísticas
  // hasta que expire el cache.
  final page = await repo.getCatalogo(limit: 500, bypassCache: true);
  return {
    for (final p in page.items) normalizeId(p.idPerfume): p,
  };
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/features/estadisticas/providers/estadisticas_provider.dart';
import 'package:perfuteca/models/venta.dart';
import 'package:perfuteca/repositories/ventas_repository.dart';

// Permite que widgets hijos cambien el tab activo de VentasScreen
final ventasTabProvider = StateProvider<int>((ref) => 0);

// ── Historial de ventas (paginado, siempre fresco) ────────────────────────────

class HistorialState {
  const HistorialState({
    this.ventas = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
  });

  final List<VentaResponse> ventas;
  final bool                isLoading;
  final bool                isLoadingMore;
  final Object?             error;
  final bool                hasMore;

  HistorialState copyWith({
    List<VentaResponse>? ventas,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
    bool? hasMore,
  }) => HistorialState(
    ventas:        ventas        ?? this.ventas,
    isLoading:     isLoading     ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    error:         clearError ? null : (error ?? this.error),
    hasMore:       hasMore       ?? this.hasMore,
  );
}

class HistorialNotifier extends Notifier<HistorialState> {
  static const _pageSize = 100;

  // Offset real ya consumido del servidor — distinto de state.ventas.length
  // porque el dedup por filaSheet puede descartar filas, y si se pagina por
  // el largo de la lista deduplicada el offset queda corrido para siempre.
  int _offset = 0;

  @override
  HistorialState build() {
    Future.microtask(load);
    return const HistorialState(isLoading: true);
  }

  VentasRepository get _repo => ref.read(ventasRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await _repo.getVentas(
        limit: _pageSize, offset: 0, bypassCache: true,
      );
      _offset = page.items.length;
      state = HistorialState(ventas: page.items, hasMore: page.hasMore);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _repo.getVentas(
        limit: _pageSize, offset: _offset, bypassCache: true,
      );
      _offset += page.items.length;
      final filasExistentes = state.ventas.map((v) => v.filaSheet).toSet();
      final nuevos = page.items.where((v) => !filasExistentes.contains(v.filaSheet));
      state = state.copyWith(
        ventas:        [...state.ventas, ...nuevos],
        hasMore:       page.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  Future<void> refresh() => load();
}

final historialProvider =
    NotifierProvider<HistorialNotifier, HistorialState>(HistorialNotifier.new);

// ── Ventas pendientes ─────────────────────────────────────────────────────────

final pendientesProvider = FutureProvider<List<VentaResponse>>((ref) {
  return ref.watch(ventasRepositoryProvider).getPendientes();
});

// ── Actualizar estado de venta ────────────────────────────────────────────────

class EstadoVentaNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> actualizar({
    required String  idVenta,
    required String  nuevoEstado,
    required List<int> filasSheet,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(ventasRepositoryProvider).actualizarEstadoOrden(
        idVenta:     idVenta,
        nuevoEstado: nuevoEstado,
        filasSheet:  filasSheet,
      );
      // Invalida cache para refrescar listas
      ref.invalidate(pendientesProvider);
      ref.invalidate(historialProvider);
      ref.invalidate(resumenBackendProvider);
      ref.invalidate(ventasParaStatsProvider);
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }
}

final estadoVentaProvider =
    AsyncNotifierProvider<EstadoVentaNotifier, void>(EstadoVentaNotifier.new);

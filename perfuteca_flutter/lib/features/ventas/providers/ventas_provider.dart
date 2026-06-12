import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/features/estadisticas/providers/estadisticas_provider.dart';
import 'package:perfuteca/models/venta.dart';
import 'package:perfuteca/repositories/ventas_repository.dart';

// Permite que widgets hijos cambien el tab activo de VentasScreen
final ventasTabProvider = StateProvider<int>((ref) => 0);

// ── Historial de ventas ───────────────────────────────────────────────────────

final historialProvider = FutureProvider<List<VentaResponse>>((ref) async {
  final page = await ref.watch(ventasRepositoryProvider).getVentas(
    limit: 500,
    bypassCache: true,
  );
  return page.items;
});

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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/repositories/catalogo_repository.dart';

// ── Query y filtro de marca activos ───────────────────────────────────────────

final busquedaQueryProvider = StateProvider<String>((ref) => '');
final busquedaMarcaProvider = StateProvider<String?>((ref) => null);

// ── Resultados de búsqueda (reactivos al query + marca) ───────────────────────

final busquedaResultadosProvider = FutureProvider.autoDispose<List<Perfume>>((ref) async {
  final q     = ref.watch(busquedaQueryProvider);
  final marca = ref.watch(busquedaMarcaProvider);

  // No busca si no hay query ni filtro.
  if (q.trim().isEmpty && (marca == null || marca.isEmpty)) return [];

  final page = await ref.watch(catalogoRepositoryProvider).buscar(
    q:     q.trim(),
    marca: marca,
    limit: 100,
  );
  return page.items;
});

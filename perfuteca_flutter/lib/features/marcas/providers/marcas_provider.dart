import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/repositories/catalogo_repository.dart';

// Marca seleccionada en la pantalla de marcas.
final marcaSeleccionadaProvider = StateProvider<String?>((ref) => null);

// Perfumes filtrados por la marca seleccionada.
final perfumesPorMarcaProvider = FutureProvider.autoDispose.family<List<Perfume>, String>(
  (ref, marca) async {
    final page = await ref.watch(catalogoRepositoryProvider).buscar(
      marca: marca,
      limit: 200,
    );
    return page.items;
  },
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nota olfativa actualmente seleccionada en el tab de Notas.
/// Se expone como provider público para que otras pantallas (ej. detalle)
/// puedan preseleccionar una nota y luego navegar al tab.
final notaSeleccionadaProvider = StateProvider<String?>((ref) => null);

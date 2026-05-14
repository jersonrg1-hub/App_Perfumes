import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/models/cotizacion.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/models/venta.dart';
import 'package:perfuteca/repositories/cotizaciones_repository.dart';

class NuevaCotizacionState {
  const NuevaCotizacionState({
    this.paso        = 1,
    this.celular     = '',
    this.cesta       = const [],
    this.conDelivery = false,
    this.registrando = false,
    this.registrada,
    this.error,
  });

  final int                   paso;
  final String                celular;
  final List<ItemCesta>       cesta;
  final bool                  conDelivery;
  final bool                  registrando;
  final CotizacionRegistrada? registrada;
  final String?               error;

  static const double costoDelivery = 10.0;

  double get subtotal => cesta.fold(0.0, (s, i) => s + i.precio);
  double get total    => subtotal; // lo que se guarda en Sheets (sin delivery)
  double get totalConDelivery => subtotal + (conDelivery ? costoDelivery : 0);

  bool get paso1Valido => celular.length == 9;
  bool get cestaValida => cesta.isNotEmpty;

  NuevaCotizacionState copyWith({
    int?                  paso,
    String?               celular,
    List<ItemCesta>?      cesta,
    bool?                 conDelivery,
    bool?                 registrando,
    CotizacionRegistrada? registrada,
    String?               error,
    bool                  clearError      = false,
    bool                  clearRegistrada = false,
  }) => NuevaCotizacionState(
    paso:        paso        ?? this.paso,
    celular:     celular     ?? this.celular,
    cesta:       cesta       ?? this.cesta,
    conDelivery: conDelivery ?? this.conDelivery,
    registrando: registrando ?? this.registrando,
    registrada:  clearRegistrada ? null : (registrada ?? this.registrada),
    error:       clearError  ? null : (error       ?? this.error),
  );
}

class NuevaCotizacionNotifier extends Notifier<NuevaCotizacionState> {
  @override
  NuevaCotizacionState build() => const NuevaCotizacionState();

  CotizacionesRepository get _repo =>
      ref.read(cotizacionesRepositoryProvider);

  void setCelular(String v)    => state = state.copyWith(celular: v);
  void irPaso(int p)           => state = state.copyWith(paso: p, clearError: true);
  void toggleDelivery()        => state = state.copyWith(conDelivery: !state.conDelivery);

  void agregarItem(Perfume perfume, int ml) {
    final precio = switch (ml) {
      2  => perfume.precio2ml,
      5  => perfume.precio5ml,
      10 => perfume.precio10ml,
      _  => null,
    };
    if (precio == null) return;

    final item = ItemCesta(
      perfume: perfume,
      ml:      ml,
      precio:  precio,
      metodo:  'Cotización',
    );
    state = state.copyWith(cesta: [...state.cesta, item]);
  }

  void quitarItem(int index) {
    final nueva = List<ItemCesta>.from(state.cesta)..removeAt(index);
    state = state.copyWith(cesta: nueva);
  }

  Future<void> guardar() async {
    state = state.copyWith(registrando: true, clearError: true);
    try {
      final registrada = await _repo.guardarCotizacion(
        celular: state.celular,
        items:   state.cesta.map((i) => i.toApiMap()).toList(),
        total:   state.total,
      );
      state = state.copyWith(
        registrando: false,
        registrada:  registrada,
        paso:        3,
      );
    } catch (e) {
      state = state.copyWith(registrando: false, error: e.toString());
    }
  }

  void reset() => state = const NuevaCotizacionState();
}

final nuevaCotizacionProvider =
    NotifierProvider<NuevaCotizacionNotifier, NuevaCotizacionState>(
        NuevaCotizacionNotifier.new);

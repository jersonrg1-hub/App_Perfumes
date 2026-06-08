import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/models/cotizacion.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/models/venta.dart';
import 'package:perfuteca/repositories/cotizaciones_repository.dart';

double _round10(double p) => (p * 10).round() / 10.0;

class NuevaCotizacionState {
  const NuevaCotizacionState({
    this.paso         = 1,
    this.celular      = '',
    this.cesta        = const [],
    this.conDelivery  = false,
    this.conDescuento = false,
    this.registrando  = false,
    this.registrada,
    this.error,
  });

  final int                   paso;
  final String                celular;
  final List<ItemCesta>       cesta;
  final bool                  conDelivery;
  final bool                  conDescuento;
  final bool                  registrando;
  final CotizacionRegistrada? registrada;
  final String?               error;

  static const double costoDelivery = 10.0;

  // Precio efectivo de un item según descuento
  double precioEfectivo(double precio) =>
      conDescuento ? _round10(precio * 0.90) : precio;

  // Subtotal SIN descuento (precios originales)
  double get subtotalOriginal => cesta.fold(0.0, (s, i) => s + i.precio);

  // Subtotal CON descuento aplicado por item
  double get subtotalDescuento =>
      cesta.fold(0.0, (s, i) => s + precioEfectivo(i.precio));

  // Ahorro total = diferencia entre subtotales
  double get ahorro => subtotalOriginal - subtotalDescuento;

  // Backward-compat: subtotal = working subtotal (discounted when applicable)
  double get subtotal => subtotalDescuento;

  // lo que se guarda en Sheets (sin delivery)
  double get total => subtotalDescuento;

  // Backward-compat: totalConDelivery uses discounted base
  double get totalConDelivery => subtotalDescuento + (conDelivery ? costoDelivery : 0);

  bool get paso1Valido => celular.length == 9;
  bool get cestaValida => cesta.isNotEmpty;

  NuevaCotizacionState copyWith({
    int?                  paso,
    String?               celular,
    List<ItemCesta>?      cesta,
    bool?                 conDelivery,
    bool?                 conDescuento,
    bool?                 registrando,
    CotizacionRegistrada? registrada,
    String?               error,
    bool                  clearError      = false,
    bool                  clearRegistrada = false,
  }) => NuevaCotizacionState(
    paso:         paso         ?? this.paso,
    celular:      celular      ?? this.celular,
    cesta:        cesta        ?? this.cesta,
    conDelivery:  conDelivery  ?? this.conDelivery,
    conDescuento: conDescuento ?? this.conDescuento,
    registrando:  registrando  ?? this.registrando,
    registrada:   clearRegistrada ? null : (registrada ?? this.registrada),
    error:        clearError   ? null : (error        ?? this.error),
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
  void toggleDescuento()       => state = state.copyWith(conDescuento: !state.conDescuento);

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
        items:   state.cesta.map((i) => {
          ...i.toApiMap(),
          'precio': state.precioEfectivo(i.precio),
        }).toList(),
        total:   state.subtotalDescuento,
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

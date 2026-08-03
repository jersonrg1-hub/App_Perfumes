import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/models/cotizacion.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/models/venta.dart';
import 'package:perfuteca/repositories/cotizaciones_repository.dart';

double _round10(double p) => (p * 10).round() / 10.0;

class NuevaCotizacionState {
  const NuevaCotizacionState({
    this.paso                = 1,
    this.celular             = '',
    this.alias               = '',
    this.cesta               = const [],
    this.conDelivery         = false,
    this.indicesConDescuento = const {},
    this.registrando         = false,
    this.registrada,
    this.error,
  });

  final int                   paso;
  final String                celular;
  final String                alias;
  final List<ItemCesta>       cesta;
  final bool                  conDelivery;
  final Set<int>               indicesConDescuento;
  final bool                  registrando;
  final CotizacionRegistrada? registrada;
  final String?               error;

  static const double costoDelivery = 10.0;

  // True solo si TODOS los items de la cesta tienen descuento — estado del switch "seleccionar todos"
  bool get conDescuento =>
      cesta.isNotEmpty && indicesConDescuento.length == cesta.length;

  // True si AL MENOS un item tiene descuento (parcial o total)
  bool get algunDescuento => indicesConDescuento.isNotEmpty;

  bool itemConDescuento(int index) => indicesConDescuento.contains(index);

  // Precio efectivo de un item según si ESE item tiene descuento
  double precioEfectivoIndex(int index, double precio) =>
      itemConDescuento(index) ? _round10(precio * 0.90) : precio;

  // Subtotal SIN descuento (precios originales)
  double get subtotalOriginal => cesta.fold(0.0, (s, i) => s + i.precio);

  // Subtotal CON descuento aplicado solo a los items seleccionados
  double get subtotalDescuento => cesta.asMap().entries.fold(
      0.0, (s, e) => s + precioEfectivoIndex(e.key, e.value.precio));

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
    String?               alias,
    List<ItemCesta>?      cesta,
    bool?                 conDelivery,
    Set<int>?             indicesConDescuento,
    bool?                 registrando,
    CotizacionRegistrada? registrada,
    String?               error,
    bool                  clearError      = false,
    bool                  clearRegistrada = false,
  }) => NuevaCotizacionState(
    paso:                paso                ?? this.paso,
    celular:             celular             ?? this.celular,
    alias:               alias               ?? this.alias,
    cesta:               cesta               ?? this.cesta,
    conDelivery:         conDelivery         ?? this.conDelivery,
    indicesConDescuento: indicesConDescuento ?? this.indicesConDescuento,
    registrando:         registrando         ?? this.registrando,
    registrada:          clearRegistrada ? null : (registrada ?? this.registrada),
    error:               clearError   ? null : (error        ?? this.error),
  );
}

class NuevaCotizacionNotifier extends Notifier<NuevaCotizacionState> {
  @override
  NuevaCotizacionState build() => const NuevaCotizacionState();

  CotizacionesRepository get _repo =>
      ref.read(cotizacionesRepositoryProvider);

  void setCelular(String v)    => state = state.copyWith(celular: v);
  void setAlias(String v)      => state = state.copyWith(alias: v);
  void irPaso(int p)           => state = state.copyWith(paso: p, clearError: true);
  void toggleDelivery()        => state = state.copyWith(conDelivery: !state.conDelivery);

  // Shortcut "seleccionar todos": si ya estan todos seleccionados, limpia; si no, selecciona todos
  void toggleDescuento() {
    if (state.conDescuento) {
      state = state.copyWith(indicesConDescuento: {});
    } else {
      state = state.copyWith(
        indicesConDescuento: {for (var i = 0; i < state.cesta.length; i++) i},
      );
    }
  }

  void toggleItemDescuento(int index) {
    final nuevos = Set<int>.from(state.indicesConDescuento);
    if (nuevos.contains(index)) {
      nuevos.remove(index);
    } else {
      nuevos.add(index);
    }
    state = state.copyWith(indicesConDescuento: nuevos);
  }

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
    final nuevaCesta = List<ItemCesta>.from(state.cesta)..removeAt(index);
    final nuevosIndices = state.indicesConDescuento
        .where((i) => i != index)
        .map((i) => i > index ? i - 1 : i)
        .toSet();
    state = state.copyWith(cesta: nuevaCesta, indicesConDescuento: nuevosIndices);
  }

  Future<void> guardar() async {
    state = state.copyWith(registrando: true, clearError: true);
    try {
      final registrada = await _repo.guardarCotizacion(
        celular: state.celular,
        alias:   state.alias,
        items:   state.cesta.asMap().entries.map((e) =>
            e.value.toApiMap(conDescuento: state.itemConDescuento(e.key))).toList(),
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

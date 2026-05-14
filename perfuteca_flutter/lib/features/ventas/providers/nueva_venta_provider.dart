import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/models/venta.dart';
import 'package:perfuteca/repositories/ventas_repository.dart';

// ── Estado del wizard de nueva venta ─────────────────────────────────────────

class NuevaVentaState {
  const NuevaVentaState({
    this.paso           = 1,
    this.comprador      = '',
    this.celular        = '',
    this.direccion      = '',
    this.tipoEnvio      = '',
    this.metodoPago     = 'Yape',
    this.fecha          = '',
    this.cesta          = const [],
    this.clientePrevio,
    this.buscandoCliente = false,
    this.registrando     = false,
    this.ventaRegistrada,
    this.error,
  });

  final int               paso;
  final String            comprador;
  final String            celular;
  final String            direccion;
  final String            tipoEnvio;
  final String            metodoPago;
  final String            fecha;
  final List<ItemCesta>   cesta;
  final ClientePrevio?    clientePrevio;
  final bool              buscandoCliente;
  final bool              registrando;
  final VentaRegistrada?  ventaRegistrada;
  final String?           error;

  double get total => cesta.fold(0, (s, i) => s + i.subtotal);

  bool get paso1Valido =>
      comprador.trim().isNotEmpty &&
      celular.length == 9 &&
      direccion.trim().isNotEmpty &&
      tipoEnvio.isNotEmpty &&
      fecha.isNotEmpty;

  NuevaVentaState copyWith({
    int?              paso,
    String?           comprador,
    String?           celular,
    String?           direccion,
    String?           tipoEnvio,
    String?           metodoPago,
    String?           fecha,
    List<ItemCesta>?  cesta,
    ClientePrevio?    clientePrevio,
    bool?             buscandoCliente,
    bool?             registrando,
    VentaRegistrada?  ventaRegistrada,
    String?           error,
    bool              clearError = false,
    bool              clearVenta = false,
    bool              clearCliente = false,
  }) => NuevaVentaState(
    paso:             paso            ?? this.paso,
    comprador:        comprador       ?? this.comprador,
    celular:          celular         ?? this.celular,
    direccion:        direccion       ?? this.direccion,
    tipoEnvio:        tipoEnvio       ?? this.tipoEnvio,
    metodoPago:       metodoPago      ?? this.metodoPago,
    fecha:            fecha           ?? this.fecha,
    cesta:            cesta           ?? this.cesta,
    clientePrevio:    clearCliente ? null : (clientePrevio ?? this.clientePrevio),
    buscandoCliente:  buscandoCliente ?? this.buscandoCliente,
    registrando:      registrando     ?? this.registrando,
    ventaRegistrada:  clearVenta ? null : (ventaRegistrada ?? this.ventaRegistrada),
    error:            clearError ? null : (error ?? this.error),
  );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class NuevaVentaNotifier extends Notifier<NuevaVentaState> {
  @override
  NuevaVentaState build() => NuevaVentaState(
    fecha: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );

  VentasRepository get _repo => ref.read(ventasRepositoryProvider);

  // ── Paso 1: datos del cliente ─────────────────────────────────────────────

  void setCelular(String v) {
    state = state.copyWith(celular: v, clearCliente: true);
    if (v.length == 9) _buscarCliente(v);
  }

  Future<void> _buscarCliente(String celular) async {
    state = state.copyWith(buscandoCliente: true);
    try {
      final cliente = await _repo.getClientePrevio(celular);
      if (cliente != null) {
        state = state.copyWith(
          buscandoCliente: false,
          clientePrevio:   cliente,
          comprador:       cliente.comprador,
          direccion:       cliente.direccion,
          tipoEnvio:       cliente.tipoEnvio,
          metodoPago:      cliente.metodoPago,
        );
      } else {
        state = state.copyWith(buscandoCliente: false);
      }
    } catch (_) {
      state = state.copyWith(buscandoCliente: false);
    }
  }

  void setComprador(String v)   => state = state.copyWith(comprador: v);
  void setDireccion(String v)   => state = state.copyWith(direccion: v);
  void setTipoEnvio(String v)   => state = state.copyWith(tipoEnvio: v);
  void setMetodoPago(String v)  => state = state.copyWith(metodoPago: v);
  void setFecha(String v)       => state = state.copyWith(fecha: v);

  void irPaso(int p) => state = state.copyWith(paso: p, clearError: true);

  // ── Paso 2: cesta ─────────────────────────────────────────────────────────

  void agregarItem(Perfume perfume, int ml) {
    final precio = switch (ml) {
      2  => perfume.precio2ml,
      5  => perfume.precio5ml,
      10 => perfume.precio10ml,
      _  => null,
    };
    if (precio == null) return;

    final item = ItemCesta(
      perfume:  perfume,
      ml:       ml,
      precio:   precio,
      metodo:   state.metodoPago,
    );
    state = state.copyWith(cesta: [...state.cesta, item]);
  }

  void quitarItem(int index) {
    final nueva = List<ItemCesta>.from(state.cesta)..removeAt(index);
    state = state.copyWith(cesta: nueva);
  }

  // ── Paso 3: confirmar ────────────────────────────────────────────────────

  Future<void> registrarVenta() async {
    state = state.copyWith(registrando: true, clearError: true);
    try {
      final registrada = await _repo.registrarVenta(
        comprador: state.comprador,
        celular:   state.celular,
        direccion: state.direccion,
        tipoEnvio: state.tipoEnvio,
        fecha:     state.fecha,
        items:     state.cesta.map((i) => i.toApiMap()).toList(),
      );
      state = state.copyWith(
        registrando:     false,
        ventaRegistrada: registrada,
        paso:            3,
      );
    } catch (e) {
      state = state.copyWith(registrando: false, error: e.toString());
    }
  }

  void reset() => state = NuevaVentaState(
    fecha: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );
}

final nuevaVentaProvider =
    NotifierProvider<NuevaVentaNotifier, NuevaVentaState>(NuevaVentaNotifier.new);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:perfuteca/core/utils/validators.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/features/estadisticas/providers/estadisticas_provider.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/models/venta.dart';
import 'package:perfuteca/repositories/ventas_repository.dart';

// ── Estado del wizard de nueva venta ─────────────────────────────────────────

class NuevaVentaState {
  const NuevaVentaState({
    this.paso           = 1,
    this.comprador      = '',
    this.celular        = '',
    this.alias          = '',
    this.direccion      = '',
    this.distrito       = '',
    this.tipoEnvio      = '',
    this.metodoPago     = 'Yape',
    this.fecha          = '',
    this.cesta          = const [],
    this.clientePrevio,
    this.buscandoCliente = false,
    this.registrando     = false,
    this.ventaRegistrada,
    this.error,
    this.refCotizacion,
    this.refItems,
  });

  final int               paso;
  final String            comprador;
  final String            celular;
  final String            alias;
  final String            direccion;
  final String            distrito;
  final String            tipoEnvio;
  final String            metodoPago;
  final String            fecha;
  final List<ItemCesta>   cesta;
  final ClientePrevio?    clientePrevio;
  final bool              buscandoCliente;
  final bool              registrando;
  final VentaRegistrada?  ventaRegistrada;
  final String?           error;
  final String?           refCotizacion;
  final String?           refItems;

  double get total => cesta.fold(0, (s, i) => s + i.subtotal);

  bool get paso1Valido {
    return comprador.trim().isNotEmpty &&
        esCelularPeruValido(celular) &&
        direccion.trim().isNotEmpty &&
        tipoEnvio.isNotEmpty &&
        fecha.isNotEmpty;
  }

  /// Campos de paso 1 aún incompletos, para mostrar en `_ValidationHint`.
  List<String> get camposFaltantes {
    final faltantes = <String>[];
    if (comprador.trim().isEmpty) faltantes.add('nombre');
    if (!esCelularPeruValido(celular)) faltantes.add('celular (9 dígitos, empieza con 9)');
    if (tipoEnvio.isEmpty) faltantes.add('tipo de envío');
    if (direccion.trim().isEmpty) faltantes.add('dirección');
    return faltantes;
  }

  NuevaVentaState copyWith({
    int?              paso,
    String?           comprador,
    String?           celular,
    String?           alias,
    String?           direccion,
    String?           distrito,
    String?           tipoEnvio,
    String?           metodoPago,
    String?           fecha,
    List<ItemCesta>?  cesta,
    ClientePrevio?    clientePrevio,
    bool?             buscandoCliente,
    bool?             registrando,
    VentaRegistrada?  ventaRegistrada,
    String?           error,
    String?           refCotizacion,
    String?           refItems,
    bool              clearError = false,
    bool              clearVenta = false,
    bool              clearCliente = false,
    bool              clearRef = false,
  }) => NuevaVentaState(
    paso:             paso            ?? this.paso,
    comprador:        comprador       ?? this.comprador,
    celular:          celular         ?? this.celular,
    alias:            alias           ?? this.alias,
    direccion:        direccion       ?? this.direccion,
    distrito:         distrito        ?? this.distrito,
    tipoEnvio:        tipoEnvio       ?? this.tipoEnvio,
    metodoPago:       metodoPago      ?? this.metodoPago,
    fecha:            fecha           ?? this.fecha,
    cesta:            cesta           ?? this.cesta,
    clientePrevio:    clearCliente ? null : (clientePrevio ?? this.clientePrevio),
    buscandoCliente:  buscandoCliente ?? this.buscandoCliente,
    registrando:      registrando     ?? this.registrando,
    ventaRegistrada:  clearVenta ? null : (ventaRegistrada ?? this.ventaRegistrada),
    error:            clearError ? null : (error ?? this.error),
    refCotizacion:    clearRef ? null : (refCotizacion ?? this.refCotizacion),
    refItems:         clearRef ? null : (refItems ?? this.refItems),
  );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class NuevaVentaNotifier extends Notifier<NuevaVentaState> {
  @override
  NuevaVentaState build() => NuevaVentaState(
    fecha: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );

  VentasRepository get _repo => ref.read(ventasRepositoryProvider);

  // Refresca el catálogo una sola vez por venta al entrar a paso 2, para que
  // perfumes agregados a Sheets mientras la app está abierta aparezcan sin
  // esperar a cerrar/reabrir la app. No en cada entrada a paso 2 (ida y
  // vuelta entre pasos) para no repetir la llamada de red innecesariamente.
  bool _catalogoRefrescado = false;

  void _refrescarCatalogoSiCorresponde() {
    if (_catalogoRefrescado) return;
    _catalogoRefrescado = true;
    // catalogoProvider es compartido con el tab Catálogo — refreshPreservandoProfundidad()
    // publica el resultado en un solo cambio de estado, sin truncar la lista
    // visible mientras se recarga.
    ref.read(catalogoProvider.notifier).refreshPreservandoProfundidad();
  }

  // ── Paso 1: datos del cliente ─────────────────────────────────────────────

  void setCelular(String v) {
    state = state.copyWith(celular: v, clearCliente: true);
    if (v.length == 9) _buscarCliente(v);
  }

  void setAlias(String v) => state = state.copyWith(alias: v);

  Future<void> _buscarCliente(String celular) async {
    state = state.copyWith(buscandoCliente: true);
    try {
      final cliente = await _repo.getClientePrevio(celular);
      if (cliente != null) {
        state = state.copyWith(
          buscandoCliente: false,
          clientePrevio:   cliente,
          // Solo rellenar si el campo está vacío — no pisar lo que el usuario ya escribió
          comprador:  state.comprador.trim().isEmpty  ? cliente.comprador  : state.comprador,
          direccion:  state.direccion.trim().isEmpty  ? cliente.direccion  : state.direccion,
          distrito:   state.distrito.trim().isEmpty   ? cliente.distrito   : state.distrito,
          tipoEnvio:  state.tipoEnvio.isEmpty         ? cliente.tipoEnvio  : state.tipoEnvio,
          metodoPago: cliente.metodoPago,
          alias:      state.alias.trim().isEmpty ? (cliente.alias ?? '') : state.alias,
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
  void setDistrito(String v)    => state = state.copyWith(distrito: v);
  void setTipoEnvio(String v)   => state = state.copyWith(tipoEnvio: v);
  void setMetodoPago(String v)  => state = state.copyWith(metodoPago: v);
  void setFecha(String v)       => state = state.copyWith(fecha: v);

  void irPaso(int p) {
    state = state.copyWith(paso: p, clearError: true);
    if (p == 2) _refrescarCatalogoSiCorresponde();
  }

  void preCargarDesdeCotizacion({
    required String celular,
    String? idCotizacion,
    String? refItems,
    List<ItemCesta> cesta = const [],
  }) {
    _catalogoRefrescado = false;
    state = NuevaVentaState(
      fecha:         DateFormat('yyyy-MM-dd').format(DateTime.now()),
      celular:       celular,
      refCotizacion: idCotizacion,
      refItems:      refItems,
      cesta:         cesta,
    );
    if (celular.length == 9) _buscarCliente(celular);
  }

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

  void setPrecioItem(int index, double nuevoPrecio) {
    if (nuevoPrecio <= 0) return;
    final item = state.cesta[index];
    final nueva = List<ItemCesta>.from(state.cesta);
    nueva[index] = ItemCesta(
      perfume: item.perfume,
      ml:      item.ml,
      precio:  nuevoPrecio,
      metodo:  item.metodo,
    );
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
        distrito:  state.distrito,
        tipoEnvio: state.tipoEnvio,
        fecha:     state.fecha,
        items:     state.cesta.map((i) => i.toApiMap()).toList(),
        alias:     state.alias,
      );
      state = state.copyWith(
        registrando:     false,
        ventaRegistrada: registrada,
        paso:            3,
      );
      // Invalida stats para que el tab Estadísticas muestre datos frescos
      ref.invalidate(resumenBackendProvider);
      ref.invalidate(ventasParaStatsProvider);
    } catch (e) {
      state = state.copyWith(registrando: false, error: e.toString());
    }
  }

  void reset() {
    _catalogoRefrescado = false;
    state = NuevaVentaState(
      fecha: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
  }
}

final nuevaVentaProvider =
    NotifierProvider<NuevaVentaNotifier, NuevaVentaState>(NuevaVentaNotifier.new);

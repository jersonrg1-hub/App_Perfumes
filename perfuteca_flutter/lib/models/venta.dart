import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:perfuteca/models/perfume.dart';

part 'venta.freezed.dart';
part 'venta.g.dart';

// ── Conversores defensivos para valores de pandas/Google Sheets ───────────────

String  _strOrEmpty(dynamic v)       => v?.toString() ?? '';
String? _toStrNullable(dynamic v)    => v == null ? null : v.toString();
int     _toInt(dynamic v)            => v == null ? 0 : (v is int ? v : (v as num).toInt());
int?    _toIntNullable(dynamic v)    => v == null ? null : (v is int ? v : (v as num).toInt());
double? _toDoubleNullable(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num)   return v.toDouble();
  return double.tryParse(v.toString());
}

// ── Respuesta de una venta del historial ──────────────────────────────────────

@freezed
class VentaResponse with _$VentaResponse {
  const factory VentaResponse({
    @JsonKey(name: 'id_compra',      fromJson: _strOrEmpty)       @Default('') String  idCompra,
    @JsonKey(name: 'fila_sheet',     fromJson: _toInt)            @Default(0)  int     filaSheet,
    @JsonKey(                        fromJson: _toStrNullable)                 String? fecha,
    @JsonKey(                        fromJson: _toStrNullable)                 String? comprador,
    @JsonKey(                        fromJson: _toStrNullable)                 String? celular,
    @JsonKey(name: 'id_perfume',     fromJson: _toStrNullable)                String? idPerfume,
    @JsonKey(name: 'ml_vendido',     fromJson: _toIntNullable)                int?    mlVendido,
    @JsonKey(name: 'precio_cobrado', fromJson: _toDoubleNullable)             double? precioCobrado,
    @JsonKey(name: 'metodo_pago',    fromJson: _toStrNullable)                String? metodoPago,
    @JsonKey(name: 'tipo_envio',     fromJson: _toStrNullable)                String? tipoEnvio,
    @JsonKey(                        fromJson: _toStrNullable)                 String? direccion,
    @JsonKey(                        fromJson: _toStrNullable)                 String? distrito,
    @JsonKey(                        fromJson: _toStrNullable)                 String? estado,
    @JsonKey(                        fromJson: _toStrNullable)                 String? alias,
  }) = _VentaResponse;

  factory VentaResponse.fromJson(Map<String, dynamic> json) =>
      _$VentaResponseFromJson(json);
}

// ── Datos del último pedido de un cliente (autocompletado) ────────────────────

@freezed
class ClientePrevio with _$ClientePrevio {
  const factory ClientePrevio({
    required String comprador,
    required String direccion,
    @Default('') String distrito,
    @JsonKey(name: 'tipo_envio')                        required String tipoEnvio,
    @JsonKey(name: 'metodo_pago')                       required String metodoPago,
    @JsonKey(name: 'total_compras', fromJson: _toInt)   @Default(0) int totalCompras,
    @JsonKey(                       fromJson: _toStrNullable)       String? alias,
  }) = _ClientePrevio;

  factory ClientePrevio.fromJson(Map<String, dynamic> json) =>
      _$ClientePrevioFromJson(json);
}

// ── Item en el carrito (solo en memoria, no se serializa) ─────────────────────

class ItemCesta {
  const ItemCesta({
    required this.perfume,
    required this.ml,
    required this.precio,
    required this.metodo,
  });

  final Perfume perfume;
  final int     ml;
  final double  precio;
  final String  metodo;

  double get subtotal => precio;

  Map<String, dynamic> toApiMap({bool conDescuento = false}) => {
    'perfume':       perfume.nombre,
    'marca':         perfume.marca,
    'id_perfume':    perfume.idPerfume,
    'ml':            ml,
    'precio':        precio,
    'metodo':        metodo,
    'con_descuento': conDescuento,
  };
}

// ── Respuesta tras registrar una venta ────────────────────────────────────────

@freezed
class VentaRegistrada with _$VentaRegistrada {
  const factory VentaRegistrada({
    @JsonKey(name: 'id_compra', fromJson: _strOrEmpty) @Default('') String idCompra,
    String? warning,
  }) = _VentaRegistrada;

  factory VentaRegistrada.fromJson(Map<String, dynamic> json) =>
      _$VentaRegistradaFromJson(json);
}

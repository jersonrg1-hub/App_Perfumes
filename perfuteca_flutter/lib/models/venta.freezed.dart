// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'venta.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VentaResponse _$VentaResponseFromJson(Map<String, dynamic> json) {
  return _VentaResponse.fromJson(json);
}

/// @nodoc
mixin _$VentaResponse {
  @JsonKey(name: 'id_compra', fromJson: _strOrEmpty)
  String get idCompra => throw _privateConstructorUsedError;
  @JsonKey(name: 'fila_sheet', fromJson: _toInt)
  int get filaSheet => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toStrNullable)
  String? get fecha => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toStrNullable)
  String? get comprador => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toStrNullable)
  String? get celular => throw _privateConstructorUsedError;
  @JsonKey(name: 'id_perfume', fromJson: _toStrNullable)
  String? get idPerfume => throw _privateConstructorUsedError;
  @JsonKey(name: 'ml_vendido', fromJson: _toIntNullable)
  int? get mlVendido => throw _privateConstructorUsedError;
  @JsonKey(name: 'precio_cobrado', fromJson: _toDoubleNullable)
  double? get precioCobrado => throw _privateConstructorUsedError;
  @JsonKey(name: 'metodo_pago', fromJson: _toStrNullable)
  String? get metodoPago => throw _privateConstructorUsedError;
  @JsonKey(name: 'tipo_envio', fromJson: _toStrNullable)
  String? get tipoEnvio => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toStrNullable)
  String? get direccion => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toStrNullable)
  String? get distrito => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toStrNullable)
  String? get estado => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toStrNullable)
  String? get alias => throw _privateConstructorUsedError;

  /// Serializes this VentaResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VentaResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VentaResponseCopyWith<VentaResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VentaResponseCopyWith<$Res> {
  factory $VentaResponseCopyWith(
          VentaResponse value, $Res Function(VentaResponse) then) =
      _$VentaResponseCopyWithImpl<$Res, VentaResponse>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id_compra', fromJson: _strOrEmpty) String idCompra,
      @JsonKey(name: 'fila_sheet', fromJson: _toInt) int filaSheet,
      @JsonKey(fromJson: _toStrNullable) String? fecha,
      @JsonKey(fromJson: _toStrNullable) String? comprador,
      @JsonKey(fromJson: _toStrNullable) String? celular,
      @JsonKey(name: 'id_perfume', fromJson: _toStrNullable) String? idPerfume,
      @JsonKey(name: 'ml_vendido', fromJson: _toIntNullable) int? mlVendido,
      @JsonKey(name: 'precio_cobrado', fromJson: _toDoubleNullable)
      double? precioCobrado,
      @JsonKey(name: 'metodo_pago', fromJson: _toStrNullable)
      String? metodoPago,
      @JsonKey(name: 'tipo_envio', fromJson: _toStrNullable) String? tipoEnvio,
      @JsonKey(fromJson: _toStrNullable) String? direccion,
      @JsonKey(fromJson: _toStrNullable) String? distrito,
      @JsonKey(fromJson: _toStrNullable) String? estado,
      @JsonKey(fromJson: _toStrNullable) String? alias});
}

/// @nodoc
class _$VentaResponseCopyWithImpl<$Res, $Val extends VentaResponse>
    implements $VentaResponseCopyWith<$Res> {
  _$VentaResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VentaResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? idCompra = null,
    Object? filaSheet = null,
    Object? fecha = freezed,
    Object? comprador = freezed,
    Object? celular = freezed,
    Object? idPerfume = freezed,
    Object? mlVendido = freezed,
    Object? precioCobrado = freezed,
    Object? metodoPago = freezed,
    Object? tipoEnvio = freezed,
    Object? direccion = freezed,
    Object? distrito = freezed,
    Object? estado = freezed,
    Object? alias = freezed,
  }) {
    return _then(_value.copyWith(
      idCompra: null == idCompra
          ? _value.idCompra
          : idCompra // ignore: cast_nullable_to_non_nullable
              as String,
      filaSheet: null == filaSheet
          ? _value.filaSheet
          : filaSheet // ignore: cast_nullable_to_non_nullable
              as int,
      fecha: freezed == fecha
          ? _value.fecha
          : fecha // ignore: cast_nullable_to_non_nullable
              as String?,
      comprador: freezed == comprador
          ? _value.comprador
          : comprador // ignore: cast_nullable_to_non_nullable
              as String?,
      celular: freezed == celular
          ? _value.celular
          : celular // ignore: cast_nullable_to_non_nullable
              as String?,
      idPerfume: freezed == idPerfume
          ? _value.idPerfume
          : idPerfume // ignore: cast_nullable_to_non_nullable
              as String?,
      mlVendido: freezed == mlVendido
          ? _value.mlVendido
          : mlVendido // ignore: cast_nullable_to_non_nullable
              as int?,
      precioCobrado: freezed == precioCobrado
          ? _value.precioCobrado
          : precioCobrado // ignore: cast_nullable_to_non_nullable
              as double?,
      metodoPago: freezed == metodoPago
          ? _value.metodoPago
          : metodoPago // ignore: cast_nullable_to_non_nullable
              as String?,
      tipoEnvio: freezed == tipoEnvio
          ? _value.tipoEnvio
          : tipoEnvio // ignore: cast_nullable_to_non_nullable
              as String?,
      direccion: freezed == direccion
          ? _value.direccion
          : direccion // ignore: cast_nullable_to_non_nullable
              as String?,
      distrito: freezed == distrito
          ? _value.distrito
          : distrito // ignore: cast_nullable_to_non_nullable
              as String?,
      estado: freezed == estado
          ? _value.estado
          : estado // ignore: cast_nullable_to_non_nullable
              as String?,
      alias: freezed == alias
          ? _value.alias
          : alias // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VentaResponseImplCopyWith<$Res>
    implements $VentaResponseCopyWith<$Res> {
  factory _$$VentaResponseImplCopyWith(
          _$VentaResponseImpl value, $Res Function(_$VentaResponseImpl) then) =
      __$$VentaResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id_compra', fromJson: _strOrEmpty) String idCompra,
      @JsonKey(name: 'fila_sheet', fromJson: _toInt) int filaSheet,
      @JsonKey(fromJson: _toStrNullable) String? fecha,
      @JsonKey(fromJson: _toStrNullable) String? comprador,
      @JsonKey(fromJson: _toStrNullable) String? celular,
      @JsonKey(name: 'id_perfume', fromJson: _toStrNullable) String? idPerfume,
      @JsonKey(name: 'ml_vendido', fromJson: _toIntNullable) int? mlVendido,
      @JsonKey(name: 'precio_cobrado', fromJson: _toDoubleNullable)
      double? precioCobrado,
      @JsonKey(name: 'metodo_pago', fromJson: _toStrNullable)
      String? metodoPago,
      @JsonKey(name: 'tipo_envio', fromJson: _toStrNullable) String? tipoEnvio,
      @JsonKey(fromJson: _toStrNullable) String? direccion,
      @JsonKey(fromJson: _toStrNullable) String? distrito,
      @JsonKey(fromJson: _toStrNullable) String? estado,
      @JsonKey(fromJson: _toStrNullable) String? alias});
}

/// @nodoc
class __$$VentaResponseImplCopyWithImpl<$Res>
    extends _$VentaResponseCopyWithImpl<$Res, _$VentaResponseImpl>
    implements _$$VentaResponseImplCopyWith<$Res> {
  __$$VentaResponseImplCopyWithImpl(
      _$VentaResponseImpl _value, $Res Function(_$VentaResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of VentaResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? idCompra = null,
    Object? filaSheet = null,
    Object? fecha = freezed,
    Object? comprador = freezed,
    Object? celular = freezed,
    Object? idPerfume = freezed,
    Object? mlVendido = freezed,
    Object? precioCobrado = freezed,
    Object? metodoPago = freezed,
    Object? tipoEnvio = freezed,
    Object? direccion = freezed,
    Object? distrito = freezed,
    Object? estado = freezed,
    Object? alias = freezed,
  }) {
    return _then(_$VentaResponseImpl(
      idCompra: null == idCompra
          ? _value.idCompra
          : idCompra // ignore: cast_nullable_to_non_nullable
              as String,
      filaSheet: null == filaSheet
          ? _value.filaSheet
          : filaSheet // ignore: cast_nullable_to_non_nullable
              as int,
      fecha: freezed == fecha
          ? _value.fecha
          : fecha // ignore: cast_nullable_to_non_nullable
              as String?,
      comprador: freezed == comprador
          ? _value.comprador
          : comprador // ignore: cast_nullable_to_non_nullable
              as String?,
      celular: freezed == celular
          ? _value.celular
          : celular // ignore: cast_nullable_to_non_nullable
              as String?,
      idPerfume: freezed == idPerfume
          ? _value.idPerfume
          : idPerfume // ignore: cast_nullable_to_non_nullable
              as String?,
      mlVendido: freezed == mlVendido
          ? _value.mlVendido
          : mlVendido // ignore: cast_nullable_to_non_nullable
              as int?,
      precioCobrado: freezed == precioCobrado
          ? _value.precioCobrado
          : precioCobrado // ignore: cast_nullable_to_non_nullable
              as double?,
      metodoPago: freezed == metodoPago
          ? _value.metodoPago
          : metodoPago // ignore: cast_nullable_to_non_nullable
              as String?,
      tipoEnvio: freezed == tipoEnvio
          ? _value.tipoEnvio
          : tipoEnvio // ignore: cast_nullable_to_non_nullable
              as String?,
      direccion: freezed == direccion
          ? _value.direccion
          : direccion // ignore: cast_nullable_to_non_nullable
              as String?,
      distrito: freezed == distrito
          ? _value.distrito
          : distrito // ignore: cast_nullable_to_non_nullable
              as String?,
      estado: freezed == estado
          ? _value.estado
          : estado // ignore: cast_nullable_to_non_nullable
              as String?,
      alias: freezed == alias
          ? _value.alias
          : alias // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VentaResponseImpl implements _VentaResponse {
  const _$VentaResponseImpl(
      {@JsonKey(name: 'id_compra', fromJson: _strOrEmpty) this.idCompra = '',
      @JsonKey(name: 'fila_sheet', fromJson: _toInt) this.filaSheet = 0,
      @JsonKey(fromJson: _toStrNullable) this.fecha,
      @JsonKey(fromJson: _toStrNullable) this.comprador,
      @JsonKey(fromJson: _toStrNullable) this.celular,
      @JsonKey(name: 'id_perfume', fromJson: _toStrNullable) this.idPerfume,
      @JsonKey(name: 'ml_vendido', fromJson: _toIntNullable) this.mlVendido,
      @JsonKey(name: 'precio_cobrado', fromJson: _toDoubleNullable)
      this.precioCobrado,
      @JsonKey(name: 'metodo_pago', fromJson: _toStrNullable) this.metodoPago,
      @JsonKey(name: 'tipo_envio', fromJson: _toStrNullable) this.tipoEnvio,
      @JsonKey(fromJson: _toStrNullable) this.direccion,
      @JsonKey(fromJson: _toStrNullable) this.distrito,
      @JsonKey(fromJson: _toStrNullable) this.estado,
      @JsonKey(fromJson: _toStrNullable) this.alias});

  factory _$VentaResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$VentaResponseImplFromJson(json);

  @override
  @JsonKey(name: 'id_compra', fromJson: _strOrEmpty)
  final String idCompra;
  @override
  @JsonKey(name: 'fila_sheet', fromJson: _toInt)
  final int filaSheet;
  @override
  @JsonKey(fromJson: _toStrNullable)
  final String? fecha;
  @override
  @JsonKey(fromJson: _toStrNullable)
  final String? comprador;
  @override
  @JsonKey(fromJson: _toStrNullable)
  final String? celular;
  @override
  @JsonKey(name: 'id_perfume', fromJson: _toStrNullable)
  final String? idPerfume;
  @override
  @JsonKey(name: 'ml_vendido', fromJson: _toIntNullable)
  final int? mlVendido;
  @override
  @JsonKey(name: 'precio_cobrado', fromJson: _toDoubleNullable)
  final double? precioCobrado;
  @override
  @JsonKey(name: 'metodo_pago', fromJson: _toStrNullable)
  final String? metodoPago;
  @override
  @JsonKey(name: 'tipo_envio', fromJson: _toStrNullable)
  final String? tipoEnvio;
  @override
  @JsonKey(fromJson: _toStrNullable)
  final String? direccion;
  @override
  @JsonKey(fromJson: _toStrNullable)
  final String? distrito;
  @override
  @JsonKey(fromJson: _toStrNullable)
  final String? estado;
  @override
  @JsonKey(fromJson: _toStrNullable)
  final String? alias;

  @override
  String toString() {
    return 'VentaResponse(idCompra: $idCompra, filaSheet: $filaSheet, fecha: $fecha, comprador: $comprador, celular: $celular, idPerfume: $idPerfume, mlVendido: $mlVendido, precioCobrado: $precioCobrado, metodoPago: $metodoPago, tipoEnvio: $tipoEnvio, direccion: $direccion, distrito: $distrito, estado: $estado, alias: $alias)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VentaResponseImpl &&
            (identical(other.idCompra, idCompra) ||
                other.idCompra == idCompra) &&
            (identical(other.filaSheet, filaSheet) ||
                other.filaSheet == filaSheet) &&
            (identical(other.fecha, fecha) || other.fecha == fecha) &&
            (identical(other.comprador, comprador) ||
                other.comprador == comprador) &&
            (identical(other.celular, celular) || other.celular == celular) &&
            (identical(other.idPerfume, idPerfume) ||
                other.idPerfume == idPerfume) &&
            (identical(other.mlVendido, mlVendido) ||
                other.mlVendido == mlVendido) &&
            (identical(other.precioCobrado, precioCobrado) ||
                other.precioCobrado == precioCobrado) &&
            (identical(other.metodoPago, metodoPago) ||
                other.metodoPago == metodoPago) &&
            (identical(other.tipoEnvio, tipoEnvio) ||
                other.tipoEnvio == tipoEnvio) &&
            (identical(other.direccion, direccion) ||
                other.direccion == direccion) &&
            (identical(other.distrito, distrito) ||
                other.distrito == distrito) &&
            (identical(other.estado, estado) || other.estado == estado) &&
            (identical(other.alias, alias) || other.alias == alias));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      idCompra,
      filaSheet,
      fecha,
      comprador,
      celular,
      idPerfume,
      mlVendido,
      precioCobrado,
      metodoPago,
      tipoEnvio,
      direccion,
      distrito,
      estado,
      alias);

  /// Create a copy of VentaResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VentaResponseImplCopyWith<_$VentaResponseImpl> get copyWith =>
      __$$VentaResponseImplCopyWithImpl<_$VentaResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VentaResponseImplToJson(
      this,
    );
  }
}

abstract class _VentaResponse implements VentaResponse {
  const factory _VentaResponse(
      {@JsonKey(name: 'id_compra', fromJson: _strOrEmpty) final String idCompra,
      @JsonKey(name: 'fila_sheet', fromJson: _toInt) final int filaSheet,
      @JsonKey(fromJson: _toStrNullable) final String? fecha,
      @JsonKey(fromJson: _toStrNullable) final String? comprador,
      @JsonKey(fromJson: _toStrNullable) final String? celular,
      @JsonKey(name: 'id_perfume', fromJson: _toStrNullable)
      final String? idPerfume,
      @JsonKey(name: 'ml_vendido', fromJson: _toIntNullable)
      final int? mlVendido,
      @JsonKey(name: 'precio_cobrado', fromJson: _toDoubleNullable)
      final double? precioCobrado,
      @JsonKey(name: 'metodo_pago', fromJson: _toStrNullable)
      final String? metodoPago,
      @JsonKey(name: 'tipo_envio', fromJson: _toStrNullable)
      final String? tipoEnvio,
      @JsonKey(fromJson: _toStrNullable) final String? direccion,
      @JsonKey(fromJson: _toStrNullable) final String? distrito,
      @JsonKey(fromJson: _toStrNullable) final String? estado,
      @JsonKey(fromJson: _toStrNullable)
      final String? alias}) = _$VentaResponseImpl;

  factory _VentaResponse.fromJson(Map<String, dynamic> json) =
      _$VentaResponseImpl.fromJson;

  @override
  @JsonKey(name: 'id_compra', fromJson: _strOrEmpty)
  String get idCompra;
  @override
  @JsonKey(name: 'fila_sheet', fromJson: _toInt)
  int get filaSheet;
  @override
  @JsonKey(fromJson: _toStrNullable)
  String? get fecha;
  @override
  @JsonKey(fromJson: _toStrNullable)
  String? get comprador;
  @override
  @JsonKey(fromJson: _toStrNullable)
  String? get celular;
  @override
  @JsonKey(name: 'id_perfume', fromJson: _toStrNullable)
  String? get idPerfume;
  @override
  @JsonKey(name: 'ml_vendido', fromJson: _toIntNullable)
  int? get mlVendido;
  @override
  @JsonKey(name: 'precio_cobrado', fromJson: _toDoubleNullable)
  double? get precioCobrado;
  @override
  @JsonKey(name: 'metodo_pago', fromJson: _toStrNullable)
  String? get metodoPago;
  @override
  @JsonKey(name: 'tipo_envio', fromJson: _toStrNullable)
  String? get tipoEnvio;
  @override
  @JsonKey(fromJson: _toStrNullable)
  String? get direccion;
  @override
  @JsonKey(fromJson: _toStrNullable)
  String? get distrito;
  @override
  @JsonKey(fromJson: _toStrNullable)
  String? get estado;
  @override
  @JsonKey(fromJson: _toStrNullable)
  String? get alias;

  /// Create a copy of VentaResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VentaResponseImplCopyWith<_$VentaResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ClientePrevio _$ClientePrevioFromJson(Map<String, dynamic> json) {
  return _ClientePrevio.fromJson(json);
}

/// @nodoc
mixin _$ClientePrevio {
  String get comprador => throw _privateConstructorUsedError;
  String get direccion => throw _privateConstructorUsedError;
  String get distrito => throw _privateConstructorUsedError;
  @JsonKey(name: 'tipo_envio')
  String get tipoEnvio => throw _privateConstructorUsedError;
  @JsonKey(name: 'metodo_pago')
  String get metodoPago => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_compras', fromJson: _toInt)
  int get totalCompras => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toStrNullable)
  String? get alias => throw _privateConstructorUsedError;

  /// Serializes this ClientePrevio to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ClientePrevio
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClientePrevioCopyWith<ClientePrevio> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClientePrevioCopyWith<$Res> {
  factory $ClientePrevioCopyWith(
          ClientePrevio value, $Res Function(ClientePrevio) then) =
      _$ClientePrevioCopyWithImpl<$Res, ClientePrevio>;
  @useResult
  $Res call(
      {String comprador,
      String direccion,
      String distrito,
      @JsonKey(name: 'tipo_envio') String tipoEnvio,
      @JsonKey(name: 'metodo_pago') String metodoPago,
      @JsonKey(name: 'total_compras', fromJson: _toInt) int totalCompras,
      @JsonKey(fromJson: _toStrNullable) String? alias});
}

/// @nodoc
class _$ClientePrevioCopyWithImpl<$Res, $Val extends ClientePrevio>
    implements $ClientePrevioCopyWith<$Res> {
  _$ClientePrevioCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClientePrevio
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? comprador = null,
    Object? direccion = null,
    Object? distrito = null,
    Object? tipoEnvio = null,
    Object? metodoPago = null,
    Object? totalCompras = null,
    Object? alias = freezed,
  }) {
    return _then(_value.copyWith(
      comprador: null == comprador
          ? _value.comprador
          : comprador // ignore: cast_nullable_to_non_nullable
              as String,
      direccion: null == direccion
          ? _value.direccion
          : direccion // ignore: cast_nullable_to_non_nullable
              as String,
      distrito: null == distrito
          ? _value.distrito
          : distrito // ignore: cast_nullable_to_non_nullable
              as String,
      tipoEnvio: null == tipoEnvio
          ? _value.tipoEnvio
          : tipoEnvio // ignore: cast_nullable_to_non_nullable
              as String,
      metodoPago: null == metodoPago
          ? _value.metodoPago
          : metodoPago // ignore: cast_nullable_to_non_nullable
              as String,
      totalCompras: null == totalCompras
          ? _value.totalCompras
          : totalCompras // ignore: cast_nullable_to_non_nullable
              as int,
      alias: freezed == alias
          ? _value.alias
          : alias // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ClientePrevioImplCopyWith<$Res>
    implements $ClientePrevioCopyWith<$Res> {
  factory _$$ClientePrevioImplCopyWith(
          _$ClientePrevioImpl value, $Res Function(_$ClientePrevioImpl) then) =
      __$$ClientePrevioImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String comprador,
      String direccion,
      String distrito,
      @JsonKey(name: 'tipo_envio') String tipoEnvio,
      @JsonKey(name: 'metodo_pago') String metodoPago,
      @JsonKey(name: 'total_compras', fromJson: _toInt) int totalCompras,
      @JsonKey(fromJson: _toStrNullable) String? alias});
}

/// @nodoc
class __$$ClientePrevioImplCopyWithImpl<$Res>
    extends _$ClientePrevioCopyWithImpl<$Res, _$ClientePrevioImpl>
    implements _$$ClientePrevioImplCopyWith<$Res> {
  __$$ClientePrevioImplCopyWithImpl(
      _$ClientePrevioImpl _value, $Res Function(_$ClientePrevioImpl) _then)
      : super(_value, _then);

  /// Create a copy of ClientePrevio
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? comprador = null,
    Object? direccion = null,
    Object? distrito = null,
    Object? tipoEnvio = null,
    Object? metodoPago = null,
    Object? totalCompras = null,
    Object? alias = freezed,
  }) {
    return _then(_$ClientePrevioImpl(
      comprador: null == comprador
          ? _value.comprador
          : comprador // ignore: cast_nullable_to_non_nullable
              as String,
      direccion: null == direccion
          ? _value.direccion
          : direccion // ignore: cast_nullable_to_non_nullable
              as String,
      distrito: null == distrito
          ? _value.distrito
          : distrito // ignore: cast_nullable_to_non_nullable
              as String,
      tipoEnvio: null == tipoEnvio
          ? _value.tipoEnvio
          : tipoEnvio // ignore: cast_nullable_to_non_nullable
              as String,
      metodoPago: null == metodoPago
          ? _value.metodoPago
          : metodoPago // ignore: cast_nullable_to_non_nullable
              as String,
      totalCompras: null == totalCompras
          ? _value.totalCompras
          : totalCompras // ignore: cast_nullable_to_non_nullable
              as int,
      alias: freezed == alias
          ? _value.alias
          : alias // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ClientePrevioImpl implements _ClientePrevio {
  const _$ClientePrevioImpl(
      {required this.comprador,
      required this.direccion,
      this.distrito = '',
      @JsonKey(name: 'tipo_envio') required this.tipoEnvio,
      @JsonKey(name: 'metodo_pago') required this.metodoPago,
      @JsonKey(name: 'total_compras', fromJson: _toInt) this.totalCompras = 0,
      @JsonKey(fromJson: _toStrNullable) this.alias});

  factory _$ClientePrevioImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClientePrevioImplFromJson(json);

  @override
  final String comprador;
  @override
  final String direccion;
  @override
  @JsonKey()
  final String distrito;
  @override
  @JsonKey(name: 'tipo_envio')
  final String tipoEnvio;
  @override
  @JsonKey(name: 'metodo_pago')
  final String metodoPago;
  @override
  @JsonKey(name: 'total_compras', fromJson: _toInt)
  final int totalCompras;
  @override
  @JsonKey(fromJson: _toStrNullable)
  final String? alias;

  @override
  String toString() {
    return 'ClientePrevio(comprador: $comprador, direccion: $direccion, distrito: $distrito, tipoEnvio: $tipoEnvio, metodoPago: $metodoPago, totalCompras: $totalCompras, alias: $alias)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClientePrevioImpl &&
            (identical(other.comprador, comprador) ||
                other.comprador == comprador) &&
            (identical(other.direccion, direccion) ||
                other.direccion == direccion) &&
            (identical(other.distrito, distrito) ||
                other.distrito == distrito) &&
            (identical(other.tipoEnvio, tipoEnvio) ||
                other.tipoEnvio == tipoEnvio) &&
            (identical(other.metodoPago, metodoPago) ||
                other.metodoPago == metodoPago) &&
            (identical(other.totalCompras, totalCompras) ||
                other.totalCompras == totalCompras) &&
            (identical(other.alias, alias) || other.alias == alias));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, comprador, direccion, distrito,
      tipoEnvio, metodoPago, totalCompras, alias);

  /// Create a copy of ClientePrevio
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClientePrevioImplCopyWith<_$ClientePrevioImpl> get copyWith =>
      __$$ClientePrevioImplCopyWithImpl<_$ClientePrevioImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ClientePrevioImplToJson(
      this,
    );
  }
}

abstract class _ClientePrevio implements ClientePrevio {
  const factory _ClientePrevio(
      {required final String comprador,
      required final String direccion,
      final String distrito,
      @JsonKey(name: 'tipo_envio') required final String tipoEnvio,
      @JsonKey(name: 'metodo_pago') required final String metodoPago,
      @JsonKey(name: 'total_compras', fromJson: _toInt) final int totalCompras,
      @JsonKey(fromJson: _toStrNullable)
      final String? alias}) = _$ClientePrevioImpl;

  factory _ClientePrevio.fromJson(Map<String, dynamic> json) =
      _$ClientePrevioImpl.fromJson;

  @override
  String get comprador;
  @override
  String get direccion;
  @override
  String get distrito;
  @override
  @JsonKey(name: 'tipo_envio')
  String get tipoEnvio;
  @override
  @JsonKey(name: 'metodo_pago')
  String get metodoPago;
  @override
  @JsonKey(name: 'total_compras', fromJson: _toInt)
  int get totalCompras;
  @override
  @JsonKey(fromJson: _toStrNullable)
  String? get alias;

  /// Create a copy of ClientePrevio
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClientePrevioImplCopyWith<_$ClientePrevioImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VentaRegistrada _$VentaRegistradaFromJson(Map<String, dynamic> json) {
  return _VentaRegistrada.fromJson(json);
}

/// @nodoc
mixin _$VentaRegistrada {
  @JsonKey(name: 'id_compra', fromJson: _strOrEmpty)
  String get idCompra => throw _privateConstructorUsedError;
  String? get warning => throw _privateConstructorUsedError;

  /// Serializes this VentaRegistrada to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VentaRegistrada
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VentaRegistradaCopyWith<VentaRegistrada> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VentaRegistradaCopyWith<$Res> {
  factory $VentaRegistradaCopyWith(
          VentaRegistrada value, $Res Function(VentaRegistrada) then) =
      _$VentaRegistradaCopyWithImpl<$Res, VentaRegistrada>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id_compra', fromJson: _strOrEmpty) String idCompra,
      String? warning});
}

/// @nodoc
class _$VentaRegistradaCopyWithImpl<$Res, $Val extends VentaRegistrada>
    implements $VentaRegistradaCopyWith<$Res> {
  _$VentaRegistradaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VentaRegistrada
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? idCompra = null,
    Object? warning = freezed,
  }) {
    return _then(_value.copyWith(
      idCompra: null == idCompra
          ? _value.idCompra
          : idCompra // ignore: cast_nullable_to_non_nullable
              as String,
      warning: freezed == warning
          ? _value.warning
          : warning // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VentaRegistradaImplCopyWith<$Res>
    implements $VentaRegistradaCopyWith<$Res> {
  factory _$$VentaRegistradaImplCopyWith(_$VentaRegistradaImpl value,
          $Res Function(_$VentaRegistradaImpl) then) =
      __$$VentaRegistradaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id_compra', fromJson: _strOrEmpty) String idCompra,
      String? warning});
}

/// @nodoc
class __$$VentaRegistradaImplCopyWithImpl<$Res>
    extends _$VentaRegistradaCopyWithImpl<$Res, _$VentaRegistradaImpl>
    implements _$$VentaRegistradaImplCopyWith<$Res> {
  __$$VentaRegistradaImplCopyWithImpl(
      _$VentaRegistradaImpl _value, $Res Function(_$VentaRegistradaImpl) _then)
      : super(_value, _then);

  /// Create a copy of VentaRegistrada
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? idCompra = null,
    Object? warning = freezed,
  }) {
    return _then(_$VentaRegistradaImpl(
      idCompra: null == idCompra
          ? _value.idCompra
          : idCompra // ignore: cast_nullable_to_non_nullable
              as String,
      warning: freezed == warning
          ? _value.warning
          : warning // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VentaRegistradaImpl implements _VentaRegistrada {
  const _$VentaRegistradaImpl(
      {@JsonKey(name: 'id_compra', fromJson: _strOrEmpty) this.idCompra = '',
      this.warning});

  factory _$VentaRegistradaImpl.fromJson(Map<String, dynamic> json) =>
      _$$VentaRegistradaImplFromJson(json);

  @override
  @JsonKey(name: 'id_compra', fromJson: _strOrEmpty)
  final String idCompra;
  @override
  final String? warning;

  @override
  String toString() {
    return 'VentaRegistrada(idCompra: $idCompra, warning: $warning)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VentaRegistradaImpl &&
            (identical(other.idCompra, idCompra) ||
                other.idCompra == idCompra) &&
            (identical(other.warning, warning) || other.warning == warning));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, idCompra, warning);

  /// Create a copy of VentaRegistrada
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VentaRegistradaImplCopyWith<_$VentaRegistradaImpl> get copyWith =>
      __$$VentaRegistradaImplCopyWithImpl<_$VentaRegistradaImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VentaRegistradaImplToJson(
      this,
    );
  }
}

abstract class _VentaRegistrada implements VentaRegistrada {
  const factory _VentaRegistrada(
      {@JsonKey(name: 'id_compra', fromJson: _strOrEmpty) final String idCompra,
      final String? warning}) = _$VentaRegistradaImpl;

  factory _VentaRegistrada.fromJson(Map<String, dynamic> json) =
      _$VentaRegistradaImpl.fromJson;

  @override
  @JsonKey(name: 'id_compra', fromJson: _strOrEmpty)
  String get idCompra;
  @override
  String? get warning;

  /// Create a copy of VentaRegistrada
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VentaRegistradaImplCopyWith<_$VentaRegistradaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

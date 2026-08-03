// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cotizacion.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CotizacionRegistrada _$CotizacionRegistradaFromJson(Map<String, dynamic> json) {
  return _CotizacionRegistrada.fromJson(json);
}

/// @nodoc
mixin _$CotizacionRegistrada {
  @JsonKey(name: 'id_cotizacion', fromJson: _strOrEmpty)
  String get idCotizacion => throw _privateConstructorUsedError;

  /// Serializes this CotizacionRegistrada to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CotizacionRegistrada
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CotizacionRegistradaCopyWith<CotizacionRegistrada> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CotizacionRegistradaCopyWith<$Res> {
  factory $CotizacionRegistradaCopyWith(CotizacionRegistrada value,
          $Res Function(CotizacionRegistrada) then) =
      _$CotizacionRegistradaCopyWithImpl<$Res, CotizacionRegistrada>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id_cotizacion', fromJson: _strOrEmpty)
      String idCotizacion});
}

/// @nodoc
class _$CotizacionRegistradaCopyWithImpl<$Res,
        $Val extends CotizacionRegistrada>
    implements $CotizacionRegistradaCopyWith<$Res> {
  _$CotizacionRegistradaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CotizacionRegistrada
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? idCotizacion = null,
  }) {
    return _then(_value.copyWith(
      idCotizacion: null == idCotizacion
          ? _value.idCotizacion
          : idCotizacion // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CotizacionRegistradaImplCopyWith<$Res>
    implements $CotizacionRegistradaCopyWith<$Res> {
  factory _$$CotizacionRegistradaImplCopyWith(_$CotizacionRegistradaImpl value,
          $Res Function(_$CotizacionRegistradaImpl) then) =
      __$$CotizacionRegistradaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id_cotizacion', fromJson: _strOrEmpty)
      String idCotizacion});
}

/// @nodoc
class __$$CotizacionRegistradaImplCopyWithImpl<$Res>
    extends _$CotizacionRegistradaCopyWithImpl<$Res, _$CotizacionRegistradaImpl>
    implements _$$CotizacionRegistradaImplCopyWith<$Res> {
  __$$CotizacionRegistradaImplCopyWithImpl(_$CotizacionRegistradaImpl _value,
      $Res Function(_$CotizacionRegistradaImpl) _then)
      : super(_value, _then);

  /// Create a copy of CotizacionRegistrada
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? idCotizacion = null,
  }) {
    return _then(_$CotizacionRegistradaImpl(
      idCotizacion: null == idCotizacion
          ? _value.idCotizacion
          : idCotizacion // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CotizacionRegistradaImpl implements _CotizacionRegistrada {
  const _$CotizacionRegistradaImpl(
      {@JsonKey(name: 'id_cotizacion', fromJson: _strOrEmpty)
      this.idCotizacion = ''});

  factory _$CotizacionRegistradaImpl.fromJson(Map<String, dynamic> json) =>
      _$$CotizacionRegistradaImplFromJson(json);

  @override
  @JsonKey(name: 'id_cotizacion', fromJson: _strOrEmpty)
  final String idCotizacion;

  @override
  String toString() {
    return 'CotizacionRegistrada(idCotizacion: $idCotizacion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CotizacionRegistradaImpl &&
            (identical(other.idCotizacion, idCotizacion) ||
                other.idCotizacion == idCotizacion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, idCotizacion);

  /// Create a copy of CotizacionRegistrada
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CotizacionRegistradaImplCopyWith<_$CotizacionRegistradaImpl>
      get copyWith =>
          __$$CotizacionRegistradaImplCopyWithImpl<_$CotizacionRegistradaImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CotizacionRegistradaImplToJson(
      this,
    );
  }
}

abstract class _CotizacionRegistrada implements CotizacionRegistrada {
  const factory _CotizacionRegistrada(
      {@JsonKey(name: 'id_cotizacion', fromJson: _strOrEmpty)
      final String idCotizacion}) = _$CotizacionRegistradaImpl;

  factory _CotizacionRegistrada.fromJson(Map<String, dynamic> json) =
      _$CotizacionRegistradaImpl.fromJson;

  @override
  @JsonKey(name: 'id_cotizacion', fromJson: _strOrEmpty)
  String get idCotizacion;

  /// Create a copy of CotizacionRegistrada
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CotizacionRegistradaImplCopyWith<_$CotizacionRegistradaImpl>
      get copyWith => throw _privateConstructorUsedError;
}

CotizacionResponse _$CotizacionResponseFromJson(Map<String, dynamic> json) {
  return _CotizacionResponse.fromJson(json);
}

/// @nodoc
mixin _$CotizacionResponse {
  @JsonKey(name: 'id_cotizacion', fromJson: _strOrEmpty)
  String get idCotizacion => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _strOrEmpty)
  String get celular => throw _privateConstructorUsedError;
  String? get fecha => throw _privateConstructorUsedError;
  String? get items => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toDoubleNullable)
  double? get total => throw _privateConstructorUsedError;
  String? get estado => throw _privateConstructorUsedError;
  @JsonKey(name: 'fila_sheet', fromJson: _toInt)
  int get filaSheet => throw _privateConstructorUsedError;
  String? get alias => throw _privateConstructorUsedError;

  /// Serializes this CotizacionResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CotizacionResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CotizacionResponseCopyWith<CotizacionResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CotizacionResponseCopyWith<$Res> {
  factory $CotizacionResponseCopyWith(
          CotizacionResponse value, $Res Function(CotizacionResponse) then) =
      _$CotizacionResponseCopyWithImpl<$Res, CotizacionResponse>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id_cotizacion', fromJson: _strOrEmpty)
      String idCotizacion,
      @JsonKey(fromJson: _strOrEmpty) String celular,
      String? fecha,
      String? items,
      @JsonKey(fromJson: _toDoubleNullable) double? total,
      String? estado,
      @JsonKey(name: 'fila_sheet', fromJson: _toInt) int filaSheet,
      String? alias});
}

/// @nodoc
class _$CotizacionResponseCopyWithImpl<$Res, $Val extends CotizacionResponse>
    implements $CotizacionResponseCopyWith<$Res> {
  _$CotizacionResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CotizacionResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? idCotizacion = null,
    Object? celular = null,
    Object? fecha = freezed,
    Object? items = freezed,
    Object? total = freezed,
    Object? estado = freezed,
    Object? filaSheet = null,
    Object? alias = freezed,
  }) {
    return _then(_value.copyWith(
      idCotizacion: null == idCotizacion
          ? _value.idCotizacion
          : idCotizacion // ignore: cast_nullable_to_non_nullable
              as String,
      celular: null == celular
          ? _value.celular
          : celular // ignore: cast_nullable_to_non_nullable
              as String,
      fecha: freezed == fecha
          ? _value.fecha
          : fecha // ignore: cast_nullable_to_non_nullable
              as String?,
      items: freezed == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as String?,
      total: freezed == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as double?,
      estado: freezed == estado
          ? _value.estado
          : estado // ignore: cast_nullable_to_non_nullable
              as String?,
      filaSheet: null == filaSheet
          ? _value.filaSheet
          : filaSheet // ignore: cast_nullable_to_non_nullable
              as int,
      alias: freezed == alias
          ? _value.alias
          : alias // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CotizacionResponseImplCopyWith<$Res>
    implements $CotizacionResponseCopyWith<$Res> {
  factory _$$CotizacionResponseImplCopyWith(_$CotizacionResponseImpl value,
          $Res Function(_$CotizacionResponseImpl) then) =
      __$$CotizacionResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id_cotizacion', fromJson: _strOrEmpty)
      String idCotizacion,
      @JsonKey(fromJson: _strOrEmpty) String celular,
      String? fecha,
      String? items,
      @JsonKey(fromJson: _toDoubleNullable) double? total,
      String? estado,
      @JsonKey(name: 'fila_sheet', fromJson: _toInt) int filaSheet,
      String? alias});
}

/// @nodoc
class __$$CotizacionResponseImplCopyWithImpl<$Res>
    extends _$CotizacionResponseCopyWithImpl<$Res, _$CotizacionResponseImpl>
    implements _$$CotizacionResponseImplCopyWith<$Res> {
  __$$CotizacionResponseImplCopyWithImpl(_$CotizacionResponseImpl _value,
      $Res Function(_$CotizacionResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of CotizacionResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? idCotizacion = null,
    Object? celular = null,
    Object? fecha = freezed,
    Object? items = freezed,
    Object? total = freezed,
    Object? estado = freezed,
    Object? filaSheet = null,
    Object? alias = freezed,
  }) {
    return _then(_$CotizacionResponseImpl(
      idCotizacion: null == idCotizacion
          ? _value.idCotizacion
          : idCotizacion // ignore: cast_nullable_to_non_nullable
              as String,
      celular: null == celular
          ? _value.celular
          : celular // ignore: cast_nullable_to_non_nullable
              as String,
      fecha: freezed == fecha
          ? _value.fecha
          : fecha // ignore: cast_nullable_to_non_nullable
              as String?,
      items: freezed == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as String?,
      total: freezed == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as double?,
      estado: freezed == estado
          ? _value.estado
          : estado // ignore: cast_nullable_to_non_nullable
              as String?,
      filaSheet: null == filaSheet
          ? _value.filaSheet
          : filaSheet // ignore: cast_nullable_to_non_nullable
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
class _$CotizacionResponseImpl implements _CotizacionResponse {
  const _$CotizacionResponseImpl(
      {@JsonKey(name: 'id_cotizacion', fromJson: _strOrEmpty)
      this.idCotizacion = '',
      @JsonKey(fromJson: _strOrEmpty) this.celular = '',
      this.fecha,
      this.items,
      @JsonKey(fromJson: _toDoubleNullable) this.total,
      this.estado,
      @JsonKey(name: 'fila_sheet', fromJson: _toInt) this.filaSheet = 0,
      this.alias});

  factory _$CotizacionResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$CotizacionResponseImplFromJson(json);

  @override
  @JsonKey(name: 'id_cotizacion', fromJson: _strOrEmpty)
  final String idCotizacion;
  @override
  @JsonKey(fromJson: _strOrEmpty)
  final String celular;
  @override
  final String? fecha;
  @override
  final String? items;
  @override
  @JsonKey(fromJson: _toDoubleNullable)
  final double? total;
  @override
  final String? estado;
  @override
  @JsonKey(name: 'fila_sheet', fromJson: _toInt)
  final int filaSheet;
  @override
  final String? alias;

  @override
  String toString() {
    return 'CotizacionResponse(idCotizacion: $idCotizacion, celular: $celular, fecha: $fecha, items: $items, total: $total, estado: $estado, filaSheet: $filaSheet, alias: $alias)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CotizacionResponseImpl &&
            (identical(other.idCotizacion, idCotizacion) ||
                other.idCotizacion == idCotizacion) &&
            (identical(other.celular, celular) || other.celular == celular) &&
            (identical(other.fecha, fecha) || other.fecha == fecha) &&
            (identical(other.items, items) || other.items == items) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.estado, estado) || other.estado == estado) &&
            (identical(other.filaSheet, filaSheet) ||
                other.filaSheet == filaSheet) &&
            (identical(other.alias, alias) || other.alias == alias));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, idCotizacion, celular, fecha,
      items, total, estado, filaSheet, alias);

  /// Create a copy of CotizacionResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CotizacionResponseImplCopyWith<_$CotizacionResponseImpl> get copyWith =>
      __$$CotizacionResponseImplCopyWithImpl<_$CotizacionResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CotizacionResponseImplToJson(
      this,
    );
  }
}

abstract class _CotizacionResponse implements CotizacionResponse {
  const factory _CotizacionResponse(
      {@JsonKey(name: 'id_cotizacion', fromJson: _strOrEmpty)
      final String idCotizacion,
      @JsonKey(fromJson: _strOrEmpty) final String celular,
      final String? fecha,
      final String? items,
      @JsonKey(fromJson: _toDoubleNullable) final double? total,
      final String? estado,
      @JsonKey(name: 'fila_sheet', fromJson: _toInt) final int filaSheet,
      final String? alias}) = _$CotizacionResponseImpl;

  factory _CotizacionResponse.fromJson(Map<String, dynamic> json) =
      _$CotizacionResponseImpl.fromJson;

  @override
  @JsonKey(name: 'id_cotizacion', fromJson: _strOrEmpty)
  String get idCotizacion;
  @override
  @JsonKey(fromJson: _strOrEmpty)
  String get celular;
  @override
  String? get fecha;
  @override
  String? get items;
  @override
  @JsonKey(fromJson: _toDoubleNullable)
  double? get total;
  @override
  String? get estado;
  @override
  @JsonKey(name: 'fila_sheet', fromJson: _toInt)
  int get filaSheet;
  @override
  String? get alias;

  /// Create a copy of CotizacionResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CotizacionResponseImplCopyWith<_$CotizacionResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

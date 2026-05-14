// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_config_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AppConfigModel _$AppConfigModelFromJson(Map<String, dynamic> json) {
  return _AppConfigModel.fromJson(json);
}

/// @nodoc
mixin _$AppConfigModel {
  @JsonKey(name: 'ml_opciones')
  List<int> get mlOpciones => throw _privateConstructorUsedError;
  @JsonKey(name: 'metodos_pago')
  List<String> get metodosPago => throw _privateConstructorUsedError;
  @JsonKey(name: 'tipos_envio')
  List<String> get tiposEnvio => throw _privateConstructorUsedError;
  @JsonKey(name: 'stock_critico_ml')
  int get stockCriticoMl => throw _privateConstructorUsedError;
  @JsonKey(name: 'stock_bajo_ml')
  int get stockBajoMl => throw _privateConstructorUsedError;
  String get version => throw _privateConstructorUsedError;

  /// Serializes this AppConfigModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppConfigModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppConfigModelCopyWith<AppConfigModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppConfigModelCopyWith<$Res> {
  factory $AppConfigModelCopyWith(
          AppConfigModel value, $Res Function(AppConfigModel) then) =
      _$AppConfigModelCopyWithImpl<$Res, AppConfigModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'ml_opciones') List<int> mlOpciones,
      @JsonKey(name: 'metodos_pago') List<String> metodosPago,
      @JsonKey(name: 'tipos_envio') List<String> tiposEnvio,
      @JsonKey(name: 'stock_critico_ml') int stockCriticoMl,
      @JsonKey(name: 'stock_bajo_ml') int stockBajoMl,
      String version});
}

/// @nodoc
class _$AppConfigModelCopyWithImpl<$Res, $Val extends AppConfigModel>
    implements $AppConfigModelCopyWith<$Res> {
  _$AppConfigModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppConfigModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mlOpciones = null,
    Object? metodosPago = null,
    Object? tiposEnvio = null,
    Object? stockCriticoMl = null,
    Object? stockBajoMl = null,
    Object? version = null,
  }) {
    return _then(_value.copyWith(
      mlOpciones: null == mlOpciones
          ? _value.mlOpciones
          : mlOpciones // ignore: cast_nullable_to_non_nullable
              as List<int>,
      metodosPago: null == metodosPago
          ? _value.metodosPago
          : metodosPago // ignore: cast_nullable_to_non_nullable
              as List<String>,
      tiposEnvio: null == tiposEnvio
          ? _value.tiposEnvio
          : tiposEnvio // ignore: cast_nullable_to_non_nullable
              as List<String>,
      stockCriticoMl: null == stockCriticoMl
          ? _value.stockCriticoMl
          : stockCriticoMl // ignore: cast_nullable_to_non_nullable
              as int,
      stockBajoMl: null == stockBajoMl
          ? _value.stockBajoMl
          : stockBajoMl // ignore: cast_nullable_to_non_nullable
              as int,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AppConfigModelImplCopyWith<$Res>
    implements $AppConfigModelCopyWith<$Res> {
  factory _$$AppConfigModelImplCopyWith(_$AppConfigModelImpl value,
          $Res Function(_$AppConfigModelImpl) then) =
      __$$AppConfigModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'ml_opciones') List<int> mlOpciones,
      @JsonKey(name: 'metodos_pago') List<String> metodosPago,
      @JsonKey(name: 'tipos_envio') List<String> tiposEnvio,
      @JsonKey(name: 'stock_critico_ml') int stockCriticoMl,
      @JsonKey(name: 'stock_bajo_ml') int stockBajoMl,
      String version});
}

/// @nodoc
class __$$AppConfigModelImplCopyWithImpl<$Res>
    extends _$AppConfigModelCopyWithImpl<$Res, _$AppConfigModelImpl>
    implements _$$AppConfigModelImplCopyWith<$Res> {
  __$$AppConfigModelImplCopyWithImpl(
      _$AppConfigModelImpl _value, $Res Function(_$AppConfigModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppConfigModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mlOpciones = null,
    Object? metodosPago = null,
    Object? tiposEnvio = null,
    Object? stockCriticoMl = null,
    Object? stockBajoMl = null,
    Object? version = null,
  }) {
    return _then(_$AppConfigModelImpl(
      mlOpciones: null == mlOpciones
          ? _value._mlOpciones
          : mlOpciones // ignore: cast_nullable_to_non_nullable
              as List<int>,
      metodosPago: null == metodosPago
          ? _value._metodosPago
          : metodosPago // ignore: cast_nullable_to_non_nullable
              as List<String>,
      tiposEnvio: null == tiposEnvio
          ? _value._tiposEnvio
          : tiposEnvio // ignore: cast_nullable_to_non_nullable
              as List<String>,
      stockCriticoMl: null == stockCriticoMl
          ? _value.stockCriticoMl
          : stockCriticoMl // ignore: cast_nullable_to_non_nullable
              as int,
      stockBajoMl: null == stockBajoMl
          ? _value.stockBajoMl
          : stockBajoMl // ignore: cast_nullable_to_non_nullable
              as int,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AppConfigModelImpl implements _AppConfigModel {
  const _$AppConfigModelImpl(
      {@JsonKey(name: 'ml_opciones') required final List<int> mlOpciones,
      @JsonKey(name: 'metodos_pago') required final List<String> metodosPago,
      @JsonKey(name: 'tipos_envio') required final List<String> tiposEnvio,
      @JsonKey(name: 'stock_critico_ml') required this.stockCriticoMl,
      @JsonKey(name: 'stock_bajo_ml') required this.stockBajoMl,
      required this.version})
      : _mlOpciones = mlOpciones,
        _metodosPago = metodosPago,
        _tiposEnvio = tiposEnvio;

  factory _$AppConfigModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppConfigModelImplFromJson(json);

  final List<int> _mlOpciones;
  @override
  @JsonKey(name: 'ml_opciones')
  List<int> get mlOpciones {
    if (_mlOpciones is EqualUnmodifiableListView) return _mlOpciones;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_mlOpciones);
  }

  final List<String> _metodosPago;
  @override
  @JsonKey(name: 'metodos_pago')
  List<String> get metodosPago {
    if (_metodosPago is EqualUnmodifiableListView) return _metodosPago;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_metodosPago);
  }

  final List<String> _tiposEnvio;
  @override
  @JsonKey(name: 'tipos_envio')
  List<String> get tiposEnvio {
    if (_tiposEnvio is EqualUnmodifiableListView) return _tiposEnvio;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tiposEnvio);
  }

  @override
  @JsonKey(name: 'stock_critico_ml')
  final int stockCriticoMl;
  @override
  @JsonKey(name: 'stock_bajo_ml')
  final int stockBajoMl;
  @override
  final String version;

  @override
  String toString() {
    return 'AppConfigModel(mlOpciones: $mlOpciones, metodosPago: $metodosPago, tiposEnvio: $tiposEnvio, stockCriticoMl: $stockCriticoMl, stockBajoMl: $stockBajoMl, version: $version)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppConfigModelImpl &&
            const DeepCollectionEquality()
                .equals(other._mlOpciones, _mlOpciones) &&
            const DeepCollectionEquality()
                .equals(other._metodosPago, _metodosPago) &&
            const DeepCollectionEquality()
                .equals(other._tiposEnvio, _tiposEnvio) &&
            (identical(other.stockCriticoMl, stockCriticoMl) ||
                other.stockCriticoMl == stockCriticoMl) &&
            (identical(other.stockBajoMl, stockBajoMl) ||
                other.stockBajoMl == stockBajoMl) &&
            (identical(other.version, version) || other.version == version));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_mlOpciones),
      const DeepCollectionEquality().hash(_metodosPago),
      const DeepCollectionEquality().hash(_tiposEnvio),
      stockCriticoMl,
      stockBajoMl,
      version);

  /// Create a copy of AppConfigModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppConfigModelImplCopyWith<_$AppConfigModelImpl> get copyWith =>
      __$$AppConfigModelImplCopyWithImpl<_$AppConfigModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppConfigModelImplToJson(
      this,
    );
  }
}

abstract class _AppConfigModel implements AppConfigModel {
  const factory _AppConfigModel(
      {@JsonKey(name: 'ml_opciones') required final List<int> mlOpciones,
      @JsonKey(name: 'metodos_pago') required final List<String> metodosPago,
      @JsonKey(name: 'tipos_envio') required final List<String> tiposEnvio,
      @JsonKey(name: 'stock_critico_ml') required final int stockCriticoMl,
      @JsonKey(name: 'stock_bajo_ml') required final int stockBajoMl,
      required final String version}) = _$AppConfigModelImpl;

  factory _AppConfigModel.fromJson(Map<String, dynamic> json) =
      _$AppConfigModelImpl.fromJson;

  @override
  @JsonKey(name: 'ml_opciones')
  List<int> get mlOpciones;
  @override
  @JsonKey(name: 'metodos_pago')
  List<String> get metodosPago;
  @override
  @JsonKey(name: 'tipos_envio')
  List<String> get tiposEnvio;
  @override
  @JsonKey(name: 'stock_critico_ml')
  int get stockCriticoMl;
  @override
  @JsonKey(name: 'stock_bajo_ml')
  int get stockBajoMl;
  @override
  String get version;

  /// Create a copy of AppConfigModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppConfigModelImplCopyWith<_$AppConfigModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

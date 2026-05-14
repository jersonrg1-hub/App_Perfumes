import 'package:freezed_annotation/freezed_annotation.dart';

part 'cotizacion.freezed.dart';
part 'cotizacion.g.dart';

String  _strOrEmpty(dynamic v)       => v?.toString() ?? '';
double? _toDoubleNullable(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num)   return v.toDouble();
  return double.tryParse(v.toString());
}
int    _toInt(dynamic v) => v == null ? 0 : (v is int ? v : (v as num).toInt());

@freezed
class CotizacionRegistrada with _$CotizacionRegistrada {
  const factory CotizacionRegistrada({
    @JsonKey(name: 'id_cotizacion', fromJson: _strOrEmpty) @Default('') String idCotizacion,
  }) = _CotizacionRegistrada;

  factory CotizacionRegistrada.fromJson(Map<String, dynamic> json) =>
      _$CotizacionRegistradaFromJson(json);
}

@freezed
class CotizacionResponse with _$CotizacionResponse {
  const factory CotizacionResponse({
    @JsonKey(name: 'id_cotizacion', fromJson: _strOrEmpty) @Default('') String idCotizacion,
    @JsonKey(fromJson: _strOrEmpty)                        @Default('') String celular,
    String? fecha,
    String? items,
    @JsonKey(fromJson: _toDoubleNullable) double? total,
    String? estado,
    @JsonKey(name: 'fila_sheet', fromJson: _toInt) @Default(0) int filaSheet,
  }) = _CotizacionResponse;

  factory CotizacionResponse.fromJson(Map<String, dynamic> json) =>
      _$CotizacionResponseFromJson(json);
}

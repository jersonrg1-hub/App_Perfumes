import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_config_model.freezed.dart';
part 'app_config_model.g.dart';

@freezed
class AppConfigModel with _$AppConfigModel {
  const factory AppConfigModel({
    @JsonKey(name: 'ml_opciones')      required List<int>    mlOpciones,
    @JsonKey(name: 'metodos_pago')     required List<String> metodosPago,
    @JsonKey(name: 'tipos_envio')      required List<String> tiposEnvio,
    @JsonKey(name: 'stock_critico_ml') required int          stockCriticoMl,
    @JsonKey(name: 'stock_bajo_ml')    required int          stockBajoMl,
    required String version,
  }) = _AppConfigModel;

  factory AppConfigModel.fromJson(Map<String, dynamic> json) =>
      _$AppConfigModelFromJson(json);

  factory AppConfigModel.defaults() => const AppConfigModel(
    mlOpciones:     [2, 5, 10],
    metodosPago:    ['Yape', 'Plin', 'Transferencia', 'Tarjeta'],
    tiposEnvio:     ['Shalom', 'Motorizado', 'Contraentrega'],
    stockCriticoMl: 10,
    stockBajoMl:    20,
    version:        '—',
  );
}

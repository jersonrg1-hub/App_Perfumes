import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:perfuteca/models/app_config_model.dart';

part 'perfume.freezed.dart';
part 'perfume.g.dart';

@freezed
class Perfume with _$Perfume {
  const factory Perfume({
    @JsonKey(name: 'id_perfume')       required String idPerfume,
    required String marca,
    required String nombre,
    @JsonKey(name: 'precio_2ml')       double? precio2ml,
    @JsonKey(name: 'precio_5ml')       double? precio5ml,
    @JsonKey(name: 'precio_10ml')      double? precio10ml,
    @JsonKey(name: 'stock_ml')         double? stockMl,
    String? notas,
    @JsonKey(name: 'perfil_olfativo')  String? perfilOlfativo,
    @JsonKey(name: 'image_url')        String? imageUrl,
    String? ocasion,
    String? estacion,
    String? hora,
    @JsonKey(name: 'palabra_clave') String? palabraClave,
  }) = _Perfume;

  factory Perfume.fromJson(Map<String, dynamic> json) => _$PerfumeFromJson(json);
}

extension PerfumeX on Perfume {
  String get displayName => '$marca — $nombre';

  Map<int, double> get precios => {
    if (precio2ml  != null) 2:  precio2ml!,
    if (precio5ml  != null) 5:  precio5ml!,
    if (precio10ml != null) 10: precio10ml!,
  };

  bool get tieneStock => (stockMl ?? 0) > 0;

  // Getters con default 10/20 — preferir esStockCritico/esStockBajo con los
  // umbrales de AppConfigModel (backend, /api/v1/config) cuando estén disponibles.
  bool get stockCritico => esStockCritico(10);
  bool get stockBajo    => esStockBajo(critico: 10, bajo: 20);

  bool esStockCritico(int critico) => (stockMl ?? 0) <= critico && tieneStock;
  bool esStockBajo({required int critico, required int bajo}) =>
      (stockMl ?? 0) <= bajo && tieneStock && !esStockCritico(critico);

  /// Estado de stock combinado según umbrales de [AppConfigModel].
  /// Preferir sobre llamar esStockCritico/esStockBajo por separado.
  ({bool esCritico, bool esBajo}) stockEstado(AppConfigModel config) {
    final esCritico = esStockCritico(config.stockCriticoMl);
    final esBajo = esStockBajo(
      critico: config.stockCriticoMl,
      bajo: config.stockBajoMl,
    );
    return (esCritico: esCritico, esBajo: esBajo);
  }
}

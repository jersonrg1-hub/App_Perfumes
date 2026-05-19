import 'package:freezed_annotation/freezed_annotation.dart';

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

  bool get tieneStock   => (stockMl ?? 0) > 0;
  bool get stockCritico => (stockMl ?? 0) <= 5  && tieneStock;
  bool get stockBajo    => (stockMl ?? 0) <= 15 && tieneStock && !stockCritico;
}

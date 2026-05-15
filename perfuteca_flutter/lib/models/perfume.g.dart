// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'perfume.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PerfumeImpl _$$PerfumeImplFromJson(Map<String, dynamic> json) =>
    _$PerfumeImpl(
      idPerfume: json['id_perfume'] as String,
      marca: json['marca'] as String,
      nombre: json['nombre'] as String,
      precio2ml: (json['precio_2ml'] as num?)?.toDouble(),
      precio5ml: (json['precio_5ml'] as num?)?.toDouble(),
      precio10ml: (json['precio_10ml'] as num?)?.toDouble(),
      stockMl: (json['stock_ml'] as num?)?.toDouble(),
      notas: json['notas'] as String?,
      perfilOlfativo: json['perfil_olfativo'] as String?,
      imageUrl: json['image_url'] as String?,
      ocasion: json['ocasion'] as String?,
      estacion: json['estacion'] as String?,
      hora: json['hora'] as String?,
    );

Map<String, dynamic> _$$PerfumeImplToJson(_$PerfumeImpl instance) =>
    <String, dynamic>{
      'id_perfume': instance.idPerfume,
      'marca': instance.marca,
      'nombre': instance.nombre,
      'precio_2ml': instance.precio2ml,
      'precio_5ml': instance.precio5ml,
      'precio_10ml': instance.precio10ml,
      'stock_ml': instance.stockMl,
      'notas': instance.notas,
      'perfil_olfativo': instance.perfilOlfativo,
      'image_url': instance.imageUrl,
      'ocasion': instance.ocasion,
      'estacion': instance.estacion,
      'hora': instance.hora,
    };

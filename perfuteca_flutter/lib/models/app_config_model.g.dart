// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppConfigModelImpl _$$AppConfigModelImplFromJson(Map<String, dynamic> json) =>
    _$AppConfigModelImpl(
      mlOpciones: (json['ml_opciones'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      metodosPago: (json['metodos_pago'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      tiposEnvio: (json['tipos_envio'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      stockCriticoMl: (json['stock_critico_ml'] as num).toInt(),
      stockBajoMl: (json['stock_bajo_ml'] as num).toInt(),
      version: json['version'] as String,
    );

Map<String, dynamic> _$$AppConfigModelImplToJson(
        _$AppConfigModelImpl instance) =>
    <String, dynamic>{
      'ml_opciones': instance.mlOpciones,
      'metodos_pago': instance.metodosPago,
      'tipos_envio': instance.tiposEnvio,
      'stock_critico_ml': instance.stockCriticoMl,
      'stock_bajo_ml': instance.stockBajoMl,
      'version': instance.version,
    };

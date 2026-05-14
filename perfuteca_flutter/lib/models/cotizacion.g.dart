// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cotizacion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CotizacionRegistradaImpl _$$CotizacionRegistradaImplFromJson(
        Map<String, dynamic> json) =>
    _$CotizacionRegistradaImpl(
      idCotizacion: json['id_cotizacion'] == null
          ? ''
          : _strOrEmpty(json['id_cotizacion']),
    );

Map<String, dynamic> _$$CotizacionRegistradaImplToJson(
        _$CotizacionRegistradaImpl instance) =>
    <String, dynamic>{
      'id_cotizacion': instance.idCotizacion,
    };

_$CotizacionResponseImpl _$$CotizacionResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$CotizacionResponseImpl(
      idCotizacion: json['id_cotizacion'] == null
          ? ''
          : _strOrEmpty(json['id_cotizacion']),
      celular: json['celular'] == null ? '' : _strOrEmpty(json['celular']),
      fecha: json['fecha'] as String?,
      items: json['items'] as String?,
      total: _toDoubleNullable(json['total']),
      estado: json['estado'] as String?,
      filaSheet: json['fila_sheet'] == null ? 0 : _toInt(json['fila_sheet']),
    );

Map<String, dynamic> _$$CotizacionResponseImplToJson(
        _$CotizacionResponseImpl instance) =>
    <String, dynamic>{
      'id_cotizacion': instance.idCotizacion,
      'celular': instance.celular,
      'fecha': instance.fecha,
      'items': instance.items,
      'total': instance.total,
      'estado': instance.estado,
      'fila_sheet': instance.filaSheet,
    };

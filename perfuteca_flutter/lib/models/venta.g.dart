// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venta.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VentaResponseImpl _$$VentaResponseImplFromJson(Map<String, dynamic> json) =>
    _$VentaResponseImpl(
      idCompra: json['id_compra'] == null ? '' : _strOrEmpty(json['id_compra']),
      filaSheet: json['fila_sheet'] == null ? 0 : _toInt(json['fila_sheet']),
      fecha: _toStrNullable(json['fecha']),
      comprador: _toStrNullable(json['comprador']),
      celular: _toStrNullable(json['celular']),
      idPerfume: _toStrNullable(json['id_perfume']),
      mlVendido: _toIntNullable(json['ml_vendido']),
      precioCobrado: _toDoubleNullable(json['precio_cobrado']),
      metodoPago: _toStrNullable(json['metodo_pago']),
      tipoEnvio: _toStrNullable(json['tipo_envio']),
      direccion: _toStrNullable(json['direccion']),
      distrito: _toStrNullable(json['distrito']),
      estado: _toStrNullable(json['estado']),
      alias: _toStrNullable(json['alias']),
    );

Map<String, dynamic> _$$VentaResponseImplToJson(_$VentaResponseImpl instance) =>
    <String, dynamic>{
      'id_compra': instance.idCompra,
      'fila_sheet': instance.filaSheet,
      'fecha': instance.fecha,
      'comprador': instance.comprador,
      'celular': instance.celular,
      'id_perfume': instance.idPerfume,
      'ml_vendido': instance.mlVendido,
      'precio_cobrado': instance.precioCobrado,
      'metodo_pago': instance.metodoPago,
      'tipo_envio': instance.tipoEnvio,
      'direccion': instance.direccion,
      'distrito': instance.distrito,
      'estado': instance.estado,
      'alias': instance.alias,
    };

_$ClientePrevioImpl _$$ClientePrevioImplFromJson(Map<String, dynamic> json) =>
    _$ClientePrevioImpl(
      comprador: json['comprador'] as String,
      direccion: json['direccion'] as String,
      distrito: json['distrito'] as String? ?? '',
      tipoEnvio: json['tipo_envio'] as String,
      metodoPago: json['metodo_pago'] as String,
      totalCompras:
          json['total_compras'] == null ? 0 : _toInt(json['total_compras']),
      alias: _toStrNullable(json['alias']),
    );

Map<String, dynamic> _$$ClientePrevioImplToJson(_$ClientePrevioImpl instance) =>
    <String, dynamic>{
      'comprador': instance.comprador,
      'direccion': instance.direccion,
      'distrito': instance.distrito,
      'tipo_envio': instance.tipoEnvio,
      'metodo_pago': instance.metodoPago,
      'total_compras': instance.totalCompras,
      'alias': instance.alias,
    };

_$VentaRegistradaImpl _$$VentaRegistradaImplFromJson(
        Map<String, dynamic> json) =>
    _$VentaRegistradaImpl(
      idCompra: json['id_compra'] == null ? '' : _strOrEmpty(json['id_compra']),
      warning: json['warning'] as String?,
    );

Map<String, dynamic> _$$VentaRegistradaImplToJson(
        _$VentaRegistradaImpl instance) =>
    <String, dynamic>{
      'id_compra': instance.idCompra,
      'warning': instance.warning,
    };

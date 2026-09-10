abstract class ApiConstants {
  static const String catalogo      = '/api/v1/catalogo/';
  static const String catalogoBuscar = '/api/v1/catalogo/buscar';
  static const String catalogoMarcas = '/api/v1/catalogo/marcas';
  static const String catalogoInvalidar = '/api/v1/catalogo/invalidar';
  static const String ventas        = '/api/v1/ventas/';
  static const String cotizaciones  = '/api/v1/cotizaciones/';
  static const String estadisticasResumen   = '/api/v1/estadisticas/resumen';
  static const String estadisticasClientes  = '/api/v1/estadisticas/clientes';
  static const String estadisticasHistorico = '/api/v1/estadisticas/historico';
  static const String ventasPendientes     = '/api/v1/ventas/pendientes';
  static const String config               = '/api/v1/config';
  static const String health        = '/health';

  static String catalogoDetalle(String id) =>
      '/api/v1/catalogo/${Uri.encodeComponent(id)}';
  static String catalogoStock(String id) =>
      '/api/v1/catalogo/${Uri.encodeComponent(id)}/stock';
  static String ventasCliente(String celular) =>
      '/api/v1/ventas/cliente/${Uri.encodeComponent(celular)}';
  static String cotizacionesCliente(String celular) =>
      '/api/v1/cotizaciones/cliente/${Uri.encodeComponent(celular)}';
  static String cotizacionesDetalle(String idCotizacion) =>
      '/api/v1/cotizaciones/${Uri.encodeComponent(idCotizacion)}';
  static String ventaEstado(String idVenta) =>
      '/api/v1/ventas/${Uri.encodeComponent(idVenta)}/estado';
}

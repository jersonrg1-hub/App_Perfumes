import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart'
    show normalizeId;
import 'package:perfuteca/models/venta.dart';

/// Ventas de una misma compra (id_compra) agrupadas en una sola orden.
class OrdenAgrupada {
  OrdenAgrupada({required this.idCompra, required this.items})
      : itemsConNormId = items
            .map((i) => (
                  item: i,
                  normId: i.idPerfume != null ? normalizeId(i.idPerfume!) : null,
                ))
            .toList();

  final String              idCompra;
  final List<VentaResponse> items;
  // Normaliza el id de perfume una sola vez al agrupar — evita re-parsear en
  // cada rebuild de las cards que la consumen.
  final List<({VentaResponse item, String? normId})> itemsConNormId;

  String? get comprador  => items.first.comprador;
  String? get celular    => items.first.celular;
  String? get direccion  => items.first.direccion;
  String? get distrito   => items.first.distrito;
  String? get tipoEnvio  => items.first.tipoEnvio;
  String? get metodoPago => items.first.metodoPago;
  String? get fecha      => items.first.fecha;
  String? get estado     => items.first.estado;

  double get total => items.fold(0.0, (s, i) => s + (i.precioCobrado ?? 0));
  List<int> get filas => items.map((i) => i.filaSheet).toList();
}

/// Agrupa ventas por id_compra preservando el orden original de aparición.
List<OrdenAgrupada> agruparOrdenes(List<VentaResponse> ventas) {
  final map = <String, List<VentaResponse>>{};
  for (final v in ventas) {
    if (v.idCompra.isEmpty) continue;
    (map[v.idCompra] ??= []).add(v);
  }
  return map.entries
      .map((e) => OrdenAgrupada(idCompra: e.key, items: e.value))
      .toList();
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/models/venta.dart';
import 'package:perfuteca/repositories/estadisticas_repository.dart';
import 'package:perfuteca/repositories/ventas_repository.dart';

// Perú es UTC-5 fijo (sin DST) — el backend agrupa "hoy"/mes/semana con esa
// fecha, así que la UI debe usar el mismo día en vez del reloj local del
// dispositivo (evita desfases con viajeros o celulares mal configurados).
// Se devuelve como DateTime "local" (no isUtc) a propósito: DateTime.parse()
// de fechas sin hora (ej. "2026-08-07", como vienen del backend) también
// crea DateTime locales — si nowPeru() quedara marcado isUtc=true, cualquier
// .isBefore/.isAfter/.difference/.subtract que lo mezcle con esas fechas
// compararía instantes absolutos con convenciones de offset distintas y
// volvería a romperse justo en el caso (huso del dispositivo ≠ Perú) que
// se busca arreglar.
DateTime nowPeru() {
  final u = DateTime.now().toUtc().subtract(const Duration(hours: 5));
  return DateTime(u.year, u.month, u.day, u.hour, u.minute, u.second,
      u.millisecond, u.microsecond);
}

// Proveedor principal: datos pre-agregados del backend (reemplaza ventasParaStatsProvider)
final resumenBackendProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  ref.keepAlive();
  return ref.watch(estadisticasRepositoryProvider).getResumen();
});

// Ventas crudas de TODO el historial — alimenta el detalle de ventas de un
// día en ResumenTab. El backend cappea cada página a 500 (límite del query
// param 'limit'), así que se pagina hasta agotar 'has_more' en vez de leer
// una sola página — de lo contrario un día con ventas antiguas fuera de las
// últimas 500 aparecía vacío en el detalle.
final ventasParaStatsProvider = FutureProvider<List<VentaResponse>>((ref) async {
  ref.keepAlive();
  final repo = ref.watch(ventasRepositoryProvider);
  final ventas = <VentaResponse>[];
  var offset = 0;
  while (true) {
    final page = await repo.getVentas(limit: 500, offset: offset, bypassCache: true);
    ventas.addAll(page.items);
    if (!page.hasMore) break;
    offset += page.items.length;
  }
  return ventas;
});

// Históricos pre-agregados del backend (sin tope de 500) — alimenta
// historialGlobalProvider, mesesDisponiblesProvider y mesStatsMapProvider.
final historicoBackendProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  ref.keepAlive();
  return ref.watch(estadisticasRepositoryProvider).getHistorico();
});

// ── Resumen (hoy + mes + top perfumes) ───────────────────────────────────────

class DistritoStat {
  const DistritoStat({
    required this.nombre,
    required this.pedidos,
    required this.totalSoles,
  });
  final String nombre;
  final int    pedidos;
  final double totalSoles;
}

class TopPerfume {
  const TopPerfume({
    required this.nombre,
    required this.marca,
    required this.totalMl,
    required this.totalSoles,
  });
  final String nombre;
  final String marca;
  final int    totalMl;
  final double totalSoles;
}

class ResumenStats {
  const ResumenStats({
    required this.ventasHoy,
    required this.totalHoy,
    required this.ticketPromedioHoy,
    required this.mlHoy,
    required this.ventasMes,
    required this.totalMes,
    required this.ticketPromedioMes,
    required this.mlMes,
    required this.ventasMesPasado,
    required this.totalMesPasado,
    required this.pendientesCount,
    required this.masVendidos,
  });
  final int    ventasHoy;
  final double totalHoy;
  final double ticketPromedioHoy;
  final int    mlHoy;
  final int    ventasMes;
  final double totalMes;
  final double ticketPromedioMes;
  final int    mlMes;
  final int    ventasMesPasado;
  final double totalMesPasado;
  final int    pendientesCount;
  final List<TopPerfume> masVendidos;

  double get variacionMes => totalMesPasado > 0
      ? (totalMes - totalMesPasado) / totalMesPasado * 100
      : 0;
}

final resumenStatsProvider = FutureProvider<ResumenStats>((ref) async {
  ref.keepAlive();
  final data        = await ref.watch(resumenBackendProvider.future);
  final perfumesMap = await ref.watch(perfumesMapProvider.future);

  final hoy       = data['hoy']       as Map<String, dynamic>? ?? {};
  final mes       = data['mes']       as Map<String, dynamic>? ?? {};
  final mesPasado = data['mes_pasado'] as Map<String, dynamic>? ?? {};
  final pendientesData = data['pendientes'] as int? ?? 0;

  final topRaw = data['top_perfumes'] as List<dynamic>? ?? [];
  final masVendidos = topRaw.take(5).map((e) {
    final map   = e as Map<String, dynamic>;
    final id    = map['id_perfume']?.toString() ?? '';
    final normId = double.tryParse(id)?.toInt().toString() ?? id;
    final p     = perfumesMap[normId];
    return TopPerfume(
      nombre:     p?.nombre ?? 'Perfume #$id',
      marca:      p?.marca  ?? '',
      totalMl:    (map['total_ml'] as num?)?.toInt() ?? 0,
      totalSoles: (map['total_soles'] as num?)?.toDouble() ?? 0,
    );
  }).toList();

  final ventasHoy = (hoy['ventas'] as num?)?.toInt() ?? 0;
  final totalHoy  = (hoy['total']  as num?)?.toDouble() ?? 0;
  final ventasMes = (mes['ventas'] as num?)?.toInt() ?? 0;
  final totalMes  = (mes['total']  as num?)?.toDouble() ?? 0;

  return ResumenStats(
    ventasHoy:         ventasHoy,
    totalHoy:          totalHoy,
    ticketPromedioHoy: ventasHoy > 0 ? totalHoy / ventasHoy : 0,
    mlHoy:             (hoy['ml'] as num?)?.toInt() ?? 0,
    ventasMes:         ventasMes,
    totalMes:          totalMes,
    ticketPromedioMes: ventasMes > 0 ? totalMes / ventasMes : 0,
    mlMes:             (mes['ml'] as num?)?.toInt() ?? 0,
    ventasMesPasado:   (mesPasado['ventas'] as num?)?.toInt() ?? 0,
    totalMesPasado:    (mesPasado['total']  as num?)?.toDouble() ?? 0,
    pendientesCount:   pendientesData,
    masVendidos:       masVendidos,
  );
});

// ── Tamaños ───────────────────────────────────────────────────────────────────

class TamanioStat {
  const TamanioStat({
    required this.ml,
    required this.cantidad,
    required this.total,
    required this.topPerfumes,
  });
  final int                  ml;
  final int                  cantidad;
  final double               total;
  final List<PerfumeDiaStat> topPerfumes;
}

/// Mapea una lista cruda `{ml, cantidad, total}` del backend a [TamanioStat],
/// ordenada por cantidad descendente.
List<TamanioStat> tamaniosFromJson(List<dynamic> raw) {
  return raw
      .map((e) {
        final m = e as Map<String, dynamic>;
        return TamanioStat(
          ml:          (m['ml']       as num?)?.toInt()    ?? 0,
          cantidad:    (m['cantidad'] as num?)?.toInt()    ?? 0,
          total:       (m['total']    as num?)?.toDouble() ?? 0,
          topPerfumes: const [],
        );
      })
      .toList()
    ..sort((a, b) => b.cantidad.compareTo(a.cantidad));
}

// Pre-agregado por el backend sobre TODO el mes (sin tope de 500 filas).
final tamaniosStatsProvider = FutureProvider<List<TamanioStat>>((ref) async {
  ref.keepAlive();
  final data = await ref.watch(resumenBackendProvider.future);
  return tamaniosFromJson(data['tamanios'] as List<dynamic>? ?? []);
});

// ── Semanal ───────────────────────────────────────────────────────────────────

class PerfumeDiaStat {
  const PerfumeDiaStat({
    required this.nombre,
    required this.totalMl,
    required this.totalSoles,
  });
  final String nombre;
  final int    totalMl;
  final double totalSoles;
}

class DiaStat {
  const DiaStat({
    required this.fecha,
    required this.numOrdenes,
    required this.total,
    required this.topPerfumes,
  });
  final DateTime              fecha;
  final int                   numOrdenes;
  final double                total;
  final List<PerfumeDiaStat>  topPerfumes;
}

class SemanaStat {
  const SemanaStat({
    required this.total,
    required this.totalMl,
    required this.numOrdenes,
    required this.porDia,
    required this.topNombre,
    required this.topCantidad,
    required this.topMl,
    required this.topTotal,
    required this.inicio,
    required this.fin,
    required this.totalSemanaAnterior,
  });
  final double        total;
  final int           totalMl;
  final int           numOrdenes;
  final List<DiaStat> porDia;
  final String        topNombre;
  final int           topCantidad;
  final int           topMl;
  final double        topTotal;
  final DateTime      inicio;
  final DateTime      fin;
  final double        totalSemanaAnterior;

  double get variacionSemana => totalSemanaAnterior > 0
      ? (total - totalSemanaAnterior) / totalSemanaAnterior * 100
      : 0;
}

final semanaStatsProvider = FutureProvider<SemanaStat>((ref) async {
  ref.keepAlive();
  final data       = await ref.watch(resumenBackendProvider.future);
  final semanalRaw = data['semanal'] as List<dynamic>? ?? [];
  final semAntTotal  = (data['semana_anterior_total'] as num?)?.toDouble() ?? 0;

  // Derivar inicio/fin a partir de la primera fecha del backend o de hoy
  final now    = DateTime.now();
  final hoy    = DateTime(now.year, now.month, now.day);
  final inicio = hoy.subtract(Duration(days: hoy.weekday - 1));
  final fin    = inicio.add(const Duration(days: 6));

  final porDia = semanalRaw.map((e) {
    final map = e as Map<String, dynamic>;
    return DiaStat(
      fecha:       DateTime.parse(map['fecha'] as String),
      numOrdenes:  (map['ordenes'] as num?)?.toInt() ?? 0,
      total:       (map['total']   as num?)?.toDouble() ?? 0,
      topPerfumes: const [],  // backend no devuelve top por día
    );
  }).toList();

  final totalSemana  = porDia.fold(0.0, (s, d) => s + d.total);
  final totalMlSem   = semanalRaw.fold<int>(
      0, (s, e) => s + ((e as Map)['ml'] as num? ?? 0).toInt());
  final numOrdenes   = porDia.fold(0, (s, d) => s + d.numOrdenes);

  return SemanaStat(
    total:               totalSemana,
    totalMl:             totalMlSem,
    numOrdenes:          numOrdenes,
    porDia:              porDia,
    topNombre:           '',   // sin datos per-perfume del backend esta semana
    topCantidad:         0,
    topMl:               0,
    topTotal:            0,
    inicio:              inicio,
    fin:                 fin,
    totalSemanaAnterior: semAntTotal,
  );
});

// ── Meses disponibles (para comparación) ─────────────────────────────────────

final mesesDisponiblesProvider = FutureProvider<List<String>>((ref) async {
  ref.keepAlive();
  final data   = await ref.watch(historicoBackendProvider.future);
  final porMes = data['por_mes'] as List<dynamic>? ?? [];
  return porMes
      .map((e) => (e as Map<String, dynamic>)['clave'] as String)
      .toList()
    ..sort();
});

// ── Mapa de stats por mes ─────────────────────────────────────────────────────

class MesStat {
  const MesStat({required this.numOrdenes, required this.total});
  final int    numOrdenes;
  final double total;
}

final mesStatsMapProvider = FutureProvider<Map<String, MesStat>>((ref) async {
  ref.keepAlive();
  final data   = await ref.watch(historicoBackendProvider.future);
  final porMes = data['por_mes'] as List<dynamic>? ?? [];

  return {
    for (final e in porMes)
      (e as Map<String, dynamic>)['clave'] as String: MesStat(
        numOrdenes: (e['num_ordenes'] as num?)?.toInt() ?? 0,
        total:      (e['total'] as num?)?.toDouble() ?? 0,
      ),
  };
});

// ── Clientes ──────────────────────────────────────────────────────────────────

class ClienteStat {
  const ClienteStat({
    required this.celular,
    required this.nombre,
    required this.direccion,
    required this.distrito,
    required this.totalCompras,
    required this.totalItems,
    required this.totalGastado,
    required this.primeraCompra,
    required this.ultimaCompra,
  });
  final String  celular;
  final String  nombre;
  final String  direccion;
  final String  distrito;
  final int     totalCompras;
  final int     totalItems;
  final double  totalGastado;
  final String? primeraCompra;
  final String? ultimaCompra;
}

// Lista de clientes pre-agregada por el backend — mucho más ligero que
// descargar 500 ventas y procesarlas localmente.
final clientesStatsProvider = FutureProvider<List<ClienteStat>>((ref) async {
  ref.keepAlive();
  final lista = await ref.watch(estadisticasRepositoryProvider).getClientes();
  return lista.map((m) => ClienteStat(
    celular:       m['celular']       as String?  ?? '',
    nombre:        m['nombre']        as String?  ?? '',
    direccion:     m['direccion']     as String?  ?? '',
    distrito:      m['distrito']      as String?  ?? '',
    totalCompras:  m['total_compras'] as int?     ?? 0,
    totalItems:    m['total_items']   as int?     ?? 0,
    totalGastado:  (m['total_gastado'] as num?)?.toDouble() ?? 0.0,
    primeraCompra: m['primera_compra'] as String?,
    ultimaCompra:  m['ultima_compra']  as String?,
  )).toList();
});

// Historial de ventas de un cliente — carga on-demand al expandir la tarjeta.
final ventasClienteProvider =
    FutureProvider.autoDispose.family<List<VentaResponse>, String>(
  (ref, celular) =>
      ref.watch(ventasRepositoryProvider).getVentasCliente(celular),
);

// ── Historial global (todo el tiempo) ─────────────────────────────────────────

class MesStatHistorico {
  const MesStatHistorico({
    required this.clave,
    required this.label,
    required this.numOrdenes,
    required this.total,
    required this.totalMl,
    this.topPerfumes = const [],
  });
  final String         clave;
  final String         label;
  final int            numOrdenes;
  final double         total;
  final int            totalMl;
  final List<TopPerfume> topPerfumes;
}

class HistorialGlobalStats {
  const HistorialGlobalStats({
    required this.totalVentas,
    required this.totalIngresos,
    required this.totalMl,
    required this.ticketPromedio,
    required this.clientesUnicos,
    required this.diasActivo,
    required this.primeraVenta,
    required this.promedioMensual,
    required this.porMes,
    required this.mejorMesClave,
    required this.masVendidosHistorico,
    required this.distritoRanking,
  });
  final int                    totalVentas;
  final double                 totalIngresos;
  final int                    totalMl;
  final double                 ticketPromedio;
  final int                    clientesUnicos;
  final int                    diasActivo;
  final String?                primeraVenta;
  final double                 promedioMensual;
  final List<MesStatHistorico> porMes;
  final String?                mejorMesClave;
  final List<TopPerfume>       masVendidosHistorico;
  final List<DistritoStat>     distritoRanking;
}

TopPerfume _topPerfumeFromJson(Map<String, dynamic> e, Map<String, dynamic> perfumesMap) {
  final id     = e['id_perfume']?.toString() ?? '';
  final normId = double.tryParse(id)?.toInt().toString() ?? id;
  final p      = perfumesMap[normId];
  return TopPerfume(
    nombre:     p?.nombre ?? 'Perfume #$id',
    marca:      p?.marca  ?? '',
    totalMl:    (e['total_ml']    as num?)?.toInt()    ?? 0,
    totalSoles: (e['total_soles'] as num?)?.toDouble() ?? 0,
  );
}

final historialGlobalProvider = FutureProvider<HistorialGlobalStats>((ref) async {
  ref.keepAlive();
  final data        = await ref.watch(historicoBackendProvider.future);
  final perfumesMap = await ref.watch(perfumesMapProvider.future);

  final totalVentas   = (data['total_ventas']    as num?)?.toInt()    ?? 0;
  final totalIngresos = (data['total_ingresos']  as num?)?.toDouble() ?? 0;
  final totalMl       = (data['total_ml']        as num?)?.toInt()    ?? 0;
  final clientesUnicos = (data['clientes_unicos'] as num?)?.toInt()   ?? 0;
  final primeraVenta  = data['primera_venta'] as String?;

  int diasActivo = 0;
  if (primeraVenta != null) {
    try {
      diasActivo = nowPeru().difference(DateTime.parse(primeraVenta)).inDays + 1;
    } catch (_) {}
  }

  final porMesRaw = data['por_mes'] as List<dynamic>? ?? [];
  final porMes = porMesRaw.map((e) {
    final m = e as Map<String, dynamic>;
    final topRaw = m['top_perfumes'] as List<dynamic>? ?? [];
    return MesStatHistorico(
      clave:       m['clave'] as String,
      label:       m['label'] as String,
      numOrdenes:  (m['num_ordenes'] as num?)?.toInt() ?? 0,
      total:       (m['total']      as num?)?.toDouble() ?? 0,
      totalMl:     (m['total_ml']   as num?)?.toInt() ?? 0,
      topPerfumes: topRaw
          .map((pe) => _topPerfumeFromJson(pe as Map<String, dynamic>, perfumesMap))
          .toList(),
    );
  }).toList();

  final mejorMesClave   = data['mejor_mes_clave']  as String?;
  final promedioMensual = (data['promedio_mensual'] as num?)?.toDouble() ?? 0;

  final topPerfumesRaw = data['top_perfumes'] as List<dynamic>? ?? [];
  final masVendidosHistorico = topPerfumesRaw
      .map((e) => _topPerfumeFromJson(e as Map<String, dynamic>, perfumesMap))
      .toList();

  final distritosRaw = data['ranking_distritos'] as List<dynamic>? ?? [];
  final distritoRanking = distritosRaw.map((e) {
    final m = e as Map<String, dynamic>;
    return DistritoStat(
      nombre:     m['nombre'] as String,
      pedidos:    (m['pedidos']     as num?)?.toInt()    ?? 0,
      totalSoles: (m['total_soles'] as num?)?.toDouble() ?? 0,
    );
  }).toList();

  return HistorialGlobalStats(
    totalVentas:          totalVentas,
    totalIngresos:        totalIngresos,
    totalMl:              totalMl,
    ticketPromedio:       totalVentas > 0 ? totalIngresos / totalVentas : 0.0,
    clientesUnicos:       clientesUnicos,
    diasActivo:           diasActivo,
    primeraVenta:         primeraVenta,
    promedioMensual:      promedioMensual,
    porMes:               porMes,
    mejorMesClave:        mejorMesClave,
    masVendidosHistorico: masVendidosHistorico,
    distritoRanking:      distritoRanking,
  );
});

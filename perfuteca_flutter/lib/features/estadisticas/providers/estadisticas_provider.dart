import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/models/venta.dart';
import 'package:perfuteca/repositories/estadisticas_repository.dart';
import 'package:perfuteca/repositories/ventas_repository.dart';

// Proveedor principal: datos pre-agregados del backend (reemplaza ventasParaStatsProvider)
final resumenBackendProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  ref.keepAlive();
  return ref.watch(estadisticasRepositoryProvider).getResumen();
});

// Ventas crudas: usadas por historial, clientes y comparación de meses.
// Con caché normal (5 min) — ya no se bypasea.
final ventasParaStatsProvider = FutureProvider<List<VentaResponse>>((ref) async {
  ref.keepAlive();
  final page = await ref.watch(ventasRepositoryProvider)
      .getVentas(limit: 500, bypassCache: true);
  return page.items;
});

// ── Helpers normalización de distritos ───────────────────────────────────────

String _normalizarDistrito(String s) {
  const from = 'áàäâãéèëêíìïîóòöôõúùüûÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛñÑ';
  const to   = 'aaaaaeeeeiiiiooooouuuuAAAAAEEEEIIIIOOOOOUUUUnn';
  final buf = StringBuffer();
  for (final c in s.toLowerCase().runes) {
    final ch = String.fromCharCode(c);
    final idx = from.indexOf(ch);
    buf.write(idx >= 0 ? to[idx] : ch);
  }
  return buf.toString();
}

String _titleCase(String s) => s
    .split(' ')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

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

final tamaniosStatsProvider = FutureProvider<List<TamanioStat>>((ref) async {
  ref.keepAlive();
  final ventas = await ref.watch(ventasParaStatsProvider.future);
  final now    = DateTime.now();

  // Filtrar solo ventas del mes actual (Entregado + Pendiente, igual que backend)
  final delMes = ventas.where((v) {
    if (v.estado?.toLowerCase() == 'anulado') return false;
    if (v.fecha == null) return false;
    try {
      final d = DateTime.parse(v.fecha!);
      return d.year == now.year && d.month == now.month;
    } catch (_) {
      return false;
    }
  });

  final mlMap = <int, ({int cantidad, double total})>{};
  for (final v in delMes) {
    final ml = v.mlVendido ?? 0;
    if (ml == 0) continue;
    final prev = mlMap[ml] ?? (cantidad: 0, total: 0.0);
    mlMap[ml] = (
      cantidad: prev.cantidad + 1,
      total:    prev.total + (v.precioCobrado ?? 0),
    );
  }

  return mlMap.entries
      .map((e) => TamanioStat(
            ml:          e.key,
            cantidad:    e.value.cantidad,
            total:       e.value.total,
            topPerfumes: const [],
          ))
      .toList()
    ..sort((a, b) => b.cantidad.compareTo(a.cantidad));
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
  final ventas = await ref.watch(ventasParaStatsProvider.future);
  final set    = <String>{};

  for (final v in ventas.where((v) => v.estado?.toLowerCase() != 'anulado')) {
    if (v.fecha == null) continue;
    try {
      final d = DateTime.parse(v.fecha!);
      set.add('${d.year}-${d.month.toString().padLeft(2, '0')}');
    } catch (_) {}
  }
  return set.toList()..sort();
});

// ── Mapa de stats por mes ─────────────────────────────────────────────────────

class MesStat {
  const MesStat({required this.numOrdenes, required this.total});
  final int    numOrdenes;
  final double total;
}

final mesStatsMapProvider = FutureProvider<Map<String, MesStat>>((ref) async {
  ref.keepAlive();
  final ventas     = await ref.watch(ventasParaStatsProvider.future);
  // Incluye Pendiente — cobros por adelantado. Excluye solo Anulado.
  final entregadas = ventas.where((v) => v.estado?.toLowerCase() != 'anulado');

  final map = <String, List<VentaResponse>>{};
  for (final v in entregadas) {
    if (v.fecha == null) continue;
    try {
      final d   = DateTime.parse(v.fecha!);
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      (map[key] ??= []).add(v);
    } catch (_) {}
  }

  return {
    for (final e in map.entries)
      e.key: MesStat(
        numOrdenes: e.value.map((v) => v.idCompra).toSet().length,
        total:      e.value.fold(0.0, (s, v) => s + (v.precioCobrado ?? 0)),
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

final historialGlobalProvider = FutureProvider<HistorialGlobalStats>((ref) async {
  ref.keepAlive();
  final ventas      = await ref.watch(ventasParaStatsProvider.future);
  final perfumesMap = await ref.watch(perfumesMapProvider.future);
  // Incluye Pendiente — cobros por adelantado. Excluye solo Anulado.
  final entregadas = ventas
      .where((v) => v.estado?.toLowerCase() != 'anulado')
      .toList();

  final totalVentas    = entregadas.map((v) => v.idCompra).toSet().length;
  final totalIngresos  = entregadas.fold(0.0, (s, v) => s + (v.precioCobrado ?? 0));
  final totalMl        = entregadas.fold(0, (s, v) => s + (v.mlVendido ?? 0));
  final ticketProm     = totalVentas > 0 ? totalIngresos / totalVentas : 0.0;
  final clientesUnicos = entregadas
      .map((v) => v.celular ?? '')
      .where((c) => c.isNotEmpty)
      .toSet()
      .length;

  final fechas = entregadas
      .where((v) => v.fecha != null)
      .map((v) => v.fecha!)
      .toList()
    ..sort();
  final primeraVenta = fechas.isEmpty ? null : fechas.first;

  int diasActivo = 0;
  if (primeraVenta != null) {
    try {
      final primera = DateTime.parse(primeraVenta);
      diasActivo = DateTime.now().difference(primera).inDays + 1;
    } catch (_) {}
  }

  const mesesCortos = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                       'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

  final mesMap = <String, List<VentaResponse>>{};
  for (final v in entregadas) {
    if (v.fecha == null) continue;
    try {
      final d   = DateTime.parse(v.fecha!);
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      (mesMap[key] ??= []).add(v);
    } catch (_) {}
  }

  final porMes = mesMap.entries.map((e) {
    final parts   = e.key.split('-');
    final month   = int.tryParse(parts[1]) ?? 0;
    final year    = parts[0];
    final total   = e.value.fold(0.0, (s, v) => s + (v.precioCobrado ?? 0));
    final mlMes   = e.value.fold(0, (s, v) => s + (v.mlVendido ?? 0));
    final ordenes = e.value.map((v) => v.idCompra).toSet().length;

    final perfMesMap = <String, ({int ml, double soles})>{};
    for (final v in e.value) {
      if (v.idPerfume == null) continue;
      final normId = double.tryParse(v.idPerfume!)?.toInt().toString() ?? v.idPerfume!;
      final prev = perfMesMap[normId] ?? (ml: 0, soles: 0.0);
      perfMesMap[normId] = (ml: prev.ml + (v.mlVendido ?? 0), soles: prev.soles + (v.precioCobrado ?? 0));
    }
    final topMes = (perfMesMap.entries.map((pe) {
      final p = perfumesMap[pe.key];
      return TopPerfume(nombre: p?.nombre ?? 'Perfume #${pe.key}', marca: p?.marca ?? '', totalMl: pe.value.ml, totalSoles: pe.value.soles);
    }).toList()..sort((a, b) => b.totalMl.compareTo(a.totalMl))).take(10).toList();

    return MesStatHistorico(
      clave:       e.key,
      label:       '${mesesCortos[month]} $year',
      numOrdenes:  ordenes,
      total:       total,
      totalMl:     mlMes,
      topPerfumes: topMes,
    );
  }).toList()
    ..sort((a, b) => a.clave.compareTo(b.clave));

  final mejorMesClave = porMes.isEmpty
      ? null
      : porMes.reduce((a, b) => a.total > b.total ? a : b).clave;

  final promedioMensual =
      porMes.isNotEmpty ? totalIngresos / porMes.length : 0.0;

  // Top perfumes histórico: agrupar por idPerfume, sumar ml y soles
  final perfMap = <String, ({int ml, double soles})>{};
  for (final v in entregadas) {
    if (v.idPerfume == null) continue;
    final normId = double.tryParse(v.idPerfume!)?.toInt().toString()
        ?? v.idPerfume!;
    final prev = perfMap[normId] ?? (ml: 0, soles: 0.0);
    perfMap[normId] = (
      ml:    prev.ml    + (v.mlVendido     ?? 0),
      soles: prev.soles + (v.precioCobrado ?? 0),
    );
  }
  final masVendidosHistorico = perfMap.entries
      .map((e) {
        final p = perfumesMap[e.key];
        return TopPerfume(
          nombre:     p?.nombre ?? 'Perfume #${e.key}',
          marca:      p?.marca  ?? '',
          totalMl:    e.value.ml,
          totalSoles: e.value.soles,
        );
      })
      .toList()
    ..sort((a, b) => b.totalMl.compareTo(a.totalMl));

  // Ranking de distritos
  final distSoles  = <String, double>{};
  final distOrders = <String, Set<String>>{};
  for (final v in entregadas) {
    final dist = (v.distrito ?? '').trim();
    if (dist.isEmpty) continue;
    final key = _normalizarDistrito(dist);
    (distOrders[key] ??= {}).add(v.idCompra);
    distSoles[key] = (distSoles[key] ?? 0.0) + (v.precioCobrado ?? 0);
  }
  final distritoRanking = distOrders.entries.map((e) => DistritoStat(
    nombre:     _titleCase(e.key),
    pedidos:    e.value.length,
    totalSoles: distSoles[e.key] ?? 0,
  )).toList()
    ..sort((a, b) => b.pedidos != a.pedidos
        ? b.pedidos.compareTo(a.pedidos)
        : b.totalSoles.compareTo(a.totalSoles));

  return HistorialGlobalStats(
    totalVentas:          totalVentas,
    totalIngresos:        totalIngresos,
    totalMl:              totalMl,
    ticketPromedio:       ticketProm,
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/features/ventas/providers/ventas_provider.dart';
import 'package:perfuteca/models/venta.dart';
import 'package:perfuteca/repositories/ventas_repository.dart';

// Carga todas las ventas sin caché para que las estadísticas reflejen el estado real.
final ventasParaStatsProvider = FutureProvider<List<VentaResponse>>((ref) async {
  final page = await ref.watch(ventasRepositoryProvider)
      .getVentas(limit: 500, bypassCache: true);
  return page.items;
});

String _normId(String id) {
  final n = double.tryParse(id);
  return n != null ? n.toInt().toString() : id;
}

// ── Resumen (hoy + mes + top perfumes) ───────────────────────────────────────

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
  // Inicia las 3 llamadas en paralelo
  final ventasFuture      = ref.watch(ventasParaStatsProvider.future);
  final pendientesFuture  = ref.watch(pendientesProvider.future);
  final perfumesMapFuture = ref.watch(perfumesMapProvider.future);

  final ventas      = await ventasFuture;
  final pendientes  = await pendientesFuture;
  final perfumesMap = await perfumesMapFuture;

  final entregadas = ventas
      .where((v) => v.estado?.toLowerCase() == 'entregado')
      .toList();

  final now     = DateTime.now();
  final hoy     = DateTime(now.year, now.month, now.day);
  final prevMes = DateTime(now.year, now.month - 1);

  // Compara el prefijo YYYY-MM-DD para ser robusto ante variantes de formato
  final todayPrefix =
      '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';

  bool esHoy(String? fecha) {
    if (fecha == null || fecha.isEmpty) return false;
    if (fecha.startsWith(todayPrefix)) return true;
    try {
      final d = DateTime.parse(fecha);
      return d.year == hoy.year && d.month == hoy.month && d.day == hoy.day;
    } catch (_) {
      return false;
    }
  }

  bool esMes(String? fecha) {
    if (fecha == null) return false;
    try {
      final d = DateTime.parse(fecha);
      return d.year == hoy.year && d.month == hoy.month;
    } catch (_) {
      return false;
    }
  }

  bool esMesPasado(String? fecha) {
    if (fecha == null) return false;
    try {
      final d = DateTime.parse(fecha);
      return d.year == prevMes.year && d.month == prevMes.month;
    } catch (_) {
      return false;
    }
  }

  // "Hoy" muestra todas las ventas del día (incluye pendientes, excluye anuladas)
  final hoyList      = ventas
      .where((v) => v.estado?.toLowerCase() != 'anulado' && esHoy(v.fecha))
      .toList();
  final mesList      = entregadas.where((v) => esMes(v.fecha)).toList();
  final mesPasadoList = entregadas.where((v) => esMesPasado(v.fecha)).toList();

  final ventasHoyCount = hoyList.map((v) => v.idCompra).toSet().length;
  final ventasMesCount = mesList.map((v) => v.idCompra).toSet().length;
  final totalHoy       = hoyList.fold(0.0, (s, v) => s + (v.precioCobrado ?? 0));
  final totalMes       = mesList.fold(0.0, (s, v) => s + (v.precioCobrado ?? 0));
  final mlHoy          = hoyList.fold(0, (s, v) => s + (v.mlVendido ?? 0));
  final mlMes          = mesList.fold(0, (s, v) => s + (v.mlVendido ?? 0));

  final mlPorId    = <String, int>{};
  final solesPorId = <String, double>{};
  for (final v in entregadas) {
    if (v.idPerfume == null) continue;
    mlPorId[v.idPerfume!] =
        (mlPorId[v.idPerfume!] ?? 0) + (v.mlVendido ?? 0);
    solesPorId[v.idPerfume!] =
        (solesPorId[v.idPerfume!] ?? 0.0) + (v.precioCobrado ?? 0);
  }

  final sorted = mlPorId.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final masVendidos = sorted.map((e) {
    final p = perfumesMap[_normId(e.key)];
    return TopPerfume(
      nombre:     p?.nombre ?? 'Perfume #${e.key}',
      marca:      p?.marca  ?? '',
      totalMl:    e.value,
      totalSoles: solesPorId[e.key] ?? 0.0,
    );
  }).toList();

  return ResumenStats(
    ventasHoy:          ventasHoyCount,
    totalHoy:           totalHoy,
    ticketPromedioHoy:  ventasHoyCount > 0 ? totalHoy / ventasHoyCount : 0,
    mlHoy:              mlHoy,
    ventasMes:          ventasMesCount,
    totalMes:           totalMes,
    ticketPromedioMes:  ventasMesCount > 0 ? totalMes / ventasMesCount : 0,
    mlMes:              mlMes,
    ventasMesPasado:    mesPasadoList.map((v) => v.idCompra).toSet().length,
    totalMesPasado:     mesPasadoList.fold(0.0, (s, v) => s + (v.precioCobrado ?? 0)),
    pendientesCount:    pendientes.map((v) => v.idCompra).toSet().length,
    masVendidos:        masVendidos,
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
  final ventas      = await ref.watch(ventasParaStatsProvider.future);
  final perfumesMap = await ref.watch(perfumesMapProvider.future);

  final count   = <int, int>{};
  final total   = <int, double>{};
  final cntPerf = <int, Map<String, int>>{};
  final solPerf = <int, Map<String, double>>{};

  for (final v in ventas) {
    final ml = v.mlVendido;
    if (ml == null) continue;
    count[ml] = (count[ml] ?? 0) + 1;
    total[ml] = (total[ml] ?? 0.0) + (v.precioCobrado ?? 0);
    if (v.idPerfume != null) {
      final id = v.idPerfume!;
      final cp = cntPerf[ml] ??= {};
      final sp = solPerf[ml] ??= {};
      cp[id] = (cp[id] ?? 0)   + 1;
      sp[id] = (sp[id] ?? 0.0) + (v.precioCobrado ?? 0);
    }
  }

  return count.entries.map((e) {
    final mlVal = e.key;
    final cp    = cntPerf[mlVal] ?? {};
    final sp    = solPerf[mlVal] ?? {};
    final top   = (cp.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .map((pe) {
          final p = perfumesMap[_normId(pe.key)];
          return PerfumeDiaStat(
            nombre:     p?.nombre ?? 'Perfume #${pe.key}',
            totalMl:    pe.value * mlVal,
            totalSoles: sp[pe.key] ?? 0,
          );
        })
        .toList();
    return TamanioStat(
      ml:          mlVal,
      cantidad:    e.value,
      total:       total[mlVal] ?? 0,
      topPerfumes: top,
    );
  }).toList()
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
  final ventas      = await ref.watch(ventasParaStatsProvider.future);
  final perfumesMap = await ref.watch(perfumesMapProvider.future);

  final entregadas = ventas
      .where((v) => v.estado?.toLowerCase() == 'entregado')
      .toList();

  final now    = DateTime.now();
  final hoy    = DateTime(now.year, now.month, now.day);
  final inicio = hoy.subtract(Duration(days: hoy.weekday - 1));
  final fin    = inicio.add(const Duration(days: 6));

  final semana = entregadas.where((v) {
    if (v.fecha == null) return false;
    try {
      final d  = DateTime.parse(v.fecha!);
      final dn = DateTime(d.year, d.month, d.day);
      return !dn.isBefore(inicio) && !dn.isAfter(fin);
    } catch (_) {
      return false;
    }
  }).toList();

  final porDia = List.generate(7, (i) {
    final dia  = inicio.add(Duration(days: i));
    final diaV = semana.where((v) {
      try {
        final d  = DateTime.parse(v.fecha!);
        return DateTime(d.year, d.month, d.day) == dia;
      } catch (_) {
        return false;
      }
    }).toList();

    // Perfumes del día: agrupar ml y soles por id
    final mlDia  = <String, int>{};
    final solDia = <String, double>{};
    for (final v in diaV) {
      if (v.idPerfume == null) continue;
      final id = v.idPerfume!;
      mlDia[id]  = (mlDia[id]  ?? 0) + (v.mlVendido ?? 0);
      solDia[id] = (solDia[id] ?? 0.0) + (v.precioCobrado ?? 0);
    }
    final topDia = (mlDia.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .map((e) {
          final p = perfumesMap[_normId(e.key)];
          return PerfumeDiaStat(
            nombre:     p?.nombre ?? 'Perfume #${e.key}',
            totalMl:    e.value,
            totalSoles: solDia[e.key] ?? 0,
          );
        })
        .toList();

    return DiaStat(
      fecha:        dia,
      numOrdenes:   diaV.map((v) => v.idCompra).toSet().length,
      total:        diaV.fold(0.0, (s, v) => s + (v.precioCobrado ?? 0)),
      topPerfumes:  topDia,
    );
  });

  final cntPorId   = <String, int>{};
  final mlTopPorId = <String, int>{};
  final solTopPorId = <String, double>{};
  for (final v in semana) {
    if (v.idPerfume == null) continue;
    cntPorId[v.idPerfume!]    = (cntPorId[v.idPerfume!] ?? 0) + 1;
    mlTopPorId[v.idPerfume!]  = (mlTopPorId[v.idPerfume!] ?? 0) + (v.mlVendido ?? 0);
    solTopPorId[v.idPerfume!] = (solTopPorId[v.idPerfume!] ?? 0.0) + (v.precioCobrado ?? 0);
  }

  String topNombre = '';
  int    topCant   = 0;
  int    topMl     = 0;
  double topTotal  = 0;
  if (cntPorId.isNotEmpty) {
    final top = cntPorId.entries.reduce((a, b) => a.value > b.value ? a : b);
    topCant   = top.value;
    topMl     = mlTopPorId[top.key] ?? 0;
    topTotal  = solTopPorId[top.key] ?? 0.0;
    final p   = perfumesMap[_normId(top.key)];
    topNombre = p?.nombre ?? 'Perfume #${top.key}';
  }

  final inicioAnterior = inicio.subtract(const Duration(days: 7));
  final finAnterior    = inicio.subtract(const Duration(days: 1));
  final semanaAnterior = entregadas.where((v) {
    if (v.fecha == null) return false;
    try {
      final d  = DateTime.parse(v.fecha!);
      final dn = DateTime(d.year, d.month, d.day);
      return !dn.isBefore(inicioAnterior) && !dn.isAfter(finAnterior);
    } catch (_) { return false; }
  }).toList();

  return SemanaStat(
    total:                semana.fold(0.0, (s, v) => s + (v.precioCobrado ?? 0)),
    totalMl:              semana.fold(0, (s, v) => s + (v.mlVendido ?? 0)),
    numOrdenes:           semana.map((v) => v.idCompra).toSet().length,
    porDia:               porDia,
    topNombre:            topNombre,
    topCantidad:          topCant,
    topMl:                topMl,
    topTotal:             topTotal,
    inicio:               inicio,
    fin:                  fin,
    totalSemanaAnterior:  semanaAnterior.fold(0.0, (s, v) => s + (v.precioCobrado ?? 0)),
  );
});

// ── Meses disponibles (para comparación) ─────────────────────────────────────

final mesesDisponiblesProvider = FutureProvider<List<String>>((ref) async {
  final ventas = await ref.watch(ventasParaStatsProvider.future);
  final set    = <String>{};

  for (final v in ventas.where((v) => v.estado?.toLowerCase() == 'entregado')) {
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
  final ventas     = await ref.watch(ventasParaStatsProvider.future);
  final entregadas = ventas.where((v) => v.estado?.toLowerCase() == 'entregado');

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
    required this.totalCompras,
    required this.totalItems,
    required this.totalGastado,
    required this.primeraCompra,
    required this.ultimaCompra,
    required this.historial,
  });
  final String              celular;
  final String              nombre;
  final String              direccion;
  final int                 totalCompras;
  final int                 totalItems;
  final double              totalGastado;
  final String?             primeraCompra;
  final String?             ultimaCompra;
  final List<VentaResponse> historial;
}

final clientesStatsProvider = FutureProvider<List<ClienteStat>>((ref) async {
  final ventas = await ref.watch(ventasParaStatsProvider.future);

  final byCelular = <String, List<VentaResponse>>{};
  for (final v in ventas) {
    final cel = v.celular ?? '';
    if (cel.isEmpty) continue;
    (byCelular[cel] ??= []).add(v);
  }

  return byCelular.entries.map((e) {
    final list       = e.value;
    // Solo ventas entregadas para cálculos financieros — pendientes y
    // canceladas no representan dinero real recibido.
    final entregadas = list
        .where((v) => v.estado?.toLowerCase() == 'entregado')
        .toList();
    final dates = list
        .where((v) => v.fecha != null)
        .map((v) => v.fecha!)
        .toList()
      ..sort();
    final direccion = list
        .lastWhere((v) => (v.direccion ?? '').trim().isNotEmpty,
            orElse: () => list.first)
        .direccion ?? '';
    return ClienteStat(
      celular:       e.key,
      nombre:        list.first.comprador ?? e.key,
      direccion:     direccion,
      totalCompras:  entregadas.map((v) => v.idCompra).toSet().length,
      totalItems:    entregadas.length,
      totalGastado:  entregadas.fold(0.0, (s, v) => s + (v.precioCobrado ?? 0)),
      primeraCompra: dates.isEmpty ? null : dates.first,
      ultimaCompra:  dates.isEmpty ? null : dates.last,
      historial:     list,
    );
  }).toList()
    ..sort((a, b) => b.totalGastado.compareTo(a.totalGastado));
});

// ── Historial global (todo el tiempo) ─────────────────────────────────────────

class MesStatHistorico {
  const MesStatHistorico({
    required this.clave,
    required this.label,
    required this.numOrdenes,
    required this.total,
    required this.totalMl,
  });
  final String clave;
  final String label;
  final int    numOrdenes;
  final double total;
  final int    totalMl;
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
}

final historialGlobalProvider = FutureProvider<HistorialGlobalStats>((ref) async {
  final ventas     = await ref.watch(ventasParaStatsProvider.future);
  final entregadas = ventas
      .where((v) => v.estado?.toLowerCase() == 'entregado')
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
    return MesStatHistorico(
      clave:      e.key,
      label:      '${mesesCortos[month]} $year',
      numOrdenes: ordenes,
      total:      total,
      totalMl:    mlMes,
    );
  }).toList()
    ..sort((a, b) => a.clave.compareTo(b.clave));

  final mejorMesClave = porMes.isEmpty
      ? null
      : porMes.reduce((a, b) => a.total > b.total ? a : b).clave;

  final promedioMensual =
      porMes.isNotEmpty ? totalIngresos / porMes.length : 0.0;

  return HistorialGlobalStats(
    totalVentas:     totalVentas,
    totalIngresos:   totalIngresos,
    totalMl:         totalMl,
    ticketPromedio:  ticketProm,
    clientesUnicos:  clientesUnicos,
    diasActivo:      diasActivo,
    primeraVenta:    primeraVenta,
    promedioMensual: promedioMensual,
    porMes:          porMes,
    mejorMesClave:   mejorMesClave,
  );
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/core/errors/app_exception.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/features/estadisticas/providers/estadisticas_provider.dart';
import 'package:perfuteca/features/estadisticas/widgets/estadisticas_shared.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';
import 'package:perfuteca/widgets/common/app_error_widget.dart';
import 'package:shimmer/shimmer.dart';

class HistoricoTab extends ConsumerStatefulWidget {
  const HistoricoTab({super.key});

  @override
  ConsumerState<HistoricoTab> createState() => _HistoricoTabState();
}

class _HistoricoTabState extends ConsumerState<HistoricoTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ref.watch(historialGlobalProvider).when(
      loading: () => const _HistoricoSkeleton(),
      error:   (e, _) => AppErrorWidget(
        error: e,
        title: 'Error al cargar historial',
        subtitle: e is AppException ? e.message : e.toString(),
        icon: Icons.wifi_off_rounded,
        subtle: true,
        onRetry: () {
          ref.invalidate(ventasParaStatsProvider);
          ref.invalidate(historicoBackendProvider);
          ref.invalidate(historialGlobalProvider);
          ref.invalidate(perfumesMapProvider);
        },
      ),
      data: (stats) => RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(ventasParaStatsProvider);
          ref.invalidate(historicoBackendProvider);
          ref.invalidate(historialGlobalProvider);
          ref.invalidate(perfumesMapProvider);
          await ref.read(historialGlobalProvider.future);
        },
        child: _HistoricoBody(stats: stats),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _HistoricoBody extends StatelessWidget {
  const _HistoricoBody({required this.stats});
  final HistorialGlobalStats stats;

  // Decoración del hero: no depende de los datos, así que se define una sola
  // vez en vez de reconstruir gradient/boxShadow en cada rebuild de la tab.
  static const _heroDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [AppColors.heroGradientStart, AppColors.heroGradientEnd],
      begin: Alignment.topLeft,
      end:   Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusLg)),
    boxShadow: [
      BoxShadow(
        color:      AppColors.heroShadow,
        blurRadius: 12,
        offset:     Offset(0, 4),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final s = stats;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ── Hero: totales globales ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: _heroDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DESDE EL INICIO',
                style: TextStyle(
                  color:         AppColors.gold,
                  fontSize:      11,
                  fontWeight:    FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'S/ ${formatMonto(s.totalIngresos)}',
                style: const TextStyle(
                  color:         AppColors.heroTextPrimary,
                  fontSize:      34,
                  fontWeight:    FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing:    10,
                runSpacing: 4,
                children: [
                  StatChip(Icons.receipt_long_rounded,
                      '${s.totalVentas} ventas'),
                  StatChip(Icons.water_drop_outlined,
                      '${s.totalMl} ml'),
                  StatChip(Icons.group_outlined,
                      '${s.clientesUnicos} clientes'),
                  StatChip(Icons.calendar_today_rounded,
                      '${s.diasActivo} días activo'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // ── Cards: ticket promedio + promedio mensual ──────────────────────
        Row(
          children: [
            Expanded(
              child: _MiniCard(
                icono:  Icons.trending_up_rounded,
                titulo: 'Ticket promedio',
                valor:  'S/ ${s.ticketPromedio.toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MiniCard(
                icono:  Icons.calendar_month_rounded,
                titulo: 'Promedio mensual',
                valor:  'S/ ${formatMonto(s.promedioMensual)}',
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Comparar meses — visible antes del timeline ───────────────────
        const _ComparaMesesSection(),
        const SizedBox(height: AppSpacing.lg),

        // ── Timeline de meses ─────────────────────────────────────────────
        Row(
          children: [
            const Icon(Icons.calendar_month_rounded,
                size: 16, color: AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(
              'Evolución mensual',
              style: AppTextStyles.heading2.copyWith(fontSize: 15),
            ),
          ],
        ),
        if (s.primeraVenta != null) ...[
          const SizedBox(height: 2),
          Text(
            'Primera venta: ${_fmtFecha(s.primeraVenta!)}',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textMuted),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),

        if (s.porMes.isEmpty)
          Center(
            child: Text(
              'Sin ventas entregadas registradas',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textMuted),
            ),
          )
        else
          _TimelineMeses(
            meses:    s.porMes,
            mejorMes: s.mejorMesClave,
          ),

        const SizedBox(height: AppSpacing.lg),
        const _DesgloseSection(),

        _TopPerfumesSection(masVendidos: s.masVendidosHistorico),
        _RankingDistritosSection(distritos: s.distritoRanking),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// ── Timeline de meses ─────────────────────────────────────────────────────────

class _TimelineMeses extends StatefulWidget {
  const _TimelineMeses({
    required this.meses,
    required this.mejorMes,
  });
  final List<MesStatHistorico> meses;
  final String?                mejorMes;

  @override
  State<_TimelineMeses> createState() => _TimelineMesesState();
}

class _TimelineMesesState extends State<_TimelineMeses> {
  final _expanded = <String>{};

  @override
  Widget build(BuildContext context) {
    final maxTotal = widget.meses.fold(0.0, (m, e) => e.total > m ? e.total : m);

    return Column(
      children: widget.meses.reversed.map((m) {
        final esMejor  = m.clave == widget.mejorMes;
        final barPct   = maxTotal > 0 ? (m.total / maxTotal).clamp(0.0, 1.0) : 0.0;
        final isOpen   = _expanded.contains(m.clave);
        final hasTop   = m.topPerfumes.isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          decoration: BoxDecoration(
            color: esMejor ? AppColors.trophyBg : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: esMejor ? AppColors.trophy : AppColors.primaryLight,
              width: esMejor ? 1.5 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 1),
            child: InkWell(
              onTap: hasTop
                  ? () => setState(() {
                        if (isOpen) { _expanded.remove(m.clave); }
                        else { _expanded.add(m.clave); }
                      })
                  : null,
              splashColor: AppColors.primaryLight,
              highlightColor: AppColors.primaryPale.withValues(alpha: 0.5),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.label,
                                style: TextStyle(
                                  fontSize:   11,
                                  fontWeight: FontWeight.w700,
                                  color: esMejor ? AppColors.trophyDark : AppColors.textPrimary,
                                ),
                              ),
                              if (esMejor)
                                const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.emoji_events_rounded, size: 9, color: AppColors.trophyDark),
                                    SizedBox(width: 2),
                                    Text('mejor', style: TextStyle(fontSize: 9, color: AppColors.trophyDark, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              height: 8,
                              child: Stack(
                                children: [
                                  Container(color: esMejor ? AppColors.trophyBarBg : AppColors.primaryPale),
                                  FractionallySizedBox(
                                    widthFactor: barPct,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: esMejor
                                              ? [AppColors.trophy, AppColors.trophyLight]
                                              : [AppColors.primary, AppColors.primaryDark],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'S/ ${formatMonto(m.total)}',
                          style: TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.w700,
                            color: esMejor ? AppColors.trophyDark : AppColors.primaryDark,
                          ),
                        ),
                        if (hasTop) ...[
                          const SizedBox(width: 4),
                          Icon(
                            isOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${m.numOrdenes} venta${m.numOrdenes != 1 ? 's' : ''}  ·  ${m.totalMl} ml',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    if (hasTop)
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 200),
                        sizeCurve: Curves.easeOut,
                        crossFadeState: isOpen
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: const SizedBox(width: double.infinity),
                        secondChild: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.sm),
                            const Divider(color: AppColors.primaryLight, height: 1),
                            const SizedBox(height: AppSpacing.sm),
                            ...m.topPerfumes.asMap().entries.map((e) => _TopPerfumeMesRow(
                                  pos:  e.key + 1,
                                  item: e.value,
                                )),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TopPerfumeMesRow extends StatelessWidget {
  const _TopPerfumeMesRow({required this.pos, required this.item});
  final int        pos;
  final TopPerfume item;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Row(
          children: [
            Container(
              width: 18, height: 18,
              decoration: BoxDecoration(
                color:  pos == 1 ? AppColors.primary : AppColors.primaryPale,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$pos',
                style: TextStyle(
                  fontSize:   9,
                  fontWeight: FontWeight.w700,
                  color: pos == 1 ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                item.nombre,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${item.totalMl}ml',
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.icono,
    required this.titulo,
    required this.valor,
  });
  final IconData icono;
  final String   titulo;
  final String   valor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color:        AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border:       Border.all(color: AppColors.primaryLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    titulo,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              valor,
              style: AppTextStyles.price.copyWith(
                fontSize: 18,
                color:    AppColors.primaryDark,
              ),
            ),
          ],
        ),
      );
}

// ── Ranking de distritos ──────────────────────────────────────────────────────

class _RankingDistritosSection extends StatelessWidget {
  const _RankingDistritosSection({required this.distritos});
  final List<DistritoStat> distritos;

  @override
  Widget build(BuildContext context) {
    final list = distritos;
    if (list.isEmpty) return const SizedBox.shrink();

    final maxPedidos = list.first.pedidos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        const Divider(color: AppColors.primaryLight),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          const Icon(Icons.location_on_rounded,
              size: 16, color: AppColors.textPrimary),
          const SizedBox(width: 6),
          Text('Ranking por distrito',
              style: AppTextStyles.heading2.copyWith(fontSize: 15)),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryPale,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text('${list.length}',
                style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark)),
          ),
        ]),
        const SizedBox(height: AppSpacing.sm),
        _ExpandableRankedList<DistritoStat>(
          items: list,
          paso: 8,
          itemBuilder: (pos, stat) =>
              _DistritoRow(pos: pos, stat: stat, maxPedidos: maxPedidos),
        ),
      ],
    );
  }
}

class _DistritoRow extends StatelessWidget {
  const _DistritoRow({
    required this.pos,
    required this.stat,
    required this.maxPedidos,
  });
  final int          pos;
  final DistritoStat stat;
  final int          maxPedidos;

  @override
  Widget build(BuildContext context) {
    final barPct = maxPedidos > 0 ? (stat.pedidos / maxPedidos).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        children: [
          _RankBadge(pos: pos),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stat.nombre,
                    style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: SizedBox(
                    height: 5,
                    child: Stack(children: [
                      Container(color: AppColors.primaryPale),
                      FractionallySizedBox(
                        widthFactor: barPct,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryDark],
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryPale,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: Text(
                    '${stat.pedidos} pedido${stat.pedidos != 1 ? 's' : ''}',
                    style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ),
              const SizedBox(height: 3),
              Text('S/ ${stat.totalSoles.toStringAsFixed(2)}',
                  style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                      fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Badge de ranking compartido (posición 1/2/otro) ───────────────────────────

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.pos});
  final int pos;

  static const double size     = 26;
  static const double fontSize = 11;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (pos == 1) {
      bg = AppColors.primary;
      fg = Colors.white;
    } else if (pos == 2) {
      bg = AppColors.textMuted;
      fg = Colors.white;
    } else {
      bg = AppColors.primaryPale;
      fg = AppColors.textMuted;
    }

    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text('$pos',
          style: TextStyle(color: fg, fontSize: fontSize, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Lista con paginación "ver más/ver menos" compartida ───────────────────────

class _ExpandableRankedList<T> extends StatefulWidget {
  const _ExpandableRankedList({
    required this.items,
    required this.itemBuilder,
    this.paso = 5,
  });
  final List<T>                    items;
  final Widget Function(int pos, T item) itemBuilder;
  final int                        paso;

  @override
  State<_ExpandableRankedList<T>> createState() =>
      _ExpandableRankedListState<T>();
}

class _ExpandableRankedListState<T> extends State<_ExpandableRankedList<T>> {
  late int _visible = widget.paso;

  @override
  Widget build(BuildContext context) {
    final mostrados = widget.items.take(_visible).toList();
    final quedan    = widget.items.length - _visible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...mostrados.asMap().entries.map((e) {
          final item = widget.itemBuilder(e.key + 1, e.value);
          final esNuevo = e.key >= _visible - widget.paso;
          return esNuevo
              ? FadeSlideListItem(index: e.key - (_visible - widget.paso), child: item)
              : item;
        }),
        if (quedan > 0)
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _visible += widget.paso),
              icon: const Icon(Icons.expand_more_rounded, size: 16),
              label: Text(
                'Ver ${quedan > widget.paso ? widget.paso : quedan} más'
                '${quedan > widget.paso ? ' ($quedan restantes)' : ''}',
              ),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
        if (_visible > widget.paso)
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _visible = widget.paso),
              icon: const Icon(Icons.expand_less_rounded, size: 16),
              label: const Text('Ver menos'),
              style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
            ),
          ),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtFecha(String fecha) {
  try {
    final d = DateTime.parse(fecha);
    const meses = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                   'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${d.day} ${meses[d.month]} ${d.year}';
  } catch (_) {
    return fecha;
  }
}

// ── Desglose por tamaño / tipo de envío (con filtro de período) ────────────────

class _DesgloseSection extends ConsumerStatefulWidget {
  const _DesgloseSection();

  @override
  ConsumerState<_DesgloseSection> createState() => _DesgloseSectionState();
}

class _DesgloseSectionState extends ConsumerState<_DesgloseSection> {
  // 'todo' | 'mes' | 'YYYY-MM'
  String _filtro = 'todo';
  bool   _porEnvio = false;

  static const _mesesCortos = [
    '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  String _labelFiltro(String key) {
    if (key == 'todo') return 'Todo el tiempo';
    if (key == 'mes')  return 'Este mes';
    try {
      final p = key.split('-');
      return '${_mesesCortos[int.parse(p[1])]} ${p[0]}';
    } catch (_) {
      return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(historicoBackendProvider).when(
      loading: () => skeletonBox(height: 200, radius: AppSpacing.radiusMd),
      error: (e, __) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.errorSurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, size: 18, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'No se pudo cargar el desglose por tamaño/envío',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(historicoBackendProvider),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
      data: (data) {
        final now       = nowPeru();
        final mesActual =
            '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final porMes = (data['por_mes'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

        final meses = porMes
            .map((m) => m['clave'] as String)
            .where((clave) => clave != mesActual)
            .toList()
          ..sort((a, b) => b.compareTo(a));

        List<dynamic> raw;
        final campoTotal = _porEnvio ? 'tipos_envio_total' : 'tamanios_total';
        final campoMes   = _porEnvio ? 'tipos_envio'       : 'tamanios';
        if (_filtro == 'todo') {
          raw = data[campoTotal] as List<dynamic>? ?? [];
        } else {
          final clave = _filtro == 'mes' ? mesActual : _filtro;
          final mes = porMes.cast<Map<String, dynamic>?>().firstWhere(
                (m) => m?['clave'] == clave,
                orElse: () => null,
              );
          raw = mes?[campoMes] as List<dynamic>? ?? [];
        }

        final items = _porEnvio ? tiposEnvioDesglose(raw) : tamaniosDesglose(raw);
        final totalCount = items.fold(0, (s, t) => s + t.cantidad);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _porEnvio ? Icons.local_shipping_outlined : Icons.water_drop_outlined,
                  size: 16, color: AppColors.textPrimary,
                ),
                const SizedBox(width: 6),
                Text('Ventas por ${_porEnvio ? 'tipo de envío' : 'tamaño'}',
                    style: AppTextStyles.heading2.copyWith(fontSize: 15)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Toggle tamaño / tipo de envío ────────────────────────────
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.water_drop_outlined, size: 14),
                  label: Text('Tamaño'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.local_shipping_outlined, size: 14),
                  label: Text('Envío'),
                ),
              ],
              selected: {_porEnvio},
              onSelectionChanged: (s) => setState(() => _porEnvio = s.first),
              style: SegmentedButton.styleFrom(
                backgroundColor:         AppColors.background,
                foregroundColor:         AppColors.textMuted,
                selectedForegroundColor: AppColors.primaryDark,
                selectedBackgroundColor: AppColors.primaryPale,
                side: const BorderSide(color: AppColors.primaryLight),
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Chips de período ──────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FiltroChip(
                    label:    'Todo el tiempo',
                    selected: _filtro == 'todo',
                    onTap:    () => setState(() => _filtro = 'todo'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _FiltroChip(
                    label:    'Este mes',
                    selected: _filtro == 'mes',
                    onTap:    () => setState(() => _filtro = 'mes'),
                  ),
                  ...meses.map((m) => Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.xs),
                        child: _FiltroChip(
                          label:    _labelFiltro(m),
                          selected: _filtro == m,
                          onTap:    () => setState(() => _filtro = m),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            if (items.isEmpty)
              Center(
                child: Text(
                  'Sin ventas en este período',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),
              )
            else
              ...items.map((it) {
                final pct = totalCount > 0 ? it.cantidad / totalCount : 0.0;
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color:        AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border:       Border.all(color: AppColors.primaryLight),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            it.label,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color:      AppColors.textPrimary,
                              fontSize:   15,
                            ),
                          ),
                          Text(
                            '${it.cantidad} venta${it.cantidad != 1 ? 's' : ''}'
                            ' — S/ ${it.total.toStringAsFixed(2)}',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 8,
                          child: Stack(children: [
                            Container(color: AppColors.primaryPale),
                            FractionallySizedBox(
                              widthFactor: pct,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    AppColors.primary,
                                    AppColors.primaryDark,
                                  ]),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${(pct * 100).toStringAsFixed(1)}% del total',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

class _FiltroChip extends StatelessWidget {
  const _FiltroChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String       label;
  final bool         selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.primaryLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize:   11,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.background : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Top perfumes ──────────────────────────────────────────────────────────────

class _TopPerfumesSection extends StatefulWidget {
  const _TopPerfumesSection({required this.masVendidos});
  final List<TopPerfume> masVendidos;

  @override
  State<_TopPerfumesSection> createState() => _TopPerfumesSectionState();
}

class _TopPerfumesSectionState extends State<_TopPerfumesSection> {
  final _buscarCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.masVendidos.isEmpty) return const SizedBox.shrink();

    final q = _query.trim().toLowerCase();
    final filtrados = q.isEmpty
        ? widget.masVendidos
        : widget.masVendidos
            .where((p) =>
                p.nombre.toLowerCase().contains(q) ||
                p.marca.toLowerCase().contains(q))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            const Icon(Icons.emoji_events_rounded,
                size: 16, color: AppColors.textPrimary),
            const SizedBox(width: 6),
            Text('Perfumes más vendidos',
                style: AppTextStyles.heading2.copyWith(fontSize: 15)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _buscarCtrl,
          onChanged: (v) => setState(() => _query = v),
          style: AppTextStyles.bodySmall,
          decoration: InputDecoration(
            hintText: 'Buscar perfume o marca...',
            hintStyle: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textMuted),
            isDense: true,
            filled: true,
            fillColor: AppColors.background,
            prefixIcon: const Icon(Icons.search_rounded,
                size: 18, color: AppColors.textMuted),
            suffixIcon: q.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 16, color: AppColors.textMuted),
                    onPressed: () => setState(() {
                      _buscarCtrl.clear();
                      _query = '';
                    }),
                  ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: const BorderSide(color: AppColors.primaryLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: const BorderSide(color: AppColors.primaryLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (filtrados.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'Sin resultados para "$q"',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted),
              ),
            ),
          )
        else
          _ExpandableRankedList<TopPerfume>(
            items: filtrados,
            paso: 5,
            itemBuilder: (pos, item) => _TopPerfumeRow(pos: pos, item: item),
          ),
      ],
    );
  }
}

class _TopPerfumeRow extends StatelessWidget {
  const _TopPerfumeRow({required this.pos, required this.item});
  final int        pos;
  final TopPerfume item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        children: [
          _RankBadge(pos: pos),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nombre,
                    style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (item.marca.isNotEmpty)
                  Text(item.marca, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryPale,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: Text('${item.totalMl}ml',
                    style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ),
              const SizedBox(height: 3),
              Text('S/ ${item.totalSoles.toStringAsFixed(2)}',
                  style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                      fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Comparar meses ────────────────────────────────────────────────────────────

class _ComparaMesesSection extends ConsumerStatefulWidget {
  const _ComparaMesesSection();

  @override
  ConsumerState<_ComparaMesesSection> createState() =>
      _ComparaMesesSectionState();
}

class _ComparaMesesSectionState extends ConsumerState<_ComparaMesesSection> {
  String? _mes1;
  String? _mes2;

  @override
  Widget build(BuildContext context) {
    final meses    = ref.watch(mesesDisponiblesProvider).valueOrNull ?? [];
    final statsMap = ref.watch(mesStatsMapProvider).valueOrNull ?? {};

    // Re-validar contra la lista actual, no solo inicializar una vez: si
    // 'meses' cambia tras un refresh y el valor guardado ya no está en la
    // lista, DropdownButton lanza un assertion error (value no en items).
    if (meses.isNotEmpty) {
      if (_mes1 == null || !meses.contains(_mes1)) _mes1 = meses.last;
      if (_mes2 == null || !meses.contains(_mes2)) {
        _mes2 = meses.length >= 2 ? meses[meses.length - 2] : meses.last;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        const Divider(color: AppColors.primaryLight),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const Icon(Icons.date_range_rounded,
                size: 16, color: AppColors.textPrimary),
            const SizedBox(width: 6),
            Text('Comparar meses',
                style: AppTextStyles.heading2.copyWith(fontSize: 15)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        if (meses.length < 2)
          Text(
            'Se necesitan al menos 2 meses de datos para comparar',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: _MesDropdown(
                  label: 'Mes 1',
                  value: _mes1,
                  meses: meses,
                  onChanged: (v) => setState(() => _mes1 = v),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MesDropdown(
                  label: 'Mes 2',
                  value: _mes2,
                  meses: meses,
                  onChanged: (v) => setState(() => _mes2 = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_mes1 != null && _mes2 != null) ...[
            Row(
              children: [
                Expanded(child: _MesCard(mes: _mes1!, stats: statsMap[_mes1])),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _MesCard(mes: _mes2!, stats: statsMap[_mes2])),
              ],
            ),
            if (statsMap[_mes1] != null &&
                statsMap[_mes2] != null &&
                statsMap[_mes2]!.total > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              _DiferenciaBanner(
                mes1:  _mes1!,
                mes2:  _mes2!,
                stat1: statsMap[_mes1]!,
                stat2: statsMap[_mes2]!,
              ),
            ],
          ],
        ],
      ],
    );
  }
}

class _MesDropdown extends StatelessWidget {
  const _MesDropdown({
    required this.label,
    required this.value,
    required this.meses,
    required this.onChanged,
  });
  final String              label;
  final String?             value;
  final List<String>        meses;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          filled: true,
          fillColor: AppColors.background,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            borderSide: const BorderSide(color: AppColors.primaryLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            borderSide: const BorderSide(color: AppColors.primaryLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
        child: DropdownButton<String>(
          value:      value,
          isExpanded: true,
          isDense:    true,
          underline:  const SizedBox.shrink(),
          items: meses
              .map((m) => DropdownMenuItem(
                    value: m,
                    child: Text(m, style: AppTextStyles.bodySmall),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      );
}

class _MesCard extends StatelessWidget {
  const _MesCard({required this.mes, required this.stats});
  final String   mes;
  final MesStat? stats;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.primaryLight),
        ),
        child: Column(
          children: [
            Text(mes,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text('${stats?.numOrdenes ?? 0} ventas',
                style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                textAlign: TextAlign.center),
            Text('S/ ${(stats?.total ?? 0).toStringAsFixed(2)}',
                style: AppTextStyles.price
                    .copyWith(color: AppColors.primaryDark, fontSize: 18),
                textAlign: TextAlign.center),
          ],
        ),
      );
}

class _DiferenciaBanner extends StatelessWidget {
  const _DiferenciaBanner({
    required this.mes1,
    required this.mes2,
    required this.stat1,
    required this.stat2,
  });
  final String  mes1;
  final String  mes2;
  final MesStat stat1;
  final MesStat stat2;

  @override
  Widget build(BuildContext context) {
    final diff     = stat1.total - stat2.total;
    final pct      = diff / stat2.total * 100;
    final positivo = diff >= 0;
    final color    = positivo ? AppColors.stockOk : AppColors.error;
    final bgColor  = positivo ? AppColors.successSurface : AppColors.errorSurface;
    final borde    = positivo
        ? AppColors.stockOk.withValues(alpha: 0.35)
        : AppColors.error.withValues(alpha: 0.25);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: borde),
      ),
      child: Column(
        children: [
          Text('Diferencia',
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                positivo
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                'S/ ${diff.abs().toStringAsFixed(2)}'
                ' (${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%)',
                style: AppTextStyles.price.copyWith(color: color, fontSize: 18),
              ),
            ],
          ),
          Text('$mes1 vs $mes2',
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ── Skeleton de carga ─────────────────────────────────────────────────────────

class _HistoricoSkeleton extends StatelessWidget {
  const _HistoricoSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.primaryLight,
      highlightColor: AppColors.surface,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          skeletonBox(height: 130, radius: AppSpacing.radiusLg),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            Expanded(child: skeletonBox(height: 72, radius: AppSpacing.radiusMd)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: skeletonBox(height: 72, radius: AppSpacing.radiusMd)),
          ]),
          const SizedBox(height: AppSpacing.lg),
          skeletonBox(width: 140, height: 14),
          const SizedBox(height: AppSpacing.sm),
          skeletonBox(height: 60, radius: AppSpacing.radiusMd),
          const SizedBox(height: AppSpacing.xs),
          skeletonBox(height: 60, radius: AppSpacing.radiusMd),
          const SizedBox(height: AppSpacing.xs),
          skeletonBox(height: 60, radius: AppSpacing.radiusMd),
          const SizedBox(height: AppSpacing.xs),
          skeletonBox(height: 60, radius: AppSpacing.radiusMd),
        ],
      ),
    );
  }
}

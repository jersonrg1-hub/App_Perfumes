import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/features/estadisticas/providers/estadisticas_provider.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';

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
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 48, color: AppColors.textFaint),
              const SizedBox(height: 12),
              Text(e.toString(),
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  ref.invalidate(ventasParaStatsProvider);
                  ref.invalidate(historialGlobalProvider);
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      data: (stats) => RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(ventasParaStatsProvider);
          ref.invalidate(historialGlobalProvider);
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

  @override
  Widget build(BuildContext context) {
    final s = stats;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ── Hero: totales globales ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1a0a04), Color(0xFF4a2810)],
              begin: Alignment.topLeft,
              end:   Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: const [
              BoxShadow(
                color:      Color(0x402C1A0E),
                blurRadius: 12,
                offset:     Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DESDE EL INICIO',
                style: TextStyle(
                  color:         Color(0xFFD4A882),
                  fontSize:      10,
                  fontWeight:    FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'S/ ${_fmt(s.totalIngresos)}',
                style: const TextStyle(
                  color:         Color(0xFFF5E6D8),
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
                  _HeroChip(Icons.receipt_long_rounded,
                      '${s.totalVentas} ventas'),
                  _HeroChip(Icons.water_drop_outlined,
                      '${s.totalMl} ml'),
                  _HeroChip(Icons.group_outlined,
                      '${s.clientesUnicos} clientes'),
                  _HeroChip(Icons.calendar_today_rounded,
                      '${s.diasActivo} días activo'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

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
                valor:  'S/ ${_fmt(s.promedioMensual)}',
              ),
            ),
          ],
        ),

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

        _TopPerfumesSection(masVendidos: s.masVendidosHistorico),
        const _ComparaMesesSection(),
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

        return GestureDetector(
          onTap: hasTop
              ? () => setState(() {
                    if (isOpen) { _expanded.remove(m.clave); }
                    else { _expanded.add(m.clave); }
                  })
              : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: esMejor ? const Color(0xFFFFF9E6) : AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: esMejor ? const Color(0xFFD4A017) : AppColors.primaryLight,
                width: esMejor ? 1.5 : 1,
              ),
            ),
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
                              color: esMejor ? const Color(0xFF7A5C00) : AppColors.textPrimary,
                            ),
                          ),
                          if (esMejor)
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.emoji_events_rounded, size: 9, color: Color(0xFF7A5C00)),
                                SizedBox(width: 2),
                                Text('mejor', style: TextStyle(fontSize: 9, color: Color(0xFF7A5C00), fontWeight: FontWeight.w700)),
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
                              Container(color: esMejor ? const Color(0xFFF5DFA0) : AppColors.primaryPale),
                              FractionallySizedBox(
                                widthFactor: barPct,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: esMejor
                                          ? [const Color(0xFFD4A017), const Color(0xFFF0C040)]
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
                      'S/ ${_fmt(m.total)}',
                      style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w700,
                        color: esMejor ? const Color(0xFF7A5C00) : AppColors.primaryDark,
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
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
                if (isOpen && hasTop) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(color: AppColors.primaryLight, height: 1),
                  const SizedBox(height: AppSpacing.sm),
                  ...m.topPerfumes.asMap().entries.map((e) => _TopPerfumeMesRow(
                        pos:  e.key + 1,
                        item: e.value,
                      )),
                ],
              ],
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

class _HeroChip extends StatelessWidget {
  const _HeroChip(this.icon, this.label);
  final IconData icon;
  final String   label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFFD4A882)),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color:    Color(0xFFD4A882),
              fontSize: 12,
            ),
          ),
        ],
      );
}

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

class _RankingDistritosSection extends StatefulWidget {
  const _RankingDistritosSection({required this.distritos});
  final List<DistritoStat> distritos;

  @override
  State<_RankingDistritosSection> createState() =>
      _RankingDistritosSectionState();
}

class _RankingDistritosSectionState extends State<_RankingDistritosSection> {
  static const _paso = 8;
  int _visible = _paso;

  @override
  Widget build(BuildContext context) {
    final list = widget.distritos;
    if (list.isEmpty) return const SizedBox.shrink();

    final maxPedidos = list.first.pedidos;
    final mostrados  = list.take(_visible).toList();
    final quedan     = list.length - _visible;

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
        ...mostrados.asMap().entries.map((e) =>
            _DistritoRow(pos: e.key + 1, stat: e.value, maxPedidos: maxPedidos)),
        if (quedan > 0)
          Center(
            child: TextButton(
              onPressed: () => setState(() => _visible += _paso),
              child: Text(
                '▼ Ver ${quedan > _paso ? _paso : quedan} más'
                '${quedan > _paso ? ' ($quedan restantes)' : ''}',
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
          ),
        if (_visible > _paso)
          Center(
            child: TextButton(
              onPressed: () => setState(() => _visible = _paso),
              child: const Text('▲ Ver menos',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
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
    final Color rankBg;
    final Color rankFg;
    if (pos == 1)      { rankBg = AppColors.primary;   rankFg = Colors.white; }
    else if (pos == 2) { rankBg = AppColors.textMuted;  rankFg = Colors.white; }
    else               { rankBg = AppColors.primaryPale; rankFg = AppColors.textMuted; }

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
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(color: rankBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('$pos',
                style: TextStyle(
                    color: rankFg, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
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
              Text('S/ ${stat.totalSoles.toStringAsFixed(0)}',
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

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmt(double v) {
  if (v >= 1000) {
    return v.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');
  }
  return v.toStringAsFixed(2);
}

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

// ── Top perfumes ──────────────────────────────────────────────────────────────

class _TopPerfumesSection extends StatefulWidget {
  const _TopPerfumesSection({required this.masVendidos});
  final List<TopPerfume> masVendidos;

  @override
  State<_TopPerfumesSection> createState() => _TopPerfumesSectionState();
}

class _TopPerfumesSectionState extends State<_TopPerfumesSection> {
  static const _paso = 5;
  int _visible = _paso;

  @override
  Widget build(BuildContext context) {
    final masVendidos = widget.masVendidos;
    if (masVendidos.isEmpty) return const SizedBox.shrink();

    final mostrados = masVendidos.take(_visible).toList();
    final quedan    = masVendidos.length - _visible;

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
        ...mostrados
            .asMap()
            .entries
            .map((e) => _TopPerfumeRow(pos: e.key + 1, item: e.value)),
        if (quedan > 0)
          Center(
            child: TextButton(
              onPressed: () => setState(() => _visible += _paso),
              child: Text(
                '▼ Ver ${quedan > _paso ? _paso : quedan} más'
                '${quedan > _paso ? ' ($quedan restantes)' : ''}',
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
          ),
        if (_visible > _paso)
          Center(
            child: TextButton(
              onPressed: () => setState(() => _visible = _paso),
              child: const Text(
                '▲ Ver menos',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
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
    final Color rankBg;
    final Color rankFg;
    if (pos == 1) {
      rankBg = AppColors.textPrimary;
      rankFg = Colors.white;
    } else if (pos == 2) {
      rankBg = AppColors.textMuted;
      rankFg = Colors.white;
    } else {
      rankBg = AppColors.primaryPale;
      rankFg = AppColors.textMuted;
    }

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
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(color: rankBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('$pos',
                style: TextStyle(
                    color: rankFg, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
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
              Text('S/ ${item.totalSoles.toStringAsFixed(0)}',
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

    if (meses.isNotEmpty) {
      _mes1 ??= meses.last;
      _mes2 ??= meses.length >= 2 ? meses[meses.length - 2] : meses.last;
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
        const SizedBox(height: AppSpacing.md),

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
          const SizedBox(height: AppSpacing.md),
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
                statsMap[_mes1]!.total > 0) ...[
              const SizedBox(height: AppSpacing.md),
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    final pct      = diff / stat1.total * 100;
    final positivo = diff >= 0;
    final color    = positivo ? const Color(0xFF16a34a) : const Color(0xFFdc2626);
    final bgColor  = positivo ? const Color(0xFFf0faf4) : const Color(0xFFfff5f5);
    final borde    = positivo ? const Color(0xFFb7e4c7) : const Color(0xFFfed7d7);
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

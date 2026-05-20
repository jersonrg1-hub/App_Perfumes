import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/features/estadisticas/providers/estadisticas_provider.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';

class HistoricoTab extends ConsumerWidget {
  const HistoricoTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        Text(
          '📅  Evolución mensual',
          style: AppTextStyles.heading2.copyWith(fontSize: 15),
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

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// ── Timeline de meses ─────────────────────────────────────────────────────────

class _TimelineMeses extends StatelessWidget {
  const _TimelineMeses({
    required this.meses,
    required this.mejorMes,
  });
  final List<MesStatHistorico> meses;
  final String?                mejorMes;

  @override
  Widget build(BuildContext context) {
    final maxTotal =
        meses.fold(0.0, (m, e) => e.total > m ? e.total : m);

    return Column(
      children: meses.reversed.map((m) {
        final esMejor = m.clave == mejorMes;
        final barPct  = maxTotal > 0 ? (m.total / maxTotal).clamp(0.0, 1.0) : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: esMejor
                ? const Color(0xFFFFF9E6)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: esMejor
                  ? const Color(0xFFD4A017)
                  : AppColors.primaryLight,
              width: esMejor ? 1.5 : 1,
            ),
          ),
          child: Column(
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
                            color: esMejor
                                ? const Color(0xFF7A5C00)
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (esMejor)
                          const Text(
                            '🏆 mejor',
                            style: TextStyle(
                              fontSize:   9,
                              color:      Color(0xFF7A5C00),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value:           barPct,
                        minHeight:       8,
                        backgroundColor: esMejor
                            ? const Color(0xFFF5DFA0)
                            : AppColors.primaryPale,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          esMejor
                              ? const Color(0xFFD4A017)
                              : AppColors.primary,
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
                      color: esMejor
                          ? const Color(0xFF7A5C00)
                          : AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${m.numOrdenes} venta${m.numOrdenes != 1 ? 's' : ''}  ·  ${m.totalMl} ml',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
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

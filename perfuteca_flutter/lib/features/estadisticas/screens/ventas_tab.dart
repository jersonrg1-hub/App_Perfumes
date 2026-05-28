import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:perfuteca/features/estadisticas/providers/estadisticas_provider.dart';
import 'package:perfuteca/features/estadisticas/screens/clientes_tab.dart';
import 'package:perfuteca/features/ventas/screens/historial_screen.dart';
import 'package:perfuteca/models/venta.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';
import 'package:shimmer/shimmer.dart';

enum _SeccionVentas { historial, tamanios, semanal, cotizaciones }

class VentasTab extends ConsumerStatefulWidget {
  const VentasTab({super.key});

  @override
  ConsumerState<VentasTab> createState() => _VentasTabState();
}

class _VentasTabState extends ConsumerState<VentasTab>
    with AutomaticKeepAliveClientMixin {
  _SeccionVentas _seccion = _SeccionVentas.historial;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        // ── Navegación por pills animadas ──────────────────────────
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: _SeccionVentas.values.map((s) {
              final sel = s == _seccion;
              final label = switch (s) {
                _SeccionVentas.historial    => 'Historial',
                _SeccionVentas.tamanios     => 'Tamaños',
                _SeccionVentas.semanal      => 'Semanal',
                _SeccionVentas.cotizaciones => 'Cotizaciones',
              };
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _seccion = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primaryDark : AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                      border: Border.all(
                        color: sel
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                      ),
                    ),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color:      sel ? Colors.white : AppColors.textMuted,
                          fontSize:   12,
                          fontWeight: FontWeight.w600,
                        ),
                        child: Text(label),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // ── Contenido ────────────────────────────────────────────────
        Expanded(
          child: switch (_seccion) {
            _SeccionVentas.historial    => const HistorialScreen(),
            _SeccionVentas.tamanios     => const _TamanosView(),
            _SeccionVentas.semanal      => const _SemanalView(),
            _SeccionVentas.cotizaciones => const CotizacionesTodasView(),
          },
        ),
      ],
    );
  }
}

String? _mejorDiaHistorico(List<VentaResponse> ventas) {
  const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  final totales = <int, double>{};
  for (final v in ventas) {
    if (v.estado?.toLowerCase() != 'entregado') continue;
    if (v.fecha == null) continue;
    try {
      final d = DateTime.parse(v.fecha!);
      totales[d.weekday] = (totales[d.weekday] ?? 0) + (v.precioCobrado ?? 0);
    } catch (_) {}
  }
  if (totales.isEmpty) return null;
  return dias[totales.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key - 1];
}

void _mostrarDetalleTamanio(BuildContext ctx, TamanioStat t) {
  showDialog<void>(
    context: ctx,
    barrierDismissible: true,
    builder: (dialogCtx) => Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.water_drop_outlined,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('${t.ml}ml — Top perfumes',
                  style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const Spacer(),
              Text('${t.cantidad} ventas',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted)),
            ]),
            const Divider(height: AppSpacing.lg),
            ...t.topPerfumes.asMap().entries.map((e) {
              final idx = e.key;
              final p   = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primaryPale,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.nombre,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${p.totalMl}ml',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'S/${p.totalSoles.toStringAsFixed(0)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Tamaños ───────────────────────────────────────────────────────────────────

class _TamanosView extends ConsumerWidget {
  const _TamanosView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(tamaniosStatsProvider).when(
      loading: () => const _TamanosSkeleton(),
      error:   (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(e.toString(), style: AppTextStyles.bodySmall),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => ref.invalidate(tamaniosStatsProvider),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
      data: (tamanios) {
        if (tamanios.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bar_chart_rounded,
                      size: 64, color: AppColors.primaryLight),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Sin ventas registradas aún',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Registra tu primera venta para ver\nestadísticas de tamaños aquí',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        final totalCount = tamanios.fold(0, (s, t) => s + t.cantidad);

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Tamaños más vendidos',
              style: AppTextStyles.heading2.copyWith(fontSize: 15),
            ),
            const SizedBox(height: AppSpacing.md),
            ...tamanios.map((t) {
              final pct = totalCount > 0 ? t.cantidad / totalCount : 0.0;
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: t.topPerfumes.isEmpty
                      ? null
                      : () => _mostrarDetalleTamanio(context, t),
                  splashColor: AppColors.primaryPale,
                  highlightColor:
                      AppColors.primaryPale.withValues(alpha: 0.5),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.water_drop_outlined,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  '${t.ml} ml',
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  '${t.cantidad} venta${t.cantidad != 1 ? 's' : ''}'
                                  ' — S/ ${t.total.toStringAsFixed(2)}',
                                  style: AppTextStyles.bodySmall,
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.chevron_right_rounded,
                                    size: 16, color: AppColors.textMuted),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            height: 10,
                            child: Stack(
                              children: [
                                Container(color: AppColors.primaryPale),
                                FractionallySizedBox(
                                  widthFactor: pct,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.primaryDark,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ── Semanal ───────────────────────────────────────────────────────────────────

class _SemanalView extends ConsumerStatefulWidget {
  const _SemanalView();

  @override
  ConsumerState<_SemanalView> createState() => _SemanalViewState();
}

class _SemanalViewState extends ConsumerState<_SemanalView> {
  static const _dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  String _fmt(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  void _mostrarDetalleDia(BuildContext ctx, DiaStat dia, String nombreDia) {
    showDialog<void>(
      context: ctx,
      barrierDismissible: true,
      builder: (dialogCtx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(nombreDia,
                    style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const Spacer(),
                Text(_fmt(dia.fecha),
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textMuted)),
              ]),
              const Divider(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ventas', style: AppTextStyles.bodySmall),
                  Text('${dia.numOrdenes} orden${dia.numOrdenes != 1 ? 'es' : ''}',
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: AppTextStyles.bodySmall),
                  Text('S/ ${dia.total.toStringAsFixed(2)}',
                      style: AppTextStyles.price.copyWith(
                          fontSize: 14, color: AppColors.primaryDark)),
                ],
              ),
              if (dia.topPerfumes.isNotEmpty) ...[
                const Divider(height: AppSpacing.lg),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 13, color: AppColors.gold),
                    const SizedBox(width: 5),
                    Text(
                      'Top perfumes del día',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ...dia.topPerfumes.asMap().entries.map((e) {
                  final idx = e.key;
                  final p   = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.primaryPale,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '${idx + 1}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p.nombre,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${p.totalMl}ml',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'S/${p.totalSoles.toStringAsFixed(0)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final semana = ref.watch(semanaStatsProvider);

    return semana.when(
      loading: () => const _SemanalSkeleton(),
      error:   (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(e.toString(), style: AppTextStyles.bodySmall),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                ref.invalidate(ventasParaStatsProvider);
                ref.invalidate(semanaStatsProvider);
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
      data: (s) => RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(resumenBackendProvider);
          ref.invalidate(ventasParaStatsProvider);
          ref.invalidate(semanaStatsProvider);
          await ref.read(semanaStatsProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
          // ── Encabezado ────────────────────────────────────────
          Text(
            'Resumen de esta semana',
            style: AppTextStyles.heading2.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 2),
          Text(
            '${_fmt(s.inicio)} — ${_fmt(s.fin)}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Hero total semana ─────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3d1a08), Color(0xFF7c3d14)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL DE LA SEMANA',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'S/ ${s.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      if (s.totalSemanaAnterior > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              s.variacionSemana >= 0
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              size: 13,
                              color: s.variacionSemana >= 0
                                  ? const Color(0xFF90EE90)
                                  : const Color(0xFFFF8A80),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${s.variacionSemana >= 0 ? '+' : ''}${s.variacionSemana.toStringAsFixed(1)}% vs sem. anterior',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _HeroPill('${s.numOrdenes} venta${s.numOrdenes != 1 ? 's' : ''}'),
                    const SizedBox(height: 6),
                    _HeroPill('${s.totalMl} ml'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Top perfume ──────────────────────────────────────
          if (s.topNombre.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.primaryLight),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events_rounded,
                          size: 13, color: AppColors.gold),
                      const SizedBox(width: 5),
                      Text(
                        'Más vendido esta semana',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.topNombre,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatPill(
                        label: '${s.topCantidad} venta${s.topCantidad != 1 ? 's' : ''}',
                        icon: Icons.receipt_long_rounded,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _StatPill(
                        label: '${s.topMl} ml',
                        icon: Icons.water_drop_outlined,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _StatPill(
                        label: 'S/ ${s.topTotal.toStringAsFixed(0)}',
                        icon: Icons.attach_money_rounded,
                        highlight: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),

          // ── Días de la semana ─────────────────────────────────
          Text(
            'Ventas por día:',
            style: AppTextStyles.bodySmall
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxTotal = s.porDia.fold(0.0,
                  (m, d) => d.total > m ? d.total : m);
              return SizedBox(
                height: 170,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: s.porDia.asMap().entries.map((e) {
                    final idx  = e.key;
                    final dia  = e.value;
                    final now  = DateTime.now();
                    final esHoy = dia.fecha.year == now.year &&
                        dia.fecha.month == now.month &&
                        dia.fecha.day == now.day;
                    final barPct = maxTotal > 0
                        ? (dia.total / maxTotal).clamp(0.0, 1.0)
                        : 0.0;

                    return Expanded(
                      child: GestureDetector(
                        onTap: dia.total > 0
                            ? () => _mostrarDetalleDia(context, dia, _dias[idx])
                            : null,
                        child: Container(
                        margin: EdgeInsets.only(right: idx < 6 ? 4 : 0),
                        decoration: BoxDecoration(
                          color: esHoy
                              ? AppColors.primaryPale
                              : AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(
                            color: esHoy
                                ? AppColors.primary
                                : AppColors.primaryLight,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Monto
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 2),
                              child: Text(
                                dia.total > 0
                                    ? 'S/${dia.total.toStringAsFixed(0)}'
                                    : '-',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: esHoy
                                      ? AppColors.primaryDark
                                      : (dia.total > 0
                                          ? AppColors.primaryDark
                                          : AppColors.textFaint),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Barra proporcional
                            Container(
                              height: 70 * barPct + 4,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 4),
                              decoration: BoxDecoration(
                                color: esHoy
                                    ? AppColors.primary
                                    : (dia.total > 0
                                        ? AppColors.primaryLight
                                        : Colors.transparent),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3),
                                ),
                              ),
                            ),
                            // Órdenes + día
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4),
                              child: Column(
                                children: [
                                  Text(
                                    '${dia.numOrdenes}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: esHoy
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    _dias[idx],
                                    style: TextStyle(
                                      color: esHoy
                                          ? AppColors.primary
                                          : AppColors.textMuted,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 9,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          // ── Mejor día históricamente ──────────────────────────
          ...ref.watch(ventasParaStatsProvider).maybeWhen(
            data: (ventas) {
              final dia = _mejorDiaHistorico(ventas);
              if (dia == null) return <Widget>[];
              return <Widget>[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.primaryLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded,
                          size: 14, color: AppColors.gold),
                      const SizedBox(width: 6),
                      Text(
                        'Históricamente tu mejor día: $dia',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            },
            orElse: () => <Widget>[],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        ),
      ),
    );
  }
}

// ── Pill del hero semanal ─────────────────────────────────────────────────────

class _HeroPill extends StatelessWidget {
  const _HeroPill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color:      Colors.white,
            fontSize:   13,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

// ── Pill de estadística ───────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.icon,
    this.highlight = false,
  });
  final String   label;
  final IconData icon;
  final bool     highlight;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: highlight ? AppColors.primaryPale : AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: highlight ? AppColors.primary : AppColors.primaryLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 11,
                color: highlight ? AppColors.primaryDark : AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: highlight ? AppColors.primaryDark : AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
}

// ── Skeleton semanal ──────────────────────────────────────────────────────────

class _SemanalSkeleton extends StatelessWidget {
  const _SemanalSkeleton();

  static Widget _box({double? w, required double h, double r = 8}) =>
      Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r),
        ),
      );

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: AppColors.primaryLight,
        highlightColor: AppColors.surface,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _box(w: 180, h: 14),
            const SizedBox(height: 4),
            _box(w: 140, h: 11),
            const SizedBox(height: AppSpacing.md),
            _box(h: 80, r: AppSpacing.radiusMd),
            const SizedBox(height: AppSpacing.md),
            _box(h: 72, r: AppSpacing.radiusMd),
            const SizedBox(height: AppSpacing.md),
            _box(w: 100, h: 12),
            const SizedBox(height: AppSpacing.sm),
            _box(h: 112, r: AppSpacing.radiusSm),
          ],
        ),
      );
}

// ── Skeleton tamaños ──────────────────────────────────────────────────────────

class _TamanosSkeleton extends StatelessWidget {
  const _TamanosSkeleton();

  static Widget _box({double? w, required double h, double r = 8}) =>
      Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r),
        ),
      );

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: AppColors.primaryLight,
        highlightColor: AppColors.surface,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _box(w: 160, h: 14),
            const SizedBox(height: AppSpacing.md),
            _box(h: 88, r: AppSpacing.radiusMd),
            const SizedBox(height: AppSpacing.sm),
            _box(h: 88, r: AppSpacing.radiusMd),
            const SizedBox(height: AppSpacing.sm),
            _box(h: 88, r: AppSpacing.radiusMd),
            const SizedBox(height: AppSpacing.sm),
            _box(h: 88, r: AppSpacing.radiusMd),
          ],
        ),
      );
}


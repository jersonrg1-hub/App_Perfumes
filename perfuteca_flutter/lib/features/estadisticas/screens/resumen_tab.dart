import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/features/estadisticas/providers/estadisticas_provider.dart';
import 'package:perfuteca/features/ventas/screens/pendientes_screen.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';
import 'package:shimmer/shimmer.dart';

const _meses = [
  '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

class ResumenTab extends ConsumerStatefulWidget {
  const ResumenTab({super.key});

  @override
  ConsumerState<ResumenTab> createState() => _ResumenTabState();
}

class _ResumenTabState extends ConsumerState<ResumenTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ref.watch(resumenStatsProvider).when(
      loading: () => const _ResumenSkeleton(),
      error:   (e, _) => _ErrorView(
        mensaje: e.toString(),
        onRetry: () {
          ref.invalidate(resumenBackendProvider);
          ref.invalidate(resumenStatsProvider);
        },
      ),
      data: (stats) => RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(resumenBackendProvider);
          ref.invalidate(resumenStatsProvider);
          await ref.read(resumenStatsProvider.future);
        },
        child: _ResumenBody(stats: stats),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _ResumenBody extends ConsumerWidget {
  const _ResumenBody({required this.stats});
  final ResumenStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s      = stats;
    final now    = DateTime.now();
    final semana  = ref.watch(semanaStatsProvider);
    final tamanios = ref.watch(tamaniosStatsProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ── Hoy — primero, es lo que más importa ─────────────────────────────
        _SeccionLabel('Hoy · ${_diaLabel(now)}', icono: Icons.wb_sunny_rounded),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: s.ventasHoy > 0
              ? () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppColors.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.radiusLg),
                      ),
                    ),
                    builder: (_) => _VentasDiaSheet(fecha: now),
                  )
              : null,
          child: _SeccionHoy(
            ventasHoy:  s.ventasHoy,
            totalHoy:   s.totalHoy,
            mlHoy:      s.mlHoy,
            ticketProm: s.ticketPromedioHoy,
            tappable:   s.ventasHoy > 0,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Pendientes ────────────────────────────────────────────────────────
        if (s.pendientesCount > 0) ...[
          _PendientesBanner(
            count: s.pendientesCount,
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(
                    title: const Text('Pedidos pendientes'),
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                  ),
                  backgroundColor: AppColors.background,
                  body: const PendientesScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── Este mes ─────────────────────────────────────────────────────────
        _HeroMesCard(stats: s, now: now),
        const SizedBox(height: AppSpacing.md),

        // ── Esta semana ───────────────────────────────────────────────────────
        _SeccionLabel('Esta semana', icono: Icons.calendar_view_week_rounded),
        const SizedBox(height: AppSpacing.sm),
        semana.when(
          loading: () => _skeletonBox(h: 100),
          error:   (_, __) => const SizedBox.shrink(),
          data:    (sem) => _MiniSemanalCard(semana: sem),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Más vendidos del mes ──────────────────────────────────────────────
        if (s.masVendidos.isNotEmpty) ...[
          _SeccionLabel('Más vendidos del mes', icono: Icons.star_rounded),
          const SizedBox(height: AppSpacing.sm),
          _TopPerfumesCard(perfumes: s.masVendidos.take(5).toList()),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── Mix del mes (tamaños) ─────────────────────────────────────────────
        tamanios.when(
          loading: () => const SizedBox.shrink(),
          error:   (_, __) => const SizedBox.shrink(),
          data: (tams) => tams.isEmpty ? const SizedBox.shrink() : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SeccionLabel('Mix del mes', icono: Icons.water_drop_outlined),
                  TextButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: AppColors.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppSpacing.radiusLg),
                        ),
                      ),
                      builder: (_) => _TamaniosDetalle(tamanios: tams),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      textStyle: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Ver detalle'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _TamaniosChips(tamanios: tams),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

Widget _skeletonBox({required double h, double r = 8}) => Container(
  height: h,
  decoration: BoxDecoration(
    color: AppColors.primaryLight,
    borderRadius: BorderRadius.circular(r),
  ),
);

// ── Hero card del mes ─────────────────────────────────────────────────────────

class _HeroMesCard extends StatelessWidget {
  const _HeroMesCard({required this.stats, required this.now});
  final ResumenStats stats;
  final DateTime     now;

  @override
  Widget build(BuildContext context) {
    final s         = stats;
    final variacion = s.variacionMes;
    final hayPrevio = s.totalMesPasado > 0;
    final subiendo  = variacion >= 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.primaryLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mes + variación
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${_meses[now.month].toUpperCase()} ${now.year}',
                style: const TextStyle(
                  color:         AppColors.primary,
                  fontSize:      11,
                  fontWeight:    FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              if (hayPrevio)
                _BadgeVariacion(variacion: variacion, subiendo: subiendo),
            ],
          ),
          const SizedBox(height: 8),

          // Total — tipografía limpia, sin gradiente
          Text(
            'S/ ${_fmt(s.totalMes)}',
            style: const TextStyle(
              fontSize:      30,
              fontWeight:    FontWeight.w800,
              color:         AppColors.textPrimary,
              letterSpacing: -0.8,
              height:        1.0,
            ),
          ),
          const SizedBox(height: 8),

          // Sub-métricas como fila de texto sutil
          DefaultTextStyle(
            style: const TextStyle(
              fontSize:   11,
              color:      AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
            child: Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                _ChipStat(
                  icono: Icons.receipt_long_rounded,
                  texto: '${s.ventasMes} venta${s.ventasMes != 1 ? 's' : ''}',
                ),
                _ChipStat(
                  icono: Icons.water_drop_outlined,
                  texto: '${s.mlMes} ml',
                ),
                _ChipStat(
                  icono: Icons.trending_up_rounded,
                  texto: 'S/ ${s.ticketPromedioMes.toStringAsFixed(0)} prom.',
                ),
              ],
            ),
          ),

          if (hayPrevio) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(color: AppColors.primaryLight, height: 1),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'vs ${_meses[now.month == 1 ? 12 : now.month - 1]}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),
                Text(
                  'S/ ${_fmt(s.totalMesPasado)}  ·  ${s.ventasMesPasado} venta${s.ventasMesPasado != 1 ? 's' : ''}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (s.totalMes / s.totalMesPasado).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.primaryPale,
                valueColor: AlwaysStoppedAnimation<Color>(
                  s.totalMes >= s.totalMesPasado
                      ? AppColors.stockOk
                      : AppColors.gold,
                ),
              ),
            ),
            if (s.totalMes >= s.totalMesPasado) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 11, color: AppColors.stockOk),
                  const SizedBox(width: 3),
                  Text(
                    'Objetivo superado',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 10,
                      color: AppColors.stockOk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ── Badge de variación ────────────────────────────────────────────────────────

class _BadgeVariacion extends StatelessWidget {
  const _BadgeVariacion({required this.variacion, required this.subiendo});
  final double variacion;
  final bool   subiendo;

  @override
  Widget build(BuildContext context) {
    final color = subiendo
        ? const Color(0xFF4CAF50)
        : const Color(0xFFE53935);
    final signo = subiendo ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border:       Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            subiendo ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '$signo${variacion.toStringAsFixed(1)}%',
            style: TextStyle(
              color:      color,
              fontSize:   11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chip pequeño para sub-métricas ────────────────────────────────────────────

class _ChipStat extends StatelessWidget {
  const _ChipStat({required this.icono, required this.texto});
  final IconData icono;
  final String   texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 12, color: const Color(0xFFD4A882)),
        const SizedBox(width: 3),
        Text(
          texto,
          style: const TextStyle(
            color:    Color(0xFFD4A882),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ── Sección Hoy ───────────────────────────────────────────────────────────────

class _SeccionHoy extends StatelessWidget {
  const _SeccionHoy({
    required this.ventasHoy,
    required this.totalHoy,
    required this.mlHoy,
    required this.ticketProm,
    this.tappable = false,
  });
  final int    ventasHoy;
  final double totalHoy;
  final int    mlHoy;
  final double ticketProm;
  final bool   tappable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: tappable ? AppColors.primary.withValues(alpha: 0.4) : AppColors.primaryLight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _ColStat(
                    label: 'Ingresos',
                    valor: 'S/ ${_fmt(totalHoy)}',
                    sub: mlHoy > 0 ? '$mlHoy ml' : null,
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1, color: AppColors.primaryLight),
                Expanded(
                  child: _ColStat(
                    label: 'Ventas',
                    valor: '$ventasHoy',
                    sub: 'orden${ventasHoy != 1 ? 'es' : ''}',
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1, color: AppColors.primaryLight),
                Expanded(
                  child: _ColStat(
                    label: 'Ticket prom.',
                    valor: ventasHoy > 0 ? 'S/ ${ticketProm.toStringAsFixed(0)}' : '—',
                  ),
                ),
              ],
            ),
          ),
          if (tappable) ...[
            const Divider(height: 1, color: AppColors.primaryLight),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.touch_app_rounded,
                      size: 11, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Toca para ver el detalle de hoy',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ColStat extends StatelessWidget {
  const _ColStat({required this.label, required this.valor, this.sub});
  final String  label;
  final String  valor;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub!,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Banner de pendientes ──────────────────────────────────────────────────────

class _PendientesBanner extends StatelessWidget {
  const _PendientesBanner({required this.count, required this.onTap});
  final int          count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        splashColor: AppColors.gold.withValues(alpha: 0.15),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.pending_actions_rounded,
                  size: 18, color: AppColors.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$count pedido${count != 1 ? 's' : ''} pendiente${count != 1 ? 's' : ''} de entregar',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 16, color: AppColors.gold),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Etiqueta de sección ───────────────────────────────────────────────────────

class _SeccionLabel extends StatelessWidget {
  const _SeccionLabel(this.label, {this.icono});
  final String   label;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.bodySmall.copyWith(
      color: AppColors.textMuted,
      fontWeight: FontWeight.w700,
      fontSize: 12,
      letterSpacing: 0.8,
    );
    if (icono == null) return Text(label, style: style);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Text(label, style: style),
      ],
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.mensaje, required this.onRetry});
  final String       mensaje;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 48, color: AppColors.textFaint),
          const SizedBox(height: 12),
          const Text('Error al cargar estadísticas',
              style: AppTextStyles.body),
          const SizedBox(height: 4),
          Text(mensaje,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmt(double v) {
  if (v >= 1000) {
    return v.toStringAsFixed(2)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');
  }
  return v.toStringAsFixed(2);
}

String _diaLabel(DateTime d) {
  const dias = ['', 'lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
  return '${dias[d.weekday]} ${d.day} ${_meses[d.month].toLowerCase()}';
}

// ── Mini semanal card ─────────────────────────────────────────────────────────

class _MiniSemanalCard extends ConsumerWidget {
  const _MiniSemanalCard({required this.semana});
  final SemanaStat semana;

  static const _dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s      = semana;
    final maxBar = s.porDia.fold(0.0, (m, d) => d.total > m ? d.total : m);
    final hoy    = DateTime.now();
    final subiendo = s.variacionSemana >= 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Totales fila
          Row(
            children: [
              Text(
                'S/ ${_fmt(s.total)}',
                style: AppTextStyles.body.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (s.totalSemanaAnterior > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (subiendo
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFE53935))
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        subiendo ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        size: 10,
                        color: subiendo ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${subiendo ? '+' : ''}${s.variacionSemana.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: subiendo ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              Text(
                '${s.numOrdenes} venta${s.numOrdenes != 1 ? 's' : ''}  ·  ${s.totalMl} ml',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Mini barras por día — tapeables si tienen ventas
          SizedBox(
            height: 52,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: s.porDia.asMap().entries.map((e) {
                final idx       = e.key;
                final dia       = e.value;
                final esHoy     = dia.fecha.year == hoy.year &&
                    dia.fecha.month == hoy.month &&
                    dia.fecha.day == hoy.day;
                final tieneVentas = dia.total > 0;
                final barPct    = maxBar > 0 ? (dia.total / maxBar).clamp(0.0, 1.0) : 0.0;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: idx < 6 ? 3 : 0),
                    child: GestureDetector(
                      onTap: tieneVentas
                          ? () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: AppColors.surface,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(AppSpacing.radiusLg),
                                ),
                              ),
                              builder: (_) => _VentasDiaSheet(fecha: dia.fecha),
                            )
                          : null,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 32 * barPct + 4,
                            decoration: BoxDecoration(
                              color: tieneVentas
                                  ? (esHoy ? AppColors.primary : AppColors.primaryDark.withValues(alpha: 0.5))
                                  : AppColors.primaryLight,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _dias[idx],
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: esHoy ? AppColors.primary : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Toca un día con ventas para ver el detalle',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              color: AppColors.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detalle de ventas de un día ───────────────────────────────────────────────

class _VentasDiaSheet extends ConsumerWidget {
  const _VentasDiaSheet({required this.fecha});
  final DateTime fecha;

  static const _mesesCortos = [
    '', 'Ene', 'Feb', 'Mar', 'Abr', 'May',
    'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];
  static const _diasSemana = [
    '', 'lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ventasAsync      = ref.watch(ventasParaStatsProvider);
    final perfumesMapAsync = ref.watch(perfumesMapProvider);
    final diaLabel =
        '${_diasSemana[fecha.weekday]} ${fecha.day} ${_mesesCortos[fecha.month]}';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.calendar_today_rounded,
                size: 15, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Ventas del $diaLabel',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ]),
          const SizedBox(height: AppSpacing.md),
          ventasAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const Text('Error al cargar ventas'),
            data: (ventas) {
              final perfumesMap = perfumesMapAsync.value ?? {};
              final delDia = ventas.where((v) {
                if (v.fecha == null) return false;
                try {
                  final d = DateTime.parse(v.fecha!);
                  return d.year == fecha.year &&
                      d.month == fecha.month &&
                      d.day == fecha.day;
                } catch (_) {
                  return false;
                }
              }).toList();

              if (delDia.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(child: Text('Sin ventas este día')),
                );
              }

              final totalDia = delDia.fold(0.0, (s, v) => s + (v.precioCobrado ?? 0));
              final ordenes  = delDia.map((v) => v.idCompra).toSet().length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPale,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$ordenes orden${ordenes != 1 ? 'es' : ''}  ·  ${delDia.length} item${delDia.length != 1 ? 's' : ''}',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textMuted),
                        ),
                        Text(
                          'S/ ${totalDia.toStringAsFixed(2)}',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...delDia.map((v) {
                    final rawId = v.idPerfume ?? '';
                    final normId = double.tryParse(rawId)
                            ?.toInt()
                            .toString() ??
                        rawId;
                    final nombre = perfumesMap[normId]?.nombre ??
                        'Perfume #${rawId.isEmpty ? '?' : rawId}';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(children: [
                        const Icon(Icons.local_florist_outlined,
                            size: 12, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            nombre,
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${v.mlVendido ?? 0}ml',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'S/ ${(v.precioCobrado ?? 0).toStringAsFixed(2)}',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700),
                        ),
                      ]),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Top 3 perfumes del mes ────────────────────────────────────────────────────

class _TopPerfumesCard extends StatelessWidget {
  const _TopPerfumesCard({required this.perfumes});
  final List<TopPerfume> perfumes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        children: perfumes.asMap().entries.map((e) {
          final pos    = e.key + 1;
          final p      = e.value;
          final esTop1 = pos == 1;
          return Container(
            margin: EdgeInsets.only(bottom: pos < perfumes.length ? AppSpacing.sm : 0),
            padding: esTop1
                ? const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs)
                : EdgeInsets.zero,
            decoration: esTop1
                ? BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3)),
                  )
                : null,
            child: Row(
              children: [
                Container(
                  width: esTop1 ? 26 : 22,
                  height: esTop1 ? 26 : 22,
                  decoration: BoxDecoration(
                    color: esTop1
                        ? AppColors.gold.withValues(alpha: 0.25)
                        : AppColors.primaryPale,
                    borderRadius: BorderRadius.circular(esTop1 ? 7 : 6),
                  ),
                  child: Center(
                    child: esTop1
                        ? const Icon(Icons.emoji_events_rounded,
                            size: 14, color: AppColors.gold)
                        : Text(
                            '$pos',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nombre,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: esTop1 ? 13 : 12,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (p.marca.isNotEmpty)
                        Text(
                          p.marca.toUpperCase(),
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 9,
                            color: esTop1 ? AppColors.gold : AppColors.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${p.totalMl} ml',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'S/ ${p.totalSoles.toStringAsFixed(2)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Detalle de tamaños en bottom sheet ───────────────────────────────────────

class _TamaniosDetalle extends StatelessWidget {
  const _TamaniosDetalle({required this.tamanios});
  final List<TamanioStat> tamanios;

  @override
  Widget build(BuildContext context) {
    final total = tamanios.fold(0, (s, t) => s + t.cantidad);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.water_drop_outlined,
                size: 16, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text('Ventas por tamaño — este mes',
                style: AppTextStyles.body
                    .copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: AppSpacing.md),
          ...tamanios.map((t) {
            final pct = total > 0 ? t.cantidad / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.water_drop_outlined,
                            size: 13, color: AppColors.primary),
                        const SizedBox(width: 5),
                        Text('${t.ml} ml',
                            style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                      ]),
                      Text(
                        '${t.cantidad} ventas  ·  S/ ${t.total.toStringAsFixed(2)}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
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
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${(pct * 100).toStringAsFixed(1)}%',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.primary, fontSize: 10),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Tamaños chips compactos ───────────────────────────────────────────────────

class _TamaniosChips extends StatelessWidget {
  const _TamaniosChips({required this.tamanios});
  final List<TamanioStat> tamanios;

  @override
  Widget build(BuildContext context) {
    final total = tamanios.fold(0, (s, t) => s + t.cantidad);
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: tamanios.map((t) {
        final pct = total > 0 ? (t.cantidad / total * 100) : 0.0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryPale,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(color: AppColors.primaryLight),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.water_drop_outlined, size: 11, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                '${t.ml}ml',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '${t.cantidad} · ${pct.toStringAsFixed(0)}%',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '· S/${t.total.toStringAsFixed(2)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Skeleton de carga ─────────────────────────────────────────────────────────

class _ResumenSkeleton extends StatelessWidget {
  const _ResumenSkeleton();

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
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.primaryLight,
      highlightColor: AppColors.surface,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _box(h: 148, r: AppSpacing.radiusLg),
          const SizedBox(height: AppSpacing.md),
          _box(w: 90, h: 11),
          const SizedBox(height: AppSpacing.sm),
          _box(h: 108, r: AppSpacing.radiusMd),
        ],
      ),
    );
  }
}

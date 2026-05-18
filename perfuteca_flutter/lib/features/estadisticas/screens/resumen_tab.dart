import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/features/estadisticas/providers/estadisticas_provider.dart';
import 'package:perfuteca/features/estadisticas/widgets/metrica_card.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';

const _meses = [
  '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

class ResumenTab extends ConsumerWidget {
  const ResumenTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(resumenStatsProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => _ErrorView(
        mensaje: e.toString(),
        onRetry: () => ref.invalidate(resumenStatsProvider),
      ),
      data:    (stats) => _ResumenBody(stats: stats),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _ResumenBody extends StatefulWidget {
  const _ResumenBody({required this.stats});
  final ResumenStats stats;

  @override
  State<_ResumenBody> createState() => _ResumenBodyState();
}

class _ResumenBodyState extends State<_ResumenBody> {
  static const _limit = 5;
  bool _verTodos = false;

  @override
  Widget build(BuildContext context) {
    final s   = widget.stats;
    final now = DateTime.now();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ── Hero: Este mes ────────────────────────────────────────────────────
        _HeroMesCard(stats: s, now: now),
        const SizedBox(height: AppSpacing.md),

        // ── Hoy ──────────────────────────────────────────────────────────────
        _SeccionLabel('☀️  Hoy · ${_diaLabel(now)}'),
        const SizedBox(height: AppSpacing.sm),
        _SeccionHoy(stats: s),
        const SizedBox(height: AppSpacing.md),

        // ── Pendientes ────────────────────────────────────────────────────────
        if (s.pendientesCount > 0) ...[
          _PendientesBanner(count: s.pendientesCount),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── Top perfumes ──────────────────────────────────────────────────────
        Text(
          '🏆  Perfumes más vendidos',
          style: AppTextStyles.heading2.copyWith(fontSize: 15),
        ),
        const SizedBox(height: AppSpacing.sm),

        if (s.masVendidos.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Center(
              child: Text(
                'Sin ventas entregadas aún',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted),
              ),
            ),
          )
        else ...[
          ...s.masVendidos
              .take(_verTodos ? s.masVendidos.length : _limit)
              .toList()
              .asMap()
              .entries
              .map((e) => _TopPerfumeRow(pos: e.key + 1, item: e.value)),

          if (s.masVendidos.length > _limit)
            Center(
              child: TextButton(
                onPressed: () => setState(() => _verTodos = !_verTodos),
                child: Text(
                  _verTodos
                      ? '▲ Ver menos'
                      : '▼ Ver más (${s.masVendidos.length - _limit} más)',
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
            ),
        ],

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

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
        gradient: const LinearGradient(
          colors: [Color(0xFF2C1A0E), Color(0xFF5A3520)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: const [
          BoxShadow(
            color:  Color(0x402C1A0E),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado: mes + variación
          Row(
            children: [
              Text(
                '📅  ${_meses[now.month]} ${now.year}',
                style: const TextStyle(
                  color:      Color(0xFFD4A882),
                  fontSize:   12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              if (hayPrevio)
                _BadgeVariacion(variacion: variacion, subiendo: subiendo),
            ],
          ),
          const SizedBox(height: 10),

          // Total del mes — número grande
          Text(
            'S/ ${_fmt(s.totalMes)}',
            style: const TextStyle(
              color:      Color(0xFFF5E6D8),
              fontSize:   34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 6),

          // Sub-métricas en fila
          Wrap(
            spacing: 12,
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

          if (hayPrevio) ...[
            const SizedBox(height: 8),
            Text(
              'Mes anterior: S/ ${_fmt(s.totalMesPasado)}  ·  ${s.ventasMesPasado} venta${s.ventasMesPasado != 1 ? 's' : ''}',
              style: const TextStyle(
                color:    Color(0xFF9B7250),
                fontSize: 11,
              ),
            ),
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
        borderRadius: BorderRadius.circular(20),
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

// ── Sección Hoy (3 MetricaCard) ───────────────────────────────────────────────

class _SeccionHoy extends StatelessWidget {
  const _SeccionHoy({required this.stats});
  final ResumenStats stats;

  @override
  Widget build(BuildContext context) {
    final s = stats;
    return Row(
      children: [
        Expanded(
          child: MetricaCard(
            titulo:    'Ingresos',
            valor:     'S/ ${_fmt(s.totalHoy)}',
            subtitulo: s.mlHoy > 0 ? '${s.mlHoy} ml' : null,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: MetricaCard(
            titulo: 'Ventas',
            valor:  '${s.ventasHoy}',
            subtitulo: s.ventasHoy > 0 ? 'órdenes' : 'sin ventas',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: MetricaCard(
            titulo:    'Promedio',
            valor:     s.ventasHoy > 0
                ? 'S/ ${s.ticketPromedioHoy.toStringAsFixed(0)}'
                : '—',
            subtitulo: 'por orden',
          ),
        ),
      ],
    );
  }
}

// ── Banner de pendientes ──────────────────────────────────────────────────────

class _PendientesBanner extends StatelessWidget {
  const _PendientesBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.pending_actions_rounded,
              size: 18, color: Color(0xFFB8860B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count pedido${count != 1 ? 's' : ''} pendiente${count != 1 ? 's' : ''} de entregar',
              style: AppTextStyles.bodySmall.copyWith(
                color: const Color(0xFF7A5C00),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Etiqueta de sección ───────────────────────────────────────────────────────

class _SeccionLabel extends StatelessWidget {
  const _SeccionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.bodySmall.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── Fila de top perfume ───────────────────────────────────────────────────────

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
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: rankBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              '$pos',
              style: TextStyle(
                color: rankFg,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🌸 ${item.nombre}',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
                child: Text(
                  '${item.totalMl}ml',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'S/ ${item.totalSoles.toStringAsFixed(0)}',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
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
          Text('Error al cargar estadísticas',
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

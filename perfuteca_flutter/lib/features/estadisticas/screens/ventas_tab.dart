import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:perfuteca/features/estadisticas/providers/estadisticas_provider.dart';
import 'package:perfuteca/features/estadisticas/widgets/metrica_card.dart';
import 'package:perfuteca/features/ventas/screens/historial_screen.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';

enum _SeccionVentas { historial, tamanios, semanal }

class VentasTab extends ConsumerStatefulWidget {
  const VentasTab({super.key});

  @override
  ConsumerState<VentasTab> createState() => _VentasTabState();
}

class _VentasTabState extends ConsumerState<VentasTab> {
  _SeccionVentas _seccion = _SeccionVentas.historial;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Chips de navegación ───────────────────────────────────────
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 4,
            ),
            children: _SeccionVentas.values.map((s) {
              final seleccionado = s == _seccion;
              final label = switch (s) {
                _SeccionVentas.historial => '📋 Historial',
                _SeccionVentas.tamanios  => '📏 Tamaños',
                _SeccionVentas.semanal   => '📅 Semanal',
              };
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ChoiceChip(
                  label: Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color:      seleccionado ? Colors.white : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selected:      seleccionado,
                  selectedColor: AppColors.primaryDark,
                  onSelected:    (_) => setState(() => _seccion = s),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              );
            }).toList(),
          ),
        ),

        // ── Contenido ────────────────────────────────────────────────
        Expanded(
          child: switch (_seccion) {
            _SeccionVentas.historial => const HistorialScreen(),
            _SeccionVentas.tamanios  => const _TamanosView(),
            _SeccionVentas.semanal   => const _SemanalView(),
          },
        ),
      ],
    );
  }
}

// ── Tamaños ───────────────────────────────────────────────────────────────────

class _TamanosView extends ConsumerWidget {
  const _TamanosView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(tamaniosStatsProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(
        child: Text(e.toString(), style: AppTextStyles.bodySmall),
      ),
      data: (tamanios) {
        if (tamanios.isEmpty) {
          return Center(
            child: Text(
              'Sin ventas registradas aún',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textMuted),
            ),
          );
        }
        final totalCount = tamanios.fold(0, (s, t) => s + t.cantidad);

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              '📏 Tamaños más vendidos',
              style: AppTextStyles.heading2.copyWith(fontSize: 15),
            ),
            const SizedBox(height: AppSpacing.md),
            ...tamanios.map((t) {
              final pct = totalCount > 0 ? t.cantidad / totalCount : 0.0;
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '📦 ${t.ml}ml',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${t.cantidad} venta${t.cantidad != 1 ? 's' : ''}'
                          ' — S/ ${t.total.toStringAsFixed(2)}',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value:      pct,
                        minHeight:  10,
                        backgroundColor: AppColors.primaryPale,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary),
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

// ── Semanal ───────────────────────────────────────────────────────────────────

class _SemanalView extends ConsumerStatefulWidget {
  const _SemanalView();

  @override
  ConsumerState<_SemanalView> createState() => _SemanalViewState();
}

class _SemanalViewState extends ConsumerState<_SemanalView> {
  String? _mes1;
  String? _mes2;

  static const _dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  String _fmt(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  @override
  Widget build(BuildContext context) {
    final semana   = ref.watch(semanaStatsProvider);
    final meses    = ref.watch(mesesDisponiblesProvider).valueOrNull ?? [];
    final statsMap = ref.watch(mesStatsMapProvider).valueOrNull ?? {};

    if (meses.isNotEmpty) {
      _mes1 ??= meses.last;
      _mes2 ??= meses.length >= 2 ? meses[meses.length - 2] : meses.last;
    }

    return semana.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(
        child: Text(e.toString(), style: AppTextStyles.bodySmall),
      ),
      data: (s) => ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ── Encabezado ────────────────────────────────────────
          Text(
            '📅 Resumen de esta semana',
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
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${s.numOrdenes} venta${s.numOrdenes != 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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
                  Text(
                    '🏆 Más vendido esta semana',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                    textAlign: TextAlign.center,
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
                height: 112,
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
                              height: 40 * barPct + 4,
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
                    );
                  }).toList(),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Comparar meses ────────────────────────────────────
          const Divider(color: AppColors.primaryLight),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '📆 Comparar meses',
            style: AppTextStyles.heading2.copyWith(fontSize: 15),
          ),
          const SizedBox(height: AppSpacing.md),

          if (meses.length < 2)
            Text(
              'Se necesitan al menos 2 meses de datos para comparar',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textMuted),
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
                  Expanded(
                    child: _MesCard(
                      mes:   _mes1!,
                      stats: statsMap[_mes1],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _MesCard(
                      mes:   _mes2!,
                      stats: statsMap[_mes2],
                    ),
                  ),
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

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
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
          borderRadius: BorderRadius.circular(20),
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

// ── Dropdown de mes ───────────────────────────────────────────────────────────

class _MesDropdown extends StatelessWidget {
  const _MesDropdown({
    required this.label,
    required this.value,
    required this.meses,
    required this.onChanged,
  });
  final String        label;
  final String?       value;
  final List<String>  meses;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
}

// ── Tarjeta de mes ────────────────────────────────────────────────────────────

class _MesCard extends StatelessWidget {
  const _MesCard({required this.mes, required this.stats});
  final String  mes;
  final MesStat? stats;

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
        children: [
          Text(
            mes,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${stats?.numOrdenes ?? 0} ventas',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            'S/ ${(stats?.total ?? 0).toStringAsFixed(2)}',
            style: AppTextStyles.price.copyWith(
              color: AppColors.primaryDark,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Banner diferencia ─────────────────────────────────────────────────────────

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
    final diff     = stat2.total - stat1.total;
    final pct      = diff / stat1.total * 100;
    final positivo = diff >= 0;
    final color    = positivo
        ? const Color(0xFF16a34a)
        : const Color(0xFFdc2626);
    final bgColor  = positivo
        ? const Color(0xFFf0faf4)
        : const Color(0xFFfff5f5);
    final borde    = positivo
        ? const Color(0xFFb7e4c7)
        : const Color(0xFFfed7d7);
    final simbolo  = positivo ? '📈' : '📉';

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
          Text(
            'Diferencia',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$simbolo S/ ${diff.abs().toStringAsFixed(2)}'
            ' (${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%)',
            style: AppTextStyles.price.copyWith(color: color, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          Text(
            '$mes2 vs $mes1',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

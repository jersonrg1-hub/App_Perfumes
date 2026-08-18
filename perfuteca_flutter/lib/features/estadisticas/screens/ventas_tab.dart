import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/features/estadisticas/providers/estadisticas_provider.dart';
import 'package:perfuteca/features/estadisticas/widgets/estadisticas_shared.dart';
import 'package:perfuteca/features/ventas/screens/historial_screen.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';
import 'package:perfuteca/widgets/common/app_error_widget.dart';
import 'package:shimmer/shimmer.dart';

class VentasTab extends ConsumerStatefulWidget {
  const VentasTab({super.key});

  @override
  ConsumerState<VentasTab> createState() => _VentasTabState();
}

class _VentasTabState extends ConsumerState<VentasTab>
    with AutomaticKeepAliveClientMixin {
  bool _verAnalisis = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        // ── Selector de vista ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.history_rounded, size: 15),
                label: Text('Historial'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.water_drop_outlined, size: 15),
                label: Text('Tamaños'),
              ),
            ],
            selected: {_verAnalisis},
            onSelectionChanged: (s) =>
                setState(() => _verAnalisis = s.first),
            style: SegmentedButton.styleFrom(
              backgroundColor:         AppColors.background,
              foregroundColor:         AppColors.textMuted,
              selectedForegroundColor: AppColors.primaryDark,
              selectedBackgroundColor: AppColors.primaryPale,
              side: const BorderSide(color: AppColors.primaryLight),
              textStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        // ── Contenido ──────────────────────────────────────────────────
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _verAnalisis
                ? const _TamanosView()
                : const HistorialScreen(),
          ),
        ),
      ],
    );
  }
}

// ── Vista de tamaños con filtro de período ────────────────────────────────────

class _TamanosView extends ConsumerStatefulWidget {
  const _TamanosView();

  @override
  ConsumerState<_TamanosView> createState() => _TamanosViewState();
}

class _TamanosViewState extends ConsumerState<_TamanosView> {
  // 'todo' | 'mes' | 'YYYY-MM'
  String _filtro = 'todo';

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
      loading: () => const _TamanosSkeleton(),
      error: (e, __) => AppErrorWidget(
        error: e,
        title: 'Error al cargar datos',
        icon: Icons.wifi_off_rounded,
        subtle: true,
        onRetry: () => ref.invalidate(historicoBackendProvider),
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

        List<dynamic> tamaniosRaw;
        if (_filtro == 'todo') {
          tamaniosRaw = data['tamanios_total'] as List<dynamic>? ?? [];
        } else {
          final clave = _filtro == 'mes' ? mesActual : _filtro;
          final mes = porMes.cast<Map<String, dynamic>?>().firstWhere(
                (m) => m?['clave'] == clave,
                orElse: () => null,
              );
          tamaniosRaw = mes?['tamanios'] as List<dynamic>? ?? [];
        }

        final tamanios   = tamaniosFromJson(tamaniosRaw);
        final totalCount = tamanios.fold(0, (s, t) => s + t.cantidad);

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // ── Chips de período ────────────────────────────────────
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

            // ── Título dinámico ─────────────────────────────────────
            Text(
              'Tamaños · ${_labelFiltro(_filtro)}',
              style: AppTextStyles.heading2.copyWith(fontSize: 15),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Lista o vacío ───────────────────────────────────────
            if (tamanios.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bar_chart_rounded,
                        size: 64, color: AppColors.primaryLight),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Sin ventas en este período',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color:      AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Selecciona otro período o registra más ventas',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...tamanios.map((t) {
                final pct = totalCount > 0
                    ? t.cantidad / totalCount
                    : 0.0;
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color:        AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border:       Border.all(color: AppColors.primaryLight),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
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
                                    color:      AppColors.textPrimary,
                                    fontSize:   16,
                                  ),
                                ),
                              ],
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
                          child: SizedBox(
                            height: 10,
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
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

// ── Chip de filtro ────────────────────────────────────────────────────────────

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
          borderRadius:
              BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color:
                selected ? AppColors.primary : AppColors.primaryLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize:   11,
            fontWeight: FontWeight.w600,
            color: selected
                ? AppColors.background
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Skeleton tamaños ──────────────────────────────────────────────────────────

class _TamanosSkeleton extends StatelessWidget {
  const _TamanosSkeleton();

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor:      AppColors.primaryLight,
        highlightColor: AppColors.surface,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            skeletonBox(width: 220, height: 32, radius: AppSpacing.radiusFull),
            const SizedBox(height: AppSpacing.sm),
            skeletonBox(width: 160, height: 14),
            const SizedBox(height: AppSpacing.sm),
            skeletonBox(height: 88, radius: AppSpacing.radiusMd),
            const SizedBox(height: AppSpacing.sm),
            skeletonBox(height: 88, radius: AppSpacing.radiusMd),
            const SizedBox(height: AppSpacing.sm),
            skeletonBox(height: 88, radius: AppSpacing.radiusMd),
            const SizedBox(height: AppSpacing.sm),
            skeletonBox(height: 88, radius: AppSpacing.radiusMd),
          ],
        ),
      );
}

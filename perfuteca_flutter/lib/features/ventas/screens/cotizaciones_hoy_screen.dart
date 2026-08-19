import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:perfuteca/features/cotizaciones/widgets/cotizacion_convertir_card.dart';
import 'package:perfuteca/features/estadisticas/providers/estadisticas_provider.dart'
    show nowPeru;
import 'package:perfuteca/models/cotizacion.dart';
import 'package:perfuteca/repositories/cotizaciones_repository.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';
import 'package:perfuteca/widgets/common/app_error_widget.dart';
import 'package:perfuteca/widgets/common/empty_state_widget.dart';
import 'package:perfuteca/widgets/common/staggered_list_item.dart';
import 'package:shimmer/shimmer.dart';

// ── Provider: cotizaciones registradas hoy ────────────────────────────────────

final cotizacionesHoyProvider =
    FutureProvider<List<CotizacionResponse>>((ref) async {
  final today = DateFormat('yyyy-MM-dd').format(nowPeru());
  final page  = await ref.read(cotizacionesRepositoryProvider).getCotizaciones(
        limit: 100,
        fechaDesde: today,
        bypassCache: true,
      );
  // La API serializa fecha como ISO "2026-05-16T00:00:00", no como "2026-05-16"
  final items = page.items.where((c) => c.fecha?.startsWith(today) == true).toList();
  return items.reversed.toList();
});

// ── Pantalla ──────────────────────────────────────────────────────────────────

class CotizacionesHoyScreen extends ConsumerStatefulWidget {
  const CotizacionesHoyScreen({super.key});

  @override
  ConsumerState<CotizacionesHoyScreen> createState() =>
      _CotizacionesHoyScreenState();
}

class _CotizacionesHoyScreenState extends ConsumerState<CotizacionesHoyScreen> {
  // Ids que ya reprodujeron su animación de entrada — persiste mientras la
  // pantalla vive, así un pull-to-refresh no repite el fade/slide en cards
  // que no cambiaron (antes se reanimaba todo en cada refresh).
  final Set<String> _yaAnimadas = {};

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(cotizacionesHoyProvider);

    return async.when(
      loading: () => const _CotizacionesShimmer(),
      error: (error, __) => AppErrorWidget(
        error: error,
        onRetry: () => ref.invalidate(cotizacionesHoyProvider),
      ),
      data: (lista) => lista.isEmpty
          ? EmptyStateWidget(
              icon: Icons.receipt_long_outlined,
              title: 'Sin cotizaciones hoy',
              subtitle: 'Crea una cotización en la pestaña Cotización',
              action: OutlinedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Actualizar'),
                onPressed: () => ref.invalidate(cotizacionesHoyProvider),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(cotizacionesHoyProvider),
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg,
                    80 + MediaQuery.of(context).padding.bottom),
                itemCount: lista.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    final convertidas = lista
                        .where((c) => c.estado?.toLowerCase().startsWith('aceptad') == true)
                        .length;
                    final anuladas = lista
                        .where((c) => c.estado?.toLowerCase() == 'anulado')
                        .length;
                    final pendientes = lista.length - convertidas - anuladas;
                    final totalS = lista.fold(0.0, (s, c) => s + (c.total ?? 0));
                    return StaggeredListItem(
                      id:         'metricas',
                      index:      0,
                      yaAnimadas: _yaAnimadas,
                      child: MetricasHoyGrid(
                        total:       totalS,
                        pendientes:  pendientes,
                        convertidas: convertidas,
                      ),
                    );
                  }
                  final c = lista[i - 1];
                  return StaggeredListItem(
                    key:        ValueKey(c.idCotizacion),
                    id:         c.idCotizacion,
                    index:      i,
                    yaAnimadas: _yaAnimadas,
                    child: CotizacionConvertirCard(
                      key: ValueKey(c.idCotizacion),
                      cotizacion: c,
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ── Métricas del día — grid de mini-tarjetas ──────────────────────────────────

class MetricasHoyGrid extends StatelessWidget {
  const MetricasHoyGrid({
    super.key,
    required this.total,
    required this.pendientes,
    required this.convertidas,
  });
  final double total;
  final int    pendientes;
  final int    convertidas;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _MetricaCard(
              key: const Key('metrica-total'),
              label: 'TOTAL HOY',
              numericValue: total,
              isMoney: true,
              background: AppColors.surface,
              borderColor: AppColors.primary,
              valueColor: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _MetricaCard(
              key: const Key('metrica-pendientes'),
              label: 'PENDIENTES',
              numericValue: pendientes.toDouble(),
              isMoney: false,
              background: pendientes > 0
                  ? AppColors.warningSurface
                  : AppColors.surface,
              borderColor: pendientes > 0
                  ? AppColors.warning
                  : AppColors.primaryLight,
              valueColor:
                  pendientes > 0 ? AppColors.warning : AppColors.textFaint,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _MetricaCard(
              key: const Key('metrica-convertidas'),
              label: 'CONVERTIDAS',
              numericValue: convertidas.toDouble(),
              isMoney: false,
              background: convertidas > 0
                  ? AppColors.successSurface
                  : AppColors.surface,
              borderColor:
                  convertidas > 0 ? AppColors.stockOk : AppColors.primaryLight,
              valueColor:
                  convertidas > 0 ? AppColors.stockOk : AppColors.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricaCard extends StatelessWidget {
  const _MetricaCard({
    super.key,
    required this.label,
    required this.numericValue,
    required this.isMoney,
    required this.background,
    required this.borderColor,
    required this.valueColor,
  });
  final String label;
  final double numericValue;
  final bool   isMoney;
  final Color  background;
  final Color  borderColor;
  final Color  valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.notasLabel.copyWith(
              color: AppColors.textFaint,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: numericValue),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isMoney
                    ? 'S/ ${v.toStringAsFixed(2)}'
                    : v.round().toString(),
                style: TextStyle(
                  fontSize:   isMoney ? 22 : 20,
                  fontWeight: FontWeight.w800,
                  color:      valueColor,
                ),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer de carga ──────────────────────────────────────────────────────────

class _CotizacionesShimmer extends StatelessWidget {
  const _CotizacionesShimmer();

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor:      AppColors.primaryLight,
        highlightColor: AppColors.primaryPale,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 80),
          itemCount: 5,
          itemBuilder: (_, i) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            height: i == 0 ? 64 : 88,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        ),
      );
}

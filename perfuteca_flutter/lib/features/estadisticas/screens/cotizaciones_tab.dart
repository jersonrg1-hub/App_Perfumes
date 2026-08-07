import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:perfuteca/features/cotizaciones/widgets/cotizacion_convertir_card.dart';
import 'package:perfuteca/features/estadisticas/providers/estadisticas_provider.dart'
    show nowPeru;
import 'package:perfuteca/features/estadisticas/widgets/estadisticas_shared.dart';
import 'package:perfuteca/models/cotizacion.dart';
import 'package:perfuteca/repositories/cotizaciones_repository.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';
import 'package:shimmer/shimmer.dart';

// ── Provider: cotizaciones últimos 14 días, sin las de hoy ────────────────────
// Las de hoy ya se ven en Ventas > Cotizaciones de Hoy — este tab muestra el
// resto del historial reciente para no duplicar la misma cotización en dos
// pantallas a la vez.

final cotizaciones14dProvider =
    FutureProvider<List<CotizacionResponse>>((ref) async {
  final ahora      = nowPeru();
  final hoy        = DateTime(ahora.year, ahora.month, ahora.day);
  final limite     = ahora.subtract(const Duration(days: 14));
  final fechaDesde = DateFormat('yyyy-MM-dd').format(limite);
  final page       = await ref.read(cotizacionesRepositoryProvider)
      .getCotizaciones(limit: 200, fechaDesde: fechaDesde, bypassCache: true);
  return page.items.where((c) {
    if (c.fecha == null) return false;
    try {
      final fecha = DateTime.parse(c.fecha!);
      return fecha.isAfter(limite.subtract(const Duration(days: 1))) &&
          fecha.isBefore(hoy);
    } catch (_) {
      return false;
    }
  }).toList()
    ..sort((a, b) => (b.fecha ?? '').compareTo(a.fecha ?? ''));
});

// ── Tab principal ─────────────────────────────────────────────────────────────

class CotizacionesTab extends ConsumerStatefulWidget {
  const CotizacionesTab({super.key});

  @override
  ConsumerState<CotizacionesTab> createState() => _CotizacionesTabState();
}

class _CotizacionesTabState extends ConsumerState<CotizacionesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final async = ref.watch(cotizaciones14dProvider);

    return async.when(
      skipLoadingOnReload: true,
      loading: () => const _CotizShimmer(),
      error: (_, __) => EstadisticasErrorView(
        title: 'Error al cargar',
        icon: Icons.cloud_off_rounded,
        onRetry: () => ref.invalidate(cotizaciones14dProvider),
      ),
      data: (lista) {
        if (lista.isEmpty) {
          return _EmptyState(
              onRefresh: () => ref.invalidate(cotizaciones14dProvider));
        }

        // Construir lista plana con headers de fecha intercalados
        final aceptadas  = lista
            .where((c) =>
                c.estado?.toLowerCase().startsWith('aceptad') == true)
            .length;
        final anuladas   = lista
            .where((c) => c.estado?.toLowerCase() == 'anulado')
            .length;
        final pendientes = lista.length - aceptadas - anuladas;
        final totalS     = lista.fold(0.0, (s, c) => s + (c.total ?? 0));

        // items: String = header de día, CotizacionResponse = card
        final items = <Object>[];
        String? lastKey;
        for (final c in lista) {
          final key = _diaKey(c.fecha ?? '');
          if (key != lastKey) {
            items.add(key);
            lastKey = key;
          }
          items.add(c);
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.invalidate(cotizaciones14dProvider),
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg,
                80 + MediaQuery.of(context).padding.bottom),
            itemCount: items.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                return FadeSlideListItem(
                  index: 0,
                  child: _MetricasRow(
                    total:      totalS,
                    pendientes: pendientes,
                    aceptadas:  aceptadas,
                    diasLabel:  'últimos 14 días',
                  ),
                );
              }
              final item = items[i - 1];
              if (item is String) {
                return _DiaHeader(label: item);
              }
              final c = item as CotizacionResponse;
              return FadeSlideListItem(
                index: i,
                child: CotizacionConvertirCard(
                  key: ValueKey(c.idCotizacion),
                  cotizacion: c,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Métricas ──────────────────────────────────────────────────────────────────

class _MetricasRow extends StatelessWidget {
  const _MetricasRow({
    required this.total,
    required this.pendientes,
    required this.aceptadas,
    required this.diasLabel,
  });
  final double total;
  final int    pendientes;
  final int    aceptadas;
  final String diasLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                diasLabel.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textFaint,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          IntrinsicHeight(
            child: Row(children: [
              _MetItem(
                label: 'TOTAL',
                value: 'S/ ${total.toStringAsFixed(2)}',
                valueColor: AppColors.primaryDark,
              ),
              const VerticalDivider(
                  width: 1, thickness: 1, color: AppColors.primaryLight),
              _MetItem(
                label: 'PENDIENTES',
                value: '$pendientes',
                valueColor:
                    pendientes > 0 ? AppColors.warning : AppColors.textFaint,
              ),
              const VerticalDivider(
                  width: 1, thickness: 1, color: AppColors.primaryLight),
              _MetItem(
                label: 'ACEPTADAS',
                value: '$aceptadas',
                valueColor:
                    aceptadas > 0 ? AppColors.stockOk : AppColors.textFaint,
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _MetItem extends StatelessWidget {
  const _MetItem(
      {required this.label, required this.value, required this.valueColor});
  final String label;
  final String value;
  final Color  valueColor;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: AppTextStyles.notasLabel.copyWith(
                    color: AppColors.textFaint,
                    letterSpacing: 0.8,
                  )),
              const SizedBox(height: AppSpacing.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value,
                    style: TextStyle(
                      fontSize:   label == 'TOTAL' ? 22 : 20,
                      fontWeight: FontWeight.w800,
                      color:      valueColor,
                    ),
                    maxLines: 1),
              ),
            ],
          ),
        ),
      );
}

// ── Estado vacío ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 64, color: AppColors.textFaint),
            const SizedBox(height: AppSpacing.lg),
            Text('Sin cotizaciones en 14 días',
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: AppSpacing.xs + 2),
            Text(
              'Las cotizaciones aparecen aquí al crearlas',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textFaint),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Actualizar'),
              onPressed: onRefresh,
            ),
          ],
        ),
      );
}

// ── Shimmer ───────────────────────────────────────────────────────────────────

class _CotizShimmer extends StatelessWidget {
  const _CotizShimmer();

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor:      AppColors.primaryLight,
        highlightColor: AppColors.primaryPale,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 80),
          itemCount: 5,
          itemBuilder: (_, i) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            height: i == 0 ? 80 : 100,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        ),
      );
}

// ── Header separador de día ───────────────────────────────────────────────────

class _DiaHeader extends StatelessWidget {
  const _DiaHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(
            bottom: AppSpacing.sm, top: AppSpacing.xs),
        child: Row(children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize:      11,
              fontWeight:    FontWeight.w700,
              color:         AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Divider(color: AppColors.primaryLight, height: 1),
          ),
        ]),
      );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _diaKey(String iso) {
  try {
    final d = DateTime.parse(iso);
    const meses = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    const dias = ['', 'lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    final now = nowPeru();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'hoy · ${d.day} ${meses[d.month]}';
    }
    return '${dias[d.weekday]} ${d.day} ${meses[d.month]}';
  } catch (_) {
    return 'fecha desconocida';
  }
}

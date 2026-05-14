import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/features/notas/providers/notas_provider.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';
import 'package:perfuteca/widgets/common/app_error_widget.dart';
import 'package:perfuteca/widgets/common/app_loading_widget.dart';
import 'package:perfuteca/widgets/perfume/perfume_image.dart';

class DetallePerfumeScreen extends ConsumerWidget {
  const DetallePerfumeScreen({super.key, required this.idPerfume});
  final String idPerfume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(perfumeDetalleProvider(idPerfume));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: async.when(
        loading: () => const AppLoadingWidget(),
        error: (e, _) => Scaffold(
          appBar: AppBar(),
          body: AppErrorWidget(
            error: e,
            onRetry: () => ref.invalidate(perfumeDetalleProvider(idPerfume)),
          ),
        ),
        data: (p) => _DetalleBody(perfume: p),
      ),
    );
  }
}

class _DetalleBody extends ConsumerWidget {
  const _DetalleBody({required this.perfume});
  final Perfume perfume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        // ── App bar con imagen ────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: AppColors.surface,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                PerfumeImage(
                  imageUrl: perfume.imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.4, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                        AppColors.background,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Contenido ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Marca + nombre ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPale,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        perfume.marca.toUpperCase(),
                        style: AppTextStyles.marca.copyWith(fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(perfume.nombre, style: AppTextStyles.heading1),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Precios ───────────────────────────────────────────────
              if (perfume.precios.isNotEmpty) ...[
                _SeccionLabel(
                  icon:  Icons.sell_outlined,
                  label: 'PRECIOS',
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl),
                  child: Row(
                    children: perfume.precios.entries.map((e) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: AppSpacing.sm),
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd),
                            border:
                                Border.all(color: AppColors.primaryLight),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadowColor,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${e.key} ml',
                                style: AppTextStyles.priceLabel,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'S/ ${e.value.toStringAsFixed(2)}',
                                style: AppTextStyles.price.copyWith(
                                  color: AppColors.primaryDark,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // ── Stock ─────────────────────────────────────────────────
              if (perfume.stockMl != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl),
                  child: _StockBar(perfume: perfume),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // ── Notas ─────────────────────────────────────────────────
              if (perfume.notas != null && perfume.notas!.isNotEmpty) ...[
                _SeccionLabel(
                  icon:  Icons.spa_outlined,
                  label: 'NOTAS OLFATIVAS',
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl),
                  child: _NotasNavigables(
                    notas: perfume.notas!,
                    onTapNota: (nota) {
                      ref.read(notaSeleccionadaProvider.notifier).state =
                          nota;
                      context.go('/notas');
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // ── Perfil olfativo ───────────────────────────────────────
              if (perfume.perfilOlfativo != null &&
                  perfume.perfilOlfativo!.isNotEmpty) ...[
                _SeccionLabel(
                  icon:  Icons.auto_awesome_outlined,
                  label: 'PERFIL OLFATIVO',
                  color: AppColors.gold,
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      perfume.perfilOlfativo!,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],

              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Notas navegables ──────────────────────────────────────────────────────────

class _NotasNavigables extends StatelessWidget {
  const _NotasNavigables({
    required this.notas,
    required this.onTapNota,
  });
  final String                 notas;
  final void Function(String)  onTapNota;

  @override
  Widget build(BuildContext context) {
    final lista = notas
        .split(RegExp(r'[,;|]'))
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    if (lista.isEmpty) return Text(notas, style: AppTextStyles.body);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: lista.map((nota) {
            return GestureDetector(
              onTap: () => onTapNota(nota),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryPale,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusXxl),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nota,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.open_in_new_rounded,
                        size: 11, color: AppColors.primary),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Toca una nota para ver más perfumes similares',
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textFaint, fontSize: 10),
        ),
      ],
    );
  }
}

// ── Barra de stock visual ─────────────────────────────────────────────────────

class _StockBar extends StatelessWidget {
  const _StockBar({required this.perfume});
  final Perfume perfume;

  @override
  Widget build(BuildContext context) {
    final stock = perfume.stockMl ?? 0;
    final color = perfume.stockCritico
        ? AppColors.stockCritical
        : perfume.stockBajo
            ? AppColors.stockLow
            : AppColors.stockOk;
    final label = perfume.stockCritico
        ? '¡Último stock!'
        : perfume.stockBajo
            ? 'Stock bajo'
            : 'Disponible';
    final icon = perfume.stockCritico
        ? Icons.warning_amber_rounded
        : perfume.stockBajo
            ? Icons.info_outline_rounded
            : Icons.check_circle_outline_rounded;

    // Escala: 0 – 100 ml como máximo referencial para la barra
    final fraccion = (stock / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${stock.toStringAsFixed(0)} ml',
                style: AppTextStyles.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraccion,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _SeccionLabel extends StatelessWidget {
  const _SeccionLabel({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String   label;
  final Color    color;

  @override
  Widget build(BuildContext context) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.notasLabel
                  .copyWith(color: color, fontSize: 11),
            ),
          ],
        ),
      );
}

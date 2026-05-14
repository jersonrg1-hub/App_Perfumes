import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';
import 'package:perfuteca/widgets/perfume/perfume_image.dart';

class PerfumeCard extends StatelessWidget {
  const PerfumeCard({super.key, required this.perfume});
  final Perfume perfume;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: () => context.push('/catalogo/${perfume.idPerfume}'),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primaryLight, width: 1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Imagen con overlays ──────────────────────────────────────
              Expanded(
                flex: 11,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PerfumeImage(
                      imageUrl: perfume.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.radiusLg),
                      ),
                    ),
                    // Gradiente inferior para legibilidad de la marca
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppSpacing.radiusLg),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.55, 1.0],
                            colors: [
                              Colors.transparent,
                              AppColors.textPrimary.withOpacity(0.55),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Marca en overlay
                    Positioned(
                      bottom: AppSpacing.sm,
                      left: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: Text(
                        perfume.marca.toUpperCase(),
                        style: AppTextStyles.marca.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                          letterSpacing: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Badge de stock
                    if (perfume.stockCritico || perfume.stockBajo)
                      Positioned(
                        top: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: _StockBadge(perfume: perfume),
                      ),
                  ],
                ),
              ),

              // ── Info ─────────────────────────────────────────────────────
              Expanded(
                flex: 7,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        perfume.nombre,
                        style: AppTextStyles.perfumeName.copyWith(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      _PrecioChips(perfume: perfume),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Badge de stock ─────────────────────────────────────────────────────────────

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.perfume});
  final Perfume perfume;

  @override
  Widget build(BuildContext context) {
    final color = perfume.stockCritico ? AppColors.stockCritical : AppColors.stockLow;
    final label = perfume.stockCritico ? '¡Último stock!' : 'Stock bajo';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Sección de precios ────────────────────────────────────────────────────────

class _PrecioChips extends StatelessWidget {
  const _PrecioChips({required this.perfume});
  final Perfume perfume;

  @override
  Widget build(BuildContext context) {
    final precios = perfume.precios;
    if (precios.isEmpty) {
      return Text('Sin precio', style: AppTextStyles.bodySmall);
    }

    final minPrecio = precios.values.reduce((a, b) => a < b ? a : b);
    final tieneVarios = precios.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Precio principal
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            if (tieneVarios)
              Text(
                'desde ',
                style: AppTextStyles.priceLabel.copyWith(
                  fontSize: 9,
                  color: AppColors.textMuted,
                ),
              ),
            Text(
              'S/ ${minPrecio.toStringAsFixed(2)}',
              style: AppTextStyles.price.copyWith(
                fontSize: 13,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        // Chips de ml disponibles
        const SizedBox(height: 3),
        Row(
          children: precios.entries.map((e) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryPale,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.primaryLight),
              ),
              child: Text(
                '${e.key}ml',
                style: AppTextStyles.priceLabel.copyWith(fontSize: 8),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }
}

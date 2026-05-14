import 'package:flutter/material.dart';
import 'package:perfuteca/models/venta.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';

class ItemCestaCard extends StatelessWidget {
  const ItemCestaCard({
    super.key,
    required this.item,
    required this.index,
    this.onQuitar,
    this.readOnly = false,
  });

  final ItemCesta item;
  final int       index;
  final VoidCallback? onQuitar;
  final bool      readOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        children: [
          // Número de ítem
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primaryPale,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Info del perfume
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.perfume.nombre,
                  style: AppTextStyles.perfumeName.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      item.perfume.marca,
                      style: AppTextStyles.marca.copyWith(fontSize: 10),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPale,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item.ml} ml',
                        style: AppTextStyles.priceLabel,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.goldLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.metodo,
                        style: AppTextStyles.priceLabel.copyWith(
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Precio y botón quitar
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'S/ ${item.precio.toStringAsFixed(2)}',
                style: AppTextStyles.price.copyWith(
                  fontSize: 15,
                  color: AppColors.primaryDark,
                ),
              ),
              if (!readOnly && onQuitar != null)
                GestureDetector(
                  onTap: onQuitar,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.remove_circle_outline_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

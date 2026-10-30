import 'package:flutter/material.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';

/// Fila de ítem de una orden: punto bullet + contenido + precio.
/// Compartida entre las cards de pendientes e historial para no duplicar
/// el mismo layout dot+precio en cada pantalla.
class OrdenItemRow extends StatelessWidget {
  const OrdenItemRow({
    super.key,
    required this.content,
    required this.precio,
    this.priceStyle,
  });

  final Widget content;
  final double precio;
  final TextStyle? priceStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: content),
          Text(
            'S/ ${precio.toStringAsFixed(2)}',
            style: priceStyle ??
                AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
          ),
        ],
      ),
    );
  }
}

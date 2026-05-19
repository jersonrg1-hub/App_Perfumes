import 'package:flutter/material.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';

class MetricaCard extends StatelessWidget {
  const MetricaCard({
    super.key,
    required this.titulo,
    required this.valor,
    this.subtitulo,
    this.valorColor,
  });

  final String  titulo;
  final String  valor;
  final String? subtitulo;
  final Color?  valorColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: const Border(
          top:    BorderSide(color: AppColors.primary, width: 3),
          left:   BorderSide(color: AppColors.primaryLight),
          right:  BorderSide(color: AppColors.primaryLight),
          bottom: BorderSide(color: AppColors.primaryLight),
        ),
        boxShadow: const [
          BoxShadow(
            color:  AppColors.shadowColor,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            titulo.toUpperCase(),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: AppTextStyles.price.copyWith(
              color: valorColor ?? AppColors.primary,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitulo!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textFaint,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

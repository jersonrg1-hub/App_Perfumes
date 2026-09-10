import 'package:flutter/material.dart';
import 'package:perfuteca/core/errors/app_exception.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';

class AppErrorWidget extends StatelessWidget {
  static const double _iconSizeSubtle  = 48;
  static const double _iconSizeDefault = 56;
  static const double _retryIconSizeSubtle = 18;

  const AppErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.compact = false,
    this.title,
    this.subtitle,
    this.icon,
    this.subtle = false,
  });

  final Object error;
  final VoidCallback? onRetry;
  final bool compact;

  /// Título a mostrar en lugar del mensaje derivado de [error].
  final String? title;

  /// Texto secundario opcional, mostrado debajo del título/mensaje.
  final String? subtitle;

  /// Ícono a mostrar en lugar del derivado automáticamente de [error].
  final IconData? icon;

  /// Tratamiento visual atenuado (ícono gris más pequeño, botón compacto),
  /// usado en estados de error informativos como los tabs de estadísticas.
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    final message = title ??
        (error is AppException
            ? (error as AppException).message
            : 'Error inesperado. Intenta nuevamente.');

    final icon = this.icon ??
        (error is NetworkException
            ? Icons.wifi_off_rounded
            : Icons.error_outline_rounded);

    if (compact) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.error, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Flexible(child: Text(message, style: AppTextStyles.bodySmall)),
            if (onRetry != null) ...[
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(subtle ? AppSpacing.lg : AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: subtle ? _iconSizeSubtle : _iconSizeDefault,
              color: subtle ? AppColors.textFaint : AppColors.error.withValues(alpha: 0.7),
            ),
            SizedBox(height: subtle ? AppSpacing.md : AppSpacing.lg),
            Text(
              message,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              SizedBox(height: subtle ? AppSpacing.lg : AppSpacing.xl),
              FilledButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh_rounded, size: subtle ? _retryIconSizeSubtle : null),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

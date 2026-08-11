import 'package:flutter/material.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';

/// Formatea un monto con separador de miles a partir de 1000 (sin símbolo de moneda).
String formatMonto(double v) {
  if (v >= 1000) {
    return v
        .toStringAsFixed(2)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');
  }
  return v.toStringAsFixed(2);
}

/// Bloque rectangular usado como placeholder en skeletons con [Shimmer].
Widget skeletonBox({double? width, required double height, double radius = 8}) =>
    Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

/// Estado de error reutilizable para los tabs de estadísticas: ícono + título +
/// subtítulo opcional + botón de reintentar.
class EstadisticasErrorView extends StatelessWidget {
  const EstadisticasErrorView({
    super.key,
    required this.title,
    required this.onRetry,
    this.subtitle,
    this.icon = Icons.wifi_off_rounded,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: AppColors.textFaint),
              const SizedBox(height: 12),
              Text(title, style: AppTextStyles.body, textAlign: TextAlign.center),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
}

/// Envuelve [child] en una animación de fade + slide hacia arriba, escalonada
/// según [index] (usada en listas que aparecen en cascada).
class FadeSlideListItem extends StatefulWidget {
  const FadeSlideListItem({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<FadeSlideListItem> createState() => _FadeSlideListItemState();
}

class _FadeSlideListItemState extends State<FadeSlideListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    final delayMs = (widget.index * 40).clamp(0, 320);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

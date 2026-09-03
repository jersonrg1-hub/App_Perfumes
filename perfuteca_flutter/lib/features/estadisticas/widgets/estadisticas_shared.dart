import 'package:flutter/material.dart';
import 'package:perfuteca/theme/app_colors.dart';

final _milesRegExp = RegExp(r'(\d)(?=(\d{3})+\.)');

/// Chip inline de ícono + texto para sub-métricas (usado en hero cards de
/// resumen e histórico).
class StatChip extends StatelessWidget {
  const StatChip(this.icon, this.label, {this.color = AppColors.gold, super.key});
  final IconData icon;
  final String   label;
  final Color    color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      );
}

/// Formatea un monto con separador de miles a partir de 1000 (sin símbolo de moneda).
String formatMonto(double v) {
  if (v >= 1000) {
    return v.toStringAsFixed(2).replaceAllMapped(_milesRegExp, (m) => '${m[1]},');
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

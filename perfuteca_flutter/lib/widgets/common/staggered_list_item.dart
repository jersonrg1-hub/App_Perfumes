import 'package:flutter/material.dart';

/// Item de lista con animación de entrada (fade + slide) que se reproduce
/// una sola vez por [id] — el llamador persiste [yaAnimadas] (típicamente
/// un `Set<String>` en el State de la pantalla) para que un id no vuelva a
/// animarse solo porque su índice cambió al reordenarse la lista, ni se
/// repita en cada pull-to-refresh. Siempre envuelve [child] en
/// `RepaintBoundary` para aislar su repaint del resto de la lista.
class StaggeredListItem extends StatelessWidget {
  const StaggeredListItem({
    super.key,
    required this.id,
    required this.index,
    required this.yaAnimadas,
    required this.child,
  });

  final String       id;
  final int          index;
  final Set<String>  yaAnimadas;
  final Widget       child;

  @override
  Widget build(BuildContext context) {
    final animar = !yaAnimadas.contains(id);
    if (animar) {
      // Diferido a post-frame para no mutar el set durante el build/layout
      // pass del itemBuilder que lo llama.
      WidgetsBinding.instance.addPostFrameCallback((_) => yaAnimadas.add(id));
    }
    final boundedChild = RepaintBoundary(child: child);
    return animar
        ? _StaggeredEntrance(index: index, child: boundedChild)
        : boundedChild;
  }
}

class _StaggeredEntrance extends StatefulWidget {
  const _StaggeredEntrance({required this.index, required this.child});
  final int    index;
  final Widget child;

  @override
  State<_StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<_StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _opacity;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide   = Tween(begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: (widget.index * 40).clamp(0, 320)), () {
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
        opacity: _opacity,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

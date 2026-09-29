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
    // Siempre el mismo tipo de widget en esta posición del árbol — antes
    // alternaba entre _StaggeredEntrance (animar=true) y RepaintBoundary
    // directo (animar=false). Ese cambio de tipo hace que Flutter destruya
    // y recree el Element completo en cualquier rebuild posterior al primer
    // frame (ej. el teclado abriéndose cambia MediaQuery y fuerza un
    // rebuild de toda la lista) — se pierde la State del hijo (un
    // formulario a medio llenar) porque no es un problema de virtualización
    // fuera de viewport, que es lo único que AutomaticKeepAliveClientMixin
    // protege.
    return _StaggeredEntrance(
      index:  index,
      animar: animar,
      child:  RepaintBoundary(child: child),
    );
  }
}

class _StaggeredEntrance extends StatefulWidget {
  const _StaggeredEntrance({
    required this.index,
    required this.animar,
    required this.child,
  });
  final int    index;
  final bool   animar;
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
    if (widget.animar) {
      Future.delayed(Duration(milliseconds: (widget.index * 40).clamp(0, 320)), () {
        if (mounted) _ctrl.forward();
      });
    } else {
      _ctrl.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant _StaggeredEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Este State se reutiliza entre rebuilds (mismo tipo de widget siempre).
    // Si ya estaba marcado como animado pero por lo que sea el controller no
    // había llegado a completar, lo salta al estado final en vez de dejar la
    // animación a medias o volver a dispararla.
    if (!widget.animar && _ctrl.value != 1) _ctrl.value = 1;
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

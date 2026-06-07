import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:perfuteca/features/busqueda/screens/busqueda_screen.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/features/catalogo/screens/catalogo_screen.dart';
import 'package:perfuteca/features/catalogo/screens/detalle_perfume_screen.dart';
import 'package:perfuteca/features/marcas/screens/marcas_screen.dart';
import 'package:perfuteca/features/notas/screens/notas_screen.dart';
import 'package:perfuteca/features/estadisticas/screens/estadisticas_screen.dart';
import 'package:perfuteca/features/ventas/providers/ventas_provider.dart';
import 'package:perfuteca/features/ventas/screens/ventas_screen.dart';
import 'package:perfuteca/theme/app_theme.dart';

// ── Navigator keys ────────────────────────────────────────────────────────────
final _rootNavigatorKey   = GlobalKey<NavigatorState>(debugLabel: 'root');
final _catalogoNavKey     = GlobalKey<NavigatorState>(debugLabel: 'catalogo');
final _marcasNavKey       = GlobalKey<NavigatorState>(debugLabel: 'marcas');
final _ventasNavKey       = GlobalKey<NavigatorState>(debugLabel: 'ventas');
final _notasNavKey        = GlobalKey<NavigatorState>(debugLabel: 'notas');
final _estadisticasNavKey = GlobalKey<NavigatorState>(debugLabel: 'estadisticas');

// ── Transición fade + slide suave para rutas sobre el root navigator ──────────
Page<T> _fadeSlidePage<T>(GoRouterState state, Widget child) =>
    CustomTransitionPage<T>(
      key:   state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.04),
            end:   Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );

// ── Router ────────────────────────────────────────────────────────────────────
final _router = GoRouter(
  navigatorKey:    _rootNavigatorKey,
  initialLocation: '/catalogo',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _Shell(shell: shell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _catalogoNavKey,
          routes: [
            GoRoute(path: '/catalogo', builder: (_, __) => const CatalogoScreen()),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _marcasNavKey,
          routes: [
            GoRoute(path: '/marcas', builder: (_, __) => const MarcasScreen()),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _ventasNavKey,
          routes: [
            GoRoute(path: '/ventas', builder: (_, __) => const VentasScreen()),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _notasNavKey,
          routes: [
            GoRoute(path: '/notas', builder: (_, __) => const NotasScreen()),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _estadisticasNavKey,
          routes: [
            GoRoute(path: '/estadisticas', builder: (_, __) => const EstadisticasScreen()),
          ],
        ),
      ],
    ),

    // Detalle de perfume — con animación fade+slide
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/catalogo/:id',
      pageBuilder: (_, state) => _fadeSlidePage(
        state,
        DetallePerfumeScreen(idPerfume: state.pathParameters['id']!),
      ),
    ),

    // Búsqueda — con animación fade+slide
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/busqueda',
      pageBuilder: (_, state) => _fadeSlidePage(state, const BusquedaScreen()),
    ),
  ],
);

// ── App ───────────────────────────────────────────────────────────────────────
class PerfutecaApp extends StatelessWidget {
  const PerfutecaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title:                      'Perfuteca',
    theme:                      AppTheme.light,
    routerConfig:               _router,
    debugShowCheckedModeBanner: false,
  );
}

// ── Shell con NavigationBar (sombra superior) ─────────────────────────────────
class _Shell extends ConsumerStatefulWidget {
  const _Shell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  ConsumerState<_Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<_Shell> {
  @override
  void initState() {
    super.initState();
    // Pre-calienta los providers clave al abrir la app, sin esperar a que el
    // usuario toque cada tab. Así la caché (o la red) empieza a trabajar de
    // inmediato en segundo plano.
    Future.microtask(() {
      ref.read(catalogoProvider);
      ref.read(marcasProvider);
      ref.read(perfumesMapProvider);
      ref.read(historialProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.shell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color:      Color(0x1A2C1A0E),
              blurRadius: 16,
              offset:     Offset(0, -3),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex:         widget.shell.currentIndex,
          onDestinationSelected: widget.shell.goBranch,
          destinations: const [
            NavigationDestination(
              icon:         Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label:        'Catálogo',
            ),
            NavigationDestination(
              icon:         Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront_rounded),
              label:        'Marcas',
            ),
            NavigationDestination(
              icon:         Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label:        'Ventas',
            ),
            NavigationDestination(
              icon:         Icon(Icons.local_florist_outlined),
              selectedIcon: Icon(Icons.local_florist_rounded),
              label:        'Notas',
            ),
            NavigationDestination(
              icon:         Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label:        'Estadísticas',
            ),
          ],
        ),
      ),
    );
  }
}

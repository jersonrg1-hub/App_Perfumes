import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:perfuteca/features/busqueda/screens/busqueda_screen.dart';
import 'package:perfuteca/features/catalogo/screens/catalogo_screen.dart';
import 'package:perfuteca/features/catalogo/screens/detalle_perfume_screen.dart';
import 'package:perfuteca/features/marcas/screens/marcas_screen.dart';
import 'package:perfuteca/features/notas/screens/notas_screen.dart';
import 'package:perfuteca/features/ventas/screens/ventas_screen.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_text_styles.dart';
import 'package:perfuteca/theme/app_theme.dart';

// ── Navigator keys — obligatorios para StatefulShellRoute ─────────────────────
final _rootNavigatorKey    = GlobalKey<NavigatorState>(debugLabel: 'root');
final _catalogoNavKey      = GlobalKey<NavigatorState>(debugLabel: 'catalogo');
final _marcasNavKey        = GlobalKey<NavigatorState>(debugLabel: 'marcas');
final _ventasNavKey        = GlobalKey<NavigatorState>(debugLabel: 'ventas');
final _notasNavKey         = GlobalKey<NavigatorState>(debugLabel: 'notas');

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
            GoRoute(
              path:    '/catalogo',
              builder: (_, __) => const CatalogoScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _marcasNavKey,
          routes: [
            GoRoute(
              path:    '/marcas',
              builder: (_, __) => const MarcasScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _ventasNavKey,
          routes: [
            GoRoute(
              path:    '/ventas',
              builder: (_, __) => const VentasScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _notasNavKey,
          routes: [
            GoRoute(
              path:    '/notas',
              builder: (_, __) => const NotasScreen(),
            ),
          ],
        ),
      ],
    ),

    // Detalle de perfume: sobre el root navigator para funcionar desde cualquier pantalla
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path:    '/catalogo/:id',
      builder: (_, state) => DetallePerfumeScreen(
        idPerfume: state.pathParameters['id']!,
      ),
    ),

    // Búsqueda: sobre el root navigator (modal, sin tabs)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path:    '/busqueda',
      builder: (_, __) => const BusquedaScreen(),
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

// ── Shell con NavigationBar inferior ─────────────────────────────────────────
class _Shell extends StatelessWidget {
  const _Shell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex:        shell.currentIndex,
        onDestinationSelected: shell.goBranch,
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
        ],
      ),
    );
  }
}

// ── Pantalla placeholder para tabs futuros ────────────────────────────────────
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title, required this.icon});
  final String  title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.surface,
      title: Text(title),
    ),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.textFaint),
          const SizedBox(height: 16),
          Text(
            'Próximamente',
            style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTextStyles.heading2.copyWith(color: AppColors.primaryDark),
          ),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/features/cotizaciones/screens/nueva_cotizacion_screen.dart';
import 'package:perfuteca/features/ventas/screens/cotizaciones_hoy_screen.dart';
import 'package:perfuteca/features/ventas/screens/pendientes_screen.dart';
import 'package:perfuteca/features/ventas/providers/ventas_provider.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';

class VentasScreen extends ConsumerStatefulWidget {
  const VentasScreen({super.key});

  @override
  ConsumerState<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends ConsumerState<VentasScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  bool _refreshing = false;

  static const _subtitulos = ['Hoy', 'Cotización', 'Pendientes'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    // Repinta el título con el sub-tab activo también cuando el usuario
    // cambia de tab con swipe (ventasTabProvider solo cubre el cambio
    // programático vía animateTo).
    _tab.addListener(() {
      if (!_tab.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    setState(() => _refreshing = true);
    ref.invalidate(pendientesProvider);
    ref.invalidate(cotizacionesHoyProvider);
    var ok = true;
    try {
      final catalogoNotifier = ref.read(catalogoProvider.notifier);
      await Future.wait([
        ref.read(pendientesProvider.future),
        ref.read(cotizacionesHoyProvider.future),
        // refresh() invalida el cache del backend (Sheets → API, hasta 30min
        // TTL) antes de recargar — sin esto, perfumes agregados en Sheets no
        // aparecían en el selector de Paso 2 de cotización hasta que el TTL
        // expirara solo. loadAll() después trae el resto de páginas, para
        // que el buscador de Paso 2 filtre sobre el catálogo completo.
        catalogoNotifier.refresh().then((_) => catalogoNotifier.loadAll()),
      ]);
    } catch (_) {
      // el error específico ya se muestra en cada pantalla vía AsyncError;
      // acá solo evitamos el SnackBar de éxito engañoso.
      ok = false;
    }
    if (!mounted) return;
    setState(() => _refreshing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Actualizado' : 'No se pudo actualizar todo'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(ventasTabProvider, (_, next) => _tab.animateTo(next));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(children: [
          const Icon(Icons.receipt_long_rounded,
              color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text('Ventas · ${_subtitulos[_tab.index]}',
              style: AppTextStyles.heading2.copyWith(fontSize: 18)),
        ]),
        actions: [
          IconButton(
            icon: _refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.textMuted),
                  )
                : const Icon(Icons.refresh_rounded, size: 20),
            color: AppColors.textMuted,
            tooltip: 'Actualizar',
            onPressed: _refreshing ? null : _onRefresh,
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor:           AppColors.primaryDark,
          unselectedLabelColor: AppColors.textMuted,
          indicator: BoxDecoration(
            color:        AppColors.primaryPale,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border:       Border.all(color: AppColors.primaryLight),
          ),
          indicatorSize:    TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          labelStyle: AppTextStyles.button.copyWith(fontSize: 11),
          unselectedLabelStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(
              icon: Icon(Icons.today_rounded, size: 18),
              text: 'Hoy',
              iconMargin: EdgeInsets.only(bottom: 2),
            ),
            Tab(
              icon: Icon(Icons.request_quote_outlined, size: 18),
              text: 'Cotización',
              iconMargin: EdgeInsets.only(bottom: 2),
            ),
            Tab(
              iconMargin: EdgeInsets.only(bottom: 2),
              text: 'Pendientes',
              icon: _PendientesBadge(),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          CotizacionesHoyScreen(),
          NuevaCotizacionScreen(),
          PendientesScreen(),
        ],
      ),
    );
  }
}

/// Badge del contador de pendientes, aislado para no re-renderizar todo
/// el Scaffold/TabBar cuando cambia `pendientesProvider`.
class _PendientesBadge extends ConsumerWidget {
  const _PendientesBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(pendientesProvider.select(
      (a) => (a.valueOrNull ?? const []).map((v) => v.idCompra).toSet().length,
    ));
    return Badge(
      isLabelVisible: count > 0,
      backgroundColor: AppColors.warning,
      label: Text('$count'),
      child: const Icon(Icons.schedule_rounded, size: 18),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
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
          Text('Ventas',
              style: AppTextStyles.heading2.copyWith(fontSize: 18)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            color: AppColors.textMuted,
            tooltip: 'Actualizar',
            onPressed: () {
              ref.invalidate(pendientesProvider);
              ref.invalidate(cotizacionesHoyProvider);
            },
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
          tabs: [
            const Tab(
              icon: Icon(Icons.today_rounded, size: 18),
              text: 'Hoy',
              iconMargin: EdgeInsets.only(bottom: 2),
            ),
            const Tab(
              icon: Icon(Icons.request_quote_outlined, size: 18),
              text: 'Cotización',
              iconMargin: EdgeInsets.only(bottom: 2),
            ),
            const Tab(
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
      label: Text('$count'),
      child: const Icon(Icons.schedule_rounded, size: 18),
    );
  }
}


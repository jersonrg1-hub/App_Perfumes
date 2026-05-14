import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/features/ventas/screens/historial_screen.dart';
import 'package:perfuteca/features/cotizaciones/screens/nueva_cotizacion_screen.dart';
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
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendientesAsync = ref.watch(pendientesProvider);
    final pendienteCount  = pendientesAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.receipt_long_rounded,
                color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Ventas',
              style: AppTextStyles.heading2.copyWith(fontSize: 18),
            ),
          ],
        ),
        actions: [
          // Botón refrescar datos
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            color: AppColors.textMuted,
            tooltip: 'Actualizar',
            onPressed: () {
              ref.invalidate(historialProvider);
              ref.invalidate(pendientesProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primaryDark,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelStyle: AppTextStyles.button.copyWith(fontSize: 13),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            const Tab(
              icon: Icon(Icons.request_quote_outlined, size: 18),
              text: 'Cotización',
              iconMargin: EdgeInsets.only(bottom: 2),
            ),
            const Tab(
              icon: Icon(Icons.history_rounded, size: 18),
              text: 'Historial',
              iconMargin: EdgeInsets.only(bottom: 2),
            ),
            Tab(
              iconMargin: const EdgeInsets.only(bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.schedule_rounded, size: 18),
                  const SizedBox(width: 4),
                  const Text('Pendientes',
                      style: TextStyle(fontSize: 13)),
                  if (pendienteCount > 0) ...[
                    const SizedBox(width: 4),
                    _Badge(count: pendienteCount),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        // Desactivar swipe para evitar conflictos con PageView del wizard
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          NuevaCotizacionScreen(),
          HistorialScreen(),
          PendientesScreen(),
        ],
      ),
    );
  }
}

// ── Badge de conteo ───────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      color: AppColors.warning,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      '$count',
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
  );
}

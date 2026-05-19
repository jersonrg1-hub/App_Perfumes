import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/features/estadisticas/providers/estadisticas_provider.dart';
import 'package:perfuteca/features/estadisticas/screens/analisis_tab.dart';
import 'package:perfuteca/features/estadisticas/screens/clientes_tab.dart';
import 'package:perfuteca/features/estadisticas/screens/resumen_tab.dart';
import 'package:perfuteca/features/estadisticas/screens/ventas_tab.dart';
import 'package:perfuteca/features/ventas/providers/ventas_provider.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';

class EstadisticasScreen extends ConsumerStatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  ConsumerState<EstadisticasScreen> createState() =>
      _EstadisticasScreenState();
}

class _EstadisticasScreenState extends ConsumerState<EstadisticasScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(children: [
          const Icon(Icons.bar_chart_rounded,
              color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text('Estadísticas',
              style: AppTextStyles.heading2.copyWith(fontSize: 18)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            color: AppColors.textMuted,
            tooltip: 'Recargar',
            onPressed: () {
              ref.invalidate(historialProvider);
              ref.invalidate(pendientesProvider);
              ref.invalidate(ventasParaStatsProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor:          AppColors.primaryDark,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor:      AppColors.primary,
          indicatorWeight:     2.5,
          labelStyle: AppTextStyles.button.copyWith(fontSize: 11),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard_rounded, size: 18),
              text: 'Resumen',
              iconMargin: EdgeInsets.only(bottom: 2),
            ),
            Tab(
              icon: Icon(Icons.receipt_long_rounded, size: 18),
              text: 'Ventas',
              iconMargin: EdgeInsets.only(bottom: 2),
            ),
            Tab(
              icon: Icon(Icons.group_rounded, size: 18),
              text: 'Clientes',
              iconMargin: EdgeInsets.only(bottom: 2),
            ),
            Tab(
              icon: Icon(Icons.inventory_2_rounded, size: 18),
              text: 'Stock',
              iconMargin: EdgeInsets.only(bottom: 2),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Aviso si la API devolvió exactamente 500 registros — puede haber más.
          ref.watch(ventasParaStatsProvider).maybeWhen(
            data: (ventas) => ventas.length >= 500
                ? Material(
                    color: const Color(0xFFFFF3CD),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 16, color: Color(0xFF856404)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Estadísticas basadas en las últimas 500 ventas. '
                            'Los datos históricos pueden estar incompletos.',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF856404),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                ResumenTab(),
                VentasTab(),
                ClientesTab(),
                AnalisisTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

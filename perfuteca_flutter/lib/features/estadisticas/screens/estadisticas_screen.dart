import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/features/estadisticas/providers/estadisticas_provider.dart';
import 'package:perfuteca/features/estadisticas/screens/analisis_tab.dart';
import 'package:perfuteca/features/estadisticas/screens/clientes_tab.dart';
import 'package:perfuteca/features/estadisticas/screens/cotizaciones_tab.dart';
import 'package:perfuteca/features/estadisticas/screens/historico_tab.dart';
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
  bool _refrescando = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 6, vsync: this);
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
            icon: _refrescando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, size: 20),
            color: AppColors.textMuted,
            tooltip: 'Recargar',
            onPressed: _refrescando
                ? null
                : () async {
                    setState(() => _refrescando = true);
                    ref.invalidate(resumenBackendProvider);
                    ref.invalidate(historialProvider);
                    ref.invalidate(pendientesProvider);
                    ref.invalidate(ventasParaStatsProvider);
                    ref.invalidate(historialGlobalProvider);
                    ref.invalidate(clientesStatsProvider);
                    ref.invalidate(cotizaciones14dProvider);
                    try {
                      await ref.read(ventasParaStatsProvider.future);
                    } catch (_) {}
                    if (mounted) setState(() => _refrescando = false);
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
              icon: Icon(Icons.history_rounded, size: 18),
              text: 'Histórico',
              iconMargin: EdgeInsets.only(bottom: 2),
            ),
            Tab(
              icon: Icon(Icons.inventory_2_rounded, size: 18),
              text: 'Stock',
              iconMargin: EdgeInsets.only(bottom: 2),
            ),
            Tab(
              icon: Icon(Icons.request_quote_rounded, size: 18),
              text: 'Cotiz.',
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
                    color: AppColors.goldLight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 16, color: AppColors.gold),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Estadísticas basadas en las últimas 500 ventas. '
                            'Los datos históricos pueden estar incompletos.',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.gold,
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
                HistoricoTab(),
                AnalisisTab(),
                CotizacionesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

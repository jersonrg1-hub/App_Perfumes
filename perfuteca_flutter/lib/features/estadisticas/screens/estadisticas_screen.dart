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
  int  _masTabKey   = 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() {
      if (_tab.index == 2 && _tab.previousIndex != 2) {
        setState(() => _masTabKey++);
      }
    });
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
              icon: Icon(Icons.history_rounded, size: 18),
              text: 'Histórico',
              iconMargin: EdgeInsets.only(bottom: 2),
            ),
            Tab(
              icon: Icon(Icons.more_horiz_rounded, size: 18),
              text: 'Más',
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
              children: [
                const ResumenTab(),
                const HistoricoTab(),
                _MasTab(key: ValueKey(_masTabKey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab "Más" — menú de navegación interna ─────────────────────────────────────

class _MasTab extends ConsumerStatefulWidget {
  // ignore: unused_element
  const _MasTab({super.key});

  @override
  ConsumerState<_MasTab> createState() => _MasTabState();
}

class _MasTabState extends ConsumerState<_MasTab> {
  String? _seccion;

  String _titulo(String seccion) => switch (seccion) {
    'ventas'       => 'Ventas',
    'clientes'     => 'Clientes',
    'stock'        => 'Stock',
    'cotizaciones' => 'Cotizaciones',
    _              => seccion,
  };

  Widget _pantalla(String seccion) => switch (seccion) {
    'ventas'       => const VentasTab(),
    'clientes'     => const ClientesTab(),
    'stock'        => const AnalisisTab(),
    'cotizaciones' => const CotizacionesTab(),
    _              => const SizedBox.shrink(),
  };

  @override
  Widget build(BuildContext context) {
    if (_seccion != null) {
      return Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _seccion = null),
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppColors.textPrimary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _titulo(_seccion!),
                  style: AppTextStyles.heading2.copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _pantalla(_seccion!)),
        ],
      );
    }

    return _MenuMas(onSelect: (s) => setState(() => _seccion = s));
  }
}

class _MenuMas extends StatelessWidget {
  const _MenuMas({required this.onSelect});
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    const items = [
      (icon: Icons.receipt_long_rounded,  label: 'Ventas',       key: 'ventas'),
      (icon: Icons.group_rounded,         label: 'Clientes',     key: 'clientes'),
      (icon: Icons.inventory_2_rounded,   label: 'Stock',        key: 'stock'),
      (icon: Icons.request_quote_rounded, label: 'Cotizaciones', key: 'cotizaciones'),
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 56),
      itemBuilder: (_, i) => ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryPale,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(items[i].icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          items[i].label,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: const Icon(
            Icons.chevron_right_rounded, color: AppColors.textMuted),
        onTap: () => onSelect(items[i].key),
      ),
    );
  }
}

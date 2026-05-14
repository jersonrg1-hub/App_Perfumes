import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/features/ventas/providers/ventas_provider.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/models/venta.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';

// ── Modelo de orden agrupada ──────────────────────────────────────────────────

class _Orden {
  _Orden({
    required this.idCompra,
    required this.items,
  });

  final String            idCompra;
  final List<VentaResponse> items;

  String? get comprador  => items.first.comprador;
  String? get celular    => items.first.celular;
  String? get direccion  => items.first.direccion;
  String? get tipoEnvio  => items.first.tipoEnvio;
  String? get metodoPago => items.first.metodoPago;
  String? get fecha      => items.first.fecha;
  String? get estado     => items.first.estado;

  double get total => items.fold(0.0, (s, i) => s + (i.precioCobrado ?? 0));
  List<int> get filas => items.map((i) => i.filaSheet).toList();
}

List<_Orden> _agrupar(List<VentaResponse> ventas) {
  final map = <String, List<VentaResponse>>{};
  for (final v in ventas) {
    if (v.idCompra.isEmpty) continue;
    (map[v.idCompra] ??= []).add(v);
  }
  return map.entries
      .map((e) => _Orden(idCompra: e.key, items: e.value))
      .toList();
}

// ── Pantalla ──────────────────────────────────────────────────────────────────

class PendientesScreen extends ConsumerWidget {
  const PendientesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async      = ref.watch(pendientesProvider);
    final perfumesMap = ref.watch(perfumesMapProvider).valueOrNull ?? {};

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
        mensaje: e.toString(),
        onRetry: () => ref.invalidate(pendientesProvider),
      ),
      data: (ventas) {
        final onRefresh = () => ref.refresh(pendientesProvider.future);
        final ordenes = _agrupar(ventas);
        return ordenes.isEmpty
            ? RefreshIndicator(onRefresh: onRefresh, child: const _EmptyView())
            : _ListaOrdenes(ordenes: ordenes, perfumesMap: perfumesMap, onRefresh: onRefresh);
      },
    );
  }
}

// ── Lista de órdenes ──────────────────────────────────────────────────────────

class _ListaOrdenes extends StatelessWidget {
  const _ListaOrdenes({
    required this.ordenes,
    required this.perfumesMap,
    required this.onRefresh,
  });
  final List<_Orden>            ordenes;
  final Map<String, Perfume>    perfumesMap;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final totalPendiente = ordenes.fold(0.0, (s, o) => s + o.total);

    return Column(
      children: [
        _ResumenBanner(cantidad: ordenes.length, total: totalPendiente),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              itemCount: ordenes.length,
              itemBuilder: (_, i) => _OrdenCard(orden: ordenes[i], perfumesMap: perfumesMap),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Banner resumen ────────────────────────────────────────────────────────────

class _ResumenBanner extends StatelessWidget {
  const _ResumenBanner({required this.cantidad, required this.total});
  final int    cantidad;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border:
            Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded,
              size: 20, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$cantidad orden${cantidad != 1 ? 'es' : ''} pendiente${cantidad != 1 ? 's' : ''}',
              style: AppTextStyles.body.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            'S/ ${total.toStringAsFixed(2)}',
            style: AppTextStyles.price
                .copyWith(fontSize: 16, color: AppColors.warning),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de orden agrupada ─────────────────────────────────────────────────

class _OrdenCard extends ConsumerStatefulWidget {
  const _OrdenCard({required this.orden, required this.perfumesMap});
  final _Orden               orden;
  final Map<String, Perfume> perfumesMap;

  @override
  ConsumerState<_OrdenCard> createState() => _OrdenCardState();
}

class _OrdenCardState extends ConsumerState<_OrdenCard> {
  bool _actualizando = false;

  Future<void> _cambiarEstado(String nuevoEstado) async {
    setState(() => _actualizando = true);
    final ok = await ref.read(estadoVentaProvider.notifier).actualizar(
          idVenta:     widget.orden.idCompra,
          nuevoEstado: nuevoEstado,
          filasSheet:  widget.orden.filas,
        );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar el estado'),
          backgroundColor: AppColors.error,
        ),
      );
    }
    if (mounted) setState(() => _actualizando = false);
  }

  Future<void> _confirmarAnular() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Anular orden'),
        content: Text(
          '¿Anular la orden #${widget.orden.idCompra} de ${widget.orden.comprador ?? '—'}?\n'
          'Se anularán los ${widget.orden.items.length} ítems.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Anular'),
          ),
        ],
      ),
    );
    if (ok == true) _cambiarEstado('Anulado');
  }

  @override
  Widget build(BuildContext context) {
    final orden = widget.orden;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primaryLight),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 4,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryPale,
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusMd)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#${orden.idCompra}',
                            style: AppTextStyles.priceLabel.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${orden.items.length} ítem${orden.items.length != 1 ? 's' : ''}',
                              style: AppTextStyles.priceLabel.copyWith(
                                  color: AppColors.primaryDark),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        orden.comprador ?? '—',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (orden.celular != null)
                        Text(orden.celular!,
                            style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                Text(
                  'S/ ${orden.total.toStringAsFixed(2)}',
                  style: AppTextStyles.price.copyWith(
                    fontSize: 20,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),

          // ── Lista de ítems ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
            child: Column(
              children: orden.items.map((item) {
                final normId = item.idPerfume != null
                    ? (double.tryParse(item.idPerfume!)?.toInt().toString()
                        ?? item.idPerfume!)
                    : null;
                final perfume = normId != null
                    ? widget.perfumesMap[normId]
                    : null;
                final nombre = perfume != null
                    ? '${perfume.nombre} (${perfume.marca})'
                    : (item.idPerfume != null
                        ? 'Perfume #${item.idPerfume}'
                        : '—');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '$nombre  ·  ${item.mlVendido ?? '?'} ml',
                          style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary),
                        ),
                      ),
                      Text(
                        'S/ ${(item.precioCobrado ?? 0).toStringAsFixed(2)}',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Divider(height: AppSpacing.md),
          ),

          // ── Info logística ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.local_shipping_outlined,
                      label: orden.tipoEnvio ?? '—',
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _InfoChip(
                      icon: Icons.payment_outlined,
                      label: orden.metodoPago ?? '—',
                      color: AppColors.goldLight,
                      textColor: AppColors.gold,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        orden.direccion ?? '—',
                        style: AppTextStyles.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Acciones ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _actualizando
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _confirmarAnular,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm),
                        ),
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Anular'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _cambiarEstado('Entregado'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm),
                          ),
                          icon: const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 16),
                          label: const Text('Marcar entregado'),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Chip de info ──────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.color = AppColors.primaryPale,
    this.textColor = AppColors.primaryDark,
  });
  final IconData icon;
  final String   label;
  final Color    color;
  final Color    textColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.priceLabel
                  .copyWith(color: textColor, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
}

// ── Estados vacío / error ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    size: 64, color: AppColors.success),
                const SizedBox(height: 12),
                Text(
                  '¡Todo entregado!',
                  style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text('No hay órdenes pendientes',
                    style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.mensaje, required this.onRetry});
  final String       mensaje;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 48, color: AppColors.textFaint),
              const SizedBox(height: 12),
              Text('Error al cargar pendientes',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(mensaje,
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/features/ventas/providers/ventas_provider.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/models/venta.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';

// ── Modelo de orden agrupada ──────────────────────────────────────────────────

class _Orden {
  _Orden({required this.idCompra, required this.items});

  final String              idCompra;
  final List<VentaResponse> items;

  String? get comprador  => items.first.comprador;
  String? get metodoPago => items.first.metodoPago;
  String? get tipoEnvio  => items.first.tipoEnvio;
  String? get fecha      => items.first.fecha;
  String? get estado     => items.first.estado;

  double get total => items.fold(0.0, (s, i) => s + (i.precioCobrado ?? 0));
}

// Agrupa lista de ventas por id_compra preservando el orden original
Map<String, List<VentaResponse>> _agruparPorOrden(List<VentaResponse> ventas) {
  final map = <String, List<VentaResponse>>{};
  for (final v in ventas) {
    if (v.idCompra.isEmpty) continue;
    (map[v.idCompra] ??= []).add(v);
  }
  return map;
}

// Agrupa órdenes por fecha
Map<String, List<_Orden>> _agruparPorFecha(List<VentaResponse> ventas) {
  final porOrden = _agruparPorOrden(ventas);
  final ordenes  = porOrden.entries
      .map((e) => _Orden(idCompra: e.key, items: e.value))
      .toList();

  final porFecha = <String, List<_Orden>>{};
  for (final o in ordenes) {
    final key = o.fecha ?? 'Sin fecha';
    (porFecha[key] ??= []).add(o);
  }
  return porFecha;
}

// ── Pantalla ──────────────────────────────────────────────────────────────────

class HistorialScreen extends ConsumerWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async       = ref.watch(historialProvider);
    final perfumesMap = ref.watch(perfumesMapProvider).valueOrNull ?? {};

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
        mensaje: e.toString(),
        onRetry: () => ref.invalidate(historialProvider),
      ),
      data: (ventas) {
        final onRefresh = () => ref.refresh(historialProvider.future);
        if (ventas.isEmpty) return RefreshIndicator(onRefresh: onRefresh, child: const _EmptyView());
        final porFecha = _agruparPorFecha(ventas);
        final fechas   = porFecha.keys.toList()..sort((a, b) => b.compareTo(a));
        return _ListaHistorial(
          porFecha: porFecha,
          fechas: fechas,
          perfumesMap: perfumesMap,
          onRefresh: onRefresh,
        );
      },
    );
  }
}

// ── Lista agrupada ────────────────────────────────────────────────────────────

class _ListaHistorial extends StatelessWidget {
  const _ListaHistorial({
    required this.porFecha,
    required this.fechas,
    required this.perfumesMap,
    required this.onRefresh,
  });
  final Map<String, List<_Orden>>  porFecha;
  final List<String>               fechas;
  final Map<String, Perfume>       perfumesMap;
  final Future<void> Function()    onRefresh;

  String _formatFecha(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      itemCount: fechas.length,
      itemBuilder: (_, i) {
        final fecha   = fechas[i];
        final ordenes = porFecha[fecha]!;
        final totalDia = ordenes.fold(0.0, (s, o) => s + o.total);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FechaHeader(
              label:    _formatFecha(fecha),
              cantidad: ordenes.length,
              total:    totalDia,
            ),
            ...ordenes.map((o) => _OrdenCard(orden: o, perfumesMap: perfumesMap)),
            const SizedBox(height: AppSpacing.sm),
          ],
        );
      },
      ),
    );
  }
}

// ── Encabezado de fecha ───────────────────────────────────────────────────────

class _FechaHeader extends StatelessWidget {
  const _FechaHeader({
    required this.label,
    required this.cantidad,
    required this.total,
  });
  final String label;
  final int    cantidad;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 3, height: 18,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryPale,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              '$cantidad orden${cantidad != 1 ? 'es' : ''}  ·  S/ ${total.toStringAsFixed(2)}',
              style: AppTextStyles.priceLabel.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta expandible de orden ───────────────────────────────────────────────

class _OrdenCard extends StatefulWidget {
  const _OrdenCard({required this.orden, required this.perfumesMap});
  final _Orden               orden;
  final Map<String, Perfume> perfumesMap;

  @override
  State<_OrdenCard> createState() => _OrdenCardState();
}

class _OrdenCardState extends State<_OrdenCard> {
  bool _expandido = false;

  Color _estadoColor(String? estado) => switch (estado?.toLowerCase()) {
    'entregado' => AppColors.success,
    'anulado'   => AppColors.error,
    _           => AppColors.warning,
  };

  IconData _estadoIcon(String? estado) => switch (estado?.toLowerCase()) {
    'entregado' => Icons.check_circle_rounded,
    'anulado'   => Icons.cancel_rounded,
    _           => Icons.schedule_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final orden  = widget.orden;
    final color  = _estadoColor(orden.estado);
    final icon   = _estadoIcon(orden.estado);

    return GestureDetector(
      onTap: () => setState(() => _expandido = !_expandido),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: _expandido ? AppColors.primary : AppColors.primaryLight,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Fila principal ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: AppSpacing.sm),

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
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                orden.estado ?? 'pendiente',
                                style: AppTextStyles.priceLabel.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          orden.comprador ?? '—',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${orden.items.length} ítem${orden.items.length != 1 ? 's' : ''}',
                              style: AppTextStyles.bodySmall,
                            ),
                            if (orden.metodoPago != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.goldLight,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  orden.metodoPago!,
                                  style: AppTextStyles.priceLabel.copyWith(
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                            if (orden.tipoEnvio != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                orden.tipoEnvio!,
                                style: AppTextStyles.priceLabel,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'S/ ${orden.total.toStringAsFixed(2)}',
                        style: AppTextStyles.price.copyWith(
                          fontSize: 16,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        _expandido
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Detalle expandible ────────────────────────────────────
            if (_expandido)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryPale,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: AppSpacing.md),
                    ...orden.items.map((item) {
                      final normId = item.idPerfume != null
                          ? (double.tryParse(item.idPerfume!)
                                  ?.toInt()
                                  .toString() ??
                              item.idPerfume!)
                          : null;
                      final perfume = normId != null
                          ? widget.perfumesMap[normId]
                          : null;
                      final nombre = perfume != null
                          ? perfume.nombre
                          : (item.idPerfume != null
                              ? 'Perfume #${item.idPerfume}'
                              : '—');
                      final marca = perfume?.marca;

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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nombre,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (marca != null)
                                    Text(
                                      '$marca  ·  ${item.mlVendido ?? '?'} ml',
                                      style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textMuted,
                                          fontSize: 10),
                                    )
                                  else
                                    Text(
                                      '${item.mlVendido ?? '?'} ml',
                                      style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textMuted),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              'S/ ${(item.precioCobrado ?? 0).toStringAsFixed(2)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
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
                const Icon(Icons.receipt_long_outlined,
                    size: 64, color: AppColors.textFaint),
                const SizedBox(height: 12),
                Text('Sin ventas registradas',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textMuted)),
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
              Text('Error al cargar historial',
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/core/utils/whatsapp_launcher.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart'
    show perfumesMapProvider;
import 'package:perfuteca/features/estadisticas/providers/estadisticas_provider.dart'
    show nowPeru;
import 'package:perfuteca/features/ventas/providers/ventas_provider.dart';
import 'package:perfuteca/models/orden_agrupada.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/models/venta.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';
import 'package:perfuteca/widgets/common/staggered_list_item.dart';
import 'package:shimmer/shimmer.dart';

// IDs de órdenes removidas optimísticamente antes de que el API confirme
final _pendientesRemovidosProvider =
    StateProvider<Set<String>>((ref) => const {});

List<OrdenAgrupada> _agrupar(List<VentaResponse> ventas) {
  return agruparOrdenes(ventas)
    ..sort((a, b) => (a.fecha ?? '').compareTo(b.fecha ?? ''));
}

// ── Pantalla ──────────────────────────────────────────────────────────────────

class PendientesScreen extends ConsumerStatefulWidget {
  const PendientesScreen({super.key});

  @override
  ConsumerState<PendientesScreen> createState() => _PendientesScreenState();
}

class _PendientesScreenState extends ConsumerState<PendientesScreen> {
  // Órdenes que ya reprodujeron su animación de entrada — persiste mientras
  // la pantalla vive, así una tarjeta no vuelve a animarse solo porque su
  // índice cambió al resolverse otras órdenes por encima de ella.
  final Set<String> _yaAnimadas = {};

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(pendientesProvider);
    final perfumesMap = ref.watch(perfumesMapProvider).valueOrNull ?? {};
    final removidos = ref.watch(_pendientesRemovidosProvider);

    return async.when(
      loading: () => const _PendientesShimmer(),
      error: (e, _) => _ErrorView(
        mensaje: e.toString(),
        onRetry: () {
          ref.read(_pendientesRemovidosProvider.notifier).state = const {};
          ref.invalidate(pendientesProvider);
        },
      ),
      data: (ventas) {
        Future<void> onRefresh() async {
          ref.read(_pendientesRemovidosProvider.notifier).state = const {};
          ref.invalidate(pendientesProvider);
          await ref.read(pendientesProvider.future);
        }

        final ordenes = _agrupar(ventas)
            .where((o) => !removidos.contains(o.idCompra))
            .toList();

        if (ordenes.isEmpty) {
          return RefreshIndicator(
              onRefresh: onRefresh, child: const _EmptyView());
        }

        return _ListaOrdenes(
          ordenes: ordenes,
          perfumesMap: perfumesMap,
          onRefresh: onRefresh,
          yaAnimadas: _yaAnimadas,
        );
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
    required this.yaAnimadas,
  });
  final List<OrdenAgrupada> ordenes;
  final Map<String, Perfume> perfumesMap;
  final Future<void> Function() onRefresh;
  final Set<String> yaAnimadas;

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
              itemBuilder: (_, i) {
                final id = ordenes[i].idCompra;
                return StaggeredListItem(
                  key: ValueKey(id),
                  id: id,
                  index: i,
                  yaAnimadas: yaAnimadas,
                  child: OrdenAgrupadaCard(
                    orden: ordenes[i],
                    perfumesMap: perfumesMap,
                  ),
                );
              },
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
  final int cantidad;
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
        color: AppColors.warningSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
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

class OrdenAgrupadaCard extends ConsumerStatefulWidget {
  const OrdenAgrupadaCard({
    required this.orden,
    required this.perfumesMap,
  });
  final OrdenAgrupada orden;
  final Map<String, Perfume> perfumesMap;

  @override
  ConsumerState<OrdenAgrupadaCard> createState() => OrdenAgrupadaCardState();
}

class OrdenAgrupadaCardState extends ConsumerState<OrdenAgrupadaCard> {
  Future<void> _cambiarEstado(String nuevoEstado) async {
    // Optimista: ocultar la tarjeta de inmediato
    ref
        .read(_pendientesRemovidosProvider.notifier)
        .update((s) => {...s, widget.orden.idCompra});

    final ok = await ref.read(estadoVentaProvider.notifier).actualizar(
          idVenta: widget.orden.idCompra,
          nuevoEstado: nuevoEstado,
          filasSheet: widget.orden.filas,
        );

    if (!ok) {
      // Restaurar si el API falló. actualizar() solo invalida
      // pendientesProvider cuando SÍ tiene éxito — si el fallo fue por
      // conflicto (ej. otro dispositivo ya anuló/entregó esta misma orden,
      // backend responde 409/500), la lista en caché sigue mostrando el
      // estado viejo. Sin invalidar acá, restaurar la tarjeta la revive con
      // datos obsoletos en vez de reflejar la verdad del servidor.
      ref
          .read(_pendientesRemovidosProvider.notifier)
          .update((s) => {...s}..remove(widget.orden.idCompra));
      ref.invalidate(pendientesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar el estado'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _enviarComunidad() async {
    final orden = widget.orden;
    const sep = '────────────────────';

    final itemsLineas = orden.itemsConNormId.asMap().entries.map((entry) {
      final idx = entry.key + 1;
      final item = entry.value.item;
      final perfume = perfumeDeItem(entry.value, widget.perfumesMap);
      final nombre = perfume != null
          ? '${perfume.marca} — ${perfume.nombre}'
          : nombreFallbackItem(item);
      return '  *$idx.* *$nombre* ${item.mlVendido ?? '?'}ml — S/ ${(item.precioCobrado ?? 0).toStringAsFixed(2)}';
    }).join('\n');

    final dirLinea = (orden.direccion?.trim().isNotEmpty == true)
        ? '\n📍 *Dirección:* ${orden.direccion}'
        : '';
    final distLinea = (orden.distrito?.trim().isNotEmpty == true)
        ? '\n🗺️ *Distrito:* ${orden.distrito}'
        : '';

    final msg = '📦 *Perfuteca — Pedido ${orden.idCompra}*\n$sep\n'
        '👤 *Cliente:* ${orden.comprador ?? '—'}\n'
        '📱 *Celular:* ${orden.celular ?? '—'}\n'
        '🚚 *Envío:* ${orden.tipoEnvio ?? '—'}$dirLinea$distLinea\n'
        '$sep\n'
        '🌸 *Perfumes:*\n$itemsLineas\n'
        '$sep\n'
        '💰 *Total: S/ ${orden.total.toStringAsFixed(2)}*\n'
        '💳 *Pago:* ${orden.metodoPago ?? '—'}';
    await abrirWhatsAppBusiness(mensaje: msg);
  }

  Future<void> _confirmarEntregado() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        backgroundColor: AppColors.surface,
        title: const Text('Confirmar entrega'),
        content: Text(
          '¿Marcar como entregada la orden #${widget.orden.idCompra} '
          'de ${widget.orden.comprador ?? '—'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (ok == true) _cambiarEstado('Entregado');
  }

  Future<void> _confirmarAnular() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        backgroundColor: AppColors.surface,
        title: const Text('Anular orden'),
        content: Text(
          '¿Anular la orden #${widget.orden.idCompra} de ${widget.orden.comprador ?? '—'}?\n'
          'Se anularán los ${widget.orden.items.length} ítems.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Anular'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (ok == true) _cambiarEstado('Anulado');
  }

  @override
  Widget build(BuildContext context) {
    final orden = widget.orden;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
          // ── Header ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: const BoxDecoration(
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
                              style: AppTextStyles.priceLabel
                                  .copyWith(color: AppColors.primaryDark),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
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
                        Text(orden.celular!, style: AppTextStyles.bodySmall),
                      if (orden.fecha != null) ...[
                        const SizedBox(height: 3),
                        _FechaAgeBadge(fecha: orden.fecha!),
                      ],
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

          // ── Lista de ítems ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
            child: Column(
              children: orden.itemsConNormId.map((entry) {
                final item = entry.item;
                final perfume = perfumeDeItem(entry, widget.perfumesMap);
                final nombre = perfume != null
                    ? '${perfume.nombre} (${perfume.marca})'
                    : nombreFallbackItem(item);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '$nombre  ·  ${item.mlVendido ?? '?'} ml',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.textSecondary),
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

          // ── Info logística ────────────────────────────────
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
                const SizedBox(height: AppSpacing.xs + 2),
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
                if (orden.distrito?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(Icons.map_outlined,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          orden.distrito!,
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Acciones ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _enviarComunidad,
                    icon: const Icon(Icons.groups_rounded, size: 16),
                    label: const Text('Enviar pedido a comunidad'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.whatsappDark,
                      side: const BorderSide(color: AppColors.whatsappDark),
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _confirmarAnular,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: AppSpacing.md),
                      ),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Anular'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _confirmarEntregado,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md),
                        ),
                        icon: const Icon(Icons.check_circle_outline_rounded,
                            size: 16),
                        label: const Text('Marcar entregado'),
                      ),
                    ),
                  ],
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
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.priceLabel.copyWith(
                  color: textColor, fontWeight: FontWeight.w700, fontSize: 11),
            ),
          ],
        ),
      );
}

// ── Badge de antigüedad de orden ─────────────────────────────────────────────

class _FechaAgeBadge extends StatelessWidget {
  const _FechaAgeBadge({required this.fecha});
  final String fecha;

  @override
  Widget build(BuildContext context) {
    try {
      final d = DateTime.parse(fecha);
      final days =
          nowPeru().difference(DateTime(d.year, d.month, d.day)).inDays;

      final Color color;
      final String label;
      if (days == 0) {
        color = AppColors.stockOk;
        label = 'Hoy';
      } else if (days == 1) {
        color = AppColors.stockOk;
        label = 'Ayer';
      } else if (days <= 3) {
        color = AppColors.warning;
        label = 'Hace $days días';
      } else {
        color = AppColors.stockCritical;
        label = 'Hace $days días';
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 11, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style:
                AppTextStyles.notasLabel.copyWith(color: color, fontSize: 11),
          ),
        ],
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}

// ── Estados vacío / error ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 64, color: AppColors.success),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '¡Todo entregado!',
                    style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text('No hay órdenes pendientes',
                      style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ),
        ],
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.mensaje, required this.onRetry});
  final String mensaje;
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
              const SizedBox(height: AppSpacing.md),
              Text('Error al cargar pendientes',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                  'No se pudo conectar. Verifica tu conexión e intenta de nuevo.',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
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

// ── Shimmer de carga ──────────────────────────────────────────────────────────

class _PendientesShimmer extends StatelessWidget {
  const _PendientesShimmer();

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: AppColors.primaryLight,
        highlightColor: AppColors.primaryPale,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          itemCount: 4,
          itemBuilder: (_, __) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        ),
      );
}

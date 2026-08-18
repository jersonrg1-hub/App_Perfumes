import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart'
    show perfumesMapProvider, normalizeId;
import 'package:perfuteca/features/estadisticas/providers/estadisticas_provider.dart'
    show nowPeru;
import 'package:perfuteca/features/ventas/providers/ventas_provider.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/models/venta.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';

// ── Modelo de orden agrupada ──────────────────────────────────────────────────

class _Orden {
  _Orden({required this.idCompra, required this.items})
      : itemsConNormId = items
            .map((i) => (
                  item: i,
                  normId: i.idPerfume != null ? normalizeId(i.idPerfume!) : null,
                ))
            .toList();

  final String              idCompra;
  final List<VentaResponse> items;
  // Normaliza el id de perfume una sola vez al agrupar — evita re-parsear en
  // cada rebuild de _OrdenCard (ej: al expandir/colapsar).
  final List<({VentaResponse item, String? normId})> itemsConNormId;

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

enum _FiltroFecha { todo, hoy, semana, mes }

class HistorialScreen extends ConsumerStatefulWidget {
  const HistorialScreen({super.key});

  @override
  ConsumerState<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends ConsumerState<HistorialScreen> {
  _FiltroFecha _filtro = _FiltroFecha.todo;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      ref.read(historialProvider.notifier).loadMore();
    }
  }

  List<VentaResponse> _aplicarFiltro(List<VentaResponse> ventas) {
    if (_filtro == _FiltroFecha.todo) return ventas;
    final now = nowPeru();
    final hoy = DateTime(now.year, now.month, now.day);
    return ventas.where((v) {
      if (v.fecha == null) return false;
      try {
        final d     = DateTime.parse(v.fecha!);
        final fecha = DateTime(d.year, d.month, d.day);
        return switch (_filtro) {
          _FiltroFecha.hoy    => fecha == hoy,
          _FiltroFecha.semana => !fecha.isBefore(
              hoy.subtract(Duration(days: hoy.weekday - 1))),
          _FiltroFecha.mes    => d.year == now.year && d.month == now.month,
          _FiltroFecha.todo   => true,
        };
      } catch (_) {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state       = ref.watch(historialProvider);
    final perfumesMap = ref.watch(perfumesMapProvider).valueOrNull ?? {};

    const opciones = [
      (_FiltroFecha.todo,   'Todo'),
      (_FiltroFecha.hoy,    'Hoy'),
      (_FiltroFecha.semana, 'Esta semana'),
      (_FiltroFecha.mes,    'Este mes'),
    ];

    return Column(
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: opciones.map((entry) {
              final (filtro, label) = entry;
              final sel = filtro == _filtro;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _filtro = filtro),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primaryDark : AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                      border: Border.all(
                        color: sel
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                      ),
                    ),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color:      sel ? Colors.white : AppColors.textMuted,
                          fontSize:   12,
                          fontWeight: FontWeight.w600,
                        ),
                        child: Text(label),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: _buildBody(state, perfumesMap),
        ),
      ],
    );
  }

  Widget _buildBody(
    HistorialState state,
    Map<String, Perfume> perfumesMap,
  ) {
    if (state.isLoading) return const _HistorialSkeleton();

    if (state.error != null && state.ventas.isEmpty) {
      return _ErrorView(
        mensaje: state.error.toString(),
        onRetry: () => ref.read(historialProvider.notifier).refresh(),
      );
    }

    final filtradas = _aplicarFiltro(state.ventas);

    Future<void> onRefresh() async {
      ref.invalidate(perfumesMapProvider);
      await ref.read(historialProvider.notifier).refresh();
    }

    if (filtradas.isEmpty) {
      return state.ventas.isEmpty
          ? RefreshIndicator(
              onRefresh: onRefresh,
              child: _EmptyView(onRefresh: onRefresh),
            )
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off_rounded,
                      size: 48, color: AppColors.textFaint),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Sin ventas en este período',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            );
    }

    final porFecha = _agruparPorFecha(filtradas);
    final fechas   = porFecha.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    return _ListaHistorial(
      scrollController: _scroll,
      porFecha:         porFecha,
      fechas:           fechas,
      perfumesMap:      perfumesMap,
      onRefresh:        onRefresh,
      isLoadingMore:    state.isLoadingMore,
      hasMore:          state.hasMore,
    );
  }
}

// ── Lista agrupada ────────────────────────────────────────────────────────────

class _ListaHistorial extends StatelessWidget {
  const _ListaHistorial({
    required this.scrollController,
    required this.porFecha,
    required this.fechas,
    required this.perfumesMap,
    required this.onRefresh,
    required this.isLoadingMore,
    required this.hasMore,
  });
  final ScrollController           scrollController;
  final Map<String, List<_Orden>>  porFecha;
  final List<String>               fechas;
  final Map<String, Perfume>       perfumesMap;
  final Future<void> Function()    onRefresh;
  final bool                       isLoadingMore;
  final bool                       hasMore;

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
        controller: scrollController,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        itemCount: fechas.length + (hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == fechas.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: isLoadingMore
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }
          final fecha    = fechas[i];
          final ordenes  = porFecha[fecha]!;
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

    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _expandido = !_expandido);
        },
        splashColor: AppColors.primaryPale,
        highlightColor: AppColors.primaryPale.withValues(alpha: 0.4),
        child: Column(
          children: [
            // ── Fila principal ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
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
                      AnimatedRotation(
                        turns: _expandido ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 18, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Detalle expandible ────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _expandido ? Container(
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
                    ...orden.itemsConNormId.map((entry) {
                      final item   = entry.item;
                      final normId = entry.normId;
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
              ) : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Estados vacío / error ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 64, color: AppColors.textFaint),
            const SizedBox(height: AppSpacing.lg),
            Text('Sin ventas registradas',
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: AppSpacing.xs + 2),
            Text('Registra ventas desde la pestaña Nueva Venta',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textFaint)),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Actualizar'),
              onPressed: onRefresh,
            ),
          ],
        ),
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

// ── Skeleton de carga ─────────────────────────────────────────────────────────

class _HistorialSkeleton extends StatelessWidget {
  const _HistorialSkeleton();

  static Widget _box({double? w, required double h, double r = 6}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.primaryLight,
      highlightColor: AppColors.surface,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  top: AppSpacing.md, bottom: AppSpacing.sm),
              child: Row(
                children: [
                  _box(w: 3, h: 18, r: 2),
                  const SizedBox(width: AppSpacing.sm),
                  _box(w: 90, h: 13),
                  const Spacer(),
                  _box(w: 110, h: 20, r: AppSpacing.radiusSm),
                ],
              ),
            ),
            ...List.generate(
              2,
              (_) => Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    _box(w: 18, h: 18, r: 9),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _box(w: 80, h: 11),
                          const SizedBox(height: 5),
                          _box(w: 130, h: 13),
                          const SizedBox(height: 4),
                          _box(w: 90, h: 10),
                        ],
                      ),
                    ),
                    _box(w: 55, h: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

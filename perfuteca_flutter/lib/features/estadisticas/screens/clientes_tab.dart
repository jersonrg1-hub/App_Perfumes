import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:perfuteca/core/utils/debouncer.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/features/estadisticas/providers/estadisticas_provider.dart';
import 'package:perfuteca/features/estadisticas/widgets/estadisticas_shared.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/models/venta.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';
import 'package:perfuteca/widgets/common/app_error_widget.dart';
import 'package:perfuteca/widgets/common/empty_state_widget.dart';

class ClientesTab extends StatefulWidget {
  const ClientesTab({super.key});

  @override
  State<ClientesTab> createState() => _ClientesTabState();
}

class _ClientesTabState extends State<ClientesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const _ClientesView();
  }
}

// ── Lista de clientes ─────────────────────────────────────────────────────────

class _ClientesView extends ConsumerStatefulWidget {
  const _ClientesView();

  @override
  ConsumerState<_ClientesView> createState() => _ClientesViewState();
}

enum _Orden { gasto, fecha, pedidos }

class _ClientesViewState extends ConsumerState<_ClientesView> {
  String  _buscar = '';
  _Orden  _orden  = _Orden.gasto;
  final _debounce   = Debouncer(const Duration(milliseconds: 300));
  final _buscarCtrl = TextEditingController();

  List<ClienteStat> _sorted(List<ClienteStat> lista) {
    final c = List<ClienteStat>.from(lista);
    switch (_orden) {
      case _Orden.gasto:
        c.sort((a, b) => b.totalGastado.compareTo(a.totalGastado));
      case _Orden.fecha:
        c.sort((a, b) =>
            (b.ultimaCompra ?? '').compareTo(a.ultimaCompra ?? ''));
      case _Orden.pedidos:
        c.sort((a, b) => b.totalCompras.compareTo(a.totalCompras));
    }
    return c;
  }

  @override
  void dispose() {
    _debounce.dispose();
    _buscarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(clientesStatsProvider).when(
      loading: () => const _ClientesSkeleton(),
      error: (e, _) => AppErrorWidget(
        error: e,
        title: 'Error al cargar clientes',
        subtitle: 'Verifica tu conexión e intenta de nuevo',
        icon: Icons.wifi_off_rounded,
        subtle: true,
        onRetry: () => ref.invalidate(clientesStatsProvider),
      ),
      data: (clientes) {
        final ordenados = _sorted(clientes);
        final q         = _buscar.toLowerCase();
        final filtrados = q.isEmpty
            ? ordenados
            : ordenados.where((c) =>
                c.nombre.toLowerCase().contains(q) ||
                c.celular.contains(_buscar) ||
                c.direccion.toLowerCase().contains(q),
              ).toList();

        // Stats para chips
        final top        = clientes.isNotEmpty ? clientes.first : null;
        final totalSum   = clientes.fold(0.0, (s, c) => s + c.totalGastado);

        return Column(
          children: [
            // ── Resumen rápido ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: Row(
                children: [
                  _ResumenChip(
                    label: 'Clientes',
                    valor: '${clientes.length}',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ResumenChip(
                      label: 'Top · ${top?.nombre.split(' ').first ?? '—'}',
                      valor: top != null
                          ? 'S/ ${top.totalGastado.toStringAsFixed(0)}'
                          : '—',
                      destacado: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _ResumenChip(
                    label: 'Total ventas',
                    valor: 'S/ ${totalSum.toStringAsFixed(0)}',
                  ),
                ],
              ),
            ),

            // ── Buscador ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                controller: _buscarCtrl,
                decoration: InputDecoration(
                  hintText:       'Buscar cliente...',
                  prefixIcon:     const Icon(Icons.search_rounded, size: 20),
                  isDense:        true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  suffixIcon: _buscar.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: AppColors.textMuted),
                          onPressed: () {
                            _buscarCtrl.clear();
                            setState(() => _buscar = '');
                          },
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(color: AppColors.primaryLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(color: AppColors.primaryLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                onChanged: (v) {
                  _debounce.run(() {
                    if (mounted) setState(() => _buscar = v);
                  });
                },
              ),
            ),

            // ── Orden ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
              child: Row(
                children: [
                  Text(
                    '${filtrados.length} cliente${filtrados.length != 1 ? 's' : ''}',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  _OrdenChip(
                    label: 'Gasto',
                    activo: _orden == _Orden.gasto,
                    onTap: () => setState(() => _orden = _Orden.gasto),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _OrdenChip(
                    label: 'Última',
                    activo: _orden == _Orden.fecha,
                    onTap: () => setState(() => _orden = _Orden.fecha),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _OrdenChip(
                    label: 'Pedidos',
                    activo: _orden == _Orden.pedidos,
                    onTap: () => setState(() => _orden = _Orden.pedidos),
                  ),
                ],
              ),
            ),

            // ── Lista ──────────────────────────────────────────────
            Expanded(
              child: filtrados.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.search_off_rounded,
                      title: _buscar.isEmpty
                          ? 'Sin clientes'
                          : 'Sin resultados para "$_buscar"',
                      subtitle: _buscar.isNotEmpty
                          ? 'Prueba con el número de celular'
                          : null,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      itemCount: filtrados.length,
                      itemBuilder: (_, i) => FadeSlideListItem(
                            index: i,
                            child: _ClienteCard(cliente: filtrados[i]),
                          ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ── Chip de resumen ───────────────────────────────────────────────────────────

class _ResumenChip extends StatelessWidget {
  const _ResumenChip({
    required this.label,
    required this.valor,
    this.destacado = false,
  });
  final String label;
  final String valor;
  final bool   destacado;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: destacado
            ? AppColors.gold.withValues(alpha: 0.12)
            : AppColors.primaryPale,
        borderRadius: BorderRadius.circular(10),
        border: destacado
            ? Border.all(color: AppColors.gold.withValues(alpha: 0.35))
            : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: destacado ? AppColors.gold : AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            valor,
            style: AppTextStyles.body.copyWith(
              color: destacado ? AppColors.gold : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _OrdenChip extends StatelessWidget {
  const _OrdenChip({
    required this.label,
    required this.activo,
    required this.onTap,
  });
  final String       label;
  final bool         activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: activo ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
              color: activo ? AppColors.primary : AppColors.primaryLight,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize:   10,
              fontWeight: FontWeight.w700,
              color: activo ? AppColors.background : AppColors.textMuted,
            ),
          ),
        ),
      );
}

// ── Avatar con iniciales ──────────────────────────────────────────────────────

class _AvatarIniciales extends StatelessWidget {
  const _AvatarIniciales({required this.nombre});
  final String nombre;

  String _iniciales() {
    final partes = nombre.trim().split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '#';
    if (partes.length == 1) return partes[0][0].toUpperCase();
    return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
  }

  Color _color() => AppColors.avatarPalette[
      nombre.hashCode.abs() % AppColors.avatarPalette.length];

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _color().withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: _color().withValues(alpha: 0.5)),
        ),
        child: Center(
          child: Text(
            _iniciales(),
            style: TextStyle(
              fontSize:   13,
              fontWeight: FontWeight.w800,
              color:      _color(),
              height:     1,
            ),
          ),
        ),
      );
}

// ── Tarjeta de cliente ────────────────────────────────────────────────────────

class _ClienteCard extends ConsumerStatefulWidget {
  const _ClienteCard({required this.cliente});
  final ClienteStat cliente;

  @override
  ConsumerState<_ClienteCard> createState() => _ClienteCardState();
}

class _ClienteCardState extends ConsumerState<_ClienteCard> {
  bool _expandido = false;

  String _badge(int compras) {
    if (compras >= 5) return 'Cliente VIP';
    if (compras >= 3) return 'Cliente frecuente';
    return 'Cliente nuevo';
  }

  Color _badgeColor(int compras) {
    if (compras >= 5) return AppColors.gold;
    if (compras >= 3) return AppColors.primary;
    return AppColors.textMuted;
  }

  String _fmtFecha(String? raw) {
    if (raw == null) return '—';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cliente;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: _expandido ? AppColors.primary : AppColors.primaryLight,
        ),
        boxShadow: const [
          BoxShadow(
            color:      AppColors.shadowColor,
            blurRadius: 4,
            offset:     Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _expandido = !_expandido);
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Column(
          children: [
            // ── Fila principal ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  _AvatarIniciales(nombre: c.nombre),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.nombre,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.phone_rounded,
                                size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 3),
                            Text(
                              '${c.celular}  ·  ${c.totalCompras} compra${c.totalCompras != 1 ? 's' : ''}',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _badge(c.totalCompras),
                              style: AppTextStyles.bodySmall.copyWith(
                                color:      _badgeColor(c.totalCompras),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (c.ultimaCompra != null) ...[
                              Text(
                                '  ·  ',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.textFaint),
                              ),
                              const Icon(Icons.schedule_rounded,
                                  size: 10, color: AppColors.textFaint),
                              const SizedBox(width: 2),
                              Text(
                                _fmtFecha(c.ultimaCompra),
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textFaint,
                                    fontSize: 10),
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
                        'S/ ${c.totalGastado.toStringAsFixed(2)}',
                        style: AppTextStyles.price.copyWith(
                          fontSize: 15,
                          color: AppColors.primaryDark,
                        ),
                      ),
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

            // ── Detalle expandible ────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _expandido ? Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.primaryPale,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: AppSpacing.md),
                    // Info general
                    _InfoRow('Total gastado',
                        'S/ ${c.totalGastado.toStringAsFixed(2)}'),
                    _InfoRow(
                        'Pedidos / Ítems',
                        '${c.totalCompras} pedidos '
                            '/ ${c.totalItems} ítems'),
                    _InfoRow(
                        'Primera compra', _fmtFecha(c.primeraCompra)),
                    _InfoRow(
                        'Última compra', _fmtFecha(c.ultimaCompra)),
                    if (c.direccion.isNotEmpty)
                      _InfoRowMultiline('Dirección', c.direccion),
                    if (c.distrito.isNotEmpty)
                      _InfoRow('Distrito', c.distrito),

                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded,
                            size: 14, color: AppColors.textPrimary),
                        const SizedBox(width: 5),
                        Text(
                          'Historial de pedidos:',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ref.watch(ventasClienteProvider(widget.cliente.celular)).when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      error: (_, __) => Text(
                        'Error al cargar historial',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                      ),
                      data: (ventas) => Column(
                        children: _pedidosAgrupados(ventas)
                            .map((e) => _PedidoRow(idCompra: e.key, items: e.value))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ) : const SizedBox.shrink(),
            ),
          ],
        ),
        ),
      ),
    );
  }

  List<MapEntry<String, List<VentaResponse>>> _pedidosAgrupados(
      List<VentaResponse> historial) {
    final map = <String, List<VentaResponse>>{};
    for (final v in historial) {
      (map[v.idCompra] ??= []).add(v);
    }
    final entries = map.entries.toList()
      ..sort((a, b) {
        final fa = a.value.first.fecha ?? '';
        final fb = b.value.first.fecha ?? '';
        return fb.compareTo(fa);
      });
    return entries;
  }
}

// ── Fila de info ──────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.valor);
  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Text(
            valor,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRowMultiline extends StatelessWidget {
  const _InfoRowMultiline(this.label, this.valor);
  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(
            flex: 3,
            child: Text(
              valor,
              textAlign: TextAlign.start,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fila de pedido ────────────────────────────────────────────────────────────

class _PedidoRow extends ConsumerWidget {
  const _PedidoRow({required this.idCompra, required this.items});
  final String              idCompra;
  final List<VentaResponse> items;

  String _fmtFecha(String? raw) {
    if (raw == null) return '—';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  String _nombrePerfume(VentaResponse v, Map<String, Perfume> map) {
    if (v.idPerfume == null) return '—';
    final normId = double.tryParse(v.idPerfume!)?.toInt().toString()
        ?? v.idPerfume!;
    final p = map[normId];
    if (p != null) return '${p.nombre} · ${p.marca}';
    return 'Perfume #${v.idPerfume}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfumesMap = ref.watch(perfumesMapProvider).valueOrNull ?? {};
    final primera     = items.first;
    final total       = items.fold(0.0, (s, v) => s + (v.precioCobrado ?? 0));
    final estado      = primera.estado ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    estado == 'Entregado'
                        ? Icons.check_circle_rounded
                        : Icons.local_shipping_rounded,
                    size: 13,
                    color: estado == 'Entregado'
                        ? AppColors.stockOk
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '#$idCompra',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                _fmtFecha(primera.fecha),
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'S/ ${total.toStringAsFixed(2)}',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          if (primera.tipoEnvio != null || primera.metodoPago != null)
            Text(
              [
                if (primera.tipoEnvio  != null) primera.tipoEnvio!,
                if (primera.metodoPago != null) primera.metodoPago!,
              ].join(' · '),
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textMuted),
            ),
          ...items.map(
            (v) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.local_florist_outlined,
                      size: 11, color: AppColors.primary),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${_nombrePerfume(v, perfumesMap)}'
                    '${v.mlVendido != null ? '  ${v.mlVendido}ml' : ''}'
                    ' — S/ ${(v.precioCobrado ?? 0).toStringAsFixed(2)}',
                    style: AppTextStyles.bodySmall,
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

// ── Skeleton clientes ─────────────────────────────────────────────────────────

class _ClientesSkeleton extends StatelessWidget {
  const _ClientesSkeleton();

  Widget _clientCard() => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        height: 74,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.primaryLight,
      highlightColor: AppColors.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
            child: Row(children: [
              skeletonBox(width: 88, height: 44, radius: 10),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: skeletonBox(height: 44, radius: 10)),
              const SizedBox(width: AppSpacing.sm),
              skeletonBox(width: 88, height: 44, radius: 10),
            ]),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: skeletonBox(height: 44, radius: AppSpacing.radiusMd),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _clientCard(),
                _clientCard(),
                _clientCard(),
                _clientCard(),
                _clientCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/features/estadisticas/providers/estadisticas_provider.dart';
import 'package:perfuteca/features/ventas/providers/ventas_provider.dart';
import 'package:perfuteca/models/cotizacion.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/models/venta.dart';
import 'package:perfuteca/repositories/cotizaciones_repository.dart';
import 'package:perfuteca/repositories/ventas_repository.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';

class ClientesTab extends StatelessWidget {
  const ClientesTab({super.key});

  @override
  Widget build(BuildContext context) => const _ClientesView();
}

// ── Lista de clientes ─────────────────────────────────────────────────────────

class _ClientesView extends ConsumerStatefulWidget {
  const _ClientesView();

  @override
  ConsumerState<_ClientesView> createState() => _ClientesViewState();
}

class _ClientesViewState extends ConsumerState<_ClientesView> {
  String _buscar = '';

  @override
  Widget build(BuildContext context) {
    return ref.watch(clientesStatsProvider).when(
      loading: () => const _ClientesSkeleton(),
      error:   (e, _) => Center(
        child: Text(e.toString(), style: AppTextStyles.bodySmall),
      ),
      data: (clientes) {
        final filtrados = _buscar.isEmpty
            ? clientes
            : clientes.where((c) =>
                c.nombre.toLowerCase().contains(_buscar.toLowerCase()) ||
                c.celular.contains(_buscar) ||
                c.direccion.toLowerCase().contains(_buscar.toLowerCase()),
              ).toList();

        final top  = clientes.isNotEmpty ? clientes.first : null;
        final prom = clientes.isEmpty
            ? 0.0
            : clientes.fold(0.0, (s, c) => s + c.totalGastado) /
                clientes.length;

        return Column(
          children: [
            // ── Resumen rápido ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: Row(
                children: [
                  _ResumenChip(
                    label: 'Total clientes',
                    valor: '${clientes.length}',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ResumenChip(
                      label: 'Cliente top',
                      valor: top?.nombre ?? '—',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _ResumenChip(
                    label: 'Gasto prom.',
                    valor: 'S/ ${prom.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),

            // ── Buscador ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                decoration: InputDecoration(
                  hintText:       'Buscar cliente...',
                  prefixIcon:     const Icon(Icons.search_rounded, size: 20),
                  isDense:        true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(color: AppColors.primaryLight),
                  ),
                ),
                onChanged: (v) => setState(() => _buscar = v),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${filtrados.length} cliente${filtrados.length != 1 ? 's' : ''}',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // ── Lista ──────────────────────────────────────────────
            Expanded(
              child: filtrados.isEmpty
                  ? Center(
                      child: Text(
                        'Sin resultados',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      itemCount: filtrados.length,
                      itemBuilder: (_, i) => _AnimatedListItem(
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
  const _ResumenChip({required this.label, required this.valor});
  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primaryPale,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            valor,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
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

// ── Tarjeta de cliente ────────────────────────────────────────────────────────

class _ClienteCard extends StatefulWidget {
  const _ClienteCard({required this.cliente});
  final ClienteStat cliente;

  @override
  State<_ClienteCard> createState() => _ClienteCardState();
}

class _ClienteCardState extends State<_ClienteCard> {
  bool _expandido = false;

  String _badge(int compras) {
    if (compras >= 5) return 'Cliente VIP';
    if (compras >= 3) return 'Cliente frecuente';
    return 'Cliente nuevo';
  }

  Color _badgeColor(int compras) {
    if (compras >= 5) return AppColors.primary;
    if (compras >= 3) return AppColors.textMuted;
    return AppColors.textFaint;
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
          onTap: () => setState(() => _expandido = !_expandido),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Column(
          children: [
            // ── Fila principal ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryPale,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded,
                        size: 20, color: AppColors.primary),
                  ),
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
                        Text(
                          '📱 ${c.celular}  ·  ${c.totalCompras} compra${c.totalCompras != 1 ? 's' : ''}',
                          style: AppTextStyles.bodySmall,
                        ),
                        Text(
                          _badge(c.totalCompras),
                          style: AppTextStyles.bodySmall.copyWith(
                            color:      _badgeColor(c.totalCompras),
                            fontWeight: FontWeight.w600,
                          ),
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
                decoration: BoxDecoration(
                  color: AppColors.primaryPale,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: AppSpacing.md),
                    // Info general
                    _InfoRow('💰 Total gastado',
                        'S/ ${c.totalGastado.toStringAsFixed(2)}'),
                    _InfoRow(
                        '🛍️ Pedidos / Ítems',
                        '${c.totalCompras} pedidos '
                            '/ ${c.totalItems} ítems'),
                    _InfoRow(
                        '📅 Primera compra', _fmtFecha(c.primeraCompra)),
                    _InfoRow(
                        '📅 Última compra', _fmtFecha(c.ultimaCompra)),
                    if (c.direccion.isNotEmpty)
                      _InfoRowMultiline('📍 Dirección', c.direccion),

                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '🧾 Historial de pedidos:',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ..._pedidosAgrupados(c.historial)
                        .map((e) => _PedidoRow(idCompra: e.key, items: e.value)),
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

  // Agrupa items por idCompra preservando orden descendente por fecha
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
    final icon        = estado == 'Entregado' ? '✅' : '📦';

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
              Text(
                '$icon #$idCompra',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
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
            (v) => Text(
              '  🌸 ${_nombrePerfume(v, perfumesMap)}'
              '${v.mlVendido != null ? '  ${v.mlVendido}ml' : ''}'
              ' — S/ ${(v.precioCobrado ?? 0).toStringAsFixed(2)}',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Todas las cotizaciones (paginadas) ────────────────────────────────────────

class CotizacionesTodasView extends ConsumerStatefulWidget {
  const CotizacionesTodasView({super.key});

  @override
  ConsumerState<CotizacionesTodasView> createState() =>
      CotizacionesTodasViewState();
}

class CotizacionesTodasViewState
    extends ConsumerState<CotizacionesTodasView> {
  static const _pageSize = 10;

  final List<CotizacionResponse> _items     = [];
  final _searchCtrl                          = TextEditingController();
  String  _buscar   = '';
  int     _offset   = 0;
  bool    _cargando = false;
  bool    _hayMas   = true;

  @override
  void initState() {
    super.initState();
    _cargarMas();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarMas() async {
    if (_cargando || !_hayMas) return;
    setState(() => _cargando = true);
    try {
      final page = await ref
          .read(cotizacionesRepositoryProvider)
          .getCotizaciones(limit: _pageSize, offset: _offset);
      setState(() {
        _items.addAll(page.items);
        _offset += page.items.length;
        _hayMas  = page.items.length == _pageSize;
      });
    } catch (_) {
      // silencioso; el usuario puede reintentar con el botón
    } finally {
      setState(() => _cargando = false);
    }
  }

  String _fmtFecha(String? raw) {
    if (raw == null) return '—';
    try {
      return DateFormat('dd/MM/yy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _buscar.isEmpty
        ? _items
        : _items
            .where((c) => c.celular.contains(_buscar))
            .toList();

    return Column(
      children: [
        // ── Buscador ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
          child: TextField(
            controller: _searchCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText:       'Buscar por celular...',
              prefixIcon:     const Icon(Icons.phone_rounded, size: 20),
              isDense:        true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(color: AppColors.primaryLight),
              ),
              suffixIcon: _buscar.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _buscar = '');
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _buscar = v.trim()),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${filtrados.length} cotización${filtrados.length != 1 ? 'es' : ''}',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // ── Lista ──────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: filtrados.length + 1,
            itemBuilder: (_, i) {
              if (i < filtrados.length) {
                return _CotizacionCard(
                  c:        filtrados[i],
                  fmtFecha: _fmtFecha,
                );
              }
              // Pie de lista: botón cargar más o spinner
              if (_cargando) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (_hayMas && _buscar.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md),
                  child: Center(
                    child: OutlinedButton.icon(
                      onPressed: _cargarMas,
                      icon: const Icon(Icons.expand_more_rounded, size: 18),
                      label: const Text('Cargar más'),
                    ),
                  ),
                );
              }
              return const SizedBox(height: AppSpacing.xl);
            },
          ),
        ),
      ],
    );
  }
}

// IDs convertidos en esta sesión — bloquea re-apertura aunque el backend falle
final _cotizacionesAceptadasClientesProvider =
    StateProvider<Set<String>>((ref) => const {});

// ── Tarjeta de cotización ─────────────────────────────────────────────────────

class _CotizacionCard extends ConsumerStatefulWidget {
  const _CotizacionCard({required this.c, required this.fmtFecha});
  final CotizacionResponse        c;
  final String Function(String?) fmtFecha;

  @override
  ConsumerState<_CotizacionCard> createState() => _CotizacionCardState();
}

class _CotizacionCardState extends ConsumerState<_CotizacionCard> {
  bool    _expandido   = false;
  bool    _registrando = false;
  bool    _exito       = false;
  String? _error;
  String? _idVenta;

  final _compradorCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  String _tipoEnvio  = '';
  String _metodoPago = 'Yape';

  @override
  void dispose() {
    _compradorCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  bool get _formValido =>
      _compradorCtrl.text.trim().isNotEmpty &&
      _tipoEnvio.isNotEmpty &&
      (_tipoEnvio == 'Contraentrega' || _direccionCtrl.text.trim().isNotEmpty);

  Future<void> _registrar() async {
    final catalogo = ref.read(catalogoProvider).perfumes;
    final cesta    = _parsearCesta(widget.c.items ?? '', catalogo, _metodoPago);

    if (cesta.isEmpty) {
      setState(() =>
          _error = 'No se pudieron reconocer los perfumes de esta cotización');
      return;
    }

    setState(() { _registrando = true; _error = null; });
    try {
      final registrada =
          await ref.read(ventasRepositoryProvider).registrarVenta(
        comprador: _compradorCtrl.text.trim(),
        celular:   widget.c.celular,
        direccion: _direccionCtrl.text.trim(),
        tipoEnvio: _tipoEnvio,
        fecha:     DateFormat('yyyy-MM-dd').format(DateTime.now()),
        items: cesta
            .map((i) => ItemCesta(
                  perfume: i.perfume,
                  ml:      i.ml,
                  precio:  i.precio,
                  metodo:  _metodoPago,
                ).toApiMap())
            .toList(),
      );
      ref.invalidate(historialProvider);
      ref.invalidate(pendientesProvider);
      setState(() {
        _registrando = false;
        _exito       = true;
        _idVenta     = registrada.idCompra;
      });
      // Marcar cotización como Aceptado (silencioso si falla)
      try {
        await ref.read(cotizacionesRepositoryProvider).actualizarEstado(
          idCotizacion: widget.c.idCotizacion,
          nuevoEstado:  'Aceptada',
        );
      } catch (_) {}
      // Bloquear re-apertura en sesión aunque el backend no responda
      ref.read(_cotizacionesAceptadasClientesProvider.notifier)
          .update((s) => {...s, widget.c.idCotizacion});
    } catch (e) {
      setState(() { _registrando = false; _error = e.toString(); });
    }
  }

  Color _estadoColor(String? estado) {
    if (estado == null) return AppColors.textFaint;
    switch (estado.toLowerCase()) {
      case 'pendiente': return AppColors.stockLow;
      case 'entregado': return AppColors.stockOk;
      case 'aceptado':  return AppColors.stockOk;
      case 'anulado':   return AppColors.stockCritical;
      default:          return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final aceptadas  = ref.watch(_cotizacionesAceptadasClientesProvider);
    final esAceptada = aceptadas.contains(widget.c.idCotizacion) ||
        widget.c.estado?.toLowerCase().startsWith('aceptad') == true;

    if (_exito) {
      return _CartaExitoCliente(
        idVenta:      _idVenta ?? '',
        idCotizacion: widget.c.idCotizacion,
        comprador:    _compradorCtrl.text.trim(),
        celular:      widget.c.celular,
        tipoEnvio:    _tipoEnvio,
        direccion:    _direccionCtrl.text.trim(),
        metodoPago:   _metodoPago,
        itemsStr:     widget.c.items ?? '',
        total:        widget.c.total ?? 0,
      );
    }

    final c = widget.c;
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: _expandido ? AppColors.primary : AppColors.primaryLight,
            width: _expandido ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 4,
                offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabecera ────────────────────────────────────────────
            InkWell(
              onTap: esAceptada
                  ? null
                  : () => setState(() => _expandido = !_expandido),
              borderRadius: _expandido
                  ? const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusMd))
                  : BorderRadius.circular(AppSpacing.radiusMd),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryPale,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.request_quote_rounded,
                          size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📱 ${c.celular.isNotEmpty ? c.celular : '—'}',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(widget.fmtFecha(c.fecha),
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'S/ ${(c.total ?? 0).toStringAsFixed(2)}',
                          style: AppTextStyles.price.copyWith(
                              fontSize: 14, color: AppColors.primaryDark),
                        ),
                        if (c.estado != null)
                          Text(
                            c.estado!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color:      _estadoColor(c.estado),
                              fontWeight: FontWeight.w700,
                              fontSize:   10,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _expandido ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 20, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),

            // ── Sección expandible ──────────────────────────────────
            if (_expandido) ...[
              const Divider(height: 1, color: AppColors.primaryLight),

              // Mini-resumen de items
              if (c.items != null && c.items!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPale,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...c.items!
                          .split(' | ')
                          .map((s) => s.trim())
                          .where((s) => s.isNotEmpty)
                          .map((l) => Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Icon(
                                          Icons.local_florist_outlined,
                                          size: 11,
                                          color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(l,
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.w500)),
                                    ),
                                  ],
                                ),
                              )),
                      if (c.total != null) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Total  S/ ${c.total!.toStringAsFixed(2)}',
                            style: AppTextStyles.price.copyWith(
                                fontSize: 13,
                                color: AppColors.primaryDark),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              const Divider(height: 1, color: AppColors.primaryLight),

              // Bloqueo si ya fue aceptada / formulario de conversión
              if (esAceptada)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(AppSpacing.md),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.successSurface,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                        color: AppColors.stockOk.withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.stockOk, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Esta cotización ya fue convertida en venta',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.stockOk,
                            fontWeight: FontWeight.w600)),
                  ]),
                )
              else
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.sell_outlined,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('Convertir en venta',
                          style: AppTextStyles.notasLabel.copyWith(
                              color: AppColors.primary, fontSize: 10)),
                    ]),
                    const SizedBox(height: AppSpacing.md),

                    _CotFieldLabel('Nombre del comprador',
                        Icons.person_outline_rounded),
                    _CotField(
                      controller: _compradorCtrl,
                      hint: 'Nombre completo',
                      capitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                    ),

                    _CotFieldLabel(
                        'Dirección de entrega', Icons.location_on_outlined),
                    _CotField(
                      controller: _direccionCtrl,
                      hint: 'Jr. Los Jardines 123',
                      capitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                    ),

                    _CotFieldLabel(
                        'Tipo de envío', Icons.local_shipping_outlined),
                    _CotChips(
                      opciones: const [
                        'Shalom',
                        'Motorizado',
                        'Contraentrega'
                      ],
                      valor: _tipoEnvio,
                      onSelect: (v) => setState(() => _tipoEnvio = v),
                    ),

                    _CotFieldLabel('Método de pago', Icons.payment_outlined),
                    _CotChips(
                      opciones: const [
                        'Yape',
                        'Plin',
                        'Transferencia',
                        'Tarjeta'
                      ],
                      valor: _metodoPago,
                      onSelect: (v) => setState(() => _metodoPago = v),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.errorSurface,
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm),
                          border: Border.all(
                              color:
                                  AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Text(_error!,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.error)),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.md),

                    Row(children: [
                      OutlinedButton(
                        onPressed: _registrando
                            ? null
                            : () => setState(() {
                                  _expandido = false;
                                  _error = null;
                                }),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textMuted,
                          side: const BorderSide(
                              color: AppColors.primaryLight),
                        ),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: (!_formValido || _registrando)
                              ? null
                              : () async {
                                  final confirmar =
                                      await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Row(
                                        children: [
                                          Icon(Icons.sell_outlined,
                                              color: AppColors.primary,
                                              size: 20),
                                          SizedBox(width: 8),
                                          Text('Confirmar venta'),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _ResumenFilaCot('Cliente',
                                              _compradorCtrl.text.trim()),
                                          _ResumenFilaCot('Celular',
                                              widget.c.celular),
                                          _ResumenFilaCot(
                                              'Envío', _tipoEnvio),
                                          _ResumenFilaCot('Dirección',
                                              _direccionCtrl.text.trim()),
                                          _ResumenFilaCot(
                                              'Pago', _metodoPago),
                                          if (widget.c.total != null) ...[
                                            const Divider(height: 16),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text('TOTAL',
                                                    style: AppTextStyles
                                                        .notasLabel
                                                        .copyWith(
                                                            color: AppColors
                                                                .textMuted)),
                                                Text(
                                                  'S/ ${widget.c.total!.toStringAsFixed(2)}',
                                                  style: AppTextStyles
                                                      .price
                                                      .copyWith(
                                                          color: AppColors
                                                              .primaryDark,
                                                          fontSize: 16),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child:
                                              const Text('Guardar venta'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmar == true) _registrar();
                                },
                          icon: _registrando
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : const Icon(Icons.check_circle_rounded,
                                  size: 16),
                          label: Text(_registrando
                              ? 'Registrando...'
                              : 'Registrar venta'),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta de éxito tras conversión ─────────────────────────────────────────

class _CartaExitoCliente extends StatelessWidget {
  const _CartaExitoCliente({
    required this.idVenta,
    required this.idCotizacion,
    required this.comprador,
    required this.celular,
    required this.tipoEnvio,
    required this.direccion,
    required this.metodoPago,
    required this.itemsStr,
    required this.total,
  });
  final String idVenta;
  final String idCotizacion;
  final String comprador;
  final String celular;
  final String tipoEnvio;
  final String direccion;
  final String metodoPago;
  final String itemsStr;
  final double total;

  Future<void> _enviarComunidad() async {
    const sep = '────────────────────';
    final lineas = itemsStr
        .split(' | ')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => '  🌸 $s')
        .join('\n');
    final dirLinea = direccion.isNotEmpty ? '\n📍 *Dirección:* $direccion' : '';
    final texto =
        '📦 *Perfuteca — Pedido $idVenta*\n$sep\n'
        '👤 *Cliente:* $comprador\n📱 *Celular:* $celular\n'
        '🚚 *Envío:* $tipoEnvio$dirLinea\n$sep\n'
        '🌸 *Perfumes:*\n$lineas\n$sep\n'
        '💰 *Total: S/ ${total.toStringAsFixed(2)}*\n'
        '💳 *Pago:* $metodoPago';
    final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(texto)}');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.successSurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border:
              Border.all(color: AppColors.stockOk.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.stockOk, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('¡Venta registrada!  $idVenta',
                        style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.stockOk)),
                    Text('Cotización $idCotizacion convertida',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted, fontSize: 10)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _enviarComunidad,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.whatsapp,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Enviar pedido a comunidad',
                    style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      );
}

// ── Widgets auxiliares del formulario ─────────────────────────────────────────

class _CotFieldLabel extends StatelessWidget {
  const _CotFieldLabel(this.text, this.icon);
  final String   text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 4),
        child: Row(children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(text,
              style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  fontSize: 11)),
        ]),
      );
}

class _CotField extends StatelessWidget {
  const _CotField({
    required this.controller,
    required this.hint,
    this.onChanged,
    this.capitalization = TextCapitalization.none,
  });
  final TextEditingController controller;
  final String                hint;
  final ValueChanged<String>? onChanged;
  final TextCapitalization    capitalization;

  @override
  Widget build(BuildContext context) => TextField(
        controller:         controller,
        textCapitalization: capitalization,
        onChanged:          onChanged,
        decoration: InputDecoration(
          hintText:  hint,
          hintStyle: AppTextStyles.bodySmall,
          filled:    true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            borderSide: const BorderSide(color: AppColors.primaryLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            borderSide: const BorderSide(color: AppColors.primaryLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );
}

class _CotChips extends StatelessWidget {
  const _CotChips({
    required this.opciones,
    required this.valor,
    required this.onSelect,
  });
  final List<String>         opciones;
  final String               valor;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: opciones.map((op) {
            final sel = valor == op;
            return Semantics(
              button: true,
              label: op,
              selected: sel,
              child: GestureDetector(
                onTap: () => onSelect(op),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                      color: sel ? AppColors.primary : AppColors.primaryLight,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Text(op,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              sel ? FontWeight.w700 : FontWeight.w500,
                          color: sel
                              ? Colors.white
                              : AppColors.textSecondary)),
                ),
              ),
            );
          }).toList(),
        ),
      );
}

class _ResumenFilaCot extends StatelessWidget {
  const _ResumenFilaCot(this.label, this.valor);
  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              child: Text(label,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted)),
            ),
            Expanded(
              child: Text(
                valor.isNotEmpty ? valor : '—',
                style: AppTextStyles.bodySmall
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
}

// ── Parser: items string → List<ItemCesta> ────────────────────────────────────
// Formato: "Perfume A 2ml S/10.00 | Perfume B 5ml S/25.00"

List<ItemCesta> _parsearCesta(String itemsStr, List<Perfume> catalogo, String metodoPago) {
  if (itemsStr.isEmpty) return [];
  final result = <ItemCesta>[];
  final rx = RegExp(r'^(.+?)\s+(\d+)ml\s+S/(\d+\.?\d*)$');

  for (final part in itemsStr.split(' | ')) {
    final m = rx.firstMatch(part.trim());
    if (m == null) continue;

    final nombre = m.group(1)!;
    final ml     = int.tryParse(m.group(2)!) ?? 0;
    final precio = double.tryParse(m.group(3)!) ?? 0.0;
    if (ml == 0) continue;

    Perfume? perfume;
    try {
      perfume = catalogo.firstWhere(
          (p) => p.nombre.toLowerCase() == nombre.toLowerCase());
    } catch (_) {
      try {
        perfume = catalogo.firstWhere((p) =>
            p.nombre.toLowerCase().contains(nombre.toLowerCase()) ||
            nombre.toLowerCase().contains(p.nombre.toLowerCase()));
      } catch (_) {
        continue;
      }
    }
    result.add(
        ItemCesta(perfume: perfume, ml: ml, precio: precio, metodo: metodoPago));
  }
  return result;
}

// ── Stagger animation wrapper ─────────────────────────────────────────────────

class _AnimatedListItem extends StatefulWidget {
  const _AnimatedListItem({required this.index, required this.child});
  final int    index;
  final Widget child;

  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    final delayMs = (widget.index * 40).clamp(0, 280);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

// ── Skeleton clientes ─────────────────────────────────────────────────────────

class _ClientesSkeleton extends StatelessWidget {
  const _ClientesSkeleton();

  static Widget _box({double? w, required double h, double r = 8}) =>
      Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r),
        ),
      );

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
              _box(w: 88, h: 44, r: 10),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _box(h: 44, r: 10)),
              const SizedBox(width: AppSpacing.sm),
              _box(w: 88, h: 44, r: 10),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _box(h: 44, r: AppSpacing.radiusMd),
          ),
          const SizedBox(height: AppSpacing.md),
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

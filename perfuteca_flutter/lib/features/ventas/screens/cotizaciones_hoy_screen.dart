import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
import 'package:shimmer/shimmer.dart';

// ── Provider: cotizaciones registradas hoy ────────────────────────────────────

final cotizacionesHoyProvider =
    FutureProvider<List<CotizacionResponse>>((ref) async {
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final page  = await ref.read(cotizacionesRepositoryProvider)
      .getCotizaciones(limit: 500, bypassCache: true);
  // La API serializa fecha como ISO "2026-05-16T00:00:00", no como "2026-05-16"
  return page.items.where((c) => c.fecha?.startsWith(today) == true).toList();
});

// IDs convertidos en esta sesión — bloquea re-apertura aunque la API falle
final _cotizacionesAceptadasProvider =
    StateProvider<Set<String>>((ref) => const {});

// ── Pantalla ──────────────────────────────────────────────────────────────────

class CotizacionesHoyScreen extends ConsumerWidget {
  const CotizacionesHoyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cotizacionesHoyProvider);

    return async.when(
      loading: () => const _CotizacionesShimmer(),
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 52, color: AppColors.textFaint),
            const SizedBox(height: 12),
            Text('Error al cargar',
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reintentar'),
              onPressed: () => ref.invalidate(cotizacionesHoyProvider),
            ),
          ],
        ),
      ),
      data: (lista) => lista.isEmpty
          ? _EmptyState(onRefresh: () => ref.invalidate(cotizacionesHoyProvider))
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(cotizacionesHoyProvider),
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg,
                    80 + MediaQuery.of(context).padding.bottom),
                itemCount: lista.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    final convertidas = lista
                        .where((c) => c.estado?.toLowerCase().startsWith('aceptad') == true)
                        .length;
                    final pendientes = lista.length - convertidas;
                    final totalS = lista.fold(0.0, (s, c) => s + (c.total ?? 0));
                    return _AnimatedListItem(
                      index: 0,
                      child: _MetricasHoyRow(
                        total:       totalS,
                        pendientes:  pendientes,
                        convertidas: convertidas,
                      ),
                    );
                  }
                  final c = lista[i - 1];
                  return _AnimatedListItem(
                    index: i,
                    child: _CotizacionCard(
                      key: ValueKey(c.idCotizacion),
                      cotizacion: c,
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ── Métricas planas del día ───────────────────────────────────────────────────

class _MetricasHoyRow extends StatelessWidget {
  const _MetricasHoyRow({
    required this.total,
    required this.pendientes,
    required this.convertidas,
  });
  final double total;
  final int    pendientes;
  final int    convertidas;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _MetricaItem(
              label: 'TOTAL HOY',
              value: 'S/ ${total.toStringAsFixed(2)}',
              valueColor: AppColors.primaryDark,
            ),
            const VerticalDivider(width: 1, thickness: 1, color: AppColors.primaryLight),
            _MetricaItem(
              label: 'PENDIENTES',
              value: '$pendientes',
              valueColor: pendientes > 0 ? AppColors.warning : AppColors.textFaint,
            ),
            const VerticalDivider(width: 1, thickness: 1, color: AppColors.primaryLight),
            _MetricaItem(
              label: 'CONVERTIDAS',
              value: '$convertidas',
              valueColor: convertidas > 0 ? AppColors.stockOk : AppColors.textFaint,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricaItem extends StatelessWidget {
  const _MetricaItem({
    required this.label,
    required this.value,
    required this.valueColor,
  });
  final String label;
  final String value;
  final Color  valueColor;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.notasLabel.copyWith(
                  color: AppColors.textFaint,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize:   label == 'TOTAL HOY' ? 24 : 20,
                    fontWeight: FontWeight.w800,
                    color:      valueColor,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Estado vacío ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 64, color: AppColors.textFaint),
            const SizedBox(height: AppSpacing.lg),
            Text('Sin cotizaciones hoy',
                style:
                    AppTextStyles.body.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: AppSpacing.xs + 2),
            Text(
              'Crea una cotización en la pestaña Cotización',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textFaint),
            ),
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

// ── Card de cotización con formulario inline para convertir a venta ───────────

class _CotizacionCard extends ConsumerStatefulWidget {
  const _CotizacionCard({super.key, required this.cotizacion});
  final CotizacionResponse cotizacion;

  @override
  ConsumerState<_CotizacionCard> createState() => _CotizacionCardState();
}

class _CotizacionCardState extends ConsumerState<_CotizacionCard> {
  bool    _expandido       = false;
  bool    _registrando     = false;
  bool    _buscandoCliente = false;
  bool    _exito           = false;
  bool    _clienteNuevo    = false;
  bool    _confirmando     = false;
  String? _error;
  String? _idVenta;

  final _compradorCtrl      = TextEditingController();
  final _direccionCtrl      = TextEditingController();
  final _distritoCtrl       = TextEditingController();
  final _botonKey           = GlobalKey();
  late final ValueNotifier<bool> _formValidoNotifier;
  late final List<String> _lineas;
  String _tipoEnvio  = '';
  String _metodoPago = 'Yape';

  @override
  void initState() {
    super.initState();
    _lineas = (widget.cotizacion.items ?? '')
        .split(' | ')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    _formValidoNotifier = ValueNotifier<bool>(false);
    _compradorCtrl.addListener(_checkForm);
    _direccionCtrl.addListener(_checkForm);
    _distritoCtrl.addListener(_checkForm);
  }

  void _checkForm() {
    _formValidoNotifier.value =
        _compradorCtrl.text.trim().isNotEmpty &&
        _direccionCtrl.text.trim().isNotEmpty &&
        _tipoEnvio.isNotEmpty;
  }

  @override
  void dispose() {
    _compradorCtrl.dispose();
    _direccionCtrl.dispose();
    _distritoCtrl.dispose();
    _formValidoNotifier.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosCliente() async {
    final celular = widget.cotizacion.celular;
    if (celular.isEmpty) return;
    setState(() { _buscandoCliente = true; _clienteNuevo = false; });
    try {
      final cliente =
          await ref.read(ventasRepositoryProvider).getClientePrevio(celular);
      if (cliente != null && mounted) {
        setState(() {
          if (_compradorCtrl.text.trim().isEmpty) {
            _compradorCtrl.text = cliente.comprador;
          }
          if (_direccionCtrl.text.trim().isEmpty) {
            _direccionCtrl.text = cliente.direccion;
          }
          if (_distritoCtrl.text.trim().isEmpty && cliente.distrito.isNotEmpty) {
            _distritoCtrl.text = cliente.distrito;
          }
          if (_tipoEnvio.isEmpty) _tipoEnvio = cliente.tipoEnvio;
          _metodoPago = cliente.metodoPago;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_botonKey.currentContext != null) {
            Scrollable.ensureVisible(
              _botonKey.currentContext!,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
            );
          }
        });
      } else if (mounted) {
        setState(() => _clienteNuevo = true);
      }
    } catch (_) {
      // Silencioso — el usuario puede llenar manualmente
    } finally {
      if (mounted) setState(() => _buscandoCliente = false);
    }
  }

  Future<void> _registrar() async {
    final catalogo = ref.read(catalogoProvider).perfumes;
    final cesta    = _parsearCesta(widget.cotizacion.items ?? '', catalogo, _metodoPago);

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
        celular:   widget.cotizacion.celular,
        direccion: _direccionCtrl.text.trim(),
        distrito:  _distritoCtrl.text.trim(),
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
      ref.invalidate(cotizacionesHoyProvider);
      ref.invalidate(resumenBackendProvider);
      ref.invalidate(resumenStatsProvider);
      ref.invalidate(semanaStatsProvider);
      ref.invalidate(tamaniosStatsProvider);
      ref.read(catalogoProvider.notifier).load();
      setState(() {
        _registrando = false;
        _exito       = true;
        _idVenta     = registrada.idCompra;
      });
      // Marcar cotización como Aceptado (silencioso si falla)
      try {
        await ref.read(cotizacionesRepositoryProvider).actualizarEstado(
          idCotizacion: widget.cotizacion.idCotizacion,
          nuevoEstado:  'Aceptada',
        );
      } catch (_) {}
      // Bloquear re-apertura en sesión aunque el backend no responda
      ref.read(_cotizacionesAceptadasProvider.notifier)
          .update((s) => {...s, widget.cotizacion.idCotizacion});
    } catch (e) {
      setState(() { _registrando = false; _error = e.toString(); _confirmando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final esAceptada =
        ref.watch(_cotizacionesAceptadasProvider
            .select((s) => s.contains(widget.cotizacion.idCotizacion))) ||
        widget.cotizacion.estado?.toLowerCase().startsWith('aceptad') == true;

    if (_exito) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, v, child) =>
            Opacity(opacity: v, child: child),
        child: _CartaExito(
          idVenta:      _idVenta ?? '',
          idCotizacion: widget.cotizacion.idCotizacion,
          comprador:    _compradorCtrl.text.trim(),
          celular:      widget.cotizacion.celular,
          tipoEnvio:    _tipoEnvio,
          direccion:    _direccionCtrl.text.trim(),
          distrito:     _distritoCtrl.text.trim(),
          metodoPago:   _metodoPago,
          itemsStr:     widget.cotizacion.items ?? '',
          total:        widget.cotizacion.total ?? 0,
        ),
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: esAceptada && !_expandido ? AppColors.successSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: esAceptada && !_expandido
                ? AppColors.stockOk.withValues(alpha: 0.3)
                : (_expandido ? AppColors.primary : AppColors.primaryLight),
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
            // ── Cabecera (siempre visible, tappeable) ───────────────────
            Semantics(
              button: true,
              label: esAceptada
                  ? 'Cotización ${widget.cotizacion.idCotizacion}, aceptada'
                  : 'Cotización ${widget.cotizacion.idCotizacion} · ${widget.cotizacion.celular} · S/${widget.cotizacion.total?.toStringAsFixed(2) ?? '0'}. Toca para convertir a venta.',
              child: InkWell(
              onTap: esAceptada
                  ? null
                  : () {
                      final abriendo = !_expandido;
                      setState(() {
                        _expandido   = !_expandido;
                        if (!abriendo) _confirmando = false;
                      });
                      if (abriendo) _cargarDatosCliente();
                    },
              splashColor: AppColors.primaryLight,
              highlightColor: AppColors.primaryPale,
              borderRadius: _expandido
                  ? const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusMd))
                  : BorderRadius.circular(AppSpacing.radiusMd),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      // Badge ID
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPale,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          widget.cotizacion.idCotizacion,
                          style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Celular
                      if (widget.cotizacion.celular.isNotEmpty) ...[
                        const Icon(Icons.phone_outlined,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: AppSpacing.xs),
                        Text(widget.cotizacion.celular,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                      const Spacer(),
                      // Total
                      if (widget.cotizacion.total != null)
                        Text(
                          'S/ ${widget.cotizacion.total!.toStringAsFixed(2)}',
                          style: AppTextStyles.price.copyWith(
                              fontSize: 14, color: AppColors.primaryDark),
                        ),
                      const SizedBox(width: AppSpacing.xs),
                      AnimatedRotation(
                        turns: _expandido ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 20, color: AppColors.textMuted),
                      ),
                    ]),
                    // Perfumes de la cotización
                    if (_lineas.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs + 2),
                      ..._lineas.map((l) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(children: [
                              const Icon(Icons.circle,
                                  size: 4, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(l,
                                    style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 11)),
                              ),
                            ]),
                          )),
                    ],
                    // Hint cuando está colapsado
                    if (!_expandido) ...[
                      const SizedBox(height: AppSpacing.sm),
                      if (esAceptada)
                        Row(children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 12, color: AppColors.stockOk),
                          const SizedBox(width: 4),
                          Text('Aceptado · ya convertida en venta',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.stockOk,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11)),
                        ])
                      else
                        Row(children: [
                          const Icon(Icons.sell_outlined,
                              size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('Toca para convertir a venta',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11)),
                        ]),
                    ],
                  ],
                ),
              ),
            ),
            ),

            // ── Formulario expandible ───────────────────────────────────
            if (_expandido) ...[
              const Divider(height: 1, color: AppColors.primaryLight),
              if (_buscandoCliente)
                const LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: AppColors.primaryPale,
                  color: AppColors.primary,
                ),
              const SizedBox(height: AppSpacing.sm),
              _MiniResumen(
                lineas: _lineas,
                total:  widget.cotizacion.total,
              ),
              if (!_buscandoCliente && _clienteNuevo) ...[
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md),
                  child: Row(children: [
                    const Icon(Icons.person_add_outlined,
                        size: 13, color: AppColors.gold),
                    const SizedBox(width: AppSpacing.xs + 1),
                    Text(
                      'Cliente nuevo · llena los datos',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ]),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1, color: AppColors.primaryLight),
              if (esAceptada)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(AppSpacing.md),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.successSurface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _confirmando
                  ? _ConfirmacionInline(
                      key: const ValueKey('confirm'),
                      comprador:  _compradorCtrl.text.trim(),
                      celular:    widget.cotizacion.celular,
                      tipoEnvio:  _tipoEnvio,
                      direccion:  _direccionCtrl.text.trim(),
                      distrito:   _distritoCtrl.text.trim(),
                      metodoPago: _metodoPago,
                      total:      widget.cotizacion.total,
                      botonKey:   _botonKey,
                      registrando: _registrando,
                      error:      _error,
                      onEditar:   () => setState(() => _confirmando = false),
                      onConfirmar: _registrar,
                    )
                  : Padding(
                      key: const ValueKey('form'),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.edit_note_rounded,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text('Completa los datos para la venta',
                                style: AppTextStyles.notasLabel.copyWith(
                                    color: AppColors.primary, fontSize: 12)),
                          ]),
                          const SizedBox(height: AppSpacing.md),
                          const _FieldLabel('Nombre del comprador',
                              Icons.person_outline_rounded),
                          _Field(
                            controller: _compradorCtrl,
                            hint: 'Nombre completo',
                            capitalization: TextCapitalization.words,
                          ),
                          const _FieldLabel('Dirección de entrega',
                              Icons.location_on_outlined),
                          _Field(
                            controller: _direccionCtrl,
                            hint: 'Jr. Los Jardines 123',
                            capitalization: TextCapitalization.words,
                          ),
                          const _FieldLabel('Distrito/Provincia',
                              Icons.map_outlined),
                          _Field(
                            controller: _distritoCtrl,
                            hint: 'Ej: Lima, Arequipa',
                            capitalization: TextCapitalization.words,
                          ),
                          const _FieldLabel('Tipo de envío',
                              Icons.local_shipping_outlined),
                          _Chips(
                            opciones: const ['Shalom', 'Motorizado'],
                            valor: _tipoEnvio,
                            onSelect: (v) { setState(() => _tipoEnvio = v); _checkForm(); },
                          ),
                          const _FieldLabel('Método de pago', Icons.payment_outlined),
                          _Chips(
                            opciones: const ['Yape', 'Plin', 'Transferencia', 'Tarjeta'],
                            valor: _metodoPago,
                            onSelect: (v) => setState(() => _metodoPago = v),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ValueListenableBuilder<bool>(
                            valueListenable: _formValidoNotifier,
                            builder: (context, formValido, _) => Row(key: _botonKey, children: [
                              OutlinedButton(
                                onPressed: _registrando
                                    ? null
                                    : () => setState(() {
                                          _expandido   = false;
                                          _confirmando = false;
                                          _error       = null;
                                        }),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textMuted,
                                  side: const BorderSide(color: AppColors.primaryLight),
                                ),
                                child: const Text('Cancelar'),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: (!formValido || _registrando)
                                      ? null
                                      : () => setState(() => _confirmando = true),
                                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                  label: const Text('Revisar pedido'),
                                ),
                              ),
                            ]),
                          ),
                        ],
                      ),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

}

// ── Confirmación inline (reemplaza modal) ─────────────────────────────────────

class _ConfirmacionInline extends StatelessWidget {
  const _ConfirmacionInline({
    super.key,
    required this.comprador,
    required this.celular,
    required this.tipoEnvio,
    required this.direccion,
    required this.distrito,
    required this.metodoPago,
    required this.total,
    required this.botonKey,
    required this.registrando,
    required this.error,
    required this.onEditar,
    required this.onConfirmar,
  });
  final String      comprador;
  final String      celular;
  final String      tipoEnvio;
  final String      direccion;
  final String      distrito;
  final String      metodoPago;
  final double?     total;
  final GlobalKey   botonKey;
  final bool        registrando;
  final String?     error;
  final VoidCallback onEditar;
  final VoidCallback onConfirmar;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.receipt_long_rounded,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text('Confirma antes de registrar',
                  style: AppTextStyles.notasLabel
                      .copyWith(color: AppColors.primary, fontSize: 12)),
            ]),
            const SizedBox(height: AppSpacing.md),
            _ResumenFila('Cliente',   comprador),
            _ResumenFila('Celular',   celular),
            _ResumenFila('Envío',     tipoEnvio),
            _ResumenFila('Dirección', direccion),
            if (distrito.isNotEmpty) _ResumenFila('Distrito', distrito),
            _ResumenFila('Pago',      metodoPago),
            if (total != null) ...[
              const Divider(height: 20, color: AppColors.primaryLight),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TOTAL',
                      style: AppTextStyles.notasLabel
                          .copyWith(color: AppColors.textMuted)),
                  Text('S/ ${total!.toStringAsFixed(2)}',
                      style: AppTextStyles.price.copyWith(
                          color: AppColors.primaryDark, fontSize: 16)),
                ],
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Text(error!,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(key: botonKey, children: [
              OutlinedButton(
                onPressed: registrando ? null : onEditar,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  side: const BorderSide(color: AppColors.primaryLight),
                ),
                child: const Text('Editar'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: registrando ? null : onConfirmar,
                  icon: registrando
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_rounded, size: 16),
                  label: Text(registrando ? 'Registrando...' : 'Confirmar venta'),
                ),
              ),
            ]),
          ],
        ),
      );
}

// ── Tarjeta de éxito ──────────────────────────────────────────────────────────

class _CartaExito extends StatelessWidget {
  const _CartaExito({
    required this.idVenta,
    required this.idCotizacion,
    required this.comprador,
    required this.celular,
    required this.tipoEnvio,
    required this.direccion,
    required this.distrito,
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
  final String distrito;
  final String metodoPago;
  final String itemsStr;
  final double total;

  Future<void> _enviarComunidad() async {
    const sep = '────────────────────';
    final partes = itemsStr.split(' | ').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final lineas = partes.asMap().entries
        .map((e) => '  *${e.key + 1}.* 🌸 ${e.value}')
        .join('\n');
    final dirLinea = direccion.isNotEmpty ? '\n📍 *Dirección:* $direccion' : '';
    final distLinea = distrito.isNotEmpty ? '\n🗺️ *Distrito:* $distrito' : '';
    final texto =
        '📦 *Perfuteca — Pedido $idVenta*\n$sep\n'
        '👤 *Cliente:* $comprador\n📱 *Celular:* $celular\n'
        '🚚 *Envío:* $tipoEnvio$dirLinea$distLinea\n$sep\n'
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
          border: Border.all(color: AppColors.stockOk.withValues(alpha: 0.4)),
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
                    Text('¡Venta registrada! · $idVenta',
                        style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.stockOk)),
                    Text('Cotización $idCotizacion convertida',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted, fontSize: 10)),
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, this.icon);
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

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.capitalization = TextCapitalization.none,
  });
  final TextEditingController  controller;
  final String                 hint;
  final TextCapitalization     capitalization;

  @override
  Widget build(BuildContext context) => Semantics(
        label: hint,
        textField: true,
        child: TextField(
        controller:           controller,
        textCapitalization:   capitalization,
        decoration: InputDecoration(
          hintText:    hint,
          hintStyle:   AppTextStyles.bodySmall,
          filled:      true,
          fillColor:   AppColors.background,
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
      ),
    );
}

class _Chips extends StatelessWidget {
  const _Chips({
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
            final radius = BorderRadius.circular(AppSpacing.radiusSm);
            return Semantics(
              button: true,
              label: op,
              selected: sel,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : AppColors.surface,
                  borderRadius: radius,
                  border: Border.all(
                    color: sel ? AppColors.primary : AppColors.primaryLight,
                    width: sel ? 1.5 : 1,
                  ),
                ),
                child: InkWell(
                  onTap: () => onSelect(op),
                  borderRadius: radius,
                  splashColor: sel
                      ? AppColors.primaryDark.withValues(alpha: 0.25)
                      : AppColors.primaryLight,
                  highlightColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    child: Text(op,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            color: sel
                                ? AppColors.background
                                : AppColors.textSecondary)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
}

// ── Mini-resumen de la cotización (visible al expandir) ───────────────────────

class _MiniResumen extends StatelessWidget {
  const _MiniResumen({
    required this.lineas,
    required this.total,
  });
  final List<String>  lineas;
  final double?       total;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.primaryPale,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...lineas.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Icon(Icons.local_florist_outlined,
                            size: 11, color: AppColors.primary),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(l,
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                )),
            if (total != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text('Total · S/ ${total!.toStringAsFixed(2)}',
                    style: AppTextStyles.price.copyWith(
                        fontSize: 13, color: AppColors.primaryDark)),
              ),
            ],
          ],
        ),
      );
}

class _ResumenFila extends StatelessWidget {
  const _ResumenFila(this.label, this.valor);
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
// Formato en Sheets: "Perfume A 2ml S/10.00 | Perfume B 5ml S/25.00"

List<ItemCesta> _parsearCesta(String itemsStr, List<Perfume> catalogo, String metodoPago) {
  if (itemsStr.isEmpty) return [];
  final result  = <ItemCesta>[];
  final rx      = RegExp(r'^(.+?)\s+(\d+)ml\s+S/(\d+\.?\d*)$');
  final byExact = <String, Perfume>{for (final p in catalogo) p.nombre.toLowerCase(): p};

  for (final part in itemsStr.split(' | ')) {
    final m = rx.firstMatch(part.trim());
    if (m == null) continue;

    final nombre = m.group(1)!;
    final ml     = int.tryParse(m.group(2)!) ?? 0;
    final precio = double.tryParse(m.group(3)!) ?? 0.0;
    if (ml == 0) continue;

    final key = nombre.toLowerCase();
    Perfume? perfume = byExact[key];
    if (perfume == null) {
      for (final p in catalogo) {
        final pn = p.nombre.toLowerCase();
        if (pn.contains(key) || key.contains(pn)) { perfume = p; break; }
      }
    }
    if (perfume == null) continue;

    result.add(ItemCesta(
        perfume: perfume, ml: ml, precio: precio, metodo: metodoPago));
  }
  return result;
}

// ── Animación de entrada staggered ────────────────────────────────────────────

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
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide   = Tween(begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: (widget.index * 40).clamp(0, 320)), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _opacity,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

// ── Shimmer de carga ──────────────────────────────────────────────────────────

class _CotizacionesShimmer extends StatelessWidget {
  const _CotizacionesShimmer();

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor:      AppColors.primaryLight,
        highlightColor: AppColors.primaryPale,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 80),
          itemCount: 5,
          itemBuilder: (_, i) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            height: i == 0 ? 64 : 88,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/features/ventas/providers/ventas_provider.dart';
import 'package:perfuteca/models/cotizacion.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/models/venta.dart';
import 'package:perfuteca/repositories/cotizaciones_repository.dart';
import 'package:perfuteca/repositories/ventas_repository.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';

// ── Provider: cotizaciones registradas hoy ────────────────────────────────────

final cotizacionesHoyProvider =
    FutureProvider.autoDispose<List<CotizacionResponse>>((ref) async {
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final page  = await ref.read(cotizacionesRepositoryProvider)
      .getCotizaciones(limit: 100);
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
      loading: () => const Center(child: CircularProgressIndicator()),
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
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 80),
                itemCount: lista.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Row(children: [
                        const Icon(Icons.today_rounded,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          '${lista.length} cotización${lista.length != 1 ? 'es' : ''} hoy — toca para convertir',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ]),
                    );
                  }
                  final c = lista[i - 1];
                  return _CotizacionCard(
                    key: ValueKey(c.idCotizacion),
                    cotizacion: c,
                  );
                },
              ),
            ),
    );
  }
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
            const SizedBox(height: 16),
            Text('Sin cotizaciones hoy',
                style:
                    AppTextStyles.body.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 6),
            Text(
              'Crea una cotización en la pestaña Cotización',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textFaint),
            ),
            const SizedBox(height: 24),
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
      _direccionCtrl.text.trim().isNotEmpty &&
      _tipoEnvio.isNotEmpty;

  Future<void> _registrar() async {
    final catalogo = ref.read(catalogoProvider).perfumes;
    final cesta    = _parsearCesta(widget.cotizacion.items ?? '', catalogo);

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
          idCotizacion: widget.cotizacion.idCotizacion,
          nuevoEstado:  'Aceptado',
        );
      } catch (_) {}
      // Bloquear re-apertura en sesión aunque el backend no responda
      ref.read(_cotizacionesAceptadasProvider.notifier)
          .update((s) => {...s, widget.cotizacion.idCotizacion});
    } catch (e) {
      setState(() { _registrando = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final aceptadas  = ref.watch(_cotizacionesAceptadasProvider);
    final esAceptada = aceptadas.contains(widget.cotizacion.idCotizacion) ||
        widget.cotizacion.estado?.toLowerCase() == 'aceptado';

    if (_exito) {
      return _CartaExito(
        idVenta:      _idVenta ?? '',
        idCotizacion: widget.cotizacion.idCotizacion,
        comprador:    _compradorCtrl.text.trim(),
        celular:      widget.cotizacion.celular,
        tipoEnvio:    _tipoEnvio,
        direccion:    _direccionCtrl.text.trim(),
        metodoPago:   _metodoPago,
        itemsStr:     widget.cotizacion.items ?? '',
        total:        widget.cotizacion.total ?? 0,
      );
    }

    final lineas = _splitLineas(widget.cotizacion.items ?? '');

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
            // ── Cabecera (siempre visible, tappeable) ───────────────────
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
                        const SizedBox(width: 3),
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
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _expandido ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 20, color: AppColors.textMuted),
                      ),
                    ]),
                    // Perfumes de la cotización
                    if (lineas.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ...lineas.map((l) => Padding(
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
                      const SizedBox(height: 8),
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

            // ── Formulario expandible ───────────────────────────────────
            if (_expandido) ...[
              const Divider(height: 1, color: AppColors.primaryLight),
              const SizedBox(height: AppSpacing.sm),
              _MiniResumen(
                lineas: lineas,
                total:  widget.cotizacion.total,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1, color: AppColors.primaryLight),
              if (esAceptada)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(AppSpacing.md),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.stockOk.withValues(alpha: 0.08),
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
              Padding(
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
                              color: AppColors.primary, fontSize: 10)),
                    ]),
                    const SizedBox(height: AppSpacing.md),

                    _FieldLabel('Nombre del comprador',
                        Icons.person_outline_rounded),
                    _Field(
                      controller: _compradorCtrl,
                      hint: 'Nombre completo',
                      capitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                    ),

                    _FieldLabel('Dirección de entrega',
                        Icons.location_on_outlined),
                    _Field(
                      controller: _direccionCtrl,
                      hint: 'Jr. Los Jardines 123',
                      capitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                    ),

                    _FieldLabel('Tipo de envío',
                        Icons.local_shipping_outlined),
                    _Chips(
                      opciones: const ['Shalom', 'Motorizado', 'Contraentrega'],
                      valor: _tipoEnvio,
                      onSelect: (v) => setState(() => _tipoEnvio = v),
                    ),

                    _FieldLabel('Método de pago', Icons.payment_outlined),
                    _Chips(
                      opciones: const ['Yape', 'Plin', 'Transferencia', 'Tarjeta'],
                      valor: _metodoPago,
                      onSelect: (v) => setState(() => _metodoPago = v),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.07),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3)),
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
                            : () => setState(
                                () { _expandido = false; _error = null; }),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textMuted,
                          side: const BorderSide(color: AppColors.primaryLight),
                        ),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: (!_formValido || _registrando)
                              ? null
                              : () async {
                                  final confirmar = await showDialog<bool>(
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
                                          _ResumenFila('Cliente',
                                              _compradorCtrl.text.trim()),
                                          _ResumenFila('Celular',
                                              widget.cotizacion.celular),
                                          _ResumenFila(
                                              'Envío', _tipoEnvio),
                                          _ResumenFila(
                                              'Dirección',
                                              _direccionCtrl.text.trim()),
                                          _ResumenFila(
                                              'Pago', _metodoPago),
                                          if (widget.cotizacion.total !=
                                              null) ...[
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
                                                  'S/ ${widget.cotizacion.total!.toStringAsFixed(2)}',
                                                  style: AppTextStyles.price
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
                                          child: const Text('Guardar venta'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmar == true) _registrar();
                                },
                          icon: _registrando
                              ? const SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_circle_rounded, size: 16),
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

  List<String> _splitLineas(String items) => items
      .split(' | ')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
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
          color: AppColors.stockOk.withValues(alpha: 0.08),
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
                    Text('¡Venta registrada!  $idVenta',
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
                  backgroundColor: const Color(0xFF25D366),
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
    this.onChanged,
    this.capitalization = TextCapitalization.none,
  });
  final TextEditingController  controller;
  final String                 hint;
  final ValueChanged<String>?  onChanged;
  final TextCapitalization     capitalization;

  @override
  Widget build(BuildContext context) => TextField(
        controller:           controller,
        textCapitalization:   capitalization,
        onChanged:            onChanged,
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
            return GestureDetector(
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
                child: Text('Total  S/ ${total!.toStringAsFixed(2)}',
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

List<ItemCesta> _parsearCesta(String itemsStr, List<Perfume> catalogo) {
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
    result.add(ItemCesta(
        perfume: perfume, ml: ml, precio: precio, metodo: 'Yape'));
  }
  return result;
}

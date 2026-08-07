// Card compartida para convertir una cotización en venta — usada por
// CotizacionesTab (Estadísticas) y CotizacionesHoyScreen (Ventas › Hoy).
// Antes vivía duplicada en ambos archivos; cada bug de frescura/race había
// que arreglarlo dos veces. Vive aquí para que ambas pantallas compartan
// exactamente la misma lógica de registro.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:perfuteca/core/utils/validators.dart';
import 'package:perfuteca/core/utils/whatsapp_launcher.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/features/estadisticas/providers/estadisticas_provider.dart';
import 'package:perfuteca/features/ventas/providers/ventas_provider.dart';
import 'package:perfuteca/features/ventas/screens/cotizaciones_hoy_screen.dart'
    show cotizacionesHoyProvider;
import 'package:perfuteca/features/estadisticas/screens/cotizaciones_tab.dart'
    show cotizaciones14dProvider;
import 'package:perfuteca/models/cotizacion.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/models/venta.dart';
import 'package:perfuteca/repositories/cotizaciones_repository.dart';
import 'package:perfuteca/repositories/ventas_repository.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';

// IDs de cotizaciones convertidas en esta sesión — bloquea re-apertura
// aunque la API de estado falle, y es la misma fuente para ambas pantallas.
final cotizacionesAceptadasSesionProvider =
    StateProvider<Set<String>>((ref) => const {});

// Quita un '@' inicial si el usuario lo tipeó al guardar el alias — evita
// mostrar '@@alias' cuando se le antepone el ícono/prefijo '@' en UI.
String _sinArroba(String alias) =>
    alias.startsWith('@') ? alias.substring(1) : alias;

class CotizacionConvertirCard extends ConsumerStatefulWidget {
  const CotizacionConvertirCard({super.key, required this.cotizacion});
  final CotizacionResponse cotizacion;

  @override
  ConsumerState<CotizacionConvertirCard> createState() =>
      _CotizacionConvertirCardState();
}

class _CotizacionConvertirCardState
    extends ConsumerState<CotizacionConvertirCard> {
  bool    _expandido       = false;
  bool    _registrando     = false;
  bool    _buscandoCliente = false;
  bool    _exito           = false;
  bool    _clienteNuevo    = false;
  bool    _confirmando     = false;
  bool    _sincronizando   = false;
  bool    _estadoSincOk    = true;
  String?          _error;
  String?          _idVenta;
  List<ItemCesta>  _cestaRegistrada = [];

  final _compradorCtrl     = TextEditingController();
  final _direccionCtrl     = TextEditingController();
  final _distritoCtrl      = TextEditingController();
  // Solo se usa cuando la cotización se guardó con alias y sin celular —
  // la venta requiere celular, así que se pide aquí antes de registrar.
  final _celularNuevoCtrl  = TextEditingController();
  final _botonKey        = GlobalKey();
  // Key separada del formulario: comparten el mismo AnimatedSwitcher y
  // durante el crossfade ambos Row pueden estar montados a la vez —
  // reusar _botonKey en los dos causaba "Multiple widgets used the same
  // GlobalKey" al tocar Revisar pedido/Editar.
  final _botonConfirmKey = GlobalKey();
  late final ValueNotifier<bool> _formValidoNotifier;
  late final List<String> _lineas;
  String _tipoEnvio  = '';
  String _metodoPago = 'Yape';

  // Si la cotización ya tenía celular, se usa tal cual. Si no (se guardó
  // solo con alias), se usa el que el usuario llena en el campo nuevo.
  bool get _requiereCelularNuevo => widget.cotizacion.celular.isEmpty;
  String get _celularResuelto => widget.cotizacion.celular.isNotEmpty
      ? widget.cotizacion.celular
      : _celularNuevoCtrl.text.trim();

  // Para mostrar en el header: celular si existe, si no el alias, si no vacío.
  // _sinArroba evita '@@alias' si el usuario ya tipeó el '@' al guardar.
  String get _identificadorMostrado => widget.cotizacion.celular.isNotEmpty
      ? widget.cotizacion.celular
      : ((widget.cotizacion.alias ?? '').isNotEmpty
          ? '@${_sinArroba(widget.cotizacion.alias!)}'
          : '');

  @override
  void initState() {
    super.initState();
    _lineas = (widget.cotizacion.items ?? '')
        .split(' | ')
        .map((s) => _quitarIdTag(s.trim()))
        .where((s) => s.isNotEmpty)
        .toList();
    _formValidoNotifier = ValueNotifier<bool>(false);
    _compradorCtrl.addListener(_checkForm);
    _direccionCtrl.addListener(_checkForm);
    _distritoCtrl.addListener(_checkForm);
    _celularNuevoCtrl.addListener(_checkForm);
  }

  void _checkForm() {
    final celularOk = !_requiereCelularNuevo ||
        esCelularPeruValido(_celularNuevoCtrl.text);
    _formValidoNotifier.value =
        _compradorCtrl.text.trim().isNotEmpty &&
        _direccionCtrl.text.trim().isNotEmpty &&
        _tipoEnvio.isNotEmpty &&
        celularOk;
  }

  @override
  void dispose() {
    _compradorCtrl.dispose();
    _direccionCtrl.dispose();
    _distritoCtrl.dispose();
    _celularNuevoCtrl.dispose();
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
        // _tipoEnvio no es un TextEditingController — su cambio arriba no
        // dispara los listeners que llaman _checkForm(). Sin esto, el botón
        // "Revisar pedido" puede quedar deshabilitado aunque el formulario
        // ya esté completo tras el autocompletado.
        _checkForm();
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
    setState(() { _registrando = true; _error = null; });
    // catalogoProvider pagina de a 50 — leer su estado actual sin más no
    // garantiza tener el catálogo completo (ej. si el usuario entró directo
    // a esta pantalla sin pasar antes por "Nueva cotización", que es quien
    // normalmente dispara loadAll()). Forzamos carga completa aquí para que
    // el matching de perfumes no falle silenciosamente por catálogo a medias.
    await ref.read(catalogoProvider.notifier).loadAll();
    final catalogo  = ref.read(catalogoProvider).perfumes;
    final parseada  = _parsearCesta(widget.cotizacion.items ?? '', catalogo, _metodoPago);
    final cesta     = parseada.items;

    if (cesta.isEmpty) {
      if (!mounted) return;
      setState(() {
        _registrando = false;
        _error = 'No se pudieron reconocer los perfumes de esta cotización';
      });
      return;
    }
    // No registrar una venta incompleta en silencio: si algún ítem del texto
    // original no matcheó a un perfume del catálogo, es mejor bloquear y
    // avisar que descontar stock solo de una parte del pedido.
    if (!parseada.completa) {
      if (!mounted) return;
      setState(() {
        _registrando = false;
        _error = 'No se pudieron reconocer todos los perfumes de esta cotización '
            '(${parseada.fallos} de ${cesta.length + parseada.fallos}). '
            'Revisa que el catálogo tenga esos perfumes antes de registrar la venta.';
      });
      return;
    }

    try {
      final registrada =
          await ref.read(ventasRepositoryProvider).registrarVenta(
        comprador: _compradorCtrl.text.trim(),
        celular:   _celularResuelto,
        alias:     widget.cotizacion.alias,
        direccion: _direccionCtrl.text.trim(),
        distrito:  _distritoCtrl.text.trim(),
        tipoEnvio: _tipoEnvio,
        fecha:     DateFormat('yyyy-MM-dd').format(DateTime.now()),
        items: cesta.map((i) => i.toApiMap()).toList(),
      );
      ref.read(catalogoProvider.notifier).load();
      if (!mounted) return;
      setState(() {
        _registrando     = false;
        _exito           = true;
        _idVenta         = registrada.idCompra;
        _cestaRegistrada = cesta;
      });
      // Marcar 'Aceptada' ANTES de invalidar las listas de cotizaciones — si
      // se invalida primero, el refetch puede llegar antes que este PUT
      // termine y traer la cotización todavía como 'Enviado'.
      await _sincronizarEstado();
      ref.invalidate(historialProvider);
      ref.invalidate(pendientesProvider);
      ref.invalidate(cotizacionesHoyProvider);
      ref.invalidate(cotizaciones14dProvider);
      ref.invalidate(resumenBackendProvider);
      ref.invalidate(resumenStatsProvider);
      ref.invalidate(semanaStatsProvider);
      ref.invalidate(ventasParaStatsProvider);
      ref.invalidate(tamaniosStatsProvider);
      ref.invalidate(clientesStatsProvider);
      ref.invalidate(historicoBackendProvider);
      ref.invalidate(historialGlobalProvider);
    } catch (e) {
      if (!mounted) return;
      setState(
          () { _registrando = false; _error = e.toString(); _confirmando = false; });
    }
  }

  Future<void> _sincronizarEstado() async {
    if (!mounted) return;
    setState(() { _sincronizando = true; });
    try {
      await ref.read(cotizacionesRepositoryProvider).actualizarEstado(
        idCotizacion: widget.cotizacion.idCotizacion,
        nuevoEstado:  'Aceptada',
      );
      ref
          .read(cotizacionesAceptadasSesionProvider.notifier)
          .update((s) => {...s, widget.cotizacion.idCotizacion});
      if (mounted) setState(() { _sincronizando = false; _estadoSincOk = true; });
    } catch (_) {
      if (mounted) setState(() { _sincronizando = false; _estadoSincOk = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final esAceptada =
        ref.watch(cotizacionesAceptadasSesionProvider
                .select((s) => s.contains(widget.cotizacion.idCotizacion))) ||
            widget.cotizacion.estado?.toLowerCase().startsWith('aceptad') ==
                true;

    if (_exito) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, v, child) => Opacity(opacity: v, child: child),
        child: _CartaExito(
          idVenta:      _idVenta ?? '',
          idCotizacion: widget.cotizacion.idCotizacion,
          comprador:    _compradorCtrl.text.trim(),
          celular:      _celularResuelto,
          tipoEnvio:    _tipoEnvio,
          direccion:    _direccionCtrl.text.trim(),
          distrito:     _distritoCtrl.text.trim(),
          metodoPago:   _metodoPago,
          itemsStr:     widget.cotizacion.items ?? '',
          cesta:        _cestaRegistrada,
          total:        widget.cotizacion.total ?? 0,
          sincronizando: _sincronizando,
          estadoSincOk:  _estadoSincOk,
          onReintentarSinc: _sincronizarEstado,
        ),
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: esAceptada && !_expandido
              ? AppColors.successSurface
              : AppColors.surface,
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
                  : 'Cotización ${widget.cotizacion.idCotizacion} · $_identificadorMostrado · S/${widget.cotizacion.total?.toStringAsFixed(2) ?? '0'}. Toca para convertir a venta.',
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
                        // Celular o alias — lo que se haya guardado
                        if (widget.cotizacion.celular.isNotEmpty) ...[
                          const Icon(Icons.phone_outlined,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: AppSpacing.xs),
                          Text(widget.cotizacion.celular,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textSecondary)),
                        ] else if ((widget.cotizacion.alias ?? '').isNotEmpty) ...[
                          const Icon(Icons.alternate_email_rounded,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: AppSpacing.xs),
                          Text(widget.cotizacion.alias!,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textSecondary)),
                        ],
                        const Spacer(),
                        EstadoPill(aceptada: esAceptada),
                      ]),
                      const SizedBox(height: AppSpacing.xs + 2),
                      Row(children: [
                        const Spacer(),
                        // Total
                        if (widget.cotizacion.total != null)
                          Text(
                            'S/ ${widget.cotizacion.total!.toStringAsFixed(2)}',
                            style: AppTextStyles.price.copyWith(
                                fontSize: 14, color: AppColors.primaryDark),
                          ),
                        const SizedBox(width: AppSpacing.xs),
                        if (!esAceptada)
                          AnimatedRotation(
                            turns: _expandido ? 0.5 : 0,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 20,
                                color: AppColors.textMuted),
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
                      if (!_expandido && !esAceptada) ...[
                        const SizedBox(height: AppSpacing.sm),
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
              _MiniResumen(lineas: _lineas, total: widget.cotizacion.total),
              if (!_buscandoCliente && _clienteNuevo) ...[
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md),
                  child: Row(children: [
                    const Icon(Icons.person_add_outlined,
                        size: 13, color: AppColors.gold),
                    const SizedBox(width: AppSpacing.xs + 1),
                    Text('Cliente nuevo · llena los datos',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        )),
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
                          comprador:   _compradorCtrl.text.trim(),
                          celular:     _celularResuelto,
                          tipoEnvio:   _tipoEnvio,
                          direccion:   _direccionCtrl.text.trim(),
                          distrito:    _distritoCtrl.text.trim(),
                          metodoPago:  _metodoPago,
                          total:       widget.cotizacion.total,
                          botonKey:    _botonConfirmKey,
                          registrando: _registrando,
                          error:       _error,
                          onEditar:    () => setState(() => _confirmando = false),
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
                              if (_requiereCelularNuevo) ...[
                                const _FieldLabel(
                                    'Celular del cliente',
                                    Icons.phone_outlined),
                                _Field(
                                  controller: _celularNuevoCtrl,
                                  hint: '987654321',
                                  keyboardType: TextInputType.phone,
                                  maxLength: 9,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                              ],
                              const _FieldLabel(
                                  'Nombre del comprador',
                                  Icons.person_outline_rounded),
                              _Field(
                                controller: _compradorCtrl,
                                hint: 'Nombre completo',
                                capitalization: TextCapitalization.words,
                              ),
                              const _FieldLabel(
                                  'Dirección de entrega',
                                  Icons.location_on_outlined),
                              _Field(
                                controller: _direccionCtrl,
                                hint: 'Jr. Los Jardines 123',
                                capitalization: TextCapitalization.words,
                              ),
                              const _FieldLabel(
                                  'Distrito/Provincia', Icons.map_outlined),
                              _Field(
                                controller: _distritoCtrl,
                                hint: 'Ej: Lima, Arequipa',
                                capitalization: TextCapitalization.words,
                              ),
                              const _FieldLabel(
                                  'Tipo de envío',
                                  Icons.local_shipping_outlined),
                              Chips(
                                opciones: const ['Shalom', 'Motorizado'],
                                valor: _tipoEnvio,
                                onSelect: (v) {
                                  setState(() => _tipoEnvio = v);
                                  _checkForm();
                                },
                              ),
                              const _FieldLabel(
                                  'Método de pago', Icons.payment_outlined),
                              Chips(
                                opciones: const [
                                  'Yape', 'Plin', 'Transferencia', 'Tarjeta'
                                ],
                                valor: _metodoPago,
                                onSelect: (v) =>
                                    setState(() => _metodoPago = v),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              ValueListenableBuilder<bool>(
                                valueListenable: _formValidoNotifier,
                                builder: (context, formValido, _) =>
                                    Row(key: _botonKey, children: [
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
                                      side: const BorderSide(
                                          color: AppColors.primaryLight),
                                    ),
                                    child: const Text('Cancelar'),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: BotonRevisarPedido(
                                      habilitado: formValido && !_registrando,
                                      onPressed: () =>
                                          setState(() => _confirmando = true),
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

// ── Confirmación inline ───────────────────────────────────────────────────────

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
            ResumenFila('Cliente',   comprador),
            ResumenFila('Celular',   celular),
            ResumenFila('Envío',     tipoEnvio),
            ResumenFila('Dirección', direccion),
            if (distrito.isNotEmpty) ResumenFila('Distrito', distrito),
            ResumenFila('Pago',      metodoPago),
            if (total != null) ...[
              const Divider(height: 20, color: AppColors.primaryLight),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TOTAL',
                      style: AppTextStyles.notasLabel
                          .copyWith(color: AppColors.textMuted)),
                  Text('S/ ${total!.toStringAsFixed(2)}',
                      style: AppTextStyles.price
                          .copyWith(color: AppColors.primaryDark, fontSize: 16)),
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
                  border:
                      Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Text(error!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.error)),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(key: botonKey, children: [
              OutlinedButton(
                onPressed: registrando ? null : onEditar,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  side:
                      const BorderSide(color: AppColors.primaryLight),
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
                  label:
                      Text(registrando ? 'Registrando...' : 'Confirmar venta'),
                ),
              ),
            ]),
          ],
        ),
      );
}

// ── Carta de éxito ────────────────────────────────────────────────────────────

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
    required this.cesta,
    required this.total,
    required this.sincronizando,
    required this.estadoSincOk,
    required this.onReintentarSinc,
  });
  final String         idVenta;
  final String         idCotizacion;
  final String         comprador;
  final String         celular;
  final String         tipoEnvio;
  final String         direccion;
  final String         distrito;
  final String         metodoPago;
  final String         itemsStr;
  final List<ItemCesta> cesta;
  final double         total;
  final bool           sincronizando;
  final bool           estadoSincOk;
  final Future<void> Function() onReintentarSinc;

  Future<void> _enviarComunidad() async {
    const sep = '────────────────────';
    final itemsLineas = cesta.asMap().entries.map((entry) {
      final idx  = entry.key + 1;
      final item = entry.value;
      return '  *$idx.* *${item.perfume.marca} — ${item.perfume.nombre}* ${item.ml}ml — S/ ${item.precio.toStringAsFixed(2)}';
    }).join('\n');
    final dirLinea  = direccion.isNotEmpty ? '\n📍 *Dirección:* $direccion' : '';
    final distLinea = distrito.isNotEmpty  ? '\n🗺️ *Distrito:* $distrito'  : '';
    final texto =
        '📦 *Perfuteca — Pedido $idVenta*\n$sep\n'
        '👤 *Cliente:* $comprador\n📱 *Celular:* $celular\n'
        '🚚 *Envío:* $tipoEnvio$dirLinea$distLinea\n$sep\n'
        '🌸 *Perfumes:*\n$itemsLineas\n$sep\n'
        '💰 *Total: S/ ${total.toStringAsFixed(2)}*\n'
        '💳 *Pago:* $metodoPago';
    await abrirWhatsAppBusiness(mensaje: texto);
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
                    Text('¡Venta registrada! · $idVenta',
                        style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.stockOk)),
                    Text('Cotización $idCotizacion convertida',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ]),
            if (sincronizando) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(children: [
                const SizedBox(
                  width: 13, height: 13,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.textMuted),
                ),
                const SizedBox(width: 6),
                Text('Marcando cotización como aceptada...',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textMuted, fontSize: 11)),
              ]),
            ] else if (!estadoSincOk) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 14, color: AppColors.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Venta OK, pero no se pudo marcar $idCotizacion como aceptada.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.error, fontSize: 11),
                    ),
                  ),
                  TextButton(
                    onPressed: onReintentarSinc,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Reintentar', style: TextStyle(fontSize: 11)),
                  ),
                ]),
              ),
            ],
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

// ── Widgets de formulario ─────────────────────────────────────────────────────

// ── Botón "Revisar pedido" con micro-shift de ícono en press ─────────────────

class BotonRevisarPedido extends StatefulWidget {
  const BotonRevisarPedido({
    super.key,
    required this.habilitado,
    required this.onPressed,
  });
  final bool         habilitado;
  final VoidCallback onPressed;

  @override
  State<BotonRevisarPedido> createState() => _BotonRevisarPedidoState();
}

class _BotonRevisarPedidoState extends State<BotonRevisarPedido> {
  bool _presionando = false;

  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: widget.habilitado ? widget.onPressed : null,
        style: FilledButton.styleFrom(padding: EdgeInsets.zero),
        child: Listener(
          onPointerDown: (_) => setState(() => _presionando = true),
          onPointerUp: (_) => setState(() => _presionando = false),
          onPointerCancel: (_) => setState(() => _presionando = false),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Revisar pedido'),
                const SizedBox(width: 6),
                AnimatedSlide(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOutCubic,
                  offset: _presionando ? const Offset(0.3, 0) : Offset.zero,
                  child: const Icon(Icons.arrow_forward_rounded, size: 16),
                ),
              ],
            ),
          ),
        ),
      );
}

// ── Pill de estado (esperando / aceptada) ─────────────────────────────────────

class EstadoPill extends StatelessWidget {
  const EstadoPill({super.key, required this.aceptada});
  final bool aceptada;

  @override
  Widget build(BuildContext context) {
    final color      = aceptada ? AppColors.stockOk : AppColors.gold;
    final background = aceptada ? AppColors.successSurface : AppColors.goldLight;
    final icon       = aceptada ? Icons.check_circle_rounded : Icons.schedule_rounded;
    final label       = aceptada ? 'Aceptada' : 'Esperando';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.priceLabel.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    this.keyboardType,
    this.maxLength,
    this.inputFormatters,
  });
  final TextEditingController controller;
  final String                hint;
  final TextCapitalization    capitalization;
  final TextInputType?              keyboardType;
  final int?                        maxLength;
  final List<TextInputFormatter>?   inputFormatters;

  @override
  Widget build(BuildContext context) => Semantics(
        label: hint,
        textField: true,
        child: TextField(
          controller:         controller,
          textCapitalization: capitalization,
          keyboardType:       keyboardType,
          maxLength:          maxLength,
          inputFormatters:    inputFormatters,
          decoration: InputDecoration(
            counterText: maxLength != null ? '' : null,
            hintText:  hint,
            hintStyle: AppTextStyles.bodySmall,
            filled:    true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide:
                  const BorderSide(color: AppColors.primaryLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide:
                  const BorderSide(color: AppColors.primaryLight),
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

class Chips extends StatefulWidget {
  const Chips({
    super.key,
    required this.opciones,
    required this.valor,
    required this.onSelect,
  });
  final List<String>         opciones;
  final String               valor;
  final ValueChanged<String> onSelect;

  @override
  State<Chips> createState() => _ChipsState();
}

class _ChipsState extends State<Chips> {
  String? _pulsando;

  void _onTap(String op) {
    setState(() => _pulsando = op);
    widget.onSelect(op);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _pulsando = null);
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: widget.opciones.map((op) {
            final sel    = widget.valor == op;
            final radius = BorderRadius.circular(AppSpacing.radiusSm);
            return Semantics(
              button: true,
              label: op,
              selected: sel,
              child: TweenAnimationBuilder<double>(
                tween: Tween(
                    begin: 1.0, end: _pulsando == op ? 1.08 : 1.0),
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
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
                    onTap: () => _onTap(op),
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
                              fontSize:   12,
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: sel
                                  ? AppColors.background
                                  : AppColors.textSecondary)),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
}

class _MiniResumen extends StatelessWidget {
  const _MiniResumen({required this.lineas, required this.total});
  final List<String> lineas;
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

class ResumenFila extends StatelessWidget {
  const ResumenFila(this.label, this.valor, {super.key});
  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 76,
              child: Text(
                label.toUpperCase(),
                style: AppTextStyles.notasLabel.copyWith(
                  color: AppColors.textFaint,
                  letterSpacing: 0.6,
                  fontSize: 10,
                ),
              ),
            ),
            Expanded(
              child: Text(
                valor.isNotEmpty ? valor : '—',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
}

// ── Parser: items string → List<ItemCesta> ────────────────────────────────────
// Formato en Sheets: "Perfume A 2ml S/10.00 [#P001] | Perfume B 5ml S/25.00 [#P002]"
// El sufijo "[#ID]" es el ID_Perfume real — permite ubicar el perfume exacto
// sin adivinar por nombre. Cotizaciones guardadas antes de este fix no lo
// traen; para esas se cae al matching por nombre como antes (mejor esfuerzo).
final _rxIdTag = RegExp(r'\s*\[#(.+?)\]$');
final _rxItem  = RegExp(r'^(.+?)\s+(\d+)ml\s+S/(\d+\.?\d*)(?:\s*\[#(.+?)\])?$');

String _quitarIdTag(String linea) => linea.replaceFirst(_rxIdTag, '');

/// Resultado de parsear una cotización a carrito: la cesta reconocida y
/// cuántas líneas del texto original NO se pudieron matchear a un perfume.
/// [fallos] > 0 es señal de que la cesta está incompleta y NO debe usarse
/// para registrar una venta silenciosamente.
class CestaParseada {
  const CestaParseada(this.items, this.fallos);
  final List<ItemCesta> items;
  final int fallos;
  bool get completa => fallos == 0;
}

CestaParseada _parsearCesta(
    String itemsStr, List<Perfume> catalogo, String metodoPago) {
  if (itemsStr.isEmpty) return const CestaParseada([], 0);
  final result = <ItemCesta>[];
  var fallos   = 0;

  final byId = <String, Perfume>{
    for (final p in catalogo) p.idPerfume: p
  };
  // El texto guardado combina "{marca} {nombre}" — la clave exacta debe
  // reflejar eso, no solo el nombre solo (si no, el match exacto nunca
  // sucede y todo cae al fallback por substring).
  final byMarcaNombre = <String, Perfume>{
    for (final p in catalogo) '${p.marca} ${p.nombre}'.toLowerCase(): p
  };
  final byNombre = <String, List<Perfume>>{};
  for (final p in catalogo) {
    byNombre.putIfAbsent(p.nombre.toLowerCase(), () => []).add(p);
  }

  for (final part in itemsStr.split(' | ')) {
    final m = _rxItem.firstMatch(part.trim());
    if (m == null) { fallos++; continue; }

    final nombre = m.group(1)!;
    final ml     = int.tryParse(m.group(2)!) ?? 0;
    final precio = double.tryParse(m.group(3)!) ?? 0.0;
    final idTag  = m.group(4);
    if (ml == 0) { fallos++; continue; }

    // 1) ID embebido — exacto, no ambiguo, no importa el tamaño del catálogo.
    Perfume? perfume = idTag != null ? byId[idTag] : null;

    // 2) Legado sin ID: exacto por "marca nombre" completo.
    perfume ??= byMarcaNombre[nombre.toLowerCase()];

    // 3) Exacto por nombre solo, pero SOLO si es único en el catálogo —
    //    si dos perfumes comparten nombre (distinta marca), es ambiguo:
    //    mejor fallar que adivinar y descontar stock del que no es.
    if (perfume == null) {
      final candidatos = byNombre[nombre.toLowerCase()];
      if (candidatos != null && candidatos.length == 1) perfume = candidatos.first;
    }

    // 4) Último recurso, substring — solo si hay EXACTAMENTE un candidato
    //    ambiguo; con más de uno, no se adivina.
    if (perfume == null) {
      final key = nombre.toLowerCase();
      final candidatos = catalogo.where((p) {
        final pn = p.nombre.toLowerCase();
        return pn.contains(key) || key.contains(pn);
      }).toList();
      if (candidatos.length == 1) perfume = candidatos.first;
    }

    if (perfume == null) { fallos++; continue; }

    result.add(ItemCesta(
        perfume: perfume, ml: ml, precio: precio, metodo: metodoPago));
  }
  return CestaParseada(result, fallos);
}

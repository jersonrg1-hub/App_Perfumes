import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:perfuteca/core/utils/whatsapp_launcher.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/features/estadisticas/providers/estadisticas_provider.dart';
import 'package:perfuteca/features/ventas/providers/nueva_venta_provider.dart';
import 'package:perfuteca/features/ventas/providers/ventas_provider.dart';
import 'package:perfuteca/features/ventas/widgets/item_cesta_card.dart';
import 'package:perfuteca/models/app_config_model.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/models/venta.dart';
import 'package:perfuteca/repositories/config_repository.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';

class NuevaVentaScreen extends ConsumerStatefulWidget {
  const NuevaVentaScreen({super.key});
  @override
  ConsumerState<NuevaVentaScreen> createState() => _NuevaVentaScreenState();
}

class _NuevaVentaScreenState extends ConsumerState<NuevaVentaScreen> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _irA(int paso) {
    ref.read(nuevaVentaProvider.notifier).irPaso(paso);
    _pageController.animateToPage(
      paso - 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    // select() — rebuild solo cuando cambia paso o ventaRegistrada,
    // no en cada cambio de cesta/campos del wizard.
    final paso            = ref.watch(nuevaVentaProvider.select((s) => s.paso));
    final ventaRegistrada = ref.watch(nuevaVentaProvider.select((s) => s.ventaRegistrada));

    ref.listen(
      nuevaVentaProvider.select((s) => s.paso),
      (prev, next) {
        if (next == 1 && prev != null && prev > 1 &&
            _pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      },
    );

    ref.listen(
      nuevaVentaProvider.select((s) => s.ventaRegistrada),
      (prev, next) {
        if (prev == null && next != null) {
          ref.read(catalogoProvider.notifier).load();
          // Frescura: invalida listas de ventas para que el nuevo pedido aparezca de inmediato
          ref.invalidate(pendientesProvider);
          ref.invalidate(historialProvider);
          ref.invalidate(ventasParaStatsProvider);
          // Stats del dashboard
          ref.invalidate(resumenBackendProvider);
          ref.invalidate(resumenStatsProvider);
          ref.invalidate(semanaStatsProvider);
          ref.invalidate(tamaniosStatsProvider);
          ref.invalidate(clientesStatsProvider);
        }
      },
    );

    if (ventaRegistrada != null) {
      // ref.read — snapshot estático, ventaRegistrada ya no cambia aquí
      final state = ref.read(nuevaVentaProvider);
      return TweenAnimationBuilder<double>(
        key: const ValueKey('ticket_exito'),
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        builder: (context, v, child) => Opacity(
          opacity: v,
          child: Transform.scale(scale: 0.94 + 0.06 * v, child: child),
        ),
        child: _TicketExito(
          idCompra:   ventaRegistrada.idCompra,
          warning:    ventaRegistrada.warning,
          celular:    state.celular,
          alias:      state.alias,
          comprador:  state.comprador,
          tipoEnvio:  state.tipoEnvio,
          direccion:  state.direccion,
          metodoPago: state.metodoPago,
          total:      state.total,
          cesta:      state.cesta,
          onNueva: () {
            ref.read(nuevaVentaProvider.notifier).reset();
            ref.invalidate(historialProvider);
            ref.invalidate(pendientesProvider);
            ref.invalidate(ventasParaStatsProvider);
            _pageController.jumpToPage(0);
          },
        ),
      );
    }

    return Column(
      children: [
        _StepIndicator(pasoActual: paso),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _Paso1(onSiguiente: () => _irA(2)),
              _Paso2(onAnterior: () => _irA(1), onSiguiente: () => _irA(3)),
              _Paso3(onAnterior: () => _irA(2)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Indicador de pasos ────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.pasoActual});
  final int pasoActual;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.md),
      child: Semantics(
        label: 'Paso $pasoActual de 3',
        child: Row(
          children: [
            _StepDot(n: 1, estado: _estadoPaso(1), label: 'Cliente'),
            _StepLine(activo: pasoActual >= 2),
            _StepDot(n: 2, estado: _estadoPaso(2), label: 'Cesta'),
            _StepLine(activo: pasoActual >= 3),
            _StepDot(n: 3, estado: _estadoPaso(3), label: 'Confirmar'),
          ],
        ),
      ),
    );
  }

  _EstadoPaso _estadoPaso(int n) {
    if (pasoActual > n)  return _EstadoPaso.completado;
    if (pasoActual == n) return _EstadoPaso.activo;
    return _EstadoPaso.pendiente;
  }
}

enum _EstadoPaso { pendiente, activo, completado }

class _StepDot extends StatelessWidget {
  const _StepDot({required this.n, required this.estado, required this.label});
  final int         n;
  final _EstadoPaso estado;
  final String      label;

  @override
  Widget build(BuildContext context) {
    final isActivo     = estado == _EstadoPaso.activo;
    final isCompletado = estado == _EstadoPaso.completado;
    final bgColor = isActivo || isCompletado
        ? AppColors.primary
        : AppColors.primaryLight;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 32, height: 32,
          decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
          child: Center(
            child: isCompletado
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : Text(
                    '$n',
                    style: AppTextStyles.button.copyWith(
                      color: isActivo ? Colors.white : AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.priceLabel.copyWith(
            color: isActivo || isCompletado
                ? AppColors.primaryDark
                : AppColors.textFaint,
            fontWeight: isActivo ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.activo});
  final bool activo;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          height: 2,
          margin: const EdgeInsets.only(bottom: 18),
          color: activo ? AppColors.primary : AppColors.primaryLight,
        ),
      );
}

// ── PASO 1: Datos del cliente ─────────────────────────────────────────────────

class _Paso1 extends ConsumerStatefulWidget {
  const _Paso1({required this.onSiguiente});
  final VoidCallback onSiguiente;
  @override
  ConsumerState<_Paso1> createState() => _Paso1State();
}

class _Paso1State extends ConsumerState<_Paso1> {
  final _celularCtrl   = TextEditingController();
  final _aliasCtrl     = TextEditingController();
  final _compradorCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _distritoCtrl  = TextEditingController();

  @override
  void dispose() {
    _celularCtrl.dispose();
    _aliasCtrl.dispose();
    _compradorCtrl.dispose();
    _direccionCtrl.dispose();
    _distritoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(nuevaVentaProvider);
    final notifier = ref.read(nuevaVentaProvider.notifier);

    if (_celularCtrl.text != state.celular)     _celularCtrl.text   = state.celular;
    if (_aliasCtrl.text != state.alias)         _aliasCtrl.text     = state.alias;
    if (_compradorCtrl.text != state.comprador) _compradorCtrl.text = state.comprador;
    if (_direccionCtrl.text != state.direccion) _direccionCtrl.text = state.direccion;
    if (_distritoCtrl.text != state.distrito)   _distritoCtrl.text  = state.distrito;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Banner de cotización de referencia ──────────────────────────
          if (state.refCotizacion != null)
            _RefCotizacionBanner(
              idCotizacion: state.refCotizacion!,
              items:        state.refItems,
            ),

          const _SectionDivider('Cliente', Icons.person_outline_rounded),

          // ── Celular ─────────────────────────────────────────────────────
          _Label('Celular', Icons.phone_outlined),
          TextField(
            controller: _celularCtrl,
            keyboardType: TextInputType.phone,
            maxLength: 9,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecor(
              hint: '987654321',
              suffix: state.buscandoCliente
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : state.clientePrevio != null
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.stockOk, size: 20)
                      : null,
            ),
            onChanged: notifier.setCelular,
          ),

          // Banner cliente frecuente
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: state.clientePrevio != null
                ? _ClienteBanner(cliente: state.clientePrevio!)
                : const SizedBox.shrink(),
          ),

          // ── Alias WhatsApp (opcional) ──────────────────────────────────
          _Label('Alias WhatsApp (opcional)', Icons.alternate_email_rounded),
          TextField(
            controller: _aliasCtrl,
            decoration: _inputDecor(hint: '@perfutecalima'),
            onChanged: notifier.setAlias,
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Nombre ──────────────────────────────────────────────────────
          _Label('Nombre del comprador', Icons.person_outline_rounded),
          TextField(
            controller: _compradorCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecor(hint: 'Nombre completo'),
            onChanged: notifier.setComprador,
          ),

          const _SectionDivider('Entrega', Icons.local_shipping_outlined),

          // ── Dirección ───────────────────────────────────────────────────
          _Label('Dirección de entrega', Icons.location_on_outlined),
          TextField(
            controller: _direccionCtrl,
            decoration: _inputDecor(hint: 'Jr. Los Jardines 123, Apto 4B'),
            onChanged: notifier.setDireccion,
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Distrito ────────────────────────────────────────────────────
          _Label('Distrito', Icons.map_outlined),
          TextField(
            controller: _distritoCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecor(hint: 'Ej: San Isidro, Miraflores...'),
            onChanged: notifier.setDistrito,
          ),

          // ── Tipo de envío (chips) ────────────────────────────────────────
          _Label('Tipo de envío', Icons.local_shipping_outlined),
          _ChipSelector(
            opciones: const ['Shalom', 'Motorizado'],
            valor: state.tipoEnvio,
            iconos: const [Icons.store_outlined, Icons.two_wheeler_rounded],
            onSelect: notifier.setTipoEnvio,
          ),

          const _SectionDivider('Pago', Icons.payment_outlined),

          // ── Método de pago (chips) ───────────────────────────────────────
          _Label('Método de pago', Icons.payment_outlined),
          _ChipSelector(
            opciones: const ['Yape', 'Plin', 'Transferencia', 'Tarjeta'],
            valor: state.metodoPago,
            iconos: const [
              Icons.smartphone_rounded,
              Icons.smartphone_outlined,
              Icons.account_balance_outlined,
              Icons.credit_card_outlined,
            ],
            onSelect: notifier.setMetodoPago,
          ),

          // ── Fecha de venta ───────────────────────────────────────────────
          _Label('Fecha de venta', Icons.calendar_today_outlined),
          InkWell(
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: now,
                firstDate: now.subtract(const Duration(days: 30)),
                lastDate: now,
                helpText: 'Selecciona la fecha de venta',
              );
              if (picked != null) {
                notifier.setFecha(
                  '${picked.year}-'
                  '${picked.month.toString().padLeft(2, '0')}-'
                  '${picked.day.toString().padLeft(2, '0')}',
                );
              }
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _formatFecha(state.fecha),
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit_calendar_rounded,
                      size: 14, color: AppColors.textMuted),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: state.paso1Valido ? widget.onSiguiente : null,
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: const Text('Agregar perfumes'),
            ),
          ),

          if (!state.paso1Valido) ...[
            const SizedBox(height: AppSpacing.sm),
            _ValidationHint(state: state),
          ],
        ],
      ),
    );
  }
}

// ── Banner cliente frecuente ──────────────────────────────────────────────────

class _ClienteBanner extends StatelessWidget {
  const _ClienteBanner({required this.cliente});
  final ClientePrevio cliente;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.successSurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.stockOk.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_rounded, color: AppColors.stockOk, size: 16),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Cliente frecuente · ${cliente.totalCompras} compra${cliente.totalCompras != 1 ? 's' : ''}',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.stockOk, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.auto_awesome_rounded,
                color: AppColors.stockOk, size: 14),
          ],
        ),
      );
}

// ── Banner de cotización de referencia ───────────────────────────────────────

class _RefCotizacionBanner extends StatelessWidget {
  const _RefCotizacionBanner({
    required this.idCotizacion,
    this.items,
  });
  final String  idCotizacion;
  final String? items;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.goldLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined,
                    size: 14, color: AppColors.gold),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Desde cotización',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  idCotizacion,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (items != null && items!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                items!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted, fontSize: 10),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      );
}

// ── Selector de chips (reemplaza dropdowns) ───────────────────────────────────

class _ChipSelector extends StatelessWidget {
  const _ChipSelector({
    required this.opciones,
    required this.valor,
    required this.onSelect,
    this.iconos,
  });
  final List<String>    opciones;
  final String          valor;
  final ValueChanged<String> onSelect;
  final List<IconData>? iconos;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: opciones.asMap().entries.map((e) {
            final selected = valor == e.value;
            final icon     = iconos?[e.key];
            return Semantics(
              button: true,
              label: e.value,
              selected: selected,
              child: GestureDetector(
                onTap: () => onSelect(e.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.primaryLight,
                      width: selected ? 1.5 : 1,
                    ),
                    boxShadow: selected
                        ? const [BoxShadow(
                            color: AppColors.shadowColor,
                            blurRadius: 4, offset: Offset(0, 2))]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon,
                            size: 14,
                            color: selected ? Colors.white : AppColors.textMuted),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
}

// ── PASO 2: Cesta ─────────────────────────────────────────────────────────────

class _Paso2 extends ConsumerStatefulWidget {
  const _Paso2({required this.onAnterior, required this.onSiguiente});
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;
  @override
  ConsumerState<_Paso2> createState() => _Paso2State();
}

class _Paso2State extends ConsumerState<_Paso2> {
  final _busquedaCtrl = TextEditingController();
  String  _query = '';
  bool    _cestaExpandida = false;
  String? _marcaFiltro;
  Timer?  _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _busquedaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state         = ref.watch(nuevaVentaProvider);
    final notifier      = ref.read(nuevaVentaProvider.notifier);
    final catalogoState = ref.watch(catalogoProvider);

    final marcas = catalogoState.perfumes
        .map((p) => p.marca)
        .toSet()
        .toList()
      ..sort();

    final q = _query.toLowerCase();
    final perfumes = catalogoState.perfumes.where((p) {
      final matchMarca = _marcaFiltro == null || p.marca == _marcaFiltro;
      final matchQuery = q.isEmpty ||
          p.nombre.toLowerCase().contains(q) ||
          p.marca.toLowerCase().contains(q);
      return matchMarca && matchQuery;
    }).toList();

    return Column(
      children: [
        // ── Filtro por marca ───────────────────────────────────────────────
        if (marcas.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg),
              children: [
                _BrandChip(
                  label: 'Todas',
                  selected: _marcaFiltro == null,
                  onTap: () => setState(() => _marcaFiltro = null),
                ),
                ...marcas.map((m) => Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: _BrandChip(
                    label: m,
                    selected: _marcaFiltro == m,
                    onTap: () => setState(
                      () => _marcaFiltro = _marcaFiltro == m ? null : m,
                    ),
                  ),
                )),
              ],
            ),
          ),

        // ── Buscador ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xs),
          child: TextField(
            controller: _busquedaCtrl,
            decoration: _inputDecor(
              hint: 'Buscar perfume por nombre o marca...',
              prefix: const Icon(Icons.search_rounded,
                  size: 20, color: AppColors.textMuted),
              suffix: _query.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _busquedaCtrl.clear();
                        setState(() => _query = '');
                      },
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.textMuted))
                  : null,
            ),
            onChanged: (v) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 250), () {
                if (mounted) setState(() => _query = v);
              });
            },
          ),
        ),

        // ── Contador de resultados ─────────────────────────────────────────
        if (_query.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(
                left: AppSpacing.lg, bottom: AppSpacing.xs),
            child: Text(
              '${perfumes.length} resultado${perfumes.length != 1 ? 's' : ''}',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textMuted),
            ),
          ),

        // ── Lista de perfumes ─────────────────────────────────────────────
        Expanded(
          child: catalogoState.isLoading
              ? const _CatalogoSkeleton()
              : perfumes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded,
                              size: 48, color: AppColors.textFaint),
                          const SizedBox(height: 12),
                          Text('Sin resultados para "$_query"',
                              style: AppTextStyles.body
                                  .copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.xs,
                          AppSpacing.lg, AppSpacing.md),
                      itemCount: perfumes.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        final p = perfumes[i];
                        final enCesta = state.cesta
                            .where((it) => it.perfume.idPerfume == p.idPerfume)
                            .length;
                        return _PerfumeItem(
                          perfume:    p,
                          metodoPago: state.metodoPago,
                          enCesta:    enCesta,
                          onAgregar:  (ml) {
                            HapticFeedback.lightImpact();
                            notifier.agregarItem(p, ml);
                          },
                        );
                      },
                    ),
        ),

        // ── Panel inferior (cesta + navegación) ───────────────────────────
        _BottomPanel(
          state:          state,
          cestaExpandida: _cestaExpandida,
          onToggleCesta:  () => setState(() => _cestaExpandida = !_cestaExpandida),
          onQuitarItem:   (i) => notifier.quitarItem(i),
          onAnterior:     widget.onAnterior,
          onSiguiente:    widget.onSiguiente,
          onEditarPrecio: (index, currentPrice, nombre) async {
            final ctrl = TextEditingController(
                text: currentPrice.toStringAsFixed(2));
            final result = await showDialog<double>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Editar precio'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: ctrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*[.,]?\d{0,2}')),
                      ],
                      autofocus: true,
                      decoration: InputDecoration(
                        prefixText: 'S/ ',
                        labelText: 'Nuevo precio',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final v = double.tryParse(
                          ctrl.text.replaceAll(',', '.'));
                      if (v != null && v > 0) Navigator.pop(ctx, v);
                    },
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            );
            if (result != null) notifier.setPrecioItem(index, result);
          },
        ),
      ],
    );
  }
}

// ── Panel inferior: cesta expandible + botones ────────────────────────────────

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.state,
    required this.cestaExpandida,
    required this.onToggleCesta,
    required this.onQuitarItem,
    required this.onAnterior,
    required this.onSiguiente,
    this.onEditarPrecio,
  });
  final NuevaVentaState state;
  final bool            cestaExpandida;
  final VoidCallback    onToggleCesta;
  final void Function(int) onQuitarItem;
  final VoidCallback    onAnterior;
  final VoidCallback    onSiguiente;
  final void Function(int index, double currentPrice, String nombre)? onEditarPrecio;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.primaryLight)),
        boxShadow: [BoxShadow(
          color: AppColors.shadowColor, blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Cesta expandible ─────────────────────────────────────────
          if (state.cesta.isNotEmpty) ...[
            InkWell(
              onTap: onToggleCesta,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        '${state.cesta.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'ítem${state.cesta.length != 1 ? 's' : ''} en cesta',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      'S/ ${state.total.toStringAsFixed(2)}',
                      style: AppTextStyles.price.copyWith(
                          fontSize: 15, color: AppColors.primaryDark),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AnimatedRotation(
                      turns: cestaExpandida ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.keyboard_arrow_up_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                  ],
                ),
              ),
            ),

            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: cestaExpandida
                  ? Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: state.cesta.length,
                        itemBuilder: (_, i) => _FadeSlideIn(
                          delay: Duration(milliseconds: i * 45),
                          child: ItemCestaCard(
                            item:     state.cesta[i],
                            index:    i,
                            onQuitar: () => onQuitarItem(i),
                            onEditarPrecio: onEditarPrecio == null
                                ? null
                                : () => onEditarPrecio!(
                                      i,
                                      state.cesta[i].precio,
                                      state.cesta[i].perfume.nombre,
                                    ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const Divider(height: 1, color: AppColors.primaryLight),
          ],

          // ── Botones de navegación ─────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm + MediaQuery.of(context).padding.bottom),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onAnterior,
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Atrás'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    side: const BorderSide(color: AppColors.primaryLight),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: state.cesta.isNotEmpty ? onSiguiente : null,
                    icon: const Icon(Icons.check_circle_outline_rounded,
                        size: 16),
                    label: Text(
                      state.cesta.isEmpty
                          ? 'Agrega un perfume'
                          : 'Continuar · S/ ${state.total.toStringAsFixed(2)}',
                    ),
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

// ── Item de perfume en la lista ───────────────────────────────────────────────

class _PerfumeItem extends StatelessWidget {
  const _PerfumeItem({
    required this.perfume,
    required this.metodoPago,
    required this.enCesta,
    required this.onAgregar,
  });
  final Perfume              perfume;
  final String               metodoPago;
  final int                  enCesta;
  final void Function(int ml) onAgregar;

  @override
  Widget build(BuildContext context) {
    final precios = perfume.precios;
    final enCestaColor = enCesta > 0 ? AppColors.stockOk : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border(
          left: BorderSide(color: enCestaColor, width: 3),
          top: const BorderSide(color: AppColors.primaryLight),
          right: const BorderSide(color: AppColors.primaryLight),
          bottom: const BorderSide(color: AppColors.primaryLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      perfume.marca.toUpperCase(),
                      style: AppTextStyles.marca.copyWith(fontSize: 9),
                    ),
                    Text(
                      perfume.nombre,
                      style: AppTextStyles.perfumeName.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Badge de stock + en cesta
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (perfume.stockMl != null)
                    _StockChip(perfume: perfume),
                  if (enCesta > 0) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.successSurface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: AppColors.stockOk.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '✓ $enCesta en cesta',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.stockOk,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          if (precios.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: precios.entries.map((e) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: _ScaleTap(
                  onTap: () => onAgregar(e.key),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPale,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(color: AppColors.primaryLight),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${e.key} ml',
                          style: AppTextStyles.priceLabel
                              .copyWith(fontSize: 9),
                        ),
                        Text(
                          e.value % 1 == 0
                              ? 'S/ ${e.value.toInt()}'
                              : 'S/ ${e.value.toStringAsFixed(2)}',
                          style: AppTextStyles.price.copyWith(
                              fontSize: 12, color: AppColors.primaryDark),
                        ),
                      ],
                    ),
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _StockChip extends ConsumerWidget {
  const _StockChip({required this.perfume});
  final Perfume perfume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider).valueOrNull ??
        AppConfigModel.defaults();
    final (:esCritico, :esBajo) = perfume.stockEstado(config);
    final color = esCritico
        ? AppColors.stockCritical
        : esBajo
            ? AppColors.stockLow
            : AppColors.textFaint;
    final icon = esCritico
        ? Icons.warning_amber_rounded
        : esBajo
            ? Icons.info_outline_rounded
            : Icons.inventory_2_outlined;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(
          '${perfume.stockMl!.toStringAsFixed(0)} ml',
          style: AppTextStyles.bodySmall
              .copyWith(fontSize: 10, color: color),
        ),
      ],
    );
  }
}

// ── PASO 3: Confirmar ─────────────────────────────────────────────────────────

class _Paso3 extends ConsumerWidget {
  const _Paso3({required this.onAnterior});
  final VoidCallback onAnterior;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(nuevaVentaProvider);
    final notifier = ref.read(nuevaVentaProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Resumen cliente ────────────────────────────────────────────
          _SeccionResumen(
            titulo: 'Datos del cliente',
            icon:   Icons.person_rounded,
            rows: [
              ('Nombre',   state.comprador),
              ('Celular',  state.celular),
              ('Dirección', state.direccion),
              ('Envío',    state.tipoEnvio),
              ('Pago',     state.metodoPago),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Productos ──────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.shopping_bag_outlined,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'PRODUCTOS (${state.cesta.length})',
                style: AppTextStyles.notasLabel
                    .copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...state.cesta.asMap().entries.map((e) => ItemCestaCard(
                item:     e.value,
                index:    e.key,
                readOnly: true,
              )),

          // ── Total ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            margin:  const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryPale, AppColors.surface],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL A COBRAR',
                        style: AppTextStyles.notasLabel
                            .copyWith(color: AppColors.textMuted, fontSize: 9)),
                    Text(
                      state.metodoPago,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
                Text(
                  'S/ ${state.total.toStringAsFixed(2)}',
                  style: AppTextStyles.price.copyWith(
                      color: AppColors.primaryDark, fontSize: 26),
                ),
              ],
            ),
          ),

          // ── Error ──────────────────────────────────────────────────────
          if (state.error != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color:  AppColors.errorSurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(state.error!,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.error)),
                  ),
                ],
              ),
            ),

          // ── Botones ────────────────────────────────────────────────────
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: state.registrando ? null : onAnterior,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Atrás'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  side: const BorderSide(color: AppColors.primaryLight),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton.icon(
                  onPressed: state.registrando
                      ? null
                      : () => notifier.registrarVenta(),
                  icon: state.registrando
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(state.registrando
                      ? 'Registrando...'
                      : 'Confirmar venta'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Pantalla de éxito ─────────────────────────────────────────────────────────

class _TicketExito extends StatelessWidget {
  const _TicketExito({
    required this.idCompra,
    required this.celular,
    required this.alias,
    required this.comprador,
    required this.tipoEnvio,
    required this.direccion,
    required this.metodoPago,
    required this.total,
    required this.cesta,
    required this.onNueva,
    this.warning,
  });
  final String       idCompra;
  final String?      warning;
  final String       celular;
  final String       alias;
  final String       comprador;
  final String       tipoEnvio;
  final String       direccion;
  final String       metodoPago;
  final double       total;
  final List<ItemCesta> cesta;
  final VoidCallback onNueva;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),

          // Ícono de éxito animado
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Opacity(
              opacity: v.clamp(0.0, 1.0),
              child: Transform.scale(scale: v.clamp(0.0, 1.0), child: child),
            ),
            child: Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.successSurface,
                border: Border.all(color: AppColors.stockOk, width: 2),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.stockOk,
                size: 52,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('¡Venta registrada!', style: AppTextStyles.heading1),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primaryPale,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: Text(
                  idCompra,
                  style: AppTextStyles.heading2
                      .copyWith(color: AppColors.primary, fontSize: 20),
                ),
              ),
              const SizedBox(width: 4),
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  color: AppColors.textMuted,
                  tooltip: 'Copiar ID',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: idCompra));
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('ID de pedido copiado'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Warning de stock
          if (warning != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color:  AppColors.warningSurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.warning, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(warning!,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.warning)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Resumen de ítems
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Text('RESUMEN',
                      style: AppTextStyles.notasLabel
                          .copyWith(color: AppColors.primary)),
                ]),
                const Divider(height: AppSpacing.lg),
                ...cesta.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPale,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Text('${item.ml}ml',
                                style: AppTextStyles.priceLabel
                                    .copyWith(fontSize: 10)),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              item.perfume.nombre,
                              style: AppTextStyles.bodySmall
                                  .copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'S/ ${item.precio.toStringAsFixed(2)}',
                            style: AppTextStyles.price.copyWith(
                                fontSize: 13,
                                color: AppColors.primaryDark),
                          ),
                        ],
                      ),
                    )),
                const Divider(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL',
                        style: AppTextStyles.notasLabel
                            .copyWith(color: AppColors.textMuted)),
                    Text(
                      'S/ ${total.toStringAsFixed(2)}',
                      style: AppTextStyles.price
                          .copyWith(color: AppColors.primaryDark, fontSize: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Botón WhatsApp cliente
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.chat_rounded, size: 18),
              label: Text('WhatsApp a $comprador'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.whatsapp,
                side: const BorderSide(color: AppColors.whatsapp),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _abrirWhatsApp(context, celular, alias, idCompra, total),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Botón comunidad (sin número — WhatsApp deja elegir el destino)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.groups_rounded, size: 18),
              label: const Text('Enviar pedido a comunidad'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.whatsappDark,
                side: const BorderSide(color: AppColors.whatsappDark),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _abrirWhatsAppComunidad(context, idCompra, total),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Nueva venta
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nueva venta'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: onNueva,
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Future<void> _abrirWhatsApp(
      BuildContext context, String cel, String alias, String id, double total) async {
    const sep = '────────────────────';
    const dias = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves',
      'Viernes', 'Sábado', 'Domingo',
    ];
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    final manana = DateTime.now().add(const Duration(days: 1));
    final fechaEnvio =
        '${dias[manana.weekday - 1]} ${manana.day} de ${meses[manana.month - 1]}';

    final itemsTexto = cesta.map((i) {
      final marca = i.perfume.marca.trim();
      return marca.isNotEmpty
          ? '  🌸 *$marca* · ${i.perfume.nombre} · ${i.ml}ml'
          : '  🌸 ${i.perfume.nombre} · ${i.ml}ml';
    }).join('\n');

    final dirLinea = direccion.trim().isNotEmpty
        ? '\n📍 *Dirección:* $direccion'
        : '';

    final msg =
      '🌸 *Perfuteca — Pedido $id*\n'
      '$sep\n'
      '👤 *Comprador:* $comprador\n'
      '📱 *Celular:* ${lineaContacto(cel, alias)}\n'
      '🚚 *Envío:* $tipoEnvio'
      '$dirLinea\n'
      '$sep\n'
      '🛍️ *Tu pedido:*\n'
      '$itemsTexto\n'
      '$sep\n'
      '📦 Tu pedido estará siendo enviado el *$fechaEnvio*.\n\n'
      '_¡Gracias por tu compra! 💛_';
    try {
      await abrirWhatsAppBusiness(celular: cel, alias: alias, mensaje: msg);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir WhatsApp'),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _abrirWhatsAppComunidad(BuildContext context, String id, double total) async {
    const sep = '────────────────────';
    final itemsLineas = cesta.map((i) {
      final marca = i.perfume.marca.trim();
      return marca.isNotEmpty
          ? '  • *$marca* ${i.perfume.nombre} ${i.ml}ml — S/ ${i.precio.toStringAsFixed(2)}'
          : '  • ${i.perfume.nombre} ${i.ml}ml — S/ ${i.precio.toStringAsFixed(2)}';
    }).join('\n');

    final dirLinea = direccion.trim().isNotEmpty
        ? '\n📍 *Dirección:* $direccion'
        : '';

    final metodosUnicos = cesta.map((i) => i.metodo).toSet().join(', ');
    final pago = metodosUnicos.isNotEmpty ? metodosUnicos : metodoPago;

    final msg =
      '📦 *Perfuteca — Pedido Nuevo $id*\n$sep\n'
      '👤 *Cliente:* $comprador\n'
      '📱 *Celular:* $celular\n'
      '🚚 *Envío:* $tipoEnvio$dirLinea\n'
      '$sep\n'
      '🌸 *Perfumes:*\n$itemsLineas\n'
      '$sep\n'
      '💰 *Total: S/ ${total.toStringAsFixed(2)}*\n'
      '💳 *Pago:* $pago';
    // Sin celular → WhatsApp Business abre el selector de chat (grupo, comunidad, etc.)
    try {
      await abrirWhatsAppBusiness(mensaje: msg);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir WhatsApp'),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _SeccionResumen extends StatelessWidget {
  const _SeccionResumen({
    required this.titulo,
    required this.icon,
    required this.rows,
  });
  final String titulo;
  final IconData icon;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.primaryLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(titulo,
                  style: AppTextStyles.notasLabel
                      .copyWith(color: AppColors.primary)),
            ]),
            const Divider(height: AppSpacing.lg),
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(r.$1,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textMuted)),
                      ),
                      Expanded(
                        child: Text(r.$2,
                            style: AppTextStyles.bodySmall
                                .copyWith(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      );
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider(this.label, this.icon);
  final String   label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
        child: Row(
          children: [
            Icon(icon, size: 13, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label.toUpperCase(),
              style: AppTextStyles.notasLabel.copyWith(
                color: AppColors.primary,
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(child: Divider(height: 1, thickness: 1)),
          ],
        ),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text, this.icon);
  final String   text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding:
            const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(text,
                style: AppTextStyles.bodySmall
                    .copyWith(fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
          ],
        ),
      );
}

InputDecoration _inputDecor({
  required String hint,
  Widget? suffix,
  Widget? prefix,
}) =>
    InputDecoration(
      hintText:       hint,
      hintStyle:      AppTextStyles.bodySmall,
      suffixIcon:     suffix,
      prefixIcon:     prefix,
      filled:         true,
      fillColor:      AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide:   BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical:   AppSpacing.md,
      ),
    );

// ── _ValidationHint ───────────────────────────────────────────────────────────

class _ValidationHint extends StatelessWidget {
  const _ValidationHint({required this.state});
  final NuevaVentaState state;

  @override
  Widget build(BuildContext context) {
    final faltantes = <String>[];
    if (state.comprador.trim().isEmpty) { faltantes.add('nombre'); }
    if (state.celular.length != 9 || !state.celular.startsWith('9')) {
      faltantes.add('celular (9 dígitos, empieza con 9)');
    }
    if (state.tipoEnvio.isEmpty) { faltantes.add('tipo de envío'); }
    if (state.direccion.trim().isEmpty) {
      faltantes.add('dirección');
    }
    if (faltantes.isEmpty) return const SizedBox.shrink();
    return Text(
      'Falta: ${faltantes.join(', ')}',
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
      textAlign: TextAlign.center,
    );
  }
}

// ── _BrandChip ────────────────────────────────────────────────────────────────

class _BrandChip extends StatelessWidget {
  const _BrandChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String       label;
  final bool         selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.primaryLight,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      );
}

// ── _formatFecha ──────────────────────────────────────────────────────────────

String _formatFecha(String isoDate) {
  if (isoDate.isEmpty) return 'Hoy';
  try {
    final d = DateTime.parse(isoDate);
    const dias = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves',
      'Viernes', 'Sábado', 'Domingo',
    ];
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return '${dias[d.weekday - 1]} ${d.day} de ${meses[d.month - 1]}';
  } catch (_) {
    return isoDate;
  }
}

// ── Entrada escalonada (stagger fadeInUp) ────────────────────────────────────

class _FadeSlideIn extends StatefulWidget {
  const _FadeSlideIn({required this.child, required this.delay});
  final Widget   child;
  final Duration delay;

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 240),
      vsync: this,
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide   = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
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

// ── Press con escala (reemplaza InkWell en chips de precio) ──────────────────

class _ScaleTap extends StatefulWidget {
  const _ScaleTap({required this.child, required this.onTap});
  final Widget       child;
  final VoidCallback onTap;

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:           this,
      duration:        const Duration(milliseconds: 130),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown:  (_) => _ctrl.forward(),
        onTapUp:    (_) {
          _ctrl.reverse();
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(scale: _scale, child: widget.child),
      );
}

// ── Skeleton catálogo ─────────────────────────────────────────────────────────

class _CatalogoSkeleton extends StatelessWidget {
  const _CatalogoSkeleton();

  static Widget _box({double? w, required double h, double r = 8}) => Container(
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
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.md),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, __) => Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(w: 60, h: 9),
                        const SizedBox(height: 6),
                        _box(w: 140, h: 13),
                      ],
                    ),
                  ),
                  _box(w: 50, h: 16, r: 4),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(children: [
                _box(w: 70, h: 44, r: AppSpacing.radiusSm),
                const SizedBox(width: AppSpacing.sm),
                _box(w: 70, h: 44, r: AppSpacing.radiusSm),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

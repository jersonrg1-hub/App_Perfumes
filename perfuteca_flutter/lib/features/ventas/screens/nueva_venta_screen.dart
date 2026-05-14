import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/features/ventas/providers/nueva_venta_provider.dart';
import 'package:perfuteca/features/ventas/providers/ventas_provider.dart';
import 'package:perfuteca/features/ventas/widgets/item_cesta_card.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';
import 'package:perfuteca/widgets/common/app_loading_widget.dart';

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
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nuevaVentaProvider);

    // Venta exitosa
    if (state.ventaRegistrada != null) {
      return _TicketExito(
        idCompra: state.ventaRegistrada!.idCompra,
        warning:  state.ventaRegistrada!.warning,
        celular:  state.celular,
        comprador: state.comprador,
        total:    state.total,
        onNueva:  () {
          ref.read(nuevaVentaProvider.notifier).reset();
          ref.invalidate(historialProvider);
          ref.invalidate(pendientesProvider);
          _pageController.jumpToPage(0);
        },
      );
    }

    return Column(
      children: [
        _StepIndicator(pasoActual: state.paso),
        Expanded(
          child: PageView(
            controller:   _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _Paso1(onSiguiente: () => _irA(2)),
              _Paso2(
                onAnterior: () => _irA(1),
                onSiguiente: () => _irA(3),
              ),
              _Paso3(
                onAnterior: () => _irA(2),
              ),
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
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.xl,
      ),
      child: Row(
        children: [
          _StepDot(n: 1, activo: pasoActual >= 1, label: 'Cliente'),
          _StepLine(activo: pasoActual >= 2),
          _StepDot(n: 2, activo: pasoActual >= 2, label: 'Cesta'),
          _StepLine(activo: pasoActual >= 3),
          _StepDot(n: 3, activo: pasoActual >= 3, label: 'Confirmar'),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.n, required this.activo, required this.label});
  final int    n;
  final bool   activo;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32, height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:  activo ? AppColors.primary : AppColors.primaryLight,
        ),
        child: Center(
          child: Text(
            '$n',
            style: AppTextStyles.button.copyWith(
              color: activo ? Colors.white : AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: AppTextStyles.priceLabel.copyWith(
          color: activo ? AppColors.primaryDark : AppColors.textFaint,
        ),
      ),
    ],
  );
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
  final _celularCtrl    = TextEditingController();
  final _compradorCtrl  = TextEditingController();
  final _direccionCtrl  = TextEditingController();

  @override
  void dispose() {
    _celularCtrl.dispose();
    _compradorCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(nuevaVentaProvider);
    final notifier = ref.read(nuevaVentaProvider.notifier);

    // Sincroniza controladores cuando llegan datos del cliente anterior
    if (_compradorCtrl.text != state.comprador) {
      _compradorCtrl.text = state.comprador;
    }
    if (_direccionCtrl.text != state.direccion) {
      _direccionCtrl.text = state.direccion;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Celular
          _Label('Celular'),
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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : state.clientePrevio != null
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.stockOk, size: 20)
                      : null,
            ),
            onChanged: notifier.setCelular,
          ),

          if (state.clientePrevio != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.stockOk.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.stockOk.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_rounded, color: AppColors.stockOk, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Cliente frecuente · ${state.clientePrevio!.totalCompras} compras',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.stockOk),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Nombre
          _Label('Nombre del comprador'),
          TextField(
            controller: _compradorCtrl,
            decoration: _inputDecor(hint: 'Nombre completo'),
            onChanged: notifier.setComprador,
          ),

          // Dirección
          _Label('Dirección'),
          TextField(
            controller: _direccionCtrl,
            decoration: _inputDecor(hint: 'Dirección de entrega'),
            onChanged: notifier.setDireccion,
          ),

          // Tipo envío
          _Label('Tipo de envío'),
          _Dropdown(
            value:   state.tipoEnvio.isEmpty ? null : state.tipoEnvio,
            items:   const ['Shalom', 'Motorizado', 'Contraentrega'],
            hint:    'Selecciona',
            onChanged: notifier.setTipoEnvio,
          ),

          // Método de pago
          _Label('Método de pago'),
          _Dropdown(
            value:   state.metodoPago,
            items:   const ['Yape', 'Plin', 'Transferencia', 'Tarjeta'],
            hint:    'Selecciona',
            onChanged: notifier.setMetodoPago,
          ),

          const SizedBox(height: AppSpacing.xl),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: state.paso1Valido ? widget.onSiguiente : null,
              child: const Text('Siguiente → Agregar perfumes'),
            ),
          ),
        ],
      ),
    );
  }
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
  String _query = '';

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(nuevaVentaProvider);
    final notifier = ref.read(nuevaVentaProvider.notifier);
    final catalogoState = ref.watch(catalogoProvider);

    // Filtra el catálogo localmente
    final perfumes = _query.isEmpty
        ? catalogoState.perfumes
        : catalogoState.perfumes.where((p) =>
            p.nombre.toLowerCase().contains(_query.toLowerCase()) ||
            p.marca.toLowerCase().contains(_query.toLowerCase())).toList();

    return Column(
      children: [
        // Buscador
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0,
          ),
          child: TextField(
            controller: _busquedaCtrl,
            decoration: _inputDecor(
              hint: 'Buscar perfume...',
              prefix: const Icon(Icons.search_rounded, size: 20,
                  color: AppColors.textMuted),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),

        // Cesta actual
        if (state.cesta.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0,
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryPale,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '🛒 Cesta (${state.cesta.length})',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      'Total: S/ ${state.total.toStringAsFixed(0)}',
                      style: AppTextStyles.price.copyWith(
                        fontSize: 14,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ...state.cesta.asMap().entries.map((e) => ItemCestaCard(
                  item:     e.value,
                  index:    e.key,
                  onQuitar: () => notifier.quitarItem(e.key),
                )),
              ],
            ),
          ),

        // Lista de perfumes
        Expanded(
          child: catalogoState.isLoading
              ? const AppLoadingWidget()
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: perfumes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) => _PerfumeItem(
                    perfume:   perfumes[i],
                    metodoPago: state.metodoPago,
                    onAgregar: (ml) => notifier.agregarItem(perfumes[i], ml),
                  ),
                ),
        ),

        // Botones
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: widget.onAnterior,
                child: const Text('← Atrás'),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: state.cesta.isNotEmpty ? widget.onSiguiente : null,
                  child: const Text('Siguiente → Confirmar'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PerfumeItem extends StatelessWidget {
  const _PerfumeItem({
    required this.perfume,
    required this.metodoPago,
    required this.onAgregar,
  });
  final Perfume   perfume;
  final String    metodoPago;
  final void Function(int ml) onAgregar;

  @override
  Widget build(BuildContext context) {
    final precios = perfume.precios;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border(
          left: BorderSide(color: AppColors.primary, width: 3),
          top:  BorderSide(color: AppColors.primaryLight),
          right: BorderSide(color: AppColors.primaryLight),
          bottom: BorderSide(color: AppColors.primaryLight),
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
              if (perfume.stockMl != null)
                Text(
                  '${perfume.stockMl!.toStringAsFixed(0)} ml',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: perfume.stockCritico
                        ? AppColors.stockCritical
                        : perfume.stockBajo
                            ? AppColors.stockLow
                            : AppColors.textMuted,
                  ),
                ),
            ],
          ),
          if (precios.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: precios.entries.map((e) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: OutlinedButton(
                  onPressed: () => onAgregar(e.key),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    side: const BorderSide(color: AppColors.primaryLight),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    '${e.key}ml · S/${e.value.toStringAsFixed(0)}',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
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
          // Resumen cliente
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

          // Cesta
          Text('Productos (${state.cesta.length})',
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          ...state.cesta.asMap().entries.map((e) => ItemCestaCard(
            item:     e.value,
            index:    e.key,
            readOnly: true,
          )),

          // Total
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            margin:  const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryPale,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOTAL', style: AppTextStyles.notasLabel),
                Text(
                  'S/ ${state.total.toStringAsFixed(2)}',
                  style: AppTextStyles.price.copyWith(
                    color: AppColors.primaryDark,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),

          if (state.error != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color:  AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Text(state.error!,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
            ),

          const SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              OutlinedButton(
                onPressed: state.registrando ? null : onAnterior,
                child: const Text('← Atrás'),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: state.registrando
                      ? null
                      : () => notifier.registrarVenta(),
                  child: state.registrando
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('✓ Confirmar venta'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Ticket de éxito ───────────────────────────────────────────────────────────

class _TicketExito extends StatelessWidget {
  const _TicketExito({
    required this.idCompra,
    required this.celular,
    required this.comprador,
    required this.total,
    required this.onNueva,
    this.warning,
  });
  final String idCompra;
  final String? warning;
  final String celular;
  final String comprador;
  final double total;
  final VoidCallback onNueva;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.stockOk,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('¡Venta registrada!', style: AppTextStyles.heading1),
          const SizedBox(height: AppSpacing.sm),
          Text(
            idCompra,
            style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
          ),

          if (warning != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color:  AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.warning, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(warning!,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.warning)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xxl),

          // Botón WhatsApp
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.chat_rounded),
              label: Text('Enviar comprobante a $comprador por WhatsApp'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF25D366),
                side: const BorderSide(color: Color(0xFF25D366)),
              ),
              onPressed: () => _abrirWhatsApp(celular, idCompra, total),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nueva venta'),
              onPressed: onNueva,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirWhatsApp(String cel, String id, double total) async {
    final msg = Uri.encodeComponent(
      '✅ *Perfuteca* — Venta $id\n'
      'Total: S/ ${total.toStringAsFixed(2)}\n'
      '¡Gracias por tu compra! 🌸',
    );
    final url = Uri.parse('https://wa.me/51$cel?text=$msg');
    if (await canLaunchUrl(url)) launchUrl(url);
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
              style: AppTextStyles.notasLabel.copyWith(
                  color: AppColors.primary)),
        ]),
        const Divider(height: AppSpacing.lg),
        ...rows.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(r.$1,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted)),
              ),
              Expanded(
                child: Text(r.$2,
                    style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        )),
      ],
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
    child: Text(text,
        style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
  );
}

InputDecoration _inputDecor({
  required String hint,
  Widget? suffix,
  Widget? prefix,
}) => InputDecoration(
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

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.value,
    required this.items,
    required this.hint,
    required this.onChanged,
  });
  final String? value;
  final List<String> items;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    value:     value,
    hint:      Text(hint, style: AppTextStyles.bodySmall),
    decoration: InputDecoration(
      filled:    true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide:   BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg, vertical: AppSpacing.md,
      ),
    ),
    items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
    onChanged: (v) { if (v != null) onChanged(v); },
  );
}

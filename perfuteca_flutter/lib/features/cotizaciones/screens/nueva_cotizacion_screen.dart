import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/features/cotizaciones/providers/nueva_cotizacion_provider.dart';
import 'package:perfuteca/features/ventas/widgets/item_cesta_card.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/models/venta.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';

class NuevaCotizacionScreen extends ConsumerStatefulWidget {
  const NuevaCotizacionScreen({super.key});

  @override
  ConsumerState<NuevaCotizacionScreen> createState() =>
      _NuevaCotizacionScreenState();
}

class _NuevaCotizacionScreenState
    extends ConsumerState<NuevaCotizacionScreen> {
  final _pageCtrl = PageController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _irA(int paso) {
    ref.read(nuevaCotizacionProvider.notifier).irPaso(paso);
    _pageCtrl.animateToPage(
      paso - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nuevaCotizacionProvider);

    // Cuando se registra exitosamente, salta a paso 3
    ref.listen(nuevaCotizacionProvider, (prev, next) {
      if (prev?.paso != 3 && next.paso == 3) {
        _pageCtrl.animateToPage(
          2,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    return Column(
      children: [
        _StepIndicator(paso: state.paso, onTapPaso: _irA),
        Expanded(
          child: PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _Paso1(onSiguiente: () => _irA(2)),
              _Paso2(onAnterior: () => _irA(1), onSiguiente: () => _irA(3)),
              state.registrada != null
                  ? _TicketExito(
                      idCotizacion: state.registrada!.idCotizacion,
                      celular:      state.celular,
                      total:        state.totalConDelivery,
                      cesta:        state.cesta,
                      conDelivery:  state.conDelivery,
                      onNueva:      () {
                        ref.read(nuevaCotizacionProvider.notifier).reset();
                        _irA(1);
                      },
                    )
                  : _Paso3(
                      onAnterior: () => _irA(2),
                      onGuardar:  () => ref.read(nuevaCotizacionProvider.notifier).guardar(),
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
  const _StepIndicator({required this.paso, required this.onTapPaso});
  final int               paso;
  final void Function(int) onTapPaso;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm, horizontal: AppSpacing.lg),
      color: AppColors.surface,
      child: Row(
        children: [
          _Dot(n: 1, label: 'Celular',   activo: paso >= 1, actual: paso == 1,
              onTap: paso > 1 ? () => onTapPaso(1) : null),
          _Linea(activa: paso >= 2),
          _Dot(n: 2, label: 'Perfumes',  activo: paso >= 2, actual: paso == 2,
              onTap: paso > 2 ? () => onTapPaso(2) : null),
          _Linea(activa: paso >= 3),
          _Dot(n: 3, label: 'Confirmar', activo: paso >= 3, actual: paso == 3,
              onTap: null),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.n,
    required this.label,
    required this.activo,
    required this.actual,
    this.onTap,
  });
  final int           n;
  final String        label;
  final bool          activo;
  final bool          actual;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: actual ? 28 : 22,
                height: actual ? 28 : 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activo ? AppColors.primary : AppColors.primaryLight,
                  boxShadow: onTap != null
                      ? [BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )]
                      : null,
                ),
                child: Center(
                  child: actual
                      ? const Icon(Icons.edit_rounded,
                          size: 13, color: Colors.white)
                      : Text(
                          '$n',
                          style: TextStyle(
                            fontSize: actual ? 12 : 10,
                            fontWeight: FontWeight.w700,
                            color: activo ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.priceLabel.copyWith(
                  color: activo ? AppColors.primaryDark : AppColors.textFaint,
                  fontWeight: actual ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
}

class _Linea extends StatelessWidget {
  const _Linea({required this.activa});
  final bool activa;

  @override
  Widget build(BuildContext context) => Expanded(
        flex: 2,
        child: Container(
          height: 2,
          color: activa ? AppColors.primary : AppColors.primaryLight,
        ),
      );
}

// ── Paso 1: Celular ───────────────────────────────────────────────────────────

class _Paso1 extends ConsumerStatefulWidget {
  const _Paso1({required this.onSiguiente});
  final VoidCallback onSiguiente;

  @override
  ConsumerState<_Paso1> createState() => _Paso1State();
}

// Normaliza celular: acepta "+51 987654321", "51987654321", "987654321", etc.
String _normalizarCelular(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  String numero;
  if (digits.length >= 11 && digits.startsWith('51')) {
    numero = digits.substring(2);
  } else if (digits.length >= 12 && digits.startsWith('051')) {
    numero = digits.substring(3);
  } else {
    numero = digits;
  }
  // Limitar a 9 dígitos
  return numero.length > 9 ? numero.substring(0, 9) : numero;
}

class _Paso1State extends ConsumerState<_Paso1> {
  late final TextEditingController _celCtrl;

  @override
  void initState() {
    super.initState();
    _celCtrl = TextEditingController(
      text: ref.read(nuevaCotizacionProvider).celular,
    );
  }

  @override
  void dispose() {
    _celCtrl.dispose();
    super.dispose();
  }

  void _onCelularChanged(String raw, NuevaCotizacionNotifier notifier) {
    final normalizado = _normalizarCelular(raw);
    if (normalizado != raw) {
      _celCtrl.value = TextEditingValue(
        text: normalizado,
        selection: TextSelection.collapsed(offset: normalizado.length),
      );
    }
    notifier.setCelular(normalizado);
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(nuevaCotizacionProvider);
    final notifier = ref.read(nuevaCotizacionProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.request_quote_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Nueva cotización',
                style: AppTextStyles.heading2.copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          Text(
            'Celular del cliente',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _celCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.phone_outlined, size: 18),
              hintText: '+51 987654321 o 987654321',
              helperText: 'Puedes pegar el número directo de WhatsApp',
              counterText: '',
              filled: true,
              fillColor: AppColors.primaryPale,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(color: AppColors.primaryLight),
              ),
            ),
            onChanged: (v) => _onCelularChanged(v, notifier),
          ),

          const SizedBox(height: AppSpacing.xl),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: state.paso1Valido ? widget.onSiguiente : null,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Continuar — agregar perfumes'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Paso 2: Seleccionar perfumes ──────────────────────────────────────────────

class _Paso2 extends ConsumerStatefulWidget {
  const _Paso2({required this.onAnterior, required this.onSiguiente});
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;

  @override
  ConsumerState<_Paso2> createState() => _Paso2State();
}

class _Paso2State extends ConsumerState<_Paso2> {
  String _filtro = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(nuevaCotizacionProvider);
    final notifier = ref.read(nuevaCotizacionProvider.notifier);
    final catalogoState = ref.watch(catalogoProvider);

    final perfumes = catalogoState.perfumes.where((p) {
      if (_filtro.isEmpty) return true;
      final q = _filtro.toLowerCase();
      return p.nombre.toLowerCase().contains(q) ||
          p.marca.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Resumen cesta expandible
        if (state.cesta.isNotEmpty)
          _CestaPanel(
            cesta: state.cesta,
            total: state.total,
            onQuitar: (i) => notifier.quitarItem(i),
          ),

        // Buscador
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Buscar perfume o marca...',
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              suffixIcon: _filtro.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _filtro = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.primaryPale,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => _filtro = v),
          ),
        ),

        // Contador de resultados
        if (!catalogoState.isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md + AppSpacing.sm),
            child: Row(
              children: [
                Text(
                  _filtro.isEmpty
                      ? '${perfumes.length} perfumes'
                      : '${perfumes.length} resultado${perfumes.length != 1 ? 's' : ''} para "$_filtro"',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),
                if (_filtro.isNotEmpty) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _filtro = '');
                      FocusScope.of(context).unfocus();
                    },
                    child: Text(
                      'Limpiar',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

        // Lista de perfumes
        Expanded(
          child: catalogoState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : perfumes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded,
                              size: 48, color: AppColors.textFaint),
                          const SizedBox(height: 8),
                          Text(
                            'Sin resultados para "$_filtro"',
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      itemCount: perfumes.length,
                      itemBuilder: (_, i) {
                        final p = perfumes[i];
                        final idx = state.cesta.indexWhere(
                            (item) => item.perfume.idPerfume == p.idPerfume);
                        final yaEnCesta = idx != -1;
                        return _PerfumeRow(
                          perfume:   p,
                          yaEnCesta: yaEnCesta,
                          onAgregar: (ml) {
                            notifier.agregarItem(p, ml);
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(
                                content: Row(children: [
                                  const Icon(Icons.check_circle_rounded,
                                      size: 16, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${p.nombre} añadido',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ]),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.success,
                                margin: const EdgeInsets.fromLTRB(
                                    AppSpacing.md, 0,
                                    AppSpacing.md, AppSpacing.md),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSm),
                                ),
                              ));
                          },
                          onQuitar: yaEnCesta
                              ? () => notifier.quitarItem(idx)
                              : null,
                        );
                      },
                    ),
        ),

        // Botones navegación
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: widget.onAnterior,
                child: const Text('Atrás'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: state.cestaValida ? widget.onSiguiente : null,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Revisar cotización'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Fila de perfume con botones ml ────────────────────────────────────────────

class _PerfumeRow extends StatelessWidget {
  const _PerfumeRow({
    required this.perfume,
    required this.yaEnCesta,
    required this.onAgregar,
    this.onQuitar,
  });
  final Perfume             perfume;
  final bool                yaEnCesta;
  final void Function(int ml) onAgregar;
  final VoidCallback?       onQuitar;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: yaEnCesta ? AppColors.primaryPale : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: yaEnCesta ? AppColors.primary : AppColors.primaryLight,
          width: yaEnCesta ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Info del perfume
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  perfume.nombre,
                  style: AppTextStyles.perfumeName.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  perfume.marca,
                  style: AppTextStyles.marca.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),

          // Botones ml o chip "Añadido"
          if (yaEnCesta)
            GestureDetector(
              onTap: onQuitar,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Añadido',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.close_rounded, size: 12, color: Colors.white70),
                  ],
                ),
              ),
            )
          else
            Row(
              children: [
                if (perfume.precio2ml != null)
                  _MlBtn(ml: 2, precio: perfume.precio2ml!, onTap: () => onAgregar(2)),
                if (perfume.precio5ml != null)
                  _MlBtn(ml: 5, precio: perfume.precio5ml!, onTap: () => onAgregar(5)),
                if (perfume.precio10ml != null)
                  _MlBtn(ml: 10, precio: perfume.precio10ml!, onTap: () => onAgregar(10)),
              ],
            ),
        ],
      ),
    );
  }
}

class _MlBtn extends StatefulWidget {
  const _MlBtn({
    required this.ml,
    required this.precio,
    required this.onTap,
  });
  final int          ml;
  final double       precio;
  final VoidCallback onTap;

  @override
  State<_MlBtn> createState() => _MlBtnState();
}

class _MlBtnState extends State<_MlBtn> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.88).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    await _ctrl.forward();
    await _ctrl.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: GestureDetector(
          onTap: _onTap,
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.ml}ml',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'S/${widget.precio.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

// ── Paso 3: Resumen + confirmar ───────────────────────────────────────────────

class _Paso3 extends ConsumerWidget {
  const _Paso3({required this.onAnterior, required this.onGuardar});
  final VoidCallback onAnterior;
  final VoidCallback onGuardar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(nuevaCotizacionProvider);
    final notifier = ref.read(nuevaCotizacionProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Datos del cliente
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryPale,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  state.celular,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          Text(
            'Perfumes cotizados',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Items de la cesta
          ...state.cesta.asMap().entries.map((e) {
            final notifier = ref.read(nuevaCotizacionProvider.notifier);
            return Dismissible(
              key: ValueKey('${e.value.perfume.idPerfume}_${e.value.ml}_${e.key}'),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => notifier.quitarItem(e.key),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: AppSpacing.lg),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.delete_rounded, color: AppColors.error, size: 20),
                    SizedBox(width: 4),
                    Text('Eliminar',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        )),
                    SizedBox(width: AppSpacing.sm),
                  ],
                ),
              ),
              child: ItemCestaCard(
                item:     e.value,
                index:    e.key,
                onQuitar: () => notifier.quitarItem(e.key),
              ),
            );
          }),

          const SizedBox(height: AppSpacing.sm),

          // Toggle delivery
          GestureDetector(
            onTap: notifier.toggleDelivery,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: state.conDelivery
                    ? AppColors.primaryPale
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: state.conDelivery
                      ? AppColors.primary
                      : AppColors.primaryLight,
                  width: state.conDelivery ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.delivery_dining_rounded,
                    size: 20,
                    color: state.conDelivery
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Incluir delivery',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: state.conDelivery
                                ? AppColors.primaryDark
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '+S/ 10.00 (solo en el mensaje al cliente)',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: state.conDelivery,
                    onChanged: (_) => notifier.toggleDelivery(),
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primaryLight,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Total
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SUBTOTAL',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'S/ ${state.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (state.conDelivery) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'DELIVERY',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'S/ 10.00',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 16),
                ],
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL COTIZACIÓN',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'S/ ${state.totalConDelivery.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (state.error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                state.error!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.error),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              OutlinedButton(
                onPressed:
                    state.registrando ? null : onAnterior,
                child: const Text('Editar'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      state.registrando ? null : onGuardar,
                  icon: state.registrando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(state.registrando
                      ? 'Guardando...'
                      : 'Enviar cotización'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md),
                  ),
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

class _TicketExito extends StatefulWidget {
  const _TicketExito({
    required this.idCotizacion,
    required this.celular,
    required this.total,
    required this.cesta,
    required this.conDelivery,
    required this.onNueva,
  });
  final String          idCotizacion;
  final String          celular;
  final double          total;
  final List<ItemCesta> cesta;
  final bool            conDelivery;
  final VoidCallback    onNueva;

  @override
  State<_TicketExito> createState() => _TicketExitoState();
}

class _TicketExitoState extends State<_TicketExito>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;
  late final Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _abrirWhatsApp() async {
    final lineas = widget.cesta.map((i) =>
      '• ${i.perfume.nombre} (${i.ml}ml) — S/ ${i.precio.toStringAsFixed(2)}',
    ).join('\n');
    final deliveryLinea = widget.conDelivery ? '\n• Delivery — S/ 10.00' : '';
    final texto =
        '¡Hola! 🌸 Te enviamos tu cotización (ID: ${widget.idCotizacion}):\n\n'
        '$lineas$deliveryLinea\n\n'
        'Total: S/ ${widget.total.toStringAsFixed(2)}';
    final numero = widget.celular.replaceAll(RegExp(r'\D'), '');
    final prefijo = numero.startsWith('51') ? numero : '51$numero';
    final uri = Uri.parse(
        'https://wa.me/$prefijo?text=${Uri.encodeComponent(texto)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: FadeTransition(
        opacity: _fade,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xl),
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 44),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '¡Cotización enviada!',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryPale,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                'ID: ${widget.idCotizacion}',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryPale,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.primaryLight),
              ),
              child: Column(
                children: [
                  _InfoLine(label: 'Celular', value: widget.celular),
                  const Divider(height: 16),
                  ...widget.cesta.map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _InfoLine(
                      label: '${i.perfume.nombre} ${i.ml}ml',
                      value: 'S/ ${i.precio.toStringAsFixed(2)}',
                    ),
                  )),
                  if (widget.conDelivery) ...[
                    _InfoLine(label: 'Delivery', value: '+ S/ 10.00'),
                    const SizedBox(height: 4),
                  ],
                  const Divider(height: 12),
                  _InfoLine(
                    label: 'Total cliente',
                    value: 'S/ ${widget.total.toStringAsFixed(2)}',
                    highlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _abrirWhatsApp,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Enviar por WhatsApp'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF25D366),
                  side: const BorderSide(color: Color(0xFF25D366)),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: widget.onNueva,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nueva cotización'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Panel expandible de cesta (Paso 2) ───────────────────────────────────────

class _CestaPanel extends StatefulWidget {
  const _CestaPanel({
    required this.cesta,
    required this.total,
    required this.onQuitar,
  });
  final List<ItemCesta>      cesta;
  final double               total;
  final void Function(int)   onQuitar;

  @override
  State<_CestaPanel> createState() => _CestaPanelState();
}

class _CestaPanelState extends State<_CestaPanel> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      decoration: BoxDecoration(
        color: _expandido ? AppColors.primaryPale : AppColors.primaryPale,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: _expandido ? AppColors.primary : AppColors.primaryLight,
          width: _expandido ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Cabecera tappeable
          InkWell(
            onTap: () => setState(() => _expandido = !_expandido),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${widget.cesta.length} ítem${widget.cesta.length != 1 ? 's' : ''} seleccionado${widget.cesta.length != 1 ? 's' : ''}',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.primaryDark),
                  ),
                  const Spacer(),
                  Text(
                    'S/ ${widget.total.toStringAsFixed(2)}',
                    style: AppTextStyles.price
                        .copyWith(fontSize: 14, color: AppColors.primaryDark),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    _expandido
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          // Lista de ítems expandible
          if (_expandido) ...[
            const Divider(height: 1),
            ...widget.cesta.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.sm, AppSpacing.sm, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${e.value.ml}ml',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          e.value.perfume.nombre,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'S/ ${e.value.precio.toStringAsFixed(2)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 16, color: AppColors.error),
                        onPressed: () => widget.onQuitar(e.key),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
    this.highlight = false,
  });
  final String label;
  final String value;
  final bool   highlight;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w700,
              color: highlight ? AppColors.primaryDark : AppColors.textPrimary,
            ),
          ),
        ],
      );
}

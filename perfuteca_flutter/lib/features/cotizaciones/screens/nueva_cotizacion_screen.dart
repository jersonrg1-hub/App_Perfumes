import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/features/cotizaciones/providers/nueva_cotizacion_provider.dart';
import 'package:perfuteca/features/ventas/screens/cotizaciones_hoy_screen.dart';
import 'package:perfuteca/features/ventas/widgets/item_cesta_card.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/models/venta.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';

// Timings unificados (H)
const _kFast   = Duration(milliseconds: 160);
const _kNormal = Duration(milliseconds: 220);
const _kPage   = Duration(milliseconds: 300);

String _fmtPrecio(double p) =>
    p == p.truncateToDouble() ? p.toInt().toString() : p.toStringAsFixed(2);

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
    FocusScope.of(context).unfocus();
    ref.read(nuevaCotizacionProvider.notifier).irPaso(paso);
    _pageCtrl.animateToPage(
      paso - 1,
      duration: _kPage,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nuevaCotizacionProvider);

    // Cuando se registra exitosamente, salta a paso 3
    ref.listen(nuevaCotizacionProvider, (prev, next) {
      if (prev?.paso != 3 && next.paso == 3) {
        _pageCtrl.animateToPage(2, duration: _kPage, curve: Curves.easeInOut);
        ref.invalidate(cotizacionesHoyProvider);
      }
    });

    return Column(
      children: [
        // G: step indicator con info contextual de pasos completados
        _StepIndicator(
          paso:       state.paso,
          onTapPaso:  _irA,
          celular:    state.celular,
          cestaCount: state.cesta.length,
        ),
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

// ── Indicador de pasos (G: info contextual + H: timings) ─────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.paso,
    required this.onTapPaso,
    required this.celular,
    required this.cestaCount,
  });
  final int                paso;
  final void Function(int) onTapPaso;
  final String             celular;
  final int                cestaCount;

  @override
  Widget build(BuildContext context) {
    final step1Sub = paso > 1 && celular.length >= 4
        ? '···${celular.substring(celular.length - 4)}'
        : null;
    final step2Sub = paso > 2 && cestaCount > 0
        ? '$cestaCount ítem${cestaCount != 1 ? 's' : ''}'
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm, horizontal: AppSpacing.lg),
      color: AppColors.surface,
      child: Row(
        children: [
          _Dot(n: 1, label: 'Celular',   sublabel: step1Sub,
              activo: paso >= 1, actual: paso == 1,
              onTap: paso > 1 ? () => onTapPaso(1) : null),
          _Linea(activa: paso >= 2),
          _Dot(n: 2, label: 'Perfumes',  sublabel: step2Sub,
              activo: paso >= 2, actual: paso == 2,
              onTap: paso > 2 ? () => onTapPaso(2) : null),
          _Linea(activa: paso >= 3),
          _Dot(n: 3, label: 'Confirmar', sublabel: null,
              activo: paso >= 3, actual: paso == 3,
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
    this.sublabel,
    required this.activo,
    required this.actual,
    this.onTap,
  });
  final int           n;
  final String        label;
  final String?       sublabel;
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
                duration: _kNormal, // H: 250→220ms
                width:  actual ? 30 : 24,
                height: actual ? 30 : 24,
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
                      ? const Icon(Icons.edit_rounded, size: 14, color: Colors.white)
                      : activo
                          ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                          : Text('$n', style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: AppColors.textMuted)),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTextStyles.priceLabel.copyWith(
                  color: activo ? AppColors.primaryDark : AppColors.textFaint,
                  fontWeight: actual ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              // G: sublabel con info de paso completado
              AnimatedSwitcher(
                duration: _kNormal,
                child: sublabel != null
                    ? Text(
                        sublabel!,
                        key: ValueKey(sublabel),
                        style: AppTextStyles.priceLabel.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                        overflow: TextOverflow.ellipsis,
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
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
        child: AnimatedContainer(
          duration: _kNormal,
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
              Text('Nueva cotización',
                  style: AppTextStyles.heading2.copyWith(fontSize: 18)),
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
              helperText: 'Acepta formato WhatsApp, con o sin código de país',
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
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
        // A: _CestaPanel con estado controlado desde aquí
        if (state.cesta.isNotEmpty)
          _CestaPanel(
            cesta:    state.cesta,
            total:    state.total,
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
              // C: solo la X del campo, sin "Limpiar" redundante
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

        // C: contador sin "Limpiar" duplicado
        if (!catalogoState.isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md + AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _filtro.isEmpty
                    ? '${perfumes.length} perfumes'
                    : '${perfumes.length} resultado${perfumes.length != 1 ? 's' : ''} para "$_filtro"',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted),
              ),
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
                        return _PerfumeRow(
                          perfume:     p,
                          itemEnCesta: idx != -1 ? state.cesta[idx] : null,
                          onAgregar: (ml) {
                            HapticFeedback.lightImpact();
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
                          onQuitar: idx != -1
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

// ── Fila de perfume con botones ml (B + H) ────────────────────────────────────

class _PerfumeRow extends StatelessWidget {
  const _PerfumeRow({
    required this.perfume,
    required this.itemEnCesta,
    required this.onAgregar,
    this.onQuitar,
  });
  final Perfume             perfume;
  final ItemCesta?          itemEnCesta;
  final void Function(int ml) onAgregar;
  final VoidCallback?       onQuitar;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _kNormal, // H: 200→220ms
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: itemEnCesta != null ? AppColors.primaryPale : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: itemEnCesta != null ? AppColors.primary : AppColors.primaryLight,
          width: itemEnCesta != null ? 1.5 : 1,
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
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  perfume.marca.toUpperCase(),
                  style: AppTextStyles.marca.copyWith(
                    fontSize: 11,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Chip en cesta o botones ml (B: Wrap para responsividad)
          if (itemEnCesta != null)
            GestureDetector(
              onTap: onQuitar,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${itemEnCesta!.ml}ml · S/${_fmtPrecio(itemEnCesta!.precio)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.close_rounded, size: 12, color: Colors.white70),
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

// H: botón ml, animación 160ms (era 120ms)
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
    _ctrl  = AnimationController(vsync: this, duration: _kFast);
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
                    'S/${_fmtPrecio(widget.precio)}',
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
                  color: AppColors.errorSurface,
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
                item:           e.value,
                index:          e.key,
                onQuitar:       () => notifier.quitarItem(e.key),
                nombreFontSize: 15,
                marcaFontSize:  12,
              ),
            );
          }),

          const SizedBox(height: AppSpacing.sm),

          // Toggle delivery
          GestureDetector(
            onTap: notifier.toggleDelivery,
            child: AnimatedContainer(
              duration: _kNormal,
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
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                color: AppColors.errorSurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                state.error!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              OutlinedButton(
                onPressed: state.registrando ? null : onAnterior,
                child: const Text('Editar'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: state.registrando ? null : onGuardar,
                  icon: state.registrando
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                      state.registrando ? 'Guardando...' : 'Enviar cotización'),
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
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
    const sep = '────────────────────';
    final bloques = <String>[];
    for (var idx = 0; idx < widget.cesta.length; idx++) {
      final i = widget.cesta[idx];
      final nombreCompleto = '${i.perfume.marca} ${i.perfume.nombre}'.trim();
      bloques.add(
        '*${idx + 1}.* 🌸 *$nombreCompleto*\n'
        '     📏 ${i.ml}ml  ·  💰 *S/ ${i.precio.toStringAsFixed(2)}*',
      );
    }
    final deliveryLine = widget.conDelivery ? '🛵 Delivery: +S/ 10.00\n' : '';
    final texto =
        '✨ *Tu cotización — Perfuteca* ✨\n$sep\n\n'
        '${bloques.join('\n\n')}\n\n'
        '$sep\n$deliveryLine'
        '💰 *Total: S/ ${widget.total.toStringAsFixed(2)}*\n$sep';
    final numero = widget.celular.replaceAll(RegExp(r'\D'), '');
    final prefijo = numero.startsWith('51') ? numero : '51$numero';
    final uri = Uri.parse(
        'https://wa.me/$prefijo?text=${Uri.encodeComponent(texto)}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
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
            const SizedBox(height: AppSpacing.lg),
            _ReceiptCard(
              idCotizacion: widget.idCotizacion,
              celular:      widget.celular,
              cesta:        widget.cesta,
              conDelivery:  widget.conDelivery,
              total:        widget.total,
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
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
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

// ── Panel expandible de cesta ─────────────────────────────────────────────────

class _CestaPanel extends StatefulWidget {
  const _CestaPanel({
    required this.cesta,
    required this.total,
    required this.onQuitar,
  });
  final List<ItemCesta>    cesta;
  final double             total;
  final void Function(int) onQuitar;

  @override
  State<_CestaPanel> createState() => _CestaPanelState();
}

class _CestaPanelState extends State<_CestaPanel> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _kNormal,
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      decoration: BoxDecoration(
        color: _expandido ? AppColors.surface : AppColors.primaryPale,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: _expandido ? AppColors.primary : AppColors.primaryLight,
          width: _expandido ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
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
                  AnimatedRotation(
                    turns: _expandido ? 0.5 : 0,
                    duration: _kNormal,
                    child: const Icon(Icons.expand_more_rounded,
                        size: 18, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          if (_expandido) ...[
            const Divider(height: 1),
            ...widget.cesta.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.sm, AppSpacing.sm, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 28, height: 20,
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
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.textPrimary,
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

// ── Ticket de recibo (F: más compacto, ID prominente) ────────────────────────

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({
    required this.idCotizacion,
    required this.celular,
    required this.cesta,
    required this.conDelivery,
    required this.total,
  });
  final String          idCotizacion;
  final String          celular;
  final List<ItemCesta> cesta;
  final bool            conDelivery;
  final double          total;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFDF9),
        boxShadow: [
          BoxShadow(color: Color(0x28000000), blurRadius: 20, offset: Offset(0, 6)),
          BoxShadow(color: Color(0x0F000000), blurRadius: 4,  offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          const _PerforatedEdge(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: Column(
              children: [
                // F: cabecera con icono + ID badge prominente con fondo primary
                Row(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.local_florist_rounded,
                            size: 13, color: AppColors.primary),
                        SizedBox(width: 5),
                        Text(
                          'PERFUTECA',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDark,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // F: ID badge fondo primary, texto blanco — más visible
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        idCotizacion,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                // Celular
                Row(
                  children: [
                    const Icon(Icons.phone_outlined,
                        size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 5),
                    Text(
                      celular,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const _DashedDivider(),
                const SizedBox(height: AppSpacing.sm),
                // F: items más compactos (bottom: 5 en vez de 8)
                ...cesta.map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      const Icon(Icons.local_florist_outlined,
                          size: 10, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '${i.perfume.nombre}  ${i.ml}ml',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        'S/ ${i.precio.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                )),
                if (conDelivery)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        Icon(Icons.delivery_dining_rounded,
                            size: 10, color: AppColors.textMuted),
                        SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Delivery',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '+ S/ 10.00',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                const _DashedDivider(),
                const SizedBox(height: AppSpacing.sm),
                // F: total más impactante con alineación clara
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'S/ ${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
          const _PerforatedEdge(),
        ],
      ),
    );
  }
}

class _PerforatedEdge extends StatelessWidget {
  const _PerforatedEdge();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (_, constraints) {
          final count = (constraints.maxWidth / 16).floor();
          return SizedBox(
            height: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                count,
                (_) => Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 1,
        width: double.infinity,
        child: CustomPaint(painter: _DashedLinePainter()),
      );
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryLight
      ..strokeWidth = 1.2;
    double x = 0;
    const dashWidth = 5.0;
    const gapWidth  = 4.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter _) => false;
}

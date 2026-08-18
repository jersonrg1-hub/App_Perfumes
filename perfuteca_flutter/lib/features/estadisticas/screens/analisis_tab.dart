import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/repositories/config_repository.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';
import 'package:perfuteca/widgets/common/app_error_widget.dart';
import 'package:shimmer/shimmer.dart';

// Defaults usados solo mientras appConfigProvider carga o si falla (sin red).
const double _kCriticoDefault = 10;
const double _kBajoDefault    = 20;

enum _FiltroStock { todos, critico, bajo, ok }
enum _OrdenStock  { menorPrimero, mayorPrimero, nombreAZ }

class AnalisisTab extends ConsumerStatefulWidget {
  const AnalisisTab({super.key});

  @override
  ConsumerState<AnalisisTab> createState() => _AnalisisTabState();
}

class _AnalisisTabState extends ConsumerState<AnalisisTab>
    with AutomaticKeepAliveClientMixin {
  _FiltroStock _filtro = _FiltroStock.todos;
  _OrdenStock  _orden  = _OrdenStock.menorPrimero;
  String       _buscar = '';
  final _buscarCtrl    = TextEditingController();
  Timer?       _debounce;

  List<Perfume> _listaFiltrada(
    List<Perfume> todos,
    double critico,
    double bajo,
  ) {
    var lista = switch (_filtro) {
      _FiltroStock.todos   => todos,
      _FiltroStock.critico => todos.where((p) => p.stockMl! <= critico).toList(),
      _FiltroStock.bajo    => todos
          .where((p) => p.stockMl! > critico && p.stockMl! <= bajo)
          .toList(),
      _FiltroStock.ok => todos.where((p) => p.stockMl! > bajo).toList(),
    };

    lista = switch (_orden) {
      _OrdenStock.menorPrimero => (lista..sort((a, b) =>
          (a.stockMl ?? 0).compareTo(b.stockMl ?? 0))),
      _OrdenStock.mayorPrimero => (lista..sort((a, b) =>
          (b.stockMl ?? 0).compareTo(a.stockMl ?? 0))),
      _OrdenStock.nombreAZ     => (lista..sort((a, b) =>
          a.nombre.compareTo(b.nombre))),
    };

    if (_buscar.isNotEmpty) {
      final q = _buscar.toLowerCase();
      lista = lista
          .where((p) =>
              p.nombre.toLowerCase().contains(q) ||
              p.marca.toLowerCase().contains(q))
          .toList();
    }

    return lista;
  }

  void _onBuscarChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _buscar = v.trim());
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _debounce?.cancel();
    _buscarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final estado = ref.watch(catalogoProvider);
    final config = ref.watch(appConfigProvider).valueOrNull;
    final critico = (config?.stockCriticoMl ?? _kCriticoDefault).toDouble();
    final bajo    = (config?.stockBajoMl    ?? _kBajoDefault).toDouble();

    if (estado.isLoading) {
      return const _StockSkeleton();
    }
    if (estado.error != null) {
      return AppErrorWidget(
        error: estado.error!,
        title: 'Error al cargar catálogo',
        icon: Icons.wifi_off_rounded,
        subtle: true,
        onRetry: () => ref.read(catalogoProvider.notifier).refresh(),
      );
    }

    final todos   = estado.perfumes
        .where((p) => p.stockMl != null)
        .toList();
    final criticos = todos.where((p) => p.stockMl! <= critico).length;
    final bajos    = todos
        .where((p) => p.stockMl! > critico && p.stockMl! <= bajo)
        .length;
    final ok       = todos.where((p) => p.stockMl! > bajo).length;

    final lista = _listaFiltrada(todos, critico, bajo);

    final maxStock = todos.isEmpty
        ? 100.0
        : todos.fold(0.0, (m, p) => (p.stockMl ?? 0) > m ? p.stockMl! : m);

    // Cabecera estática: chips + búscador + filtros + contador
    final header = [
      // ── Resumen de stock ─────────────────────────────────────
      Row(children: [
        Expanded(child: _StockChip(label: 'Total',   valor: '${todos.length}', color: AppColors.primaryPale,         textColor: AppColors.textPrimary)),
        const SizedBox(width: 6),
        Expanded(child: _StockChip(label: 'Crítico', valor: '$criticos',        color: AppColors.errorSurface,   textColor: AppColors.stockCritical)),
        const SizedBox(width: 6),
        Expanded(child: _StockChip(label: 'Bajo',    valor: '$bajos',           color: AppColors.warningSurface, textColor: AppColors.stockLow)),
        const SizedBox(width: 6),
        Expanded(child: _StockChip(label: 'OK',      valor: '$ok',              color: AppColors.successSurface, textColor: AppColors.stockOk)),
      ]),
      const SizedBox(height: AppSpacing.sm),
      // ── Buscador ─────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: TextField(
          controller: _buscarCtrl,
          decoration: InputDecoration(
            hintText: 'Buscar perfume...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            isDense: true,
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
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
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            suffixIcon: _buscar.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _debounce?.cancel();
                      _buscarCtrl.clear();
                      setState(() => _buscar = '');
                    },
                  )
                : null,
          ),
          onChanged: _onBuscarChanged,
        ),
      ),
      // ── Filtros y ordenamiento ────────────────────────────────
      Row(
        children: [
          Expanded(
            flex: 2,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Mostrar',
                isDense: true,
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  borderSide: const BorderSide(color: AppColors.primaryLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  borderSide: const BorderSide(color: AppColors.primaryLight),
                ),
              ),
              child: DropdownButton<_FiltroStock>(
                value: _filtro, isExpanded: true, isDense: true,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: _FiltroStock.todos,   child: Text('Todos')),
                  DropdownMenuItem(value: _FiltroStock.critico, child: Text('Críticos')),
                  DropdownMenuItem(value: _FiltroStock.bajo,    child: Text('Bajos')),
                  DropdownMenuItem(value: _FiltroStock.ok,      child: Text('OK')),
                ],
                onChanged: (v) => setState(() => _filtro = v!),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Ordenar por',
                isDense: true,
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  borderSide: const BorderSide(color: AppColors.primaryLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  borderSide: const BorderSide(color: AppColors.primaryLight),
                ),
              ),
              child: DropdownButton<_OrdenStock>(
                value: _orden, isExpanded: true, isDense: true,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: _OrdenStock.menorPrimero, child: Text('Stock ↑')),
                  DropdownMenuItem(value: _OrdenStock.mayorPrimero, child: Text('Stock ↓')),
                  DropdownMenuItem(value: _OrdenStock.nombreAZ,     child: Text('Nombre A-Z')),
                ],
                onChanged: (v) => setState(() => _orden = v!),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        '${lista.length} perfume${lista.length != 1 ? 's' : ''}',
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w700, color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
    ];

    if (lista.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          ...header,
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: Text(
                'No hay perfumes en esta categoría',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate(header),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl),
          sliver: SliverList.builder(
            itemCount: lista.length,
            itemBuilder: (_, i) => _StockRow(
              perfume: lista[i],
              maxStock: maxStock,
              critico: critico,
              bajo: bajo,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Chip de resumen de stock ──────────────────────────────────────────────────

class _StockChip extends StatelessWidget {
  const _StockChip({
    required this.label,
    required this.valor,
    required this.color,
    required this.textColor,
  });
  final String label;
  final String valor;
  final Color  color;
  final Color  textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color:      textColor,
              fontWeight: FontWeight.w600,
              fontSize:   11,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            valor,
            style: AppTextStyles.body.copyWith(
              color:      textColor,
              fontWeight: FontWeight.w700,
              fontSize:   20,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Fila de stock ─────────────────────────────────────────────────────────────

class _StockRow extends StatelessWidget {
  const _StockRow({
    required this.perfume,
    required this.maxStock,
    required this.critico,
    required this.bajo,
  });
  final Perfume perfume;
  final double  maxStock;
  final double  critico;
  final double  bajo;

  Color get _barColor {
    final s = perfume.stockMl ?? 0;
    if (s <= critico) return AppColors.stockCritical;
    if (s <= bajo)     return AppColors.stockLow;
    return AppColors.stockOk;
  }

  @override
  Widget build(BuildContext context) {
    final stock = perfume.stockMl ?? 0;
    final pct   = maxStock > 0 ? (stock / maxStock).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm - 2),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      perfume.marca.toUpperCase(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color:         AppColors.primary,
                        fontWeight:    FontWeight.w700,
                        fontSize:      10,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      perfume.nombre,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _StockBadge(stock: stock, critico: critico, bajo: bajo),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Container(color: AppColors.primaryLight),
                  FractionallySizedBox(
                    widthFactor: pct,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _barColor.withValues(alpha: 0.7),
                            _barColor,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton de carga ─────────────────────────────────────────────────────────

class _StockSkeleton extends StatelessWidget {
  const _StockSkeleton();

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor:      AppColors.primaryLight,
        highlightColor: AppColors.primaryPale,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Row(children: List.generate(4, (i) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ))),
            const SizedBox(height: AppSpacing.sm),
            Container(height: 44, decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            )),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              Expanded(flex: 2, child: Container(height: 44, decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ))),
              const SizedBox(width: AppSpacing.sm),
              Expanded(flex: 3, child: Container(height: 44, decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ))),
            ]),
            const SizedBox(height: AppSpacing.sm),
            ...List.generate(8, (_) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm - 2),
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            )),
          ],
        ),
      );
}

// ── Badge de stock ────────────────────────────────────────────────────────────

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.stock, required this.critico, required this.bajo});
  final double stock;
  final double critico;
  final double bajo;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;

    if (stock <= critico) {
      bg    = AppColors.errorSurface;
      fg    = AppColors.stockCritical;
    } else if (stock <= bajo) {
      bg    = AppColors.warningSurface;
      fg    = AppColors.stockLow;
    } else {
      bg    = AppColors.successSurface;
      fg    = AppColors.stockOk;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: fg),
          const SizedBox(width: 4),
          Text(
            '${stock.toStringAsFixed(0)} ml',
            style: AppTextStyles.bodySmall.copyWith(
              color:      fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

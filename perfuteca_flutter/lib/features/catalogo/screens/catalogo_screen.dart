import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';
import 'package:perfuteca/widgets/common/app_error_widget.dart';
import 'package:perfuteca/widgets/common/app_loading_widget.dart';
import 'package:perfuteca/widgets/perfume/perfume_card.dart';

// ── Ordenamiento ──────────────────────────────────────────────────────────────

enum _Sort {
  nombre('Nombre A-Z',    Icons.sort_by_alpha_rounded),
  precioAsc('Precio ↑',  Icons.arrow_upward_rounded),
  precioDesc('Precio ↓', Icons.arrow_downward_rounded),
  stock('Más stock',     Icons.inventory_2_outlined);

  const _Sort(this.label, this.icon);
  final String   label;
  final IconData icon;
}

double _minPrecio(Perfume p) =>
    p.precios.isEmpty ? double.infinity : p.precios.values.reduce((a, b) => a < b ? a : b);

// ── Pantalla ──────────────────────────────────────────────────────────────────

class CatalogoScreen extends ConsumerStatefulWidget {
  const CatalogoScreen({super.key});

  @override
  ConsumerState<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends ConsumerState<CatalogoScreen> {
  final _scrollController = ScrollController();
  String? _marcaFiltro;
  _Sort   _sort = _Sort.nombre;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(catalogoProvider.notifier).loadMore();
    }
  }

  List<Perfume> _applyFilters(List<Perfume> all) {
    var lista = _marcaFiltro == null
        ? all
        : all.where((p) => p.marca == _marcaFiltro).toList();

    return switch (_sort) {
      _Sort.nombre     => ([...lista]..sort((a, b) => a.nombre.compareTo(b.nombre))),
      _Sort.precioAsc  => ([...lista]..sort((a, b) => _minPrecio(a).compareTo(_minPrecio(b)))),
      _Sort.precioDesc => ([...lista]..sort((a, b) => _minPrecio(b).compareTo(_minPrecio(a)))),
      _Sort.stock      => ([...lista]..sort((a, b) =>
            (b.stockMl ?? 0).compareTo(a.stockMl ?? 0))),
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(catalogoProvider);
    if (state.isLoading && state.perfumes.isEmpty) return const CatalogoShimmer();
    if (state.error != null && state.perfumes.isEmpty) {
      return AppErrorWidget(
        error: state.error!,
        onRetry: () => ref.read(catalogoProvider.notifier).refresh(),
      );
    }

    final marcas    = state.perfumes.map((p) => p.marca).toSet().toList()..sort();
    final filtrados = _applyFilters(state.perfumes);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(catalogoProvider.notifier).refresh(),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.surface,
            elevation: 0,
            scrolledUnderElevation: 1,
            shadowColor: AppColors.shadowColor,
            expandedHeight: 108,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, 50, AppSpacing.xl, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Perfuteca',
                            style: AppTextStyles.heading1.copyWith(
                              color: AppColors.primaryDark,
                              fontSize: 22,
                            ),
                          ),
                          if (state.total > 0)
                            Text(
                              '${state.total} perfumes en catálogo',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textMuted),
                            ),
                        ],
                      ),
                    ),
                    // Búsqueda
                    _IconBtn(
                      icon: Icons.search_rounded,
                      onTap: () => context.push('/busqueda'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Ordenar
                    _SortBtn(
                      current: _sort,
                      onChanged: (s) => setState(() => _sort = s),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Chips de marca ────────────────────────────────────────────────
          if (marcas.isNotEmpty)
            SliverToBoxAdapter(
              child: _MarcaChipBar(
                marcas:      marcas,
                activa:      _marcaFiltro,
                onSelect:    (m) => setState(
                  () => _marcaFiltro = m == _marcaFiltro ? null : m,
                ),
              ),
            ),

          // ── Fila resultados ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
              child: Row(
                children: [
                  Text(
                    '${filtrados.length} perfume${filtrados.length != 1 ? 's' : ''}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_marcaFiltro != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      '· $_marcaFiltro',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => setState(() => _marcaFiltro = null),
                      child: const Icon(Icons.close_rounded,
                          size: 14, color: AppColors.primary),
                    ),
                  ],
                  const Spacer(),
                  _SortChip(sort: _sort),
                ],
              ),
            ),
          ),

          // ── Grid ─────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
            sliver: filtrados.isEmpty
                ? SliverToBoxAdapter(
                    child: SizedBox(
                      height: 300,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off_rounded,
                              size: 56, color: AppColors.textFaint),
                          const SizedBox(height: 12),
                          Text(
                            'Sin perfumes de "$_marcaFiltro"',
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => setState(() => _marcaFiltro = null),
                            child: const Text('Ver todos'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:   2,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing:  AppSpacing.md,
                      childAspectRatio: 0.62,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => PerfumeCard(perfume: filtrados[i]),
                      childCount: filtrados.length,
                    ),
                  ),
          ),

          if (state.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2),
                ),
              ),
            ),

          if (state.error != null && state.perfumes.isNotEmpty)
            SliverToBoxAdapter(
              child: AppErrorWidget(
                error: state.error!,
                compact: true,
                onRetry: () => ref.read(catalogoProvider.notifier).loadMore(),
              ),
            ),

          const SliverPadding(
              padding: EdgeInsets.only(bottom: AppSpacing.xxl)),
        ],
      ),
    );
  }
}

// ── Botón de icono redondeado ─────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData     icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.primaryPale,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: AppColors.primaryDark, size: 22),
          ),
        ),
      );
}

// ── Botón de ordenar ──────────────────────────────────────────────────────────

class _SortBtn extends StatelessWidget {
  const _SortBtn({required this.current, required this.onChanged});
  final _Sort                   current;
  final void Function(_Sort)    onChanged;

  @override
  Widget build(BuildContext context) => PopupMenuButton<_Sort>(
        onSelected: onChanged,
        tooltip: 'Ordenar',
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        itemBuilder: (_) => _Sort.values
            .map((s) => PopupMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      Icon(s.icon,
                          size: 16,
                          color: s == current
                              ? AppColors.primary
                              : AppColors.textMuted),
                      const SizedBox(width: 8),
                      Text(
                        s.label,
                        style: TextStyle(
                          color: s == current
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight: s == current
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      if (s == current) ...[
                        const Spacer(),
                        const Icon(Icons.check_rounded,
                            size: 14, color: AppColors.primary),
                      ],
                    ],
                  ),
                ))
            .toList(),
        child: Material(
          color: AppColors.primaryPale,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(current.icon,
                color: AppColors.primaryDark, size: 22),
          ),
        ),
      );
}

// ── Chip que muestra el orden activo ─────────────────────────────────────────

class _SortChip extends StatelessWidget {
  const _SortChip({required this.sort});
  final _Sort sort;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primaryPale,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(sort.icon, size: 11, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              sort.label,
              style: AppTextStyles.priceLabel
                  .copyWith(color: AppColors.primaryDark),
            ),
          ],
        ),
      );
}

// ── Barra de filtro de marcas ─────────────────────────────────────────────────

class _MarcaChipBar extends StatelessWidget {
  const _MarcaChipBar({
    required this.marcas,
    required this.activa,
    required this.onSelect,
  });
  final List<String>        marcas;
  final String?             activa;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            // Chip "Todas"
            _MarcaChip(
              label:  'Todas',
              activo: activa == null,
              onTap:  () {
                if (activa != null) onSelect(activa!); // toggle off
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            ...marcas.map((m) => Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: _MarcaChip(
                    label:  m,
                    activo: m == activa,
                    onTap:  () => onSelect(m),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _MarcaChip extends StatelessWidget {
  const _MarcaChip({
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
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 7),
          decoration: BoxDecoration(
            color: activo ? AppColors.primary : AppColors.primaryPale,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: activo ? AppColors.primary : AppColors.primaryLight,
              width: activo ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
              color: activo ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      );
}

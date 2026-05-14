import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/features/busqueda/providers/busqueda_provider.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';
import 'package:perfuteca/widgets/common/app_error_widget.dart';
import 'package:perfuteca/widgets/common/app_loading_widget.dart';
import 'package:perfuteca/widgets/common/empty_state_widget.dart';
import 'package:perfuteca/widgets/perfume/perfume_card.dart';

class BusquedaScreen extends ConsumerStatefulWidget {
  const BusquedaScreen({super.key});

  @override
  ConsumerState<BusquedaScreen> createState() => _BusquedaScreenState();
}

class _BusquedaScreenState extends ConsumerState<BusquedaScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marcasAsync  = ref.watch(marcasProvider);
    final marcaActiva  = ref.watch(busquedaMarcaProvider);
    final query        = ref.watch(busquedaQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: 'Nombre, marca, notas...',
            hintStyle: AppTextStyles.bodySmall,
            border: InputBorder.none,
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textMuted,
            ),
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    color: AppColors.textMuted,
                    onPressed: () {
                      _controller.clear();
                      ref.read(busquedaQueryProvider.notifier).state = '';
                    },
                  )
                : null,
          ),
          onChanged: (v) =>
              ref.read(busquedaQueryProvider.notifier).state = v,
        ),
        actions: const [SizedBox(width: AppSpacing.sm)],
      ),
      body: Column(
        children: [
          // ── Filtros de marca ────────────────────────────────────────────
          marcasAsync.when(
            loading: () => const SizedBox(height: 52),
            error:   (_, __) => const SizedBox.shrink(),
            data: (marcas) => _MarcaFilterBar(
              marcas:      marcas,
              marcaActiva: marcaActiva,
              onSelect: (m) {
                ref.read(busquedaMarcaProvider.notifier).state =
                    marcaActiva == m ? null : m;
              },
            ),
          ),

          const Divider(height: 1),

          // ── Resultados ──────────────────────────────────────────────────
          Expanded(child: _Resultados()),
        ],
      ),
    );
  }
}

class _MarcaFilterBar extends StatelessWidget {
  const _MarcaFilterBar({
    required this.marcas,
    required this.marcaActiva,
    required this.onSelect,
  });
  final List<String> marcas;
  final String? marcaActiva;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        itemCount: marcas.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final m      = marcas[i];
          final active = m == marcaActiva;
          return GestureDetector(
            onTap: () => onSelect(m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color:  active ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.primaryLight,
                ),
              ),
              child: Text(
                m,
                style: AppTextStyles.bodySmall.copyWith(
                  color: active ? Colors.white : AppColors.textMuted,
                  fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Resultados extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q     = ref.watch(busquedaQueryProvider);
    final marca = ref.watch(busquedaMarcaProvider);

    if (q.trim().isEmpty && (marca == null || marca.isEmpty)) {
      return const EmptyStateWidget(
        icon:     Icons.manage_search_rounded,
        title:    'Escribe para buscar',
        subtitle: 'Por nombre, marca o notas olfativas',
      );
    }

    final async = ref.watch(busquedaResultadosProvider);

    return async.when(
      loading: () => const AppLoadingWidget(),
      error:   (e, _) => AppErrorWidget(error: e),
      data: (perfumes) {
        if (perfumes.isEmpty) {
          return EmptyStateWidget(
            title:    'Sin resultados para "$q"',
            subtitle: 'Prueba con otro nombre o marca',
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0,
              ),
              child: Row(
                children: [
                  Text(
                    '${perfumes.length} resultado${perfumes.length != 1 ? "s" : ""}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:    2,
                  crossAxisSpacing:  AppSpacing.md,
                  mainAxisSpacing:   AppSpacing.md,
                  childAspectRatio:  0.62,
                ),
                itemCount:    perfumes.length,
                itemBuilder:  (_, i) => PerfumeCard(perfume: perfumes[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

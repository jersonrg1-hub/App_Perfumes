import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/features/marcas/providers/marcas_provider.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';
import 'package:perfuteca/widgets/common/app_error_widget.dart';
import 'package:perfuteca/widgets/common/app_loading_widget.dart';
import 'package:perfuteca/widgets/perfume/perfume_card.dart';

class MarcasScreen extends ConsumerWidget {
  const MarcasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marcaActiva = ref.watch(marcaSeleccionadaProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(marcaActiva ?? 'Marcas'),
        leading: marcaActiva != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () =>
                    ref.read(marcaSeleccionadaProvider.notifier).state = null,
              )
            : null,
      ),
      body: marcaActiva == null
          ? _ListaMarcas()
          : _PerfumesPorMarca(marca: marcaActiva),
    );
  }
}

// ── Lista de marcas ────────────────────────────────────────────────────────────

class _ListaMarcas extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(marcasProvider);

    return async.when(
      loading: () => const AppLoadingWidget(),
      error: (e, _) => AppErrorWidget(
        error: e,
        onRetry: () => ref.invalidate(marcasProvider),
      ),
      data: (marcas) => ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: marcas.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, i) {
          final marca = marcas[i];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xs,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _colorForLetter(marca[0]),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Center(
                child: Text(
                  marca[0].toUpperCase(),
                  style: AppTextStyles.heading2.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            title: Text(marca, style: AppTextStyles.perfumeName),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
            onTap: () =>
                ref.read(marcaSeleccionadaProvider.notifier).state = marca,
          );
        },
      ),
    );
  }

  Color _colorForLetter(String letra) {
    // Paleta suave basada en el índice de la letra
    final colores = [
      AppColors.primary,
      AppColors.primaryDark,
      AppColors.gold,
      const Color(0xFF7B6D8D),
      const Color(0xFF5C8A6E),
      const Color(0xFF8A5C5C),
    ];
    return colores[letra.codeUnitAt(0) % colores.length];
  }
}

// ── Perfumes de una marca ─────────────────────────────────────────────────────

class _PerfumesPorMarca extends ConsumerWidget {
  const _PerfumesPorMarca({required this.marca});
  final String marca;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(perfumesPorMarcaProvider(marca));

    return async.when(
      loading: () => const AppLoadingWidget(),
      error: (e, _) => AppErrorWidget(error: e),
      data: (perfumes) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0,
            ),
            child: Row(
              children: [
                Text(
                  '${perfumes.length} perfume${perfumes.length != 1 ? "s" : ""}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:   2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing:  AppSpacing.md,
                childAspectRatio: 0.62,
              ),
              itemCount:   perfumes.length,
              itemBuilder: (_, i) => PerfumeCard(perfume: perfumes[i]),
            ),
          ),
        ],
      ),
    );
  }
}

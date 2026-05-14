import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/features/notas/providers/notas_provider.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';
import 'package:perfuteca/widgets/perfume/perfume_card.dart';

// re-exportamos el provider público — los widgets de este archivo lo usan directamente

// ── Helpers ───────────────────────────────────────────────────────────────────

String _emoji(String nota) {
  final n = nota.toLowerCase();
  if (n.contains('rosa'))                                   return '🌹';
  if (n.contains('jazmín') || n.contains('jazmin'))        return '🌸';
  if (n.contains('lavanda'))                               return '💜';
  if (n.contains('floral') || n.contains('pétalo'))        return '🌺';
  if (n.contains('vainilla'))                              return '🍦';
  if (n.contains('ámbar') || n.contains('amber'))          return '✨';
  if (n.contains('madera') || n.contains('roble'))         return '🪵';
  if (n.contains('cedro'))                                 return '🌲';
  if (n.contains('sándalo') || n.contains('sandalo'))      return '🌳';
  if (n.contains('pachulí') || n.contains('pachuli'))      return '🍃';
  if (n.contains('vetiver') || n.contains('musgo'))        return '🌿';
  if (n.contains('cítric') || n.contains('citric'))        return '🍋';
  if (n.contains('bergamota'))                             return '🍊';
  if (n.contains('limón') || n.contains('limon'))          return '🍋';
  if (n.contains('naranja'))                               return '🍊';
  if (n.contains('durazno') || n.contains('melocotón'))    return '🍑';
  if (n.contains('frut') || n.contains('manzana'))         return '🍎';
  if (n.contains('especia') || n.contains('canela'))       return '🌶️';
  if (n.contains('pimienta'))                              return '🫚';
  if (n.contains('almizcle'))                              return '🌾';
  if (n.contains('acuátic') || n.contains('acuatic')
      || n.contains('marino') || n.contains('agua'))       return '💧';
  if (n.contains('cuero'))                                 return '🤎';
  if (n.contains('tabaco'))                                return '🍂';
  if (n.contains('café') || n.contains('cafe'))            return '☕';
  if (n.contains('iris') || n.contains('violeta'))         return '💐';
  if (n.contains('tuberosa'))                              return '🌼';
  return '🌺';
}

// Fondo + borde asignado por hash para consistencia entre sesiones
Color _bg(String nota) {
  const bgs = [
    Color(0xFFFFF3E0), Color(0xFFFCE4EC), Color(0xFFE8F5E9),
    Color(0xFFF3E5F5), Color(0xFFE3F2FD), Color(0xFFFFF8E1),
    Color(0xFFE0F2F1), Color(0xFFFBE9E7), Color(0xFFF9FBE7),
    Color(0xFFE8EAF6),
  ];
  return bgs[nota.hashCode.abs() % bgs.length];
}

Color _border(String nota) {
  const borders = [
    Color(0xFFFFCC80), Color(0xFFF48FB1), Color(0xFFA5D6A7),
    Color(0xFFCE93D8), Color(0xFF90CAF9), Color(0xFFFFE082),
    Color(0xFF80CBC4), Color(0xFFFF8A65), Color(0xFFDCE775),
    Color(0xFF9FA8DA),
  ];
  return borders[nota.hashCode.abs() % borders.length];
}

Map<String, int> _contarPorNota(List<Perfume> perfumes) {
  final map = <String, int>{};
  for (final p in perfumes) {
    if (p.notas == null || p.notas!.isEmpty) continue;
    for (final n in p.notas!.split(',')) {
      final nota = n.trim();
      if (nota.isNotEmpty) map[nota] = (map[nota] ?? 0) + 1;
    }
  }
  return map;
}

List<Perfume> _filtrarPorNota(List<Perfume> perfumes, String nota) =>
    perfumes.where((p) {
      if (p.notas == null) return false;
      return p.notas!.split(',').map((n) => n.trim()).contains(nota);
    }).toList();

// ── Pantalla principal ────────────────────────────────────────────────────────

class NotasScreen extends ConsumerWidget {
  const NotasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notaActiva = ref.watch(notaSeleccionadaProvider);
    final mapAsync   = ref.watch(perfumesMapProvider);

    final perfumes = mapAsync.valueOrNull?.values.toList() ?? [];
    final conteo   = _contarPorNota(perfumes);
    // ordenadas de mayor a menor popularidad
    final notas    = conteo.keys.toList()
      ..sort((a, b) => conteo[b]!.compareTo(conteo[a]!));

    void seleccionar(String n) {
      ref.read(notaSeleccionadaProvider.notifier).state =
          n == notaActiva ? null : n;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.local_florist_rounded,
                color: AppColors.gold, size: 20),
            const SizedBox(width: AppSpacing.sm),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                notaActiva ?? 'Notas olfativas',
                key: ValueKey(notaActiva),
                style: AppTextStyles.heading2.copyWith(fontSize: 18),
              ),
            ),
          ],
        ),
        actions: [
          if (notaActiva != null)
            IconButton(
              icon: const Icon(Icons.grid_view_rounded, size: 20),
              color: AppColors.textMuted,
              tooltip: 'Ver todas las notas',
              onPressed: () =>
                  ref.read(notaSeleccionadaProvider.notifier).state = null,
            ),
        ],
      ),
      body: mapAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ErrorView(
          onRetry: () => ref.invalidate(perfumesMapProvider),
        ),
        data: (_) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: notaActiva == null
              ? _VistaExplora(
                  key: const ValueKey('explora'),
                  notas:      notas,
                  conteo:     conteo,
                  totalNotas: notas.length,
                  onSelect:   seleccionar,
                )
              : _VistaFiltrada(
                  key:        ValueKey(notaActiva),
                  notaActiva: notaActiva,
                  notas:      notas,
                  filtrados:  _filtrarPorNota(perfumes, notaActiva),
                  onSelect:   seleccionar,
                  onRefresh:  () => ref.refresh(perfumesMapProvider.future),
                ),
        ),
      ),
    );
  }
}

// ── Vista exploración: grid de tarjetas de nota ───────────────────────────────

class _VistaExplora extends StatelessWidget {
  const _VistaExplora({
    super.key,
    required this.notas,
    required this.conteo,
    required this.totalNotas,
    required this.onSelect,
  });
  final List<String>        notas;
  final Map<String, int>    conteo;
  final int                 totalNotas;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.lg,
                AppSpacing.md, AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explora por nota olfativa',
                  style: AppTextStyles.heading2
                      .copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalNotas notas disponibles · toca una para ver los perfumes',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _NotaCard(
                nota:   notas[i],
                conteo: conteo[notas[i]] ?? 0,
                onTap:  () => onSelect(notas[i]),
              ),
              childCount: notas.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:   2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing:  AppSpacing.sm,
              childAspectRatio: 1.65,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tarjeta de nota ───────────────────────────────────────────────────────────

class _NotaCard extends StatelessWidget {
  const _NotaCard({
    required this.nota,
    required this.conteo,
    required this.onTap,
  });
  final String       nota;
  final int          conteo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor     = _bg(nota);
    final borderColor = _border(nota);
    final emojiText   = _emoji(nota);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        splashColor: borderColor.withValues(alpha: 0.3),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(emojiText,
                      style: const TextStyle(fontSize: 24)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: borderColor.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$conteo',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nota,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$conteo perfume${conteo != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0x99000000),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Vista filtrada: banner + chips + grid ─────────────────────────────────────

class _VistaFiltrada extends StatelessWidget {
  const _VistaFiltrada({
    super.key,
    required this.notaActiva,
    required this.notas,
    required this.filtrados,
    required this.onSelect,
    required this.onRefresh,
  });
  final String                  notaActiva;
  final List<String>            notas;
  final List<Perfume>           filtrados;
  final void Function(String)   onSelect;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Banner de nota activa
        _NotaBanner(nota: notaActiva, conteo: filtrados.length),

        // Chip bar (con emojis, compacta)
        _ChipBar(notas: notas, notaActiva: notaActiva, onSelect: onSelect),

        // Grid
        Expanded(
          child: filtrados.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_emoji(notaActiva),
                          style: const TextStyle(fontSize: 48)),
                      const SizedBox(height: 8),
                      Text(
                        'Sin perfumes con nota "$notaActiva"',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: onRefresh,
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.sm,
                        AppSpacing.md, AppSpacing.md),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:   2,
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing:  AppSpacing.sm,
                      childAspectRatio: 0.62,
                    ),
                    itemCount: filtrados.length,
                    itemBuilder: (_, i) => PerfumeCard(perfume: filtrados[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Banner de nota activa ─────────────────────────────────────────────────────

class _NotaBanner extends StatelessWidget {
  const _NotaBanner({required this.nota, required this.conteo});
  final String nota;
  final int    conteo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(
        color: _bg(nota),
        border: Border(
          bottom: BorderSide(color: _border(nota), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          Text(_emoji(nota), style: const TextStyle(fontSize: 22)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              nota,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _border(nota).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$conteo perfume${conteo != 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Barra de chips ────────────────────────────────────────────────────────────

class _ChipBar extends StatelessWidget {
  const _ChipBar({
    required this.notas,
    required this.notaActiva,
    required this.onSelect,
  });
  final List<String>        notas;
  final String?             notaActiva;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: notas.map((nota) {
            final activa = nota == notaActiva;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: GestureDetector(
                onTap: () => onSelect(nota),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + 2, vertical: 6),
                  decoration: BoxDecoration(
                    color: activa ? _border(nota) : _bg(nota),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _border(nota),
                      width: activa ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    '${_emoji(nota)} $nota',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          activa ? FontWeight.w700 : FontWeight.w500,
                      color: activa
                          ? Colors.white
                          : const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColors.textFaint),
            const SizedBox(height: 12),
            Text('Error al cargar perfumes',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
}

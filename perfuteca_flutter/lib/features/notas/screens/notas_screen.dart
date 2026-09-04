import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/features/notas/providers/notas_provider.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';
import 'package:perfuteca/widgets/perfume/perfume_card.dart';

// ── Modo de exploración ───────────────────────────────────────────────────────

enum _Modo {
  notas('Notas',       Icons.spa_outlined),
  perfil('Perfil',     Icons.auto_awesome_outlined),
  ocasion('Ocasión',   Icons.event_outlined),
  estacion('Estación', Icons.wb_sunny_outlined),
  hora('Hora',         Icons.schedule_outlined),
  clave('Estilo',      Icons.label_outline_rounded);

  const _Modo(this.label, this.icon);
  final String   label;
  final IconData icon;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _normalizar(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1).toLowerCase();
}

String _getFieldRaw(Perfume p, _Modo modo) => switch (modo) {
  _Modo.notas    => p.notas          ?? '',
  _Modo.perfil   => p.perfilOlfativo ?? '',
  _Modo.ocasion  => p.ocasion        ?? '',
  _Modo.estacion => p.estacion       ?? '',
  _Modo.hora     => p.hora           ?? '',
  _Modo.clave    => p.palabraClave   ?? '',
};

Map<String, int> _contarPorModo(List<Perfume> perfumes, _Modo modo) {
  final map = <String, int>{};
  for (final p in perfumes) {
    final raw = _getFieldRaw(p, modo);
    if (raw.isEmpty) continue;
    for (final part in raw.split(RegExp(r'[,;|]'))) {
      final item = _normalizar(part.trim());
      if (item.isNotEmpty) map[item] = (map[item] ?? 0) + 1;
    }
  }
  return map;
}

// AND en todos los niveles: el perfume debe tener TODOS los valores
// elegidos, tanto entre categorías como dentro de una misma categoría.
List<Perfume> _filtrarMultiple(
    List<Perfume> perfumes, Map<_Modo, Set<String>> filtros) {
  if (filtros.isEmpty) return perfumes;
  return perfumes.where((p) {
    return filtros.entries.every((entry) {
      final raw = _getFieldRaw(p, entry.key);
      if (raw.isEmpty) return false;
      final items = raw
          .split(RegExp(r'[,;|]'))
          .map((n) => _normalizar(n.trim()))
          .toSet();
      return entry.value.every(items.contains);
    });
  }).toList();
}

String _emoji(String nota) {
  final n = nota.toLowerCase();
  if (n.contains('rosa'))                                 return '🌹';
  if (n.contains('jazmín') || n.contains('jazmin'))      return '🌸';
  if (n.contains('lavanda'))                             return '💜';
  if (n.contains('floral') || n.contains('pétalo'))      return '🌺';
  if (n.contains('vainilla'))                            return '🍦';
  if (n.contains('ámbar') || n.contains('amber'))        return '✨';
  if (n.contains('madera') || n.contains('roble'))       return '🪵';
  if (n.contains('cedro'))                               return '🌲';
  if (n.contains('sándalo') || n.contains('sandalo'))    return '🌳';
  if (n.contains('pachulí') || n.contains('pachuli'))    return '🍃';
  if (n.contains('vetiver') || n.contains('musgo'))      return '🌿';
  if (n.contains('cítric') || n.contains('citric'))      return '🍋';
  if (n.contains('bergamota'))                           return '🍊';
  if (n.contains('limón') || n.contains('limon'))        return '🍋';
  if (n.contains('naranja'))                             return '🍊';
  if (n.contains('durazno') || n.contains('melocotón'))  return '🍑';
  if (n.contains('frut') || n.contains('manzana'))       return '🍎';
  if (n.contains('especia') || n.contains('canela'))     return '🌶️';
  if (n.contains('pimienta'))                            return '🫚';
  if (n.contains('almizcle'))                            return '🌾';
  if (n.contains('acuátic') || n.contains('acuatic')
      || n.contains('marino') || n.contains('agua')) { return '💧'; }
  if (n.contains('cuero'))                               return '🤎';
  if (n.contains('tabaco'))                              return '🍂';
  if (n.contains('café') || n.contains('cafe'))          return '☕';
  if (n.contains('iris') || n.contains('violeta'))       return '💐';
  if (n.contains('tuberosa'))                            return '🌼';
  return '🌺';
}

String _emojiValor(String valor, _Modo modo) {
  if (modo == _Modo.notas) return _emoji(valor);
  final v = valor.toLowerCase();
  switch (modo) {
    case _Modo.perfil:
      if (v.contains('floral'))                          return '🌸';
      if (v.contains('oriental'))                       return '✨';
      if (v.contains('frutal') || v.contains('frut'))   return '🍑';
      if (v.contains('amaderado'))                      return '🪵';
      if (v.contains('acuát') || v.contains('fresc')
          || v.contains('marino')) { return '💧'; }
      if (v.contains('cítric'))                         return '🍋';
      if (v.contains('gourmand') || v.contains('dulce')) return '🍦';
      if (v.contains('especiad'))                       return '🌶️';
      return '🌺';
    case _Modo.ocasion:
      if (v.contains('noche') || v.contains('velada'))  return '🌙';
      if (v.contains('diario') || v.contains('día')
          || v.contains('dia')) { return '☀️'; }
      if (v.contains('trabajo') || v.contains('oficina')) return '💼';
      if (v.contains('cita') || v.contains('romántic')
          || v.contains('romantico')) { return '💕'; }
      if (v.contains('formal') || v.contains('evento')) return '🎭';
      if (v.contains('casual'))                         return '👟';
      return '🎉';
    case _Modo.estacion:
      if (v.contains('verano'))                         return '☀️';
      if (v.contains('invierno'))                      return '❄️';
      if (v.contains('primavera'))                     return '🌸';
      if (v.contains('otoño') || v.contains('otono'))  return '🍂';
      if (v.contains('todo'))                          return '🌍';
      return '🌤️';
    case _Modo.hora:
      if (v.contains('mañana') || v.contains('manana')
          || v.contains('madrugada')) { return '🌅'; }
      if (v.contains('tarde') || v.contains('mediodía')
          || v.contains('mediodia')) { return '🌞'; }
      if (v.contains('noche'))                         return '🌙';
      if (v.contains('todo') || v.contains('cualquier')) return '🕐';
      return '⏰';
    case _Modo.clave:
      if (v.contains('dulce'))                                   return '🍦';
      if (v.contains('intenso'))                                 return '🔥';
      if (v.contains('elegant'))                                 return '💎';
      if (v.contains('fresc'))                                   return '💧';
      if (v.contains('dura') || v.contains('persist'))           return '⏳';
      if (v.contains('versát') || v.contains('versat'))          return '🌈';
      if (v.contains('frutal') || v.contains('frut'))            return '🍑';
      if (v.contains('floral'))                                  return '🌸';
      if (v.contains('mader') || v.contains('ahumad'))           return '🪵';
      if (v.contains('sutil'))                                   return '🌿';
      if (v.contains('distint') || v.contains('único'))          return '✨';
      if (v.contains('postre') || v.contains('gourmand'))        return '🍰';
      if (v.contains('romántic') || v.contains('romantico'))     return '💕';
      if (v.contains('atrevid') || v.contains('sensual'))        return '🌹';
      return '🏷️';
    default:
      return '🏷️';
  }
}

Color _bg(String valor) {
  const bgs = [
    Color(0xFFFFF3E0), Color(0xFFFCE4EC), Color(0xFFE8F5E9),
    Color(0xFFF3E5F5), Color(0xFFE3F2FD), Color(0xFFFFF8E1),
    Color(0xFFE0F2F1), Color(0xFFFBE9E7), Color(0xFFF9FBE7),
    Color(0xFFE8EAF6),
  ];
  return bgs[valor.hashCode.abs() % bgs.length];
}

Color _border(String valor) {
  const borders = [
    Color(0xFFFFCC80), Color(0xFFF48FB1), Color(0xFFA5D6A7),
    Color(0xFFCE93D8), Color(0xFF90CAF9), Color(0xFFFFE082),
    Color(0xFF80CBC4), Color(0xFFFF8A65), Color(0xFFDCE775),
    Color(0xFF9FA8DA),
  ];
  return borders[valor.hashCode.abs() % borders.length];
}

// ── Pantalla principal ────────────────────────────────────────────────────────

class NotasScreen extends ConsumerStatefulWidget {
  const NotasScreen({super.key});

  @override
  ConsumerState<NotasScreen> createState() => _NotasScreenState();
}

class _NotasScreenState extends ConsumerState<NotasScreen> {
  _Modo _modo = _Modo.notas;
  final Map<_Modo, Set<String>> _filtros = {};

  bool get _tieneFiltros => _filtros.isNotEmpty;

  void _setModo(_Modo modo) {
    if (_modo == modo) return;
    setState(() => _modo = modo);
  }

  void _toggleFiltro(String valor) {
    setState(() {
      final set = _filtros.putIfAbsent(_modo, () => {});
      if (!set.add(valor)) set.remove(valor);
      if (set.isEmpty) _filtros.remove(_modo);
    });
  }

  void _removerValor(_Modo modo, String valor) {
    setState(() {
      final set = _filtros[modo];
      if (set == null) return;
      set.remove(valor);
      if (set.isEmpty) _filtros.remove(modo);
    });
  }

  void _limpiarTodo() => setState(() => _filtros.clear());

  @override
  Widget build(BuildContext context) {
    // Escuchar navegación desde DetallePerfumeScreen
    ref.listen(notaSeleccionadaProvider, (_, next) {
      if (next != null) {
        setState(() {
          _modo = _Modo.notas;
          _filtros[_Modo.notas] = {_normalizar(next)};
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(notaSeleccionadaProvider.notifier).state = null;
          }
        });
      }
    });

    final mapAsync = ref.watch(perfumesMapProvider);
    final perfumes = mapAsync.valueOrNull?.values.toList() ?? [];
    final conteo   = _contarPorModo(perfumes, _modo);
    final valores  = conteo.keys.toList()
      ..sort((a, b) => conteo[b]!.compareTo(conteo[a]!));
    final filtrados = _filtrarMultiple(perfumes, _filtros);

    String titulo() {
      if (_tieneFiltros) {
        return '${filtrados.length} perfume${filtrados.length != 1 ? 's' : ''}';
      }
      return switch (_modo) {
        _Modo.notas    => 'Notas olfativas',
        _Modo.perfil   => 'Perfil olfativo',
        _Modo.ocasion  => 'Ocasión',
        _Modo.estacion => 'Estación',
        _Modo.hora     => 'Hora del día',
        _Modo.clave    => 'Estilo',
      };
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Icon(
              _tieneFiltros ? Icons.filter_list_rounded : _modo.icon,
              color: AppColors.gold,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                titulo(),
                key: ValueKey(titulo()),
                style: AppTextStyles.heading2.copyWith(fontSize: 18),
              ),
            ),
          ],
        ),
        actions: [
          if (_tieneFiltros)
            TextButton.icon(
              onPressed: _limpiarTodo,
              icon: const Icon(Icons.close_rounded, size: 15),
              label: const Text('Limpiar'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: _ModoBar(
            modoActivo: _modo,
            filtros:    _filtros,
            onSelect:   _setModo,
          ),
        ),
      ),
      body: mapAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) =>
            _ErrorView(onRetry: () => ref.invalidate(perfumesMapProvider)),
        data: (_) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _tieneFiltros
              ? _VistaMultifiltro(
                  key:            ValueKey(_filtros.length),
                  filtros:        _filtros,
                  modo:           _modo,
                  valores:        valores,
                  filtrados:      filtrados,
                  onToggle:       _toggleFiltro,
                  onRemoverValor: _removerValor,
                  onRefresh:      () => ref.refresh(perfumesMapProvider.future),
                )
              : _VistaExplora(
                  key:      ValueKey('explora-$_modo'),
                  valores:  valores,
                  conteo:   conteo,
                  modo:     _modo,
                  onSelect: _toggleFiltro,
                ),
        ),
      ),
    );
  }
}

// ── Barra de modos con indicador de filtro activo ─────────────────────────────

class _ModoBar extends StatelessWidget {
  const _ModoBar({
    required this.modoActivo,
    required this.filtros,
    required this.onSelect,
  });
  final _Modo                     modoActivo;
  final Map<_Modo, Set<String>>   filtros;
  final void Function(_Modo)      onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: _Modo.values.map((modo) {
            final activo      = modo == modoActivo;
            final tieneFiltro = filtros.containsKey(modo);
            final bgColor = tieneFiltro
                ? AppColors.primary
                : (activo
                    ? AppColors.primaryPale
                    : AppColors.primaryPale);
            final textColor = tieneFiltro
                ? Colors.white
                : (activo ? AppColors.primaryDark : AppColors.textSecondary);
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: GestureDetector(
                onTap: () => onSelect(modo),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(
                      color: tieneFiltro
                          ? AppColors.primary
                          : (activo
                              ? AppColors.primary
                              : AppColors.primaryLight),
                      width: activo || tieneFiltro ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(modo.icon, size: 12, color: textColor),
                      const SizedBox(width: 4),
                      Text(
                        modo.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: activo || tieneFiltro
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      if (tieneFiltro) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.check_rounded,
                            size: 11, color: Colors.white),
                      ],
                    ],
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

// ── Vista exploración ─────────────────────────────────────────────────────────

class _VistaExplora extends StatelessWidget {
  const _VistaExplora({
    super.key,
    required this.valores,
    required this.conteo,
    required this.modo,
    required this.onSelect,
  });
  final List<String>         valores;
  final Map<String, int>     conteo;
  final _Modo                modo;
  final void Function(String) onSelect;

  String get _subtitulo {
    final n = valores.length;
    return switch (modo) {
      _Modo.notas    => '$n notas · toca una para filtrar',
      _Modo.perfil   => '$n perfiles olfativos · toca uno para filtrar',
      _Modo.ocasion  => '$n ocasiones · toca una para filtrar',
      _Modo.estacion => '$n estaciones · toca una para filtrar',
      _Modo.hora     => '$n horarios · toca uno para filtrar',
      _Modo.clave    => '$n descriptores · toca uno para filtrar',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (valores.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(modo.icon, size: 48, color: AppColors.textFaint),
            const SizedBox(height: 12),
            Text('Sin datos de ${modo.label.toLowerCase()}',
                style:
                    AppTextStyles.body.copyWith(color: AppColors.textMuted)),
          ],
        ),
      );
    }
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg,
                AppSpacing.md, AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Explora por ${modo.label.toLowerCase()}',
                    style: AppTextStyles.heading2
                        .copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(_subtitulo,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _ValorCard(
                valor:  valores[i],
                conteo: conteo[valores[i]] ?? 0,
                modo:   modo,
                onTap:  () => onSelect(valores[i]),
              ),
              childCount: valores.length,
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

// ── Vista con filtros combinados ──────────────────────────────────────────────

class _VistaMultifiltro extends StatelessWidget {
  const _VistaMultifiltro({
    super.key,
    required this.filtros,
    required this.modo,
    required this.valores,
    required this.filtrados,
    required this.onToggle,
    required this.onRemoverValor,
    required this.onRefresh,
  });
  final Map<_Modo, Set<String>>        filtros;
  final _Modo                          modo;
  final List<String>                   valores;
  final List<Perfume>                  filtrados;
  final void Function(String)          onToggle;
  final void Function(_Modo, String)   onRemoverValor;
  final Future<void> Function()        onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chips de filtros activos (removibles)
        _FiltrosActivosBar(filtros: filtros, onRemover: onRemoverValor),

        // Chips del modo actual para agregar/cambiar ese filtro
        _ChipBar(
          valores:        valores,
          valoresActivos: filtros[modo] ?? const {},
          modo:           modo,
          onSelect:       onToggle,
        ),

        // Resultados
        Expanded(
          child: filtrados.isEmpty
              ? _SinResultados(filtros: filtros)
              : RefreshIndicator(
                  onRefresh: onRefresh,
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                        AppSpacing.sm, AppSpacing.md, AppSpacing.md),
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

// ── Barra de filtros activos (removibles) ─────────────────────────────────────

class _FiltrosActivosBar extends StatelessWidget {
  const _FiltrosActivosBar(
      {required this.filtros, required this.onRemover});
  final Map<_Modo, Set<String>>      filtros;
  final void Function(_Modo, String) onRemover;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.filter_list_rounded,
              size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            'Combinando:',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filtros.entries
                    .expand((e) => e.value.map((valor) => (e.key, valor)))
                    .map((par) {
                  final (modo, valor) = par;
                  final emoji = _emojiValor(valor, modo);
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: GestureDetector(
                      onTap: () => onRemover(modo, valor),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _bg(valor),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          border: Border.all(color: _border(valor)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(emoji,
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 3),
                            Text(
                              valor,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(Icons.close_rounded,
                                size: 11, color: Color(0xFF777777)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de valor (vista exploración) ──────────────────────────────────────

class _ValorCard extends StatelessWidget {
  const _ValorCard({
    required this.valor,
    required this.conteo,
    required this.modo,
    required this.onTap,
  });
  final String       valor;
  final int          conteo;
  final _Modo        modo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor     = _bg(valor);
    final borderColor = _border(valor);
    final emojiText   = _emojiValor(valor, modo);
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
                  Text(emojiText, style: const TextStyle(fontSize: 24)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: borderColor.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text('$conteo',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A))),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(valor,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text('$conteo perfume${conteo != 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontSize: 10, color: Color(0x99000000))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Chips del modo actual ─────────────────────────────────────────────────────

class _ChipBar extends StatelessWidget {
  const _ChipBar({
    required this.valores,
    required this.valoresActivos,
    required this.modo,
    required this.onSelect,
  });
  final List<String>          valores;
  final Set<String>           valoresActivos;
  final _Modo                 modo;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    if (valores.isEmpty) return const SizedBox.shrink();
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
                left: AppSpacing.md, bottom: AppSpacing.xs),
            child: Row(
              children: [
                Icon(modo.icon, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Agregar ${modo.label.toLowerCase()}:',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: valores.map((valor) {
                final activo = valoresActivos.contains(valor);
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: GestureDetector(
                    onTap: () => onSelect(valor),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: activo ? _border(valor) : _bg(valor),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        border: Border.all(
                            color: _border(valor),
                            width: activo ? 2 : 1),
                      ),
                      child: Text(
                        '${_emojiValor(valor, modo)} $valor',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: activo
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: activo
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
        ],
      ),
    );
  }
}

// ── Sin resultados ────────────────────────────────────────────────────────────

class _SinResultados extends StatelessWidget {
  const _SinResultados({required this.filtros});
  final Map<_Modo, Set<String>> filtros;

  @override
  Widget build(BuildContext context) {
    final partes = filtros.values.expand((set) => set).join(' + ');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Sin perfumes para\n"$partes"',
              style: AppTextStyles.body.copyWith(
                  color: AppColors.textMuted, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Prueba quitando algún filtro',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textFaint),
            ),
          ],
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

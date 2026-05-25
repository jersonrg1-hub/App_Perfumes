import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfuteca/features/catalogo/providers/catalogo_provider.dart';
import 'package:perfuteca/models/perfume.dart';
import 'package:perfuteca/theme/app_colors.dart';
import 'package:perfuteca/theme/app_spacing.dart';
import 'package:perfuteca/theme/app_text_styles.dart';

const double _kCritico = 5;
const double _kBajo    = 15;

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

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final estado = ref.watch(catalogoProvider);

    if (estado.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (estado.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 48, color: AppColors.textFaint),
              const SizedBox(height: 12),
              Text('Error al cargar catálogo',
                  style: AppTextStyles.body),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.read(catalogoProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final todos   = estado.perfumes
        .where((p) => p.stockMl != null)
        .toList();
    final criticos = todos.where((p) => p.stockMl! <= _kCritico).length;
    final bajos    = todos
        .where((p) => p.stockMl! > _kCritico && p.stockMl! <= _kBajo)
        .length;
    final ok       = todos.where((p) => p.stockMl! > _kBajo).length;

    var lista = switch (_filtro) {
      _FiltroStock.todos   => todos,
      _FiltroStock.critico => todos.where((p) => p.stockMl! <= _kCritico).toList(),
      _FiltroStock.bajo    => todos
          .where((p) => p.stockMl! > _kCritico && p.stockMl! <= _kBajo)
          .toList(),
      _FiltroStock.ok => todos.where((p) => p.stockMl! > _kBajo).toList(),
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

    final maxStock = todos.isEmpty
        ? 100.0
        : todos.fold(0.0, (m, p) => (p.stockMl ?? 0) > m ? p.stockMl! : m);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ── Resumen de stock ───────────────────────────────────────
        Row(children: [
          Expanded(child: _StockChip(label: 'Total',  valor: '${todos.length}',   color: AppColors.primaryPale,         textColor: AppColors.textPrimary)),
          const SizedBox(width: 6),
          Expanded(child: _StockChip(label: '🔴 Crítico', valor: '$criticos', color: const Color(0xFFfee2e2), textColor: const Color(0xFF7f1d1d))),
          const SizedBox(width: 6),
          Expanded(child: _StockChip(label: '🟡 Bajo',    valor: '$bajos',    color: const Color(0xFFfef9c3), textColor: const Color(0xFF713f12))),
          const SizedBox(width: 6),
          Expanded(child: _StockChip(label: '🟢 OK',      valor: '$ok',       color: const Color(0xFFdcfce7), textColor: const Color(0xFF14532d))),
        ]),
        const SizedBox(height: AppSpacing.md),

        // ── Buscador ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: TextField(
            controller: _buscarCtrl,
            decoration: InputDecoration(
              hintText: 'Buscar perfume...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(color: AppColors.primaryLight),
              ),
              suffixIcon: _buscar.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _buscarCtrl.clear();
                        setState(() => _buscar = '');
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _buscar = v.trim()),
          ),
        ),

        // ── Filtros y ordenamiento ─────────────────────────────────
        Row(
          children: [
            Expanded(
              flex: 2,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Mostrar',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                ),
                child: DropdownButton<_FiltroStock>(
                  value:      _filtro,
                  isExpanded: true,
                  isDense:    true,
                  underline:  const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: _FiltroStock.todos,   child: Text('Todos')),
                    DropdownMenuItem(value: _FiltroStock.critico,  child: Text('🔴 Críticos')),
                    DropdownMenuItem(value: _FiltroStock.bajo,     child: Text('🟡 Bajos')),
                    DropdownMenuItem(value: _FiltroStock.ok,       child: Text('🟢 OK')),
                  ],
                  onChanged: (v) => setState(() => _filtro = v!),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 3,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Ordenar por',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                ),
                child: DropdownButton<_OrdenStock>(
                  value:      _orden,
                  isExpanded: true,
                  isDense:    true,
                  underline:  const SizedBox.shrink(),
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
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // ── Lista ──────────────────────────────────────────────────
        if (lista.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: Text(
                'No hay perfumes en esta categoría',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted),
              ),
            ),
          )
        else
          ...lista.map((p) => _StockRow(perfume: p, maxStock: maxStock)),

        const SizedBox(height: AppSpacing.xl),
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
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color:      textColor,
              fontWeight: FontWeight.w600,
              fontSize:   10,
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
  const _StockRow({required this.perfume, required this.maxStock});
  final Perfume perfume;
  final double  maxStock;

  Color get _barColor {
    final s = perfume.stockMl ?? 0;
    if (s <= _kCritico) return AppColors.stockCritical;
    if (s <= _kBajo)    return AppColors.stockLow;
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
                        fontSize:      9,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      '🌸 ${perfume.nombre}',
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
              _StockBadge(stock: stock),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value:           pct,
              minHeight:       6,
              backgroundColor: AppColors.primaryLight,
              valueColor: AlwaysStoppedAnimation<Color>(_barColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge de stock ────────────────────────────────────────────────────────────

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.stock});
  final double stock;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String emoji;

    if (stock <= _kCritico) {
      bg    = const Color(0xFFfee2e2);
      fg    = AppColors.stockCritical;
      emoji = '🔴';
    } else if (stock <= _kBajo) {
      bg    = const Color(0xFFfef9c3);
      fg    = AppColors.stockLow;
      emoji = '🟡';
    } else {
      bg    = const Color(0xFFdcfce7);
      fg    = AppColors.stockOk;
      emoji = '🟢';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        '$emoji ${stock.toStringAsFixed(0)}ml',
        style: AppTextStyles.bodySmall.copyWith(
          color:      fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

# Densidad de UI para S25 Ultra Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ajustar densidad de layout (columnas de grid, padding, spacing) en toda la app Flutter para reducir scroll y mostrar más información por pantalla, apuntado específicamente al S25 Ultra (~480dp de ancho lógico) — único dispositivo usado.

**Architecture:** Cambios puros de constantes de layout (`crossAxisCount`, `childAspectRatio`, `EdgeInsets`/`SizedBox` con `AppSpacing.*`). No hay lógica nueva, no hay providers ni modelos tocados. Cada task es un archivo o grupo de archivos relacionado, verificable con `flutter analyze` + inspección visual — no hay comportamiento nuevo que testear con unit tests (es sintonización visual, no lógica).

**Tech Stack:** Flutter/Dart, tema `AppSpacing` (`lib/theme/app_spacing.dart`).

**Spec:** `docs/superpowers/specs/2026-08-18-densidad-s25-ultra-design.md`

---

## Notas para quien ejecute este plan

- Todos los paths son relativos a `perfuteca_flutter/`.
- Cada task cierra con `flutter analyze` (debe salir sin warnings nuevos) y un commit. No hay tests automatizados que escribir — son cambios de constantes visuales sin comportamiento testeable; la verificación es visual (ver spec, sección "Verificación").
- Cuando un paso dice "cambiar `AppSpacing.md` a `AppSpacing.sm`" en una línea específica, es la única ocurrencia de ese patrón en esa línea — usar el contexto de la línea anterior/siguiente dado en cada paso para ubicarla sin ambigüedad, porque `SizedBox(height: AppSpacing.md)` se repite muchas veces por archivo.
- Ejecutar `flutter analyze` desde `perfuteca_flutter/`.

---

### Task 1: Catálogo y Búsqueda — grids a 3 columnas

**Files:**
- Modify: `lib/features/catalogo/screens/catalogo_screen.dart:227-234`
- Modify: `lib/widgets/common/app_loading_widget.dart:28-33` (shimmer del catálogo, debe coincidir con el grid real)
- Modify: `lib/features/busqueda/screens/busqueda_screen.dart:193-198`

- [ ] **Step 1: Catálogo — grid real**

En `lib/features/catalogo/screens/catalogo_screen.dart`, la sección:

```dart
                : SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:   2,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing:  AppSpacing.md,
                      childAspectRatio: 0.62,
                    ),
```

cambia a:

```dart
                : SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:   3,
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing:  AppSpacing.sm,
                      childAspectRatio: 0.56,
                    ),
```

- [ ] **Step 2: Catálogo — shimmer de carga**

En `lib/widgets/common/app_loading_widget.dart`, dentro de `CatalogoShimmer`:

```dart
      child: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.72,
        ),
```

cambia a:

```dart
      child: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 0.62,
        ),
```

(mantiene la misma diferencia relativa que ya existía entre el shimmer y el grid real — el shimmer siempre fue un poco más "cuadrado" que las cards reales).

- [ ] **Step 3: Búsqueda — grid real**

En `lib/features/busqueda/screens/busqueda_screen.dart`:

```dart
              child: GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:    2,
                  crossAxisSpacing:  AppSpacing.md,
                  mainAxisSpacing:   AppSpacing.md,
                  childAspectRatio:  0.62,
                ),
```

cambia a:

```dart
              child: GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:    3,
                  crossAxisSpacing:  AppSpacing.sm,
                  mainAxisSpacing:   AppSpacing.sm,
                  childAspectRatio:  0.56,
                ),
```

- [ ] **Step 4: Verificar en un dispositivo/emulador con ~480dp de ancho**

Correr la app (`flutter run`, o instalar el APK en el S25 Ultra) y abrir Catálogo y Búsqueda.
Verificar que `PerfumeCard` no trunca de forma fea nombres largos (ej. "Bombshell Seduction",
"Light Blue Eau Intense") a 3 columnas. Si el texto se ve muy apretado, ajustar
`childAspectRatio` (bajarlo un poco más, ej. 0.52) — es un valor de prueba visual, no hay
fórmula exacta.

- [ ] **Step 5: `flutter analyze` y commit**

Run: `cd perfuteca_flutter && flutter analyze`
Expected: No issues found! (o mismos warnings preexistentes, ninguno nuevo)

```bash
git add perfuteca_flutter/lib/features/catalogo/screens/catalogo_screen.dart \
        perfuteca_flutter/lib/widgets/common/app_loading_widget.dart \
        perfuteca_flutter/lib/features/busqueda/screens/busqueda_screen.dart
git commit -m "feat(ui): catalogo y busqueda a 3 columnas para S25 Ultra"
```

---

### Task 2: Listas de ventas/cotizaciones — padding compacto

**Files:**
- Modify: `lib/features/ventas/screens/historial_screen.dart:436`
- Modify: `lib/features/ventas/screens/pendientes_screen.dart:502,1060`
- Modify: `lib/features/cotizaciones/widgets/cotizacion_convertir_card.dart:397,967`
- Modify: `lib/features/ventas/screens/cotizaciones_hoy_screen.dart:287` (shimmer, para que coincida)

- [ ] **Step 1: Historial — padding de la fila principal de `_OrdenCard`**

En `lib/features/ventas/screens/historial_screen.dart`, dentro de `_OrdenCardState.build`,
la fila principal (justo debajo de `child: Column(children: [` → `// ── Fila principal`):

```dart
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: color),
```

cambia a:

```dart
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: color),
```

- [ ] **Step 2: Pendientes — gap entre cards de orden**

En `lib/features/ventas/screens/pendientes_screen.dart`, dos ocurrencias del patrón
`margin: const EdgeInsets.only(bottom: AppSpacing.md),` seguido de `decoration: BoxDecoration(`
(la card real, ~línea 502) — cambiar `AppSpacing.md` a `AppSpacing.sm` en esa línea.

La segunda ocurrencia (~línea 1060) está dentro del shimmer de carga
(`class` de skeleton, `Container(margin: const EdgeInsets.only(bottom: AppSpacing.md), height: 160,`)
— cambiar también a `AppSpacing.sm` para que coincida con la card real.

No tocar la línea ~708 (`padding: const EdgeInsets.all(AppSpacing.md)` de la zona de
botones de acción) — esa es la comodidad táctil de los botones, no densidad de lista.

- [ ] **Step 3: Cotizaciones — gap entre cards**

En `lib/features/cotizaciones/widgets/cotizacion_convertir_card.dart`, dos ocurrencias de
`margin: const EdgeInsets.only(bottom: AppSpacing.md),` (líneas ~397 y ~967 — son la card en
dos estados/variantes distintos del widget) — cambiar ambas a `AppSpacing.sm`.

No tocar línea ~578 (`margin: const EdgeInsets.all(AppSpacing.md)`, padding interno de un
elemento dentro de la card) ni línea ~1320 (`margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md)`).

En `lib/features/ventas/screens/cotizaciones_hoy_screen.dart:287`, el shimmer de carga
(`_CotizacionesShimmer`, `Container(margin: const EdgeInsets.only(bottom: AppSpacing.md), height: i == 0 ? 64 : 88,`)
— cambiar a `AppSpacing.sm` para que coincida.

- [ ] **Step 4: Verificar visualmente**

Abrir Historial, Pendientes y Cotizaciones de hoy en la app. Confirmar que se ven más
filas sin scroll y que el texto/badges de cada card no se ven apretados ni desbordan.

- [ ] **Step 5: `flutter analyze` y commit**

Run: `cd perfuteca_flutter && flutter analyze`
Expected: No issues found!

```bash
git add perfuteca_flutter/lib/features/ventas/screens/historial_screen.dart \
        perfuteca_flutter/lib/features/ventas/screens/pendientes_screen.dart \
        perfuteca_flutter/lib/features/cotizaciones/widgets/cotizacion_convertir_card.dart \
        perfuteca_flutter/lib/features/ventas/screens/cotizaciones_hoy_screen.dart
git commit -m "feat(ui): listas de ventas y cotizaciones mas compactas para S25 Ultra"
```

---

### Task 3: Estadísticas — Resumen: espaciado entre secciones

**Files:**
- Modify: `lib/features/estadisticas/screens/resumen_tab.dart:105,127,132,142,149,188`

- [ ] **Step 1: Reducir los `SizedBox` que separan secciones del dashboard**

En `_ResumenBody.build`, dentro del `ListView(children: [...])`, hay 6 separadores entre
secciones (Hoy → Pendientes → Mes → Semana → Más vendidos → Mix del mes). Cambiar cada uno
de `AppSpacing.md` a `AppSpacing.sm`:

1. Línea 105 — después de `_SeccionHoy(...)`, antes de `// ── Pendientes`:
   `const SizedBox(height: AppSpacing.md),` → `const SizedBox(height: AppSpacing.sm),`
2. Línea 127 — después de `_PendientesBanner(...)`, dentro del `if (s.pendientesCount > 0)`:
   mismo cambio.
3. Línea 132 — después de `_HeroMesCard(...)`, antes de `// ── Esta semana`: mismo cambio.
4. Línea 142 — después de `semana.when(...)`, antes de `// ── Más vendidos`: mismo cambio.
5. Línea 149 — después de `_TopPerfumesCard(...)`, dentro del `if (s.masVendidos.isNotEmpty)`:
   mismo cambio.
6. Línea 188 — dentro del bloque `tamanios.when(data: ...)`, después de `_TamaniosChips(...)`,
   cierre del bloque "Mix del mes": mismo cambio.

**No tocar** la línea 193 (`const SizedBox(height: AppSpacing.xl)`, espacio final antes del
borde inferior de la pantalla — se deja igual a propósito) ni ningún `SizedBox` dentro de
`_HeroMesCard`, `_MiniSemanalCard` o `_TopPerfumesCard` (contenido interno de cada card, fuera
de alcance).

- [ ] **Step 2: Verificar visualmente**

Abrir el tab Resumen de Estadísticas. Confirmar que las secciones se ven más juntas pero
cada card individual conserva su tipografía y aire interno normal.

- [ ] **Step 3: `flutter analyze` y commit**

Run: `cd perfuteca_flutter && flutter analyze`
Expected: No issues found!

```bash
git add perfuteca_flutter/lib/features/estadisticas/screens/resumen_tab.dart
git commit -m "feat(ui): espaciado compacto entre secciones en Resumen para S25 Ultra"
```

---

### Task 4: Estadísticas — Ventas, Clientes, Histórico, Análisis: espaciado entre secciones

**Files:**
- Modify: `lib/features/estadisticas/screens/ventas_tab.dart:175,182,355,357`
- Modify: `lib/features/estadisticas/screens/clientes_tab.dart:831,836`
- Modify: `lib/features/estadisticas/screens/historico_tab.dart:130,861,890,902,1080`
- Modify: `lib/features/estadisticas/screens/analisis_tab.dart:115,446,463`

Mismo criterio que Task 3: solo los `SizedBox(height: AppSpacing.md)` que separan secciones
de nivel superior del scroll body (o sus shimmers de carga, para que coincidan), no los que
están dentro del build de una card/widget individual.

- [ ] **Step 1: `ventas_tab.dart`**

- Línea 175 — después del `Row` de chips de filtro (`_FiltroChip`), antes de `// ── Título dinámico`.
- Línea 182 — después del `Text('Tamaños · ...')`, antes de `// ── Lista o vacío`.
- Línea 355 y 357 — dentro de `_TamanosSkeleton` (shimmer), mismos separadores que las líneas
  175/182 del contenido real.

Cambiar las 4 ocurrencias de `AppSpacing.md` a `AppSpacing.sm`.
**No tocar** línea 193 (dentro del estado vacío `if (tamanios.isEmpty)`, dentro de una `Column`
de ícono+texto — es espaciado interno de un mensaje, no separador de sección).

- [ ] **Step 2: `clientes_tab.dart`**

- Líneas 831 y 836 — dentro del shimmer de carga (`Shimmer.fromColors(... child: Column(children: [`),
  separadores entre el bloque de filtros, el buscador y la lista.

Cambiar ambas de `AppSpacing.md` a `AppSpacing.sm`.
**No tocar** línea 202 (dentro del build de una card de cliente individual).

- [ ] **Step 3: `historico_tab.dart`**

- Línea 130 — después del `Wrap` de chips del hero, antes de `// ── Cards: ticket promedio...`.
- Línea 861 — después del `Row` con el ícono "Comparar meses", antes del contenido de comparación.
- Línea 890 — después del `Row` de los dos `_MesDropdown`, antes del `if (_mes1 != null && _mes2 != null)`.
- Línea 902 — dentro de ese mismo bloque, antes de `_DiferenciaBanner(...)`.
- Línea 1080 — dentro del shimmer de carga equivalente al hero (línea 130).

Cambiar las 5 ocurrencias de `AppSpacing.md` a `AppSpacing.sm`.

- [ ] **Step 4: `analisis_tab.dart`**

- Línea 115 — después del `Row` de `_StockChip` (Total/Crítico/Bajo/OK), antes del buscador.
- Línea 446 y 463 — dentro del shimmer de carga, separadores equivalentes.

Cambiar las 3 ocurrencias de `AppSpacing.md` a `AppSpacing.sm`.

- [ ] **Step 5: Verificar visualmente**

Abrir los 4 tabs (Ventas, Clientes, Histórico, Análisis) dentro de Estadísticas. Confirmar
menos espacio muerto entre secciones y que los shimmers de carga tienen la misma proporción
que el contenido real (no debe "saltar" el layout cuando termina de cargar).

- [ ] **Step 6: `flutter analyze` y commit**

Run: `cd perfuteca_flutter && flutter analyze`
Expected: No issues found!

```bash
git add perfuteca_flutter/lib/features/estadisticas/screens/ventas_tab.dart \
        perfuteca_flutter/lib/features/estadisticas/screens/clientes_tab.dart \
        perfuteca_flutter/lib/features/estadisticas/screens/historico_tab.dart \
        perfuteca_flutter/lib/features/estadisticas/screens/analisis_tab.dart
git commit -m "feat(ui): espaciado compacto entre secciones en Ventas/Clientes/Historico/Analisis"
```

---

### Task 5: Build final y verificación end-to-end

**Files:** ninguno (solo build + smoke test)

- [ ] **Step 1: Build de release**

```bash
cd perfuteca_flutter
flutter build apk --release
```

Expected: build exitoso, APK en `build/app/outputs/flutter-apk/app-release.apk`.

- [ ] **Step 2: Instalar en el S25 Ultra y recorrer las 6 pantallas tocadas**

Catálogo, Búsqueda, Historial, Pendientes, Cotizaciones de hoy, Estadísticas (los 5 tabs).
Confirmar que no hay overflow de texto/pixels (buscar franjas amarillas/negras de overflow
de Flutter) y que la sensación general es "más info, mismo tamaño de letra".

- [ ] **Step 3: Si todo bien, no hace falta commit adicional** — el trabajo ya quedó
  commiteado en los Tasks 1-4. Este task es solo verificación manual final.

# Densidad de UI para S25 Ultra — design spec

**Fecha:** 2026-08-18
**Estado:** Aprobado, pendiente de plan de implementación

## Contexto

Perfuteca (Flutter) es usada por una sola persona en un único dispositivo: Samsung
Galaxy S25 Ultra (pantalla 6.8", ~480dp de ancho lógico, 120Hz). No hay necesidad
de soportar otros tamaños de pantalla ni de mantener lógica responsive genérica —
los valores de densidad pueden ajustarse directamente para este dispositivo.

Hoy la app usa una densidad pensada para teléfonos más chicos: grids con
`crossAxisCount: 2` fijo en todas partes, y espaciados generosos (`AppSpacing.md`/`lg`)
entre secciones de listas y del dashboard de estadísticas. En un ancho de 480dp esto
deja espacio sin aprovechar y fuerza más scroll del necesario.

**Objetivo:** reducir scroll / mostrar más información por pantalla, sin sacrificar
legibilidad de texto ni tamaño de controles táctiles (no se toca tipografía ni
tap targets — solo densidad de layout: columnas, padding, spacing).

## Alcance

Tres cambios independientes, todos de solo-layout (sin cambios de lógica de negocio
ni de providers):

### 1. Grids de catálogo → 3 columnas

**Archivos:** `lib/features/catalogo/screens/catalogo_screen.dart`,
`lib/features/busqueda/screens/busqueda_screen.dart`, y
`lib/widgets/common/app_loading_widget.dart` (skeleton debe coincidir con el grid real).

- `SliverGridDelegateWithFixedCrossAxisCount.crossAxisCount`: `2` → `3`.
- `childAspectRatio`: `0.62` → ajustar (probar ~0.55–0.58) para compensar el ancho
  de card menor; verificar visualmente que `PerfumeCard` no trunque texto de forma
  fea con nombres/marcas largos.
- `crossAxisSpacing` / `mainAxisSpacing`: `AppSpacing.md` (12) → `AppSpacing.sm` (8).

**No tocar:** `lib/features/marcas/screens/marcas_screen.dart` y
`lib/features/notas/screens/notas_screen.dart` quedan en 2 columnas — sus cards
llevan más texto (nombre de marca completo / contenido de nota) y a 3 columnas
se apretaría mal.

### 2. Listas de ventas/cotizaciones → padding compacto

**Archivos:** `lib/features/ventas/screens/historial_screen.dart`,
`lib/features/ventas/screens/pendientes_screen.dart`,
`lib/features/ventas/screens/cotizaciones_hoy_screen.dart`,
`lib/features/ventas/screens/ventas_screen.dart`.

- Padding interno de las cards de orden (`_OrdenCard` y equivalentes):
  `EdgeInsets.all(AppSpacing.md)` (12) → `EdgeInsets.all(AppSpacing.sm)` (8).
- Espaciado vertical entre cards consecutivas: `AppSpacing.lg` (16) → `AppSpacing.md` (12).
- Tipografía de las cards no cambia — el objetivo es ver más filas, no texto más chico.

### 3. Estadísticas → espaciado entre secciones compacto

**Archivos:** `lib/features/estadisticas/screens/resumen_tab.dart`,
`clientes_tab.dart`, `ventas_tab.dart`, `historico_tab.dart`, `analisis_tab.dart`.

Se descartó convertir las stat cards a un grid de 2 columnas: `_HeroMesCard` es una
card hero full-width con número grande (30px) + badge de variación + chips en `Wrap`;
partirla a mitad de ancho degrada la legibilidad del número principal, que es la
métrica más importante de la pantalla. En su lugar:

- Los `SizedBox(height: AppSpacing.md)` que separan secciones (Hoy / Pendientes /
  Mes / Semana / Más vendidos / Mix del mes, y las secciones equivalentes en los
  otros tabs) pasan a `AppSpacing.sm`.
- El contenido interno de cada card (tipografía, badges, chips) no cambia.

## Fuera de alcance

- No se agregan breakpoints ni `MediaQuery`/`LayoutBuilder` condicionales — es
  código específico para este dispositivo, no responsive genérico.
- No se toca tipografía (`AppTextStyles`) ni tamaño de botones/tap targets.
- No se tocan `marcas_screen.dart` ni `notas_screen.dart`.
- No se toca el wizard de Nueva Venta (`nueva_venta_screen.dart`) — no fue parte
  de lo evaluado en este spec.

## Verificación

- `flutter analyze` sin nuevos warnings.
- Revisión visual en el dispositivo real (S25 Ultra) o emulador con mismas
  dimensiones: catálogo/búsqueda con 3 columnas legibles, listas más compactas
  sin overflow de texto, estadísticas con menos espacio muerto entre secciones.
- Confirmar que `PerfumeCard` no trunca/desborda con nombres largos a 3 columnas
  (ej. "Bombshell Seduction", "Light Blue Eau Intense").

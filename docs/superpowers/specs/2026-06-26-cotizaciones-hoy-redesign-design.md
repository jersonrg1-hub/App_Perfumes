# Rediseño visual — Cotizaciones de Hoy

## Contexto

Pantalla `perfuteca_flutter/lib/features/ventas/screens/cotizaciones_hoy_screen.dart`
(tab Ventas) se ve plana/genérica. Card de conversión vive en
`perfuteca_flutter/lib/features/cotizaciones/widgets/cotizacion_convertir_card.dart`
(compartida con `estadisticas/screens/cotizaciones_tab.dart` — cualquier cambio
visual ahí también afecta esa pantalla, pero el scope de este rediseño es
únicamente Ventas › Cotizaciones de Hoy).

## Decisión de estilo

Dirección **Status-first** elegida sobre 3 mockups (hero banner degradado,
editorial serif, status-first): métricas en mini-tarjetas separadas por
categoría + pill de estado prominente por card. Animaciones con intensidad
subida (count-up, springs) sobre la base fade+slide existente.

## Alcance

1. **`_MetricasHoyRow`** → grid de 3 mini-tarjetas independientes (no más
   `IntrinsicHeight`+`VerticalDivider` flat):
   - TOTAL HOY: outline terracota (`AppColors.primary`), fondo `surface`.
   - PENDIENTES: fondo `warningSurface`, borde `warning`.
   - CONVERTIDAS: fondo `successSurface`, borde `stockOk`.
   - Valor numérico anima con count-up (`TweenAnimationBuilder<double>`,
     ~600ms, `Curves.easeOutCubic`) al montar.

2. **Header de `CotizacionConvertirCard` (colapsada)** — sustituye el badge
   ID pequeño actual por un pill de estado más prominente, alineado
   top-right del header:
   - No aceptada: `⏳ Esperando` — fondo dorado claro, texto `AppColors.gold`.
   - Aceptada: `✅ Aceptada` — fondo `successSurface`, texto `stockOk`
     (reemplaza el ícono+texto inline que ya existe, mismo dato, presentación
     más prominente como pill).
   - Pill entra con scale-spring al aparecer (`AnimatedScale` o
     `TweenAnimationBuilder` con curva `Curves.elasticOut` corta, ~350ms).
   - Nombre del badge ID (`#C012`) y celular se mantienen, reordenados para
     no competir visualmente con el pill.

3. **Form expandido** (`_Field`, `_Chips`, botón "Revisar pedido"):
   - `_Chips`: al seleccionar, animación de escala breve (overshoot leve)
     en vez del único `AnimatedContainer` de color/borde actual — combinar
     ambos (color change + scale pulse ~150ms).
   - Botón "Revisar pedido": el ícono (`arrow_forward_rounded`) se desplaza
     levemente a la derecha en press (`AnimatedContainer`/`Transform` sobre
     `onTapDown`/`onTapUp` o usar `InkWell` + `AnimatedSlide` del ícono).
   - Mantener misma estructura de campos/orden — solo refinar
     transiciones, no reestructurar el formulario.

4. **`_ConfirmacionInline`** (resumen antes de confirmar):
   - Refinar espaciado/tipografía de `_ResumenFila` (label más sutil,
     valor con más peso) — mismo contenido, mejor jerarquía visual.
   - Mantener layout de 2 botones (Editar / Confirmar venta) sin cambios
     funcionales.

5. **Animación de lista** — `_AnimatedListItem` (fade+slide stagger) se
   mantiene sin cambios; las animaciones nuevas (count-up, spring) son
   adicionales, no reemplazan el stagger existente.

## Fuera de alcance

- Pantalla `Pendientes` (`pendientes_screen.dart`) — no se toca.
- `cotizaciones_tab.dart` (Estadísticas) — comparte `CotizacionConvertirCard`,
  por lo que heredará visualmente los cambios del punto 2/3/4, pero no se
  audita ni ajusta específicamente para esa pantalla en este trabajo.
- Lógica de negocio (registro de venta, sincronización de estado,
  WhatsApp) — sin cambios, solo presentación.
- Estados vacío/error/shimmer de `cotizaciones_hoy_screen.dart` — sin
  cambios visuales (fuera del pedido original).

## Riesgos / notas de implementación

- `CotizacionConvertirCard` es compartida — verificar manualmente que
  `cotizaciones_tab.dart` (Estadísticas) no rompe visualmente tras el
  cambio del pill de estado y chips.
- Usar exclusivamente `AppColors.*`, `AppSpacing.*`, `AppTextStyles.*`
  (regla del proyecto) — no hardcodear colores/tamaños nuevos.
- Sin nuevos paquetes — animaciones con widgets nativos de Flutter
  (`TweenAnimationBuilder`, `AnimatedScale`, `AnimatedContainer`).

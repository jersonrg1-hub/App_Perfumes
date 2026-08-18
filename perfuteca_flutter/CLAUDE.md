# CLAUDE.md — Perfuteca Flutter

Frontend Flutter para Perfuteca. Consume FastAPI en Render.

## Arquitectura

Feature-first: `lib/features/<feature>/screens/` + `lib/features/<feature>/providers/`

```
lib/
├── config/           # URL base API, configuración
├── core/
│   ├── constants/    # Constantes globales
│   ├── errors/       # Manejo errores
│   └── network/interceptors/  # HTTP interceptors (X-API-Key)
├── features/
│   ├── busqueda/
│   ├── catalogo/
│   ├── cotizaciones/
│   ├── estadisticas/  # 5 tabs: resumen, ventas, clientes, historico, analisis
│   ├── marcas/
│   ├── notas/
│   └── ventas/        # nueva_venta, pendientes, historial, cotizaciones_hoy
├── models/            # Clases de datos compartidas
├── repositories/      # Capa HTTP → FastAPI
├── theme/
└── widgets/common/ + widgets/perfume/
```

## Features — pantallas

| Feature | Screens | Providers |
|---|---|---|
| busqueda | `busqueda_screen` | `busqueda_provider` |
| catalogo | `catalogo_screen`, `detalle_perfume_screen` | `catalogo_provider` |
| cotizaciones | `nueva_cotizacion_screen` | `nueva_cotizacion_provider` |
| estadisticas | `estadisticas_screen` + 5 tabs | `estadisticas_provider` |
| marcas | `marcas_screen` | `marcas_provider` |
| notas | `notas_screen` | `notas_provider` |
| ventas | `ventas_screen`, `nueva_venta_screen`, `pendientes_screen`, `historial_screen`, `cotizaciones_hoy_screen` | `nueva_venta_provider`, `ventas_provider` |

## State management

Riverpod — providers por feature, no global store.

## API

- Header `X-API-Key` requerido en todos endpoints salvo `/catalogo/`
- Base URL configurada en `lib/config/` o `lib/core/constants/`

## Build

```powershell
cd perfuteca_flutter
flutter build apk --release
# APK en: build/app/outputs/flutter-apk/app-release.apk
```

## Design system

**Personalidad:** perfumería de lujo — cálido, elegante, nunca frío ni plano.

**Regla absoluta:** nunca hardcodear colores, tamaños ni radios. Siempre usar:
- `AppColors.*` — paleta terracota + dorado
- `AppTextStyles.*` — Cormorant Garamond (títulos/nombres) + sistema sans (body)
- `AppSpacing.*` — xs(4) sm(8) md(12) lg(16) xl(24) xxl(32)

**Colores clave:**
- Primary: `AppColors.primary` `#C8956C` terracota
- Acento: `AppColors.gold` `#C9A96E`
- Fondo: `AppColors.background` `#FAF5F0`
- Texto: `textPrimary` → `textSecondary` → `textMuted` → `textFaint`

**Patrones:**
- Cards: elevation 2, `radiusLg`, borde `primaryLight`
- Botones: `FilledButton` con `primary`, `radiusMd`
- Chips: pill shape (`radiusXxl`), fondo `primaryPale`
- Sin dark mode (light only, Material 3)

## Widgets reutilizables

Siempre usar estos antes de crear nuevos:

| Widget | Uso |
|---|---|
| `AppLoadingWidget` | Skeleton/loading en cualquier pantalla |
| `AppErrorWidget` | Estado de error con mensaje |
| `EmptyStateWidget` | Lista/resultado vacío |
| `PerfumeCard` | Card de perfume en catálogo/listados |
| `PerfumeImage` | Imagen de perfume con fallback |

## Helpers compartidos — usar antes de reimplementar

| Helper | Ubicación | Uso |
|---|---|---|
| `Perfume.stockEstado()` | `lib/models/perfume.dart` | esCritico/esBajo — antes triplicado en perfume_card, nueva_venta_screen, detalle_perfume_screen |
| `esCelularPeruValido()` | `lib/core/utils/validators.dart` | Validación celular — usado en nueva_cotizacion_provider y cotizacion_convertir_card |
| `AppErrorWidget` / `EmptyStateWidget` | `lib/widgets/common/` | No reimplementar por pantalla (ver Widgets reutilizables arriba) |

## Reglas
- No lógica de negocio en screens — va en providers o repositories
- Screens solo UI + llamadas a provider
- Modelos en `lib/models/`, no duplicar en features
- `setState`/lógica post-`await` siempre detrás de `if (!mounted) return` — bugs de crash por widget desmontado ya ocurrieron en cards dentro de ListView que se reordena

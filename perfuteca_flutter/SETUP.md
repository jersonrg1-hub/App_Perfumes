# Perfuteca Flutter — Pasos para arrancar

## 1. Instalar Flutter SDK

Descargar desde: https://docs.flutter.dev/get-started/install/windows
Agregar `flutter/bin` al PATH de Windows.
Verificar: `flutter doctor`

## 2. Instalar dependencias

```bash
cd perfuteca_flutter
flutter pub get
```

## 3. Generar código (Freezed + json_serializable)

```bash
dart run build_runner build --delete-conflicting-outputs
```

Genera `*.freezed.dart` y `*.g.dart`. Solo necesario al cambiar modelos `@freezed`.

## 4. Correr la app

Requiere `API_KEY` y `BASE_URL` como dart-defines:

```powershell
# Windows PowerShell
flutter run `
  --dart-define=API_KEY=TU_API_KEY `
  --dart-define=BASE_URL=https://perfuteca-api.onrender.com
```

O usa `run.ps1` (ya tiene los valores configurados):
```powershell
.\run.ps1
```

## 5. Compilar APK release

```bash
flutter build apk --release `
  --dart-define=API_KEY=TU_API_KEY `
  --dart-define=BASE_URL=https://perfuteca-api.onrender.com
```

APK en: `build/app/outputs/flutter-apk/app-release.apk`

---

## Estructura del proyecto

```
lib/
├── config/env.dart          ← URL base + API Key + timeouts (via dart-define)
├── core/
│   ├── constants/           ← endpoints de la API
│   ├── errors/              ← jerarquía de excepciones
│   └── network/             ← Dio + interceptors (auth, logging, retry, cache)
├── theme/                   ← colores, tipografía, tema Material 3
├── models/                  ← Freezed: Perfume, Venta, Cotizacion, Paginated, AppConfig
├── repositories/            ← acceso a datos (llaman a Dio)
├── features/
│   ├── catalogo/            ← pantalla principal + detalle perfume
│   ├── busqueda/            ← buscador con filtro de marcas
│   ├── marcas/              ← lista de marcas → perfumes por marca
│   ├── notas/               ← filtro por notas olfativas
│   ├── ventas/              ← nueva venta, pendientes, historial, cotizaciones hoy
│   ├── cotizaciones/        ← nueva cotización con link WhatsApp
│   └── estadisticas/        ← dashboard: resumen, ventas, clientes, histórico, análisis
└── widgets/                 ← AppLoadingWidget, AppErrorWidget, EmptyStateWidget, PerfumeCard
```

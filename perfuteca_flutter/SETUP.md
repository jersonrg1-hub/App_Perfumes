# Perfuteca Flutter — Pasos para arrancar

## 1. Instalar Flutter SDK

Descargar desde: https://docs.flutter.dev/get-started/install/windows
Agregar `flutter/bin` al PATH de Windows.
Verificar: `flutter doctor`

## 2. Configurar la URL del backend

Edita `lib/config/env.dart` y reemplaza `TU-APP` con tu URL de Render:

```dart
defaultValue: 'https://perfuteca-api.onrender.com',
```

O pásala como variable al compilar (sin tocar código):
```bash
flutter run --dart-define=BASE_URL=https://tu-app.onrender.com
```

## 3. Instalar dependencias

```bash
cd perfuteca_flutter
flutter pub get
```

## 4. Generar código (Freezed + json_serializable)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Esto genera los archivos `*.freezed.dart` y `*.g.dart` para los modelos.
Solo necesitas ejecutarlo cuando cambias un modelo con `@freezed`.

## 5. Correr la app

```bash
# En emulador/dispositivo Android
flutter run

# Con URL de producción
flutter run --dart-define=BASE_URL=https://tu-app.onrender.com
```

## 6. Compilar APK de debug

```bash
flutter build apk --debug
```

APK en: `build/app/outputs/flutter-apk/app-debug.apk`

## 7. Compilar APK de release

```bash
flutter build apk --release --dart-define=BASE_URL=https://tu-app.onrender.com
```

---

## Estructura del proyecto

```
lib/
├── config/env.dart          ← URL del backend (única config que necesitas cambiar)
├── core/
│   ├── constants/           ← endpoints de la API
│   ├── errors/              ← jerarquía de excepciones
│   └── network/             ← Dio + interceptors (auth, logging, retry)
├── theme/                   ← colores, tipografía, tema Material 3
├── models/                  ← Freezed: Perfume, Paginated, AppConfigModel
├── repositories/            ← acceso a datos (llaman a Dio)
├── features/
│   ├── catalogo/            ← pantalla principal + detalle
│   ├── busqueda/            ← buscador con filtro de marcas
│   └── marcas/              ← lista de marcas → perfumes por marca
└── widgets/                 ← componentes reutilizables
```

## Próximas funcionalidades preparadas

- `lib/features/ventas/`      ← tab "Ventas" (placeholder activo)
- `lib/features/perfil/`      ← tab "Perfil" / auth
- Favoritos (SharedPreferences)
- Carrito de compra
- Offline caching (Hive o SQLite)

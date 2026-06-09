# Flutter — reglas base incluidas automáticamente por el plugin.
# Solo agregar reglas para packages que usen reflexión o JNI.

# Dio / OkHttp (networking)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# Gson / JSON (usado internamente por algunos packages)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }

# shared_preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# connectivity_plus
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# url_launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# cached_network_image / flutter_cache_manager
-keep class com.baseflow.cachemanager.** { *; }

# path_provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Mantener clases de excepciones para stack traces legibles
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

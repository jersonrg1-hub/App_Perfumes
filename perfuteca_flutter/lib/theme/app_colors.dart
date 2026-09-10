import 'package:flutter/material.dart';

/// Paleta de colores de Perfuteca — terracota cálido + dorado.
abstract class AppColors {
  // Terracota (color primario)
  static const primary      = Color(0xFFC8956C);
  static const primaryDark  = Color(0xFFB8724A);
  static const primaryLight = Color(0xFFF0DDD0);
  static const primaryPale  = Color(0xFFFAF4ED);

  // Dorado (perfil olfativo / acento)
  static const gold         = Color(0xFFC9A96E);
  static const goldLight    = Color(0xFFF5EDD8);
  // Texto/ícono dorado sobre goldLight — gold base no da contraste
  // suficiente (~2.5:1) para texto pequeño sobre ese fondo claro.
  static const goldDark     = Color(0xFF8A6D2F);

  // Fondos
  static const background     = Color(0xFFFAF5F0);
  static const surface        = Color(0xFFFFFCFA);
  static const surfaceVariant = Color(0xFFF5EDE4);

  // Texto
  static const textPrimary   = Color(0xFF2C1A0E);
  static const textSecondary = Color(0xFF4A2E18);
  static const textMuted     = Color(0xFF8B6640);
  static const textFaint     = Color(0xFFB89878);

  // Semánticos — tonos cálidos para armonia con la paleta terracota
  static const success = Color(0xFF3D8B51);
  static const warning = Color(0xFFE08C00);
  static const error   = Color(0xFFCC3333);
  static const info    = gold; // sin uso standalone; alias a gold

  // Variante clara de success — mismo contraste que Material green[300],
  // usada sobre fondos oscuros (ej. resumen de total en primaryDark) donde
  // el success normal pierde legibilidad.
  static const successOnDark = Color(0xFF81C784);

  // Superficies semánticas (fills de cards/banners — evita inline withValues)
  static const successSurface = Color(0xFFEAF4EA);
  static const warningSurface = Color(0xFFFFF3E0);
  static const errorSurface   = Color(0xFFFDECEC);

  // Stock — alias de semánticos
  static const stockOk       = success;
  static const stockLow      = warning;
  static const stockCritical = error;

  // Hero histórico — gradiente oscuro deliberadamente fuera de la paleta
  // terracota, usado solo en el card de total acumulado desde el inicio.
  static const heroGradientStart = Color(0xFF1A0A04);
  static const heroGradientEnd   = Color(0xFF4A2810);
  static const heroShadow        = Color(0x402C1A0E);
  static const heroTextPrimary   = Color(0xFFF5E6D8);

  // Trophy — dorado más intenso que gold base, usado solo para resaltar
  // el "mejor mes" dentro del timeline de histórico.
  static const trophy      = Color(0xFFD4A017);
  static const trophyDark  = Color(0xFF7A5C00);
  static const trophyLight = Color(0xFFF0C040);
  static const trophyBg    = Color(0xFFFFF9E6);
  static const trophyBarBg = Color(0xFFF5DFA0);

  // Paleta de avatares con iniciales — variedad cromática deliberada, ajena
  // a la paleta terracota, para diferenciar clientes visualmente.
  static const avatarPalette = [
    Color(0xFFC8956C),
    Color(0xFFC9A96E),
    Color(0xFF7B9EC8),
    Color(0xFF8B9E76),
    Color(0xFFB07BB0),
    Color(0xFF9E887B),
  ];

  // Sombras
  static const shadowColor = Color(0x1A2C1A0E);

  // WhatsApp
  static const whatsapp     = Color(0xFF25D366);
  static const whatsappDark = Color(0xFF128C7E);
}

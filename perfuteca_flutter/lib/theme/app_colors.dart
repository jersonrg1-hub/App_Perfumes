import 'package:flutter/material.dart';

/// Paleta de colores — espeja la paleta Streamlit del backend.
abstract class AppColors {
  // Terracota (color primario)
  static const primary      = Color(0xFFC8956C);
  static const primaryDark  = Color(0xFFB8724A);
  static const primaryLight = Color(0xFFF0DDD0);
  static const primaryPale  = Color(0xFFFAF4ED);

  // Dorado (perfil olfativo / acento)
  static const gold         = Color(0xFFC9A96E);
  static const goldLight    = Color(0xFFF5EDD8);

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

  // Superficies semánticas (fills de cards/banners — evita inline withValues)
  static const successSurface = Color(0xFFEAF4EA);
  static const warningSurface = Color(0xFFFFF3E0);
  static const errorSurface   = Color(0xFFFDECEC);

  // Stock — alias de semánticos
  static const stockOk       = success;
  static const stockLow      = warning;
  static const stockCritical = error;

  // Sombras
  static const shadowColor = Color(0x1A2C1A0E);

  // WhatsApp
  static const whatsapp     = Color(0xFF25D366);
  static const whatsappDark = Color(0xFF128C7E);
}

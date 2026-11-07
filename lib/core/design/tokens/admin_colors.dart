import 'package:flutter/material.dart';
import 'kera_colors.dart';

/// Admin portal color tokens strictly aligned with Kera's modern executive design system.
/// Adheres strictly to WCAG 4.5:1 contrast standards.
class AdminColors {
  AdminColors._();

  // Kera Brand Orange Accent (Primary actions, CTA buttons, chart line 2)
  static const Color primary = KeraColors.orange500;
  static const Color accent = KeraColors.orange500;
  static const Color primaryTint = KeraColors.orange100;
  static const Color primaryDark = KeraColors.orange600;
  static const Color keraOrange = KeraColors.orange500;
  static const Color orangeTint = KeraColors.orange100;

  // Deep Navy Structural Palette (Master Header, Status, Active Anchors, chart line 1)
  static const Color navy = KeraColors.navy800;
  static const Color navyDark = KeraColors.navy900;
  static const Color navyTint = KeraColors.navy100;
  static const Color headerNavy = KeraColors.navy800;
  static const Color headerNavyDark = KeraColors.navy900;
  static const Color headerButtonBg = KeraColors.navy600;
  static const Color headerTextSecondary = Color(0xFFA5B4CB);

  // Light Theme Canvas Palette
  static const Color lightBackground = KeraColors.surfaceCanvas;
  static const Color lightSurface = KeraColors.white;
  static const Color lightSurfaceRaised = KeraColors.white;
  static const Color lightBorder = KeraColors.border;
  static const Color lightTextPrimary = KeraColors.textPrimary;
  static const Color lightTextSecondary = KeraColors.textSecondary;
  static const Color lightMuted = KeraColors.textMutedColor;

  // Dark Theme Palette
  static const Color darkBackground = KeraColors.darkCanvas;
  static const Color darkSurface = Color(0xFF102138);
  static const Color darkSurfaceRaised = Color(0xFF182D4A);
  static const Color darkBorder = Color(0xFF1E385C);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkMuted = Color(0xFF64748B);

  // Default Palette
  static const Color background = lightBackground;
  static const Color surface = lightSurface;
  static const Color raised = lightSurfaceRaised;
  static const Color border = lightBorder;
  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;
  static const Color muted = lightMuted;

  // Semantic Status Colors (True Modern Multi-Color Status with >= 4.5:1 contrast)
  static const Color success = KeraColors.green600;
  static const Color successTint = KeraColors.green50;
  static const Color successBg = KeraColors.green50;

  static const Color warning = KeraColors.amber600;
  static const Color warningTint = KeraColors.amber50;
  static const Color warningBg = KeraColors.amber50;

  static const Color danger = KeraColors.red600;
  static const Color dangerTint = KeraColors.red50;
  static const Color dangerBg = KeraColors.red50;

  static const Color error = KeraColors.red600;
  static const Color errorTint = KeraColors.red50;
  static const Color errorBg = KeraColors.red50;

  static const Color info = KeraColors.sky600;
  static const Color infoTint = KeraColors.sky50;
  static const Color infoBg = KeraColors.sky50;

  // Dynamic Resolvers for Dark/Light mode
  static Color surfaceOf(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color borderOf(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color textPrimaryOf(bool isDark) => isDark ? darkTextPrimary : lightTextPrimary;
  static Color textSecondaryOf(bool isDark) => isDark ? darkTextSecondary : lightTextSecondary;
  static Color backgroundOf(bool isDark) => isDark ? darkBackground : lightBackground;
}

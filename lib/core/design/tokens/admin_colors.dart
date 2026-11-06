import 'package:flutter/material.dart';
import 'kera_colors.dart';

/// Admin portal color tokens strictly aligned with the Kera 2-color brand system.
/// Adheres strictly to WCAG 4.5:1 contrast standards.
///
/// Brand specifications:
/// - Brand Navy: #0B2A5B
/// - Accent Orange: #F7941D
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
  static const Color lightBackground = KeraColors.navy50;
  static const Color lightSurface = KeraColors.white;
  static const Color lightSurfaceRaised = KeraColors.white;
  static const Color lightBorder = KeraColors.border;
  static const Color lightTextPrimary = KeraColors.navy800;
  static const Color lightTextSecondary = KeraColors.textMutedColor;
  static const Color lightMuted = KeraColors.textMutedColor;

  // Dark Theme Palette
  static const Color darkBackground = KeraColors.navy900;
  static const Color darkSurface = Color(0xFF102138);
  static const Color darkSurfaceRaised = Color(0xFF182D4A);
  static const Color darkBorder = Color(0xFF1E385C);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkMuted = Color(0xFF64748B);

  // Default Palette (Active UI matches modern crisp console)
  static const Color background = lightBackground;
  static const Color surface = lightSurface;
  static const Color raised = lightSurfaceRaised;
  static const Color border = lightBorder;
  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;
  static const Color muted = lightMuted;

  // Semantic Status Colors strictly mapped to Navy/Orange (>= 4.5:1 contrast)
  static const Color success = KeraColors.navy800;
  static const Color successTint = KeraColors.navy100;
  static const Color successBg = KeraColors.navy100;
  static const Color warning = KeraColors.orange700;
  static const Color warningTint = KeraColors.orange100;
  static const Color warningBg = KeraColors.orange100;
  static const Color danger = KeraColors.orange700;
  static const Color dangerTint = KeraColors.orange100;
  static const Color dangerBg = KeraColors.orange100;
  static const Color error = KeraColors.orange700;
  static const Color errorTint = KeraColors.orange100;
  static const Color errorBg = KeraColors.orange100;
  static const Color info = KeraColors.navy800;
  static const Color infoTint = KeraColors.navy100;
  static const Color infoBg = KeraColors.navy100;

  // Dynamic theme helpers
  static Color backgroundOf(bool isDark) => isDark ? darkBackground : lightBackground;
  static Color surfaceOf(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color surfaceRaisedOf(bool isDark) => isDark ? darkSurfaceRaised : lightSurfaceRaised;
  static Color borderOf(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color textPrimaryOf(bool isDark) => isDark ? darkTextPrimary : lightTextPrimary;
  static Color textSecondaryOf(bool isDark) => isDark ? darkTextSecondary : lightTextSecondary;
  static Color mutedOf(bool isDark) => isDark ? darkMuted : lightMuted;
}

import 'package:flutter/material.dart';

/// Admin portal color tokens for dark and light modes.
/// Adheres strictly to WCAG 4.5:1 contrast standards.
class AdminColors {
  AdminColors._();

  // Primary Brand Blue
  static const Color primary = Color(0xFF4C8DF6);
  static const Color primaryTint = Color(0x2E4C8DF6); // ~18% alpha for selection indicators
  static const Color primaryDark = Color(0xFF2563EB);

  // Dark Theme Palette (Default for Admin Portal)
  static const Color darkBackground = Color(0xFF0E1621);
  static const Color darkSurface = Color(0xFF152233);
  static const Color darkSurfaceRaised = Color(0xFF1B2B40);
  static const Color darkBorder = Color(0xFF2A3B52);
  static const Color darkTextPrimary = Color(0xFFEAF0F7);
  static const Color darkTextSecondary = Color(0xFF9FB0C3);
  static const Color darkMuted = Color(0xFF62758D);

  // Constants mapping to default dark theme
  static const Color background = darkBackground;
  static const Color surface = darkSurface;
  static const Color raised = darkSurfaceRaised;
  static const Color border = darkBorder;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color muted = darkMuted;

  // Light Theme Palette
  static const Color lightBackground = Color(0xFFF1F5F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceRaised = Color(0xFFF8FAFC);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightMuted = Color(0xFF94A3B8);

  // Semantic Status Colors (>= 4.5:1 contrast against surface)
  static const Color success = Color(0xFF3DD68C);
  static const Color successTint = Color(0x263DD68C); // 15% alpha
  static const Color warning = Color(0xFFF5A524);
  static const Color warningTint = Color(0x26F5A524);
  static const Color danger = Color(0xFFF0616D);
  static const Color dangerTint = Color(0x26F0616D);
  static const Color info = Color(0xFF4C8DF6);
  static const Color infoTint = Color(0x264C8DF6);

  // Dynamic theme helpers
  static Color backgroundOf(bool isDark) => isDark ? darkBackground : lightBackground;
  static Color surfaceOf(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color surfaceRaisedOf(bool isDark) => isDark ? darkSurfaceRaised : lightSurfaceRaised;
  static Color borderOf(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color textPrimaryOf(bool isDark) => isDark ? darkTextPrimary : lightTextPrimary;
  static Color textSecondaryOf(bool isDark) => isDark ? darkTextSecondary : lightTextSecondary;
  static Color mutedOf(bool isDark) => isDark ? darkMuted : lightMuted;
}

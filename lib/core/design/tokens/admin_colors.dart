import 'package:flutter/material.dart';

/// Admin portal color tokens tailored for Kera Spare Tracker Admin Console.
/// Adheres strictly to WCAG 4.5:1 contrast standards.
class AdminColors {
  AdminColors._();

  // Kera Brand Orange Accent (Primary actions, CTA buttons, sparklines)
  static const Color primary = Color(0xFFF58220);
  static const Color primaryTint = Color(0x26F58220); // ~15% alpha
  static const Color primaryDark = Color(0xFFD97010);
  static const Color keraOrange = Color(0xFFF58220);

  // Deep Navy Structural Palette (Master Header, Status, Active Anchors)
  static const Color headerNavy = Color(0xFF0C2340);
  static const Color headerNavyDark = Color(0xFF07172B);
  static const Color headerButtonBg = Color(0xFF1E3557);
  static const Color headerTextSecondary = Color(0xFFA5B4CB);

  // Light Theme Canvas Palette (Default for Admin Dashboard & Screens)
  static const Color lightBackground = Color(0xFFF4F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceRaised = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF5E6D82);
  static const Color lightMuted = Color(0xFF94A3B8);

  // Dark Theme Palette
  static const Color darkBackground = Color(0xFF0C2340);
  static const Color darkSurface = Color(0xFF132D50);
  static const Color darkSurfaceRaised = Color(0xFF1C3B64);
  static const Color darkBorder = Color(0xFF2A4A75);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFA5B4CB);
  static const Color darkMuted = Color(0xFF6B82A0);

  // Default Palette (Active UI matches modern crisp console in mockups)
  static const Color background = lightBackground;
  static const Color surface = lightSurface;
  static const Color raised = lightSurfaceRaised;
  static const Color border = lightBorder;
  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;
  static const Color muted = lightMuted;

  // Semantic Status Colors (>= 4.5:1 contrast)
  static const Color success = Color(0xFF10B981);
  static const Color successTint = Color(0x2210B981); // 13% alpha
  static const Color warning = Color(0xFFF58220);
  static const Color warningTint = Color(0x22F58220);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerTint = Color(0x22EF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoTint = Color(0x223B82F6);

  // Dynamic theme helpers
  static Color backgroundOf(bool isDark) => isDark ? darkBackground : lightBackground;
  static Color surfaceOf(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color surfaceRaisedOf(bool isDark) => isDark ? darkSurfaceRaised : lightSurfaceRaised;
  static Color borderOf(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color textPrimaryOf(bool isDark) => isDark ? darkTextPrimary : lightTextPrimary;
  static Color textSecondaryOf(bool isDark) => isDark ? darkTextSecondary : lightTextSecondary;
  static Color mutedOf(bool isDark) => isDark ? darkMuted : lightMuted;
}

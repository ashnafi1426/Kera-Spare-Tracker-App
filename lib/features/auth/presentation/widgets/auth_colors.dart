import 'package:flutter/material.dart';

/// Design tokens for Kera Spare Tracker Authentication flow matching approved Figma designs.
class AuthColors {
  AuthColors._();

  static const Color primaryNavy = Color(0xFF0B1F44);
  static const Color secondaryNavy = Color(0xFF142D55);
  static const Color accentOrange = Color(0xFFE99A27);
  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primaryText = Color(0xFF172B4D);
  static const Color secondaryText = Color(0xFF718096);
  static const Color border = Color(0xFFE2E8F0);
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color inputBg = Color(0xFFF8FAFC);
  static const Color cardShadow = Color(0x0A0B1F44);

  // Dark Mode Overrides
  static const Color darkBackground = Color(0xFF0B1628);
  static const Color darkSurface = Color(0xFF11223B);
  static const Color darkBorder = Color(0xFF1E3A63);
  static const Color darkInputBg = Color(0xFF162B4A);
  static const Color darkPrimaryText = Color(0xFFF8FAFC);
  static const Color darkSecondaryText = Color(0xFF94A3B8);

  static Color bgOf(bool isDark) => isDark ? darkBackground : background;
  static Color surfaceOf(bool isDark) => isDark ? darkSurface : surface;
  static Color borderOf(bool isDark) => isDark ? darkBorder : border;
  static Color inputBgOf(bool isDark) => isDark ? darkInputBg : inputBg;
  static Color textPrimaryOf(bool isDark) => isDark ? darkPrimaryText : primaryText;
  static Color textSecondaryOf(bool isDark) => isDark ? darkSecondaryText : secondaryText;
}

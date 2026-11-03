import 'package:flutter/material.dart';
import 'admin_colors.dart';

/// Typography tokens for Admin portal.
/// Scale: Title 20, Section Header 16, Body 14, Caption 12 (never below 12).
class AdminTypography {
  AdminTypography._();

  static const String fontNotoSans = 'NotoSansEthiopic';

  // Static getters for standard light theme admin styling
  static TextStyle get h1 => title(false);
  static TextStyle get h2 => title(false).copyWith(fontSize: 18);
  static TextStyle get h3 => sectionHeader(false);
  static TextStyle get bodyLarge => body(false).copyWith(fontSize: 15);
  static TextStyle get bodyMedium => body(false);
  static TextStyle get caption => captionOf(false);
  static TextStyle get captionMedium => captionMediumOf(false);

  // White text styles for Navy App Bars & Headers
  static TextStyle get headerTitle => const TextStyle(
        fontFamily: fontNotoSans,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: -0.2,
      );

  static TextStyle get headerSubtitle => const TextStyle(
        fontFamily: fontNotoSans,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AdminColors.headerTextSecondary,
      );

  // Dynamic theme methods
  static TextStyle title(bool isDark) => TextStyle(
        fontFamily: fontNotoSans,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AdminColors.textPrimaryOf(isDark),
        letterSpacing: -0.2,
      );

  static TextStyle sectionHeader(bool isDark) => TextStyle(
        fontFamily: fontNotoSans,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AdminColors.textPrimaryOf(isDark),
      );

  static TextStyle body(bool isDark) => TextStyle(
        fontFamily: fontNotoSans,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AdminColors.textPrimaryOf(isDark),
      );

  static TextStyle bodySecondary(bool isDark) => TextStyle(
        fontFamily: fontNotoSans,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AdminColors.textSecondaryOf(isDark),
      );

  static TextStyle captionOf(bool isDark) => TextStyle(
        fontFamily: fontNotoSans,
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AdminColors.textSecondaryOf(isDark),
      );

  static TextStyle captionMediumOf(bool isDark) => TextStyle(
        fontFamily: fontNotoSans,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AdminColors.textSecondaryOf(isDark),
      );

  /// Metric number: 28pt bold with tabular figures for aligned numbers
  static TextStyle metricNumber([bool isDark = true]) => TextStyle(
        fontFamily: fontNotoSans,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AdminColors.textPrimaryOf(isDark),
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Compact metric number for smaller cards
  static TextStyle metricNumberCompact([bool isDark = true]) => TextStyle(
        fontFamily: fontNotoSans,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AdminColors.textPrimaryOf(isDark),
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

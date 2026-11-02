import 'package:flutter/material.dart';
import 'kera_colors.dart';

/// Centralized bilingual typography system supporting Amharic (Ge'ez script)
/// and English (Latin script) with tabular numbers for financial figures.
class KeraTypography {
  KeraTypography._();

  /// Primary Ethiopic font family.
  static const String fontEthiopic = 'NotoSansEthiopic';

  // --- Headings ---
  /// Screen Titles & Large Overview Metric Headings (28px Bold).
  static TextStyle headlineLarge({Color color = KeraColors.textPrimary}) => TextStyle(
        fontFamily: fontEthiopic,
        fontSize: 28,
        height: 36 / 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: color,
      );

  /// Dialog Titles, Section Headings (22px SemiBold).
  static TextStyle headlineMedium({Color color = KeraColors.textPrimary}) => TextStyle(
        fontFamily: fontEthiopic,
        fontSize: 22,
        height: 30 / 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: color,
      );

  /// Card Headers & Metric Titles (18px SemiBold).
  static TextStyle headlineSmall({Color color = KeraColors.textPrimary}) => TextStyle(
        fontFamily: fontEthiopic,
        fontSize: 18,
        height: 26 / 18,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // --- Titles ---
  /// Part Item Titles & Form Section Titles (16px SemiBold).
  static TextStyle titleMedium({Color color = KeraColors.textPrimary}) => TextStyle(
        fontFamily: fontEthiopic,
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// Compact titles and group labels (15px SemiBold).
  static TextStyle titleSmall({Color color = KeraColors.textPrimary}) => TextStyle(
        fontFamily: fontEthiopic,
        fontSize: 15,
        height: 22 / 15,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // --- Body ---
  /// Primary Body Copy & Descriptions (16px Regular).
  static TextStyle bodyLarge({Color color = KeraColors.textPrimary}) => TextStyle(
        fontFamily: fontEthiopic,
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: color,
      );

  /// Standard Subtitles, Shelf Locations, Notes (14px Regular).
  static TextStyle bodyMedium({Color color = KeraColors.textSecondary}) => TextStyle(
        fontFamily: fontEthiopic,
        fontSize: 14,
        height: 22 / 14,
        fontWeight: FontWeight.w400,
        color: color,
      );

  /// Part Numbers, Micro-copy, Timestamps (12px Regular).
  static TextStyle bodySmall({Color color = KeraColors.textSecondary}) => TextStyle(
        fontFamily: fontEthiopic,
        fontSize: 12,
        height: 18 / 12,
        fontWeight: FontWeight.w400,
        color: color,
      );

  // --- Labels & Badges ---
  /// Action Buttons (14px SemiBold).
  static TextStyle labelLarge({Color color = KeraColors.textWhite}) => TextStyle(
        fontFamily: fontEthiopic,
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: color,
      );

  /// Filter Chips & Stock Badges (12px Medium).
  static TextStyle labelMedium({Color color = KeraColors.textPrimary}) => TextStyle(
        fontFamily: fontEthiopic,
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        color: color,
      );

  /// Micro Tags & Status Badges (11px SemiBold).
  static TextStyle labelSmall({Color color = KeraColors.textPrimary}) => TextStyle(
        fontFamily: fontEthiopic,
        fontSize: 11,
        height: 14 / 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: color,
      );

  // --- Tabular Numerical Figures (ETB Currency & Counts) ---
  /// High-Clarity Tabular Numerical Display (24px Bold).
  static TextStyle numericStat({Color color = KeraColors.textPrimary}) => TextStyle(
        fontFamily: fontEthiopic,
        fontSize: 24,
        height: 30 / 24,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color,
      );

  /// Medium Tabular Currency Figure (18px Bold).
  static TextStyle numericMedium({Color color = KeraColors.textPrimary}) => TextStyle(
        fontFamily: fontEthiopic,
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color,
      );

  /// Compact Tabular Currency Figure (14px Bold).
  static TextStyle numericCompact({Color color = KeraColors.textPrimary}) => TextStyle(
        fontFamily: fontEthiopic,
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color,
      );

  /// Generates the standard Flutter [TextTheme] adhering to the Stitch specification.
  static TextTheme get textTheme => TextTheme(
        headlineLarge: headlineLarge(),
        headlineMedium: headlineMedium(),
        headlineSmall: headlineSmall(),
        titleMedium: titleMedium(),
        titleSmall: titleSmall(),
        bodyLarge: bodyLarge(),
        bodyMedium: bodyMedium(),
        bodySmall: bodySmall(),
        labelLarge: labelLarge(),
        labelMedium: labelMedium(),
        labelSmall: labelSmall(),
      );
}


import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../design/tokens/kera_colors.dart';
import '../design/tokens/kera_radii.dart';
import '../design/tokens/kera_spacing.dart';
import '../design/tokens/kera_typography.dart';

/// Centralized application theme for Kera Spare Tracker.
///
/// Built for Material 3 using the Google Stitch Pragmatic Modern-Industrial design
/// specifications: high contrast, dust-resilient legibility, and grease-friendly
/// >=48px touch targets for heavy retail counter environments.
///
/// Brand specifications:
/// - Brand Navy: #0B2A5B
/// - Accent Orange: #F7941D
class AppTheme {
  AppTheme._();

  // Brand Palette Constants
  static const Color primaryNavy = KeraColors.primaryNavy; // #0B2A5B
  static const Color keraOrange = KeraColors.keraOrange;   // #F7941D
  static const Color primaryColor = KeraColors.primaryNavy;
  static const Color secondaryColor = KeraColors.keraOrange;
  static const Color errorColor = Color(0xFFDC2626);

  // Chart Palette (Theme-aware access)
  static const Color chartLineRevenue = Color(0xFFF7941D); // Orange for revenue
  static const Color chartLineProfit = Color(0xFF10B981);  // Green for profit
  static const Color chartLineCost = Color(0xFF3B82F6);    // Blue for cost

  /// Light theme for the application adhering strictly to Stitch.
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: KeraColors.primaryNavy,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE8EEF8),
      onPrimaryContainer: KeraColors.primaryNavy,
      secondary: KeraColors.keraOrange,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFFF3E6),
      onSecondaryContainer: Color(0xFF9A5200),
      tertiary: KeraColors.utilityTeal,
      onTertiary: Colors.white,
      surface: KeraColors.surfacePure,
      onSurface: KeraColors.textPrimary,
      onSurfaceVariant: KeraColors.textSecondary,
      error: KeraColors.error,
      onError: Colors.white,
      outline: KeraColors.outlineBorder,
      outlineVariant: KeraColors.outlineVariant,
      surfaceContainerLowest: KeraColors.surfacePure,
      surfaceContainerLow: KeraColors.surfaceMuted,
      surfaceContainer: KeraColors.surfaceContainer,
      surfaceContainerHigh: KeraColors.surfaceContainerHigh,
      surfaceContainerHighest: KeraColors.surfaceContainerHighest,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: KeraTypography.fontEthiopic,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: KeraColors.surfaceCanvas,
      canvasColor: KeraColors.surfaceCanvas,
      cardColor: KeraColors.surfacePure,
      dividerColor: KeraColors.outlineBorder,
      textTheme: KeraTypography.textTheme,
      cardTheme: const CardThemeData(
        color: KeraColors.surfacePure,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: KeraRadii.borderCard,
          side: BorderSide(color: KeraColors.outlineBorder, width: 1),
        ),
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: KeraColors.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 2,
        titleTextStyle: TextStyle(
          fontFamily: KeraTypography.fontEthiopic,
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
          size: 22,
        ),
        actionsIconTheme: IconThemeData(
          color: Colors.white,
          size: 22,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KeraColors.keraOrange,
          foregroundColor: Colors.white,
          minimumSize: const Size(KeraSpacing.minTouchTarget, KeraSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: KeraRadii.borderButton,
          ),
          textStyle: KeraTypography.labelLarge(color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KeraColors.primaryNavy,
          minimumSize: const Size(KeraSpacing.minTouchTarget, KeraSpacing.minTouchTarget),
          side: const BorderSide(color: KeraColors.outlineBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: const RoundedRectangleBorder(
            borderRadius: KeraRadii.borderButton,
          ),
          textStyle: KeraTypography.labelLarge(color: KeraColors.primaryNavy),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KeraColors.keraOrange,
          minimumSize: const Size(KeraSpacing.minTouchTarget, KeraSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: KeraTypography.labelLarge(color: KeraColors.keraOrange),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KeraColors.surfacePure,
        contentPadding: KeraSpacing.inputPadding,
        border: const OutlineInputBorder(
          borderRadius: KeraRadii.borderInput,
          borderSide: BorderSide(color: KeraColors.outlineBorder),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: KeraRadii.borderInput,
          borderSide: BorderSide(color: KeraColors.outlineBorder),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: KeraRadii.borderInput,
          borderSide: BorderSide(color: KeraColors.keraOrange, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: KeraRadii.borderInput,
          borderSide: BorderSide(color: KeraColors.error, width: 1.5),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: KeraRadii.borderInput,
          borderSide: BorderSide(color: KeraColors.error, width: 2),
        ),
        labelStyle: KeraTypography.bodyMedium(color: KeraColors.textSecondary),
        hintStyle: KeraTypography.bodyMedium(color: KeraColors.textMuted),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: KeraColors.keraOrange,
        foregroundColor: Colors.white,
        elevation: 3,
        sizeConstraints: BoxConstraints.tightFor(
          width: 56,
          height: 56,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: KeraColors.outlineBorder,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: KeraColors.surfacePure,
        elevation: 3,
        height: 64,
        indicatorColor: KeraColors.keraOrangeTint,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return KeraTypography.labelMedium(color: KeraColors.keraOrange).copyWith(
              fontWeight: FontWeight.w700,
            );
          }
          return KeraTypography.labelMedium(color: KeraColors.textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: KeraColors.keraOrange, size: 24);
          }
          return const IconThemeData(color: KeraColors.textSecondary, size: 24);
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: KeraColors.surfacePure,
        selectedColor: KeraColors.keraOrangeTint,
        side: const BorderSide(color: KeraColors.outlineBorder, width: 1),
        shape: const RoundedRectangleBorder(borderRadius: KeraRadii.borderMicro),
        labelStyle: KeraTypography.labelMedium(),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: KeraColors.surfacePure,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: KeraRadii.borderSheet,
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: KeraColors.surfacePure,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: KeraRadii.borderCard,
        ),
      ),
    );
  }

  /// Dark theme for the application (Admin portal / Dark mode preference).
  static ThemeData get darkTheme {
    const darkSurface = KeraColors.darkCanvas;        // #071322
    const darkCard = KeraColors.darkCard;            // #102138
    const darkBorder = KeraColors.darkBorder;        // #1E385C
    const darkTextPrimary = KeraColors.darkTextPrimary; // #F1F5F9
    const darkTextSecondary = KeraColors.darkTextSecondary; // #94A3B8

    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: KeraColors.keraOrange,
      onPrimary: Colors.white,
      primaryContainer: Color(0x2EF7941D),
      onPrimaryContainer: Colors.white,
      secondary: KeraColors.keraOrange,
      onSecondary: Colors.white,
      secondaryContainer: Color(0x2EF7941D),
      onSecondaryContainer: Colors.white,
      surface: darkCard,
      onSurface: darkTextPrimary,
      onSurfaceVariant: darkTextSecondary,
      error: KeraColors.error,
      onError: Colors.white,
      outline: darkBorder,
      outlineVariant: Color(0xFF264773),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: KeraTypography.fontEthiopic,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkSurface,
      canvasColor: darkSurface,
      cardColor: darkCard,
      dividerColor: darkBorder,
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(
          color: darkTextPrimary,
          size: 22,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KeraColors.keraOrange,
          foregroundColor: Colors.white,
          minimumSize: const Size(KeraSpacing.minTouchTarget, KeraSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextPrimary,
          minimumSize: const Size(KeraSpacing.minTouchTarget, KeraSpacing.minTouchTarget),
          side: const BorderSide(color: darkBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KeraColors.keraOrange,
          minimumSize: const Size(AppConstants.minTouchTargetSize, AppConstants.minTouchTargetSize),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: KeraColors.keraOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: KeraColors.error),
        ),
        labelStyle: const TextStyle(fontSize: 15, color: darkTextSecondary),
        hintStyle: const TextStyle(fontSize: 14, color: darkTextSecondary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: KeraColors.keraOrange,
        foregroundColor: Colors.white,
        elevation: 2,
        sizeConstraints: BoxConstraints.tightFor(
          width: 56,
          height: 56,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: const Color(0x2EF7941D),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: KeraColors.keraOrange,
            );
          }
          return const TextStyle(
            fontSize: 12,
            color: darkTextSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: KeraColors.keraOrange);
          }
          return const IconThemeData(color: darkTextSecondary);
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkCard,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: KeraRadii.borderSheet,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: darkCard,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: KeraRadii.borderCard,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkCard,
        selectedColor: const Color(0x2EF7941D),
        side: const BorderSide(color: darkBorder, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: const TextStyle(fontSize: 12, color: darkTextPrimary),
      ),
    );
  }
}

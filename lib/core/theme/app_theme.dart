import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../design/tokens/kera_colors.dart';
import '../design/tokens/kera_radii.dart';
import '../design/tokens/kera_spacing.dart';
import '../design/tokens/kera_theme_colors.dart';
import '../design/tokens/kera_typography.dart';

/// Centralized modern executive theme for Kera Spare Tracker.
///
/// Implements the professional mobile inventory design system:
/// - Primary: Deep Navy Blue (#0B2A5B)
/// - Accent: Professional Orange (#F7941D)
/// - Canvas: Clean light grey / off-white (#F8FAFC)
/// - Cards: Pure White (#FFFFFF) with subtle shadows & rounded corners
/// - Success: Professional Green (#10B981, #047857)
/// - Warning: Amber (#F59E0B, #B45309)
/// - Error: Professional Red (#EF4444, #DC2626)
class AppTheme {
  AppTheme._();

  // Brand Palette Constants
  static const Color primaryNavy = KeraColors.navy800;   // #0B2A5B
  static const Color keraOrange = KeraColors.orange500;   // #F7941D
  static const Color primaryColor = KeraColors.navy800;
  static const Color secondaryColor = KeraColors.orange500;
  static const Color errorColor = KeraColors.red600;

  // Chart Palette (Series 1 = Navy, Series 2 = Orange, Series 3 = Green)
  static const Color chartLineRevenue = KeraColors.orange500;
  static const Color chartLineProfit = KeraColors.green600;
  static const Color chartLineCost = KeraColors.navy800;

  /// Light theme for the application.
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: KeraColors.navy800,
      onPrimary: Colors.white,
      primaryContainer: KeraColors.navy100,
      onPrimaryContainer: KeraColors.navy800,
      secondary: KeraColors.orange500,
      onSecondary: Colors.white,
      secondaryContainer: KeraColors.orange100,
      onSecondaryContainer: KeraColors.orange700,
      tertiary: KeraColors.green600,
      onTertiary: Colors.white,
      surface: KeraColors.white,
      onSurface: KeraColors.textPrimary,
      onSurfaceVariant: KeraColors.textMutedColor,
      error: KeraColors.red600,
      onError: Colors.white,
      outline: KeraColors.border,
      outlineVariant: KeraColors.navy100,
      surfaceContainerLowest: KeraColors.white,
      surfaceContainerLow: KeraColors.surfaceSubtle,
      surfaceContainer: KeraColors.surfaceContainer,
      surfaceContainerHigh: KeraColors.surfaceContainerHigh,
      surfaceContainerHighest: KeraColors.surfaceContainerHighest,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: KeraTypography.fontEthiopic,
      fontFamilyFallback: KeraTypography.fontFallbacks,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: KeraColors.surfaceCanvas,
      canvasColor: KeraColors.surfaceCanvas,
      cardColor: KeraColors.white,
      dividerColor: KeraColors.border,
      extensions: const <ThemeExtension<dynamic>>[
        KeraThemeColors.light,
      ],
      textTheme: KeraTypography.textTheme,
      cardTheme: const CardThemeData(
        color: KeraColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: KeraRadii.borderCard,
          side: BorderSide(color: KeraColors.border, width: 1),
        ),
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: KeraColors.navy800,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 2,
        titleTextStyle: TextStyle(
          fontFamily: KeraTypography.fontEthiopic,
          fontFamilyFallback: KeraTypography.fontFallbacks,
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
          backgroundColor: KeraColors.orange500,
          foregroundColor: Colors.white,
          minimumSize: const Size(KeraSpacing.minTouchTarget, KeraSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: KeraRadii.borderButton,
          ),
          textStyle: KeraTypography.labelLarge(color: Colors.white).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KeraColors.navy800,
          minimumSize: const Size(KeraSpacing.minTouchTarget, KeraSpacing.minTouchTarget),
          side: const BorderSide(color: KeraColors.navy800, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: const RoundedRectangleBorder(
            borderRadius: KeraRadii.borderButton,
          ),
          textStyle: KeraTypography.labelLarge(color: KeraColors.navy800).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KeraColors.orange700,
          minimumSize: const Size(KeraSpacing.minTouchTarget, KeraSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          textStyle: KeraTypography.labelLarge(color: KeraColors.orange700).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return KeraColors.orange500;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: KeraColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return KeraColors.orange500;
          }
          return KeraColors.disabledColor;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return KeraColors.orange100;
          }
          return KeraColors.navy100;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return KeraColors.orange500;
          }
          return KeraColors.border;
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KeraColors.white,
        contentPadding: KeraSpacing.inputPadding,
        border: const OutlineInputBorder(
          borderRadius: KeraRadii.borderInput,
          borderSide: BorderSide(color: KeraColors.border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: KeraRadii.borderInput,
          borderSide: BorderSide(color: KeraColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: KeraRadii.borderInput,
          borderSide: BorderSide(color: KeraColors.navy800, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: KeraRadii.borderInput,
          borderSide: BorderSide(color: KeraColors.red600, width: 1.5),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: KeraRadii.borderInput,
          borderSide: BorderSide(color: KeraColors.red600, width: 2),
        ),
        labelStyle: KeraTypography.bodyMedium(color: KeraColors.textMutedColor),
        hintStyle: KeraTypography.bodyMedium(color: KeraColors.disabledColor),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: KeraColors.orange500,
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
        color: KeraColors.border,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: KeraColors.white,
        elevation: 3,
        height: 64,
        indicatorColor: KeraColors.navy100,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return KeraTypography.labelMedium(color: KeraColors.navy800).copyWith(
              fontWeight: FontWeight.w700,
            );
          }
          return KeraTypography.labelMedium(color: KeraColors.textMutedColor);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: KeraColors.navy800, size: 24);
          }
          return const IconThemeData(color: KeraColors.textMutedColor, size: 24);
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: KeraColors.white,
        selectedColor: KeraColors.navy100,
        side: const BorderSide(color: KeraColors.border, width: 1),
        shape: const RoundedRectangleBorder(borderRadius: KeraRadii.borderMicro),
        labelStyle: KeraTypography.labelMedium(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: KeraColors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: KeraRadii.borderSheet,
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: KeraColors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: KeraRadii.borderCard,
        ),
      ),
    );
  }

  /// Dark theme for the application.
  static ThemeData get darkTheme {
    const darkSurface = KeraColors.darkCanvas;
    const darkCard = KeraColors.darkCard;
    const darkBorder = KeraColors.darkBorder;
    const darkTextPrimary = KeraColors.darkTextPrimary;
    const darkTextSecondary = KeraColors.darkTextSecondary;

    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: KeraColors.orange500,
      onPrimary: Colors.white,
      primaryContainer: KeraColors.navy800,
      onPrimaryContainer: Colors.white,
      secondary: KeraColors.orange500,
      onSecondary: Colors.white,
      secondaryContainer: KeraColors.navy800,
      onSecondaryContainer: Colors.white,
      surface: darkCard,
      onSurface: darkTextPrimary,
      onSurfaceVariant: darkTextSecondary,
      error: KeraColors.red500,
      onError: Colors.white,
      outline: darkBorder,
      outlineVariant: Color(0xFF264773),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: KeraTypography.fontEthiopic,
      fontFamilyFallback: KeraTypography.fontFallbacks,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkSurface,
      canvasColor: darkSurface,
      cardColor: darkCard,
      dividerColor: darkBorder,
      extensions: const <ThemeExtension<dynamic>>[
        KeraThemeColors.dark,
      ],
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
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
          fontFamily: KeraTypography.fontEthiopic,
          fontFamilyFallback: KeraTypography.fontFallbacks,
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
          backgroundColor: KeraColors.orange500,
          foregroundColor: Colors.white,
          minimumSize: const Size(KeraSpacing.minTouchTarget, KeraSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
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
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KeraColors.orange500,
          minimumSize: const Size(AppConstants.minTouchTargetSize, AppConstants.minTouchTargetSize),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return KeraColors.orange500;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: darkBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KeraColors.orange500, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KeraColors.red500),
        ),
        labelStyle: const TextStyle(fontSize: 15, color: darkTextSecondary),
        hintStyle: const TextStyle(fontSize: 14, color: darkTextSecondary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: KeraColors.orange500,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkCard,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: KeraRadii.borderSheet,
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: darkCard,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: KeraRadii.borderCard,
        ),
      ),
    );
  }
}

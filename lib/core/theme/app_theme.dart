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
class AppTheme {
  AppTheme._();

  // --- Stitch Brand Palette Aliases for Backwards Compatibility ---
  static const Color primaryColor = KeraColors.primaryNavy; // #172B4D
  static const Color onPrimaryColor = KeraColors.textWhite;
  static const Color primaryContainer = Color(0xFFDBEAFE);
  static const Color onPrimaryContainer = KeraColors.primaryNavy;

  static const Color actionBlue = KeraColors.actionBlue; // #2563EB
  static const Color secondaryColor = KeraColors.actionBlue; // Interactive blue trigger
  static const Color onSecondaryColor = Colors.white;
  static const Color secondaryContainer = KeraColors.actionBlueTint;
  static const Color onSecondaryContainer = Color(0xFF1D4ED8);

  static const Color surfaceColor = KeraColors.surfaceCanvas; // #F8FAFC
  static const Color surfaceCardColor = KeraColors.surfacePure; // #FFFFFF
  static const Color onSurfaceColor = KeraColors.textPrimary; // #191C1E
  static const Color onSurfaceVariant = KeraColors.textSecondary; // #64748B

  static const Color errorColor = KeraColors.error; // #DC2626
  static const Color successColor = KeraColors.success; // #16A34A
  static const Color warningColor = KeraColors.warning; // #D97706
  static const Color outlineColor = KeraColors.outlineBorder; // #E2E8F0

  /// Light theme for the application adhering strictly to Stitch.
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: KeraColors.primaryNavy,
      onPrimary: KeraColors.textWhite,
      primaryContainer: Color(0xFFDBEAFE),
      onPrimaryContainer: KeraColors.primaryNavy,
      secondary: KeraColors.actionBlue,
      onSecondary: Colors.white,
      secondaryContainer: KeraColors.actionBlueTint,
      onSecondaryContainer: Color(0xFF1D4ED8),
      tertiary: KeraColors.utilityTeal,
      onTertiary: Colors.white,
      surface: KeraColors.surfaceCanvas,
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
        foregroundColor: KeraColors.textWhite,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 2,
        titleTextStyle: TextStyle(
          fontFamily: KeraTypography.fontEthiopic,
          color: KeraColors.textWhite,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(
          color: KeraColors.textWhite,
          size: 22,
        ),
        actionsIconTheme: IconThemeData(
          color: KeraColors.textWhite,
          size: 22,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KeraColors.actionBlue,
          foregroundColor: KeraColors.textWhite,
          minimumSize: const Size(KeraSpacing.minTouchTarget, KeraSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: KeraRadii.borderButton,
          ),
          textStyle: KeraTypography.labelLarge(),
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
          foregroundColor: KeraColors.actionBlue,
          minimumSize: const Size(KeraSpacing.minTouchTarget, KeraSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: KeraTypography.labelLarge(color: KeraColors.actionBlue),
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
          borderSide: BorderSide(color: KeraColors.actionBlue, width: 2),
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
        backgroundColor: KeraColors.actionBlue,
        foregroundColor: KeraColors.textWhite,
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
        indicatorColor: KeraColors.actionBlueTint,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return KeraTypography.labelMedium(color: KeraColors.actionBlue).copyWith(
              fontWeight: FontWeight.w700,
            );
          }
          return KeraTypography.labelMedium(color: KeraColors.textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: KeraColors.actionBlue, size: 24);
          }
          return const IconThemeData(color: KeraColors.textSecondary, size: 24);
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: KeraColors.surfacePure,
        selectedColor: KeraColors.actionBlueTint,
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
    const darkPrimary = Color(0xFF4C8DF6);
    const darkOnPrimary = Colors.white;
    const darkPrimaryContainer = Color(0x2E4C8DF6);
    const darkOnPrimaryContainer = Color(0xFFEAF0F7);

    const darkSecondary = Color(0xFFF5A524);
    const darkOnSecondary = Color(0xFF0E1621);
    const darkSecondaryContainer = Color(0x2E4C8DF6);
    const darkOnSecondaryContainer = Color(0xFFEAF0F7);

    const darkSurface = Color(0xFF0E1621);
    const darkCard = Color(0xFF152233);
    const darkOnSurface = Color(0xFFEAF0F7);
    const darkOnSurfaceVariant = Color(0xFF9FB0C3);

    const darkOutline = Color(0xFF2A3B52);
    const darkError = Color(0xFFF0616D);

    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: darkPrimary,
      onPrimary: darkOnPrimary,
      primaryContainer: darkPrimaryContainer,
      onPrimaryContainer: darkOnPrimaryContainer,
      secondary: darkSecondary,
      onSecondary: darkOnSecondary,
      secondaryContainer: darkSecondaryContainer,
      onSecondaryContainer: darkOnSecondaryContainer,
      surface: darkSurface,
      onSurface: darkOnSurface,
      onSurfaceVariant: darkOnSurfaceVariant,
      error: darkError,
      onError: Colors.black,
      outline: darkOutline,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: KeraTypography.fontEthiopic,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkSurface,
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkOutline, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkCard,
        foregroundColor: darkOnSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          color: darkOnSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: darkOnPrimary,
          minimumSize: const Size(double.infinity, AppConstants.standardButtonHeight),
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
          foregroundColor: darkPrimary,
          minimumSize: const Size(double.infinity, AppConstants.standardButtonHeight),
          side: const BorderSide(color: darkPrimary, width: 1.5),
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
          foregroundColor: darkPrimary,
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
          borderSide: const BorderSide(color: darkOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkError),
        ),
        labelStyle: const TextStyle(fontSize: 15, color: darkOnSurfaceVariant),
        hintStyle: const TextStyle(fontSize: 14, color: darkOnSurfaceVariant),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkSecondary,
        foregroundColor: darkOnSecondary,
        elevation: 2,
        sizeConstraints: const BoxConstraints.tightFor(
          width: 56,
          height: 56,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkOutline,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: const Color(0x2E4C8DF6),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4C8DF6),
            );
          }
          return const TextStyle(
            fontSize: 12,
            color: darkOnSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF4C8DF6));
          }
          return const IconThemeData(color: darkOnSurfaceVariant);
        }),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: darkSurface,
        indicatorColor: Color(0x2E4C8DF6),
        selectedIconTheme: IconThemeData(color: Color(0xFF4C8DF6)),
        unselectedIconTheme: IconThemeData(color: darkOnSurfaceVariant),
        selectedLabelTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4C8DF6),
        ),
        unselectedLabelTextStyle: TextStyle(
          fontSize: 12,
          color: darkOnSurfaceVariant,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface,
        selectedColor: const Color(0x2E4C8DF6),
        side: const BorderSide(color: darkOutline, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: const TextStyle(fontSize: 12, color: darkOnSurface),
      ),
    );
  }
}

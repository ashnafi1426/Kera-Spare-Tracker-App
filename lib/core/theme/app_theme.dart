import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../design/tokens/kera_colors.dart';
import '../design/tokens/kera_radii.dart';
import '../design/tokens/kera_spacing.dart';
import '../design/tokens/kera_theme_colors.dart';
import '../design/tokens/kera_typography.dart';

/// Centralized application theme for Kera Spare Tracker.
/// Strictly implements the TWO-COLOR brand palette sampled from the logo:
/// - Brand Color 1: NAVY (#0B2A5B main, #061B3F dark background, #1D4A8A mid, #E6ECF7 tint)
/// - Brand Color 2: ORANGE (#F7941D main CTA, #E07F00 pressed, #B35F00 AA text, #FFF1DC soft tint)
/// - Neutrals: White #FFFFFF, Page #F3F5FA, Border #D3DAE8, Muted text #4A5B78, Disabled #9AA7BD.
class AppTheme {
  AppTheme._();

  // Brand Palette Constants
  static const Color primaryNavy = KeraColors.navy800;   // #0B2A5B
  static const Color keraOrange = KeraColors.orange500;   // #F7941D
  static const Color primaryColor = KeraColors.navy800;
  static const Color secondaryColor = KeraColors.orange500;
  static const Color errorColor = KeraColors.orange700;

  // 2-Color Chart Palette (Theme-aware access: Series 1 = Navy, Series 2 = Orange)
  static const Color chartLineRevenue = KeraColors.orange500; // Orange for revenue / series 2
  static const Color chartLineProfit = KeraColors.navy800;   // Navy for profit / series 1
  static const Color chartLineCost = KeraColors.navy600;     // Navy tint for secondary series

  /// Light theme for the application adhering strictly to the 2-color brand system.
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: KeraColors.navy800,
      onPrimary: Colors.white,
      primaryContainer: KeraColors.navy100,
      onPrimaryContainer: KeraColors.navy800,
      secondary: KeraColors.orange500,
      onSecondary: KeraColors.navy900, // Contrast rule: Navy text on orange
      secondaryContainer: KeraColors.orange100,
      onSecondaryContainer: KeraColors.orange700,
      tertiary: KeraColors.navy600,
      onTertiary: Colors.white,
      surface: KeraColors.white,
      onSurface: KeraColors.navy800,
      onSurfaceVariant: KeraColors.textMutedColor,
      error: KeraColors.orange700,
      onError: Colors.white,
      outline: KeraColors.border,
      outlineVariant: KeraColors.navy100,
      surfaceContainerLowest: KeraColors.white,
      surfaceContainerLow: KeraColors.navy50,
      surfaceContainer: KeraColors.navy50,
      surfaceContainerHigh: KeraColors.navy100,
      surfaceContainerHighest: KeraColors.navy100,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: KeraTypography.fontEthiopic,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: KeraColors.navy50,
      canvasColor: KeraColors.navy50,
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
          foregroundColor: KeraColors.navy900, // Navy bold text on orange per contrast rule
          minimumSize: const Size(KeraSpacing.minTouchTarget, KeraSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: KeraRadii.borderButton,
          ),
          textStyle: KeraTypography.labelLarge(color: KeraColors.navy900).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KeraColors.navy800,
          minimumSize: const Size(KeraSpacing.minTouchTarget, KeraSpacing.minTouchTarget),
          side: const BorderSide(color: KeraColors.navy800, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        checkColor: WidgetStateProperty.all(KeraColors.navy900),
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
          borderSide: BorderSide(color: KeraColors.orange700, width: 1.5),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: KeraRadii.borderInput,
          borderSide: BorderSide(color: KeraColors.orange700, width: 2),
        ),
        labelStyle: KeraTypography.bodyMedium(color: KeraColors.textMutedColor),
        hintStyle: KeraTypography.bodyMedium(color: KeraColors.disabledColor),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: KeraColors.orange500,
        foregroundColor: KeraColors.navy900,
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

  /// Dark theme for the application strictly adhering to the 2-color brand system.
  static ThemeData get darkTheme {
    const darkSurface = KeraColors.navy900;       // #061B3F
    const darkCard = Color(0xFF102138);           // Slightly lighter navy card
    const darkBorder = Color(0xFF1E385C);         // Crisp navy border
    const darkTextPrimary = Color(0xFFF1F5F9);    // Near-white text
    const darkTextSecondary = Color(0xFF94A3B8);  // Soft navy-gray text

    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: KeraColors.orange500,
      onPrimary: KeraColors.navy900,
      primaryContainer: KeraColors.navy800,
      onPrimaryContainer: Colors.white,
      secondary: KeraColors.orange500,
      onSecondary: KeraColors.navy900,
      secondaryContainer: KeraColors.navy800,
      onSecondaryContainer: Colors.white,
      surface: darkCard,
      onSurface: darkTextPrimary,
      onSurfaceVariant: darkTextSecondary,
      error: KeraColors.orange700,
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
      extensions: const <ThemeExtension<dynamic>>[
        KeraThemeColors.dark,
      ],
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
          backgroundColor: KeraColors.orange500,
          foregroundColor: KeraColors.navy900,
          minimumSize: const Size(KeraSpacing.minTouchTarget, KeraSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
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
        checkColor: WidgetStateProperty.all(KeraColors.navy900),
        side: const BorderSide(color: darkBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
          borderSide: const BorderSide(color: KeraColors.orange500, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: KeraColors.orange700),
        ),
        labelStyle: const TextStyle(fontSize: 15, color: darkTextSecondary),
        hintStyle: const TextStyle(fontSize: 14, color: darkTextSecondary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: KeraColors.orange500,
        foregroundColor: KeraColors.navy900,
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

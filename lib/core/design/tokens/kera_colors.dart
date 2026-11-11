import 'package:flutter/material.dart';
import 'kera_theme_colors.dart';

/// Centralized modern design system color palette for Kera Spare Tracker.
///
/// Design Vision:
/// - Primary: Deep Navy Blue (#0B2A5B, #061B3F)
/// - Accent: Professional Orange (#F7941D, #FF6B00)
/// - Background: Clean Light Grey / Off-White (#F8FAFC)
/// - Cards & Surfaces: Pure White (#FFFFFF) with subtle shadows & rounded corners
/// - Success: Professional Emerald Green (#10B981, #047857, bg: #ECFDF5)
/// - Warning: Amber (#F59E0B, #B45309, bg: #FFFBEB)
/// - Error: Professional Red (#EF4444, #B91C1C, bg: #FEF2F2)
/// - Typography: Slate-900 / Navy-900 high legibility
class KeraColors {
  KeraColors._();

  // --- Primary Navy Palette ---
  static const Color navy950 = Color(0xFF041026);
  static const Color navy900 = Color(0xFF061B3F);
  static const Color navy800 = Color(0xFF0B2A5B); // Primary brand anchor
  static const Color navy700 = Color(0xFF123B7A);
  static const Color navy600 = Color(0xFF1D4A8A);
  static const Color navy500 = Color(0xFF2563EB); // Interactive blue
  static const Color navy200 = Color(0xFFC7D7F0);
  static const Color navy100 = Color(0xFFE8EEF8);
  static const Color navy50  = Color(0xFFF4F6FA);

  // --- Professional Accent Orange Palette ---
  static const Color orange900 = Color(0xFF78350F);
  static const Color orange700 = Color(0xFFB45309);
  static const Color orange600 = Color(0xFFE07F00);
  static const Color orange500 = Color(0xFFF7941D); // Primary accent & CTA
  static const Color orange200 = Color(0xFFFED7AA);
  static const Color orange100 = Color(0xFFFFF1DC);
  static const Color orange50  = Color(0xFFFFFBF5);

  // --- Neutrals & Canvas Surfaces ---
  static const Color white = Color(0xFFFFFFFF);
  static const Color canvasBg = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFEEF2F6);
  static const Color textDark = Color(0xFF0B192C);
  static const Color textMutedColor = Color(0xFF64748B);
  static const Color disabledColor = Color(0xFF94A3B8);

  // --- Semantic: Professional Green (Success / In Stock / Synced) ---
  static const Color green500 = Color(0xFF10B981);
  static const Color green600 = Color(0xFF059669);
  static const Color green700 = Color(0xFF047857);
  static const Color green100 = Color(0xFFD1FAE5);
  static const Color green50  = Color(0xFFECFDF5);

  // --- Semantic: Amber (Warning / Low Stock / Pending) ---
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber700 = Color(0xFFB45309);
  static const Color amber100 = Color(0xFFFEF3C7);
  static const Color amber50  = Color(0xFFFFFBEB);

  // --- Semantic: Red (Error / Out of Stock / Conflict) ---
  static const Color red500 = Color(0xFFEF4444);
  static const Color red600 = Color(0xFFDC2626);
  static const Color red700 = Color(0xFFB91C1C);
  static const Color red100 = Color(0xFFFEE2E2);
  static const Color red50  = Color(0xFFFEF2F2);

  // --- Semantic: Sky Blue (Info / Neutral Highlights) ---
  static const Color sky600 = Color(0xFF0284C7);
  static const Color sky100 = Color(0xFFE0F2FE);
  static const Color sky50  = Color(0xFFF0F9FF);

  // --- Splash Screen & Gradients ---
  static const Color splashRadialNavy = Color(0xFF0F2B58);
  static const Color splashBgLightWarm = Color(0xFFFFF9F2);
  static const Color splashBgLightNeutral = Color(0xFFFCFDFE);

  // --- Auth & Form Containers ---
  static const Color inputBg = Color(0xFFF8FAFC);
  static const Color flagContainerBg = Color(0xFFEFF3F8);

  // --- Brand Aliases for Compatibility ---
  static const Color brandNavy = navy800;
  static const Color brandNavyDark = navy900;
  static const Color brandNavyLight = navy600;
  static const Color navyTint = navy100;
  static const Color primaryNavy = navy800;
  static const Color primaryNavyLight = navy600;
  static const Color primaryNavyDark = navy900;

  static const Color keraOrange = orange500;
  static const Color brandOrange = orange500;
  static const Color orangeTint = orange100;
  static const Color keraOrangeDark = orange600;
  static const Color keraOrangeTint = orange100;

  // --- Surface & Canvas Hierarchy ---
  static const Color surfaceCanvas = canvasBg;
  static const Color surfacePure = white;
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color surfaceSubtle = Color(0xFFF8FAFC);
  static const Color surfaceContainer = Color(0xFFF1F5F9);
  static const Color surfaceContainerLow = Color(0xFFF8FAFC);
  static const Color surfaceContainerHigh = Color(0xFFE2E8F0);
  static const Color surfaceContainerHighest = Color(0xFFCBD5E1);
  static const Color backgroundLight = canvasBg;
  static const Color surfaceCard = white;

  // --- Outlines & Dividers ---
  static const Color outlineBorder = border;
  static const Color borderOpaque = border;
  static const Color outlineVariant = Color(0xFFCBD5E1);
  static const Color borderVariant = Color(0xFFCBD5E1);
  static const Color borderNeutral = border;
  static const Color borderLight = borderSubtle;

  // --- High-Contrast Typography ---
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = textMutedColor;
  static const Color textMuted = textMutedColor;
  static const Color textWhite = white;

  // --- Interactive Elements ---
  static const Color actionBlue = navy800;
  static const Color actionBluePressed = navy900;
  static const Color actionBlueTint = navy100;

  static const Color utilityTeal = Color(0xFF0D9488);
  static const Color utilityTealPressed = Color(0xFF0F766E);
  static const Color utilityTealTint = Color(0xFFCCFBF1);
  static const Color tealDark = Color(0xFF115E59);
  static const Color tealFixed = Color(0xFF0D9488);
  static const Color tealAccent = orange500;

  // --- Stock Indicators (Professional Semantic: Green / Amber / Red) ---
  static const Color stockInBg = green50;
  static const Color stockInText = green700;
  static const Color stockInBorder = Color(0xFFA7F3D0);

  static const Color stockLowBg = amber50;
  static const Color stockLowText = amber700;
  static const Color stockLowBorder = Color(0xFFFDE68A);

  static const Color stockOutBg = red50;
  static const Color stockOutText = red700;
  static const Color stockOutBorder = Color(0xFFFECACA);

  // --- Sync Indicators ---
  static const Color syncSuccessBg = green50;
  static const Color syncSuccessText = green700;
  static const Color syncSuccessBorder = Color(0xFFA7F3D0);

  static const Color syncPendingBg = amber50;
  static const Color syncPendingText = amber700;
  static const Color syncPendingBorder = Color(0xFFFDE68A);

  static const Color syncFailedBg = red50;
  static const Color syncFailedText = red700;
  static const Color syncFailedBorder = Color(0xFFFECACA);

  // --- General Status Semantic Aliases ---
  static const Color success = green700;
  static const Color successBg = green50;
  static const Color successGreen = green600;

  static const Color warning = amber700;
  static const Color warningBg = amber50;
  static const Color warningAmber = amber600;
  static const Color warningAmberBg = amber50;
  static const Color warningAmberBorder = Color(0xFFFDE68A);

  static const Color error = red600;
  static const Color errorBg = red50;
  static const Color errorLight = red100;
  static const Color errorRed = red700;

  static const Color info = sky600;
  static const Color infoBg = sky50;

  // --- Scrim & Shadows ---
  static const Color scrim = Color(0x66061B3F);

  static const BoxShadow shadowLevel1 = BoxShadow(
    color: Color(0x0A0B2A5B),
    blurRadius: 4,
    offset: Offset(0, 1),
  );

  static const BoxShadow shadowLevel2 = BoxShadow(
    color: Color(0x120B2A5B),
    blurRadius: 10,
    offset: Offset(0, 4),
  );

  static const BoxShadow shadowLevel3 = BoxShadow(
    color: Color(0x200B2A5B),
    blurRadius: 20,
    offset: Offset(0, 8),
  );

  // --- Dark Theme Tokens ---
  static const Color darkCanvas = Color(0xFF091424);
  static const Color darkCard = Color(0xFF102138);
  static const Color darkCardElevated = Color(0xFF182D4A);
  static const Color darkBorder = Color(0xFF1E385C);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // --- Theme-Aware Dynamic Resolvers ---
  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkCard : surfacePure;

  static Color canvas(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkCanvas : surfaceCanvas;

  static Color container(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkCardElevated : surfaceMuted;

  static Color borderOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBorder : outlineBorder;

  static Color text(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextPrimary : textPrimary;

  static Color textSubtle(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextSecondary : textSecondary;

  /// Returns custom brand tokens from Theme.
  static KeraThemeColors tokensOf(BuildContext context) =>
      Theme.of(context).extension<KeraThemeColors>() ??
      (Theme.of(context).brightness == Brightness.dark
          ? KeraThemeColors.dark
          : KeraThemeColors.light);
}

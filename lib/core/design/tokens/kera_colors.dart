import 'package:flutter/material.dart';
import 'kera_theme_colors.dart';

/// Centralized color palette strictly conforming to the 2-color brand system
/// sampled from Kera Spare Tracker's official logo.
///
/// Brand specifications:
/// - Brand color 1 (NAVY):
///   - navy900: #061B3F (Dark canvas & high-contrast deep text)
///   - navy800: #0B2A5B (MAIN navy: structure, app bar, active tab, icons, series 1)
///   - navy600: #1D4A8A (Mid navy: secondary outlines, focused borders)
///   - navy100: #E6ECF7 (Soft navy tint: in-stock / synced status chips, active pill fill)
///   - navy50:  #F3F5FA (Light neutral canvas)
/// - Brand color 2 (ORANGE):
///   - orange500: #F7941D (MAIN orange: single primary CTA, highlights, attention, series 2)
///   - orange600: #E07F00 (Orange pressed / hover state)
///   - orange700: #B35F00 (High-contrast orange text on light surfaces - WCAG AA)
///   - orange100: #FFF1DC (Soft orange tint: pending / low stock status chips)
/// - Neutrals:
///   - white:     #FFFFFF (Cards, plates, on-navy text)
///   - border:    #D3DAE8 (Crisp 1px card and input outlines)
///   - textMuted: #4A5B78 (Subtitles, part numbers, bilingual captions)
///   - disabled:  #9AA7BD (Disabled buttons, inactive elements)
class KeraColors {
  KeraColors._();

  // --- Strict Brand Palette Tokens ---
  static const Color navy900 = Color(0xFF061B3F);
  static const Color navy800 = Color(0xFF0B2A5B);
  static const Color navy600 = Color(0xFF1D4A8A);
  static const Color navy100 = Color(0xFFE6ECF7);
  static const Color navy50 = Color(0xFFF3F5FA);

  static const Color orange500 = Color(0xFFF7941D);
  static const Color orange600 = Color(0xFFE07F00);
  static const Color orange700 = Color(0xFFB35F00);
  static const Color orange100 = Color(0xFFFFF1DC);

  static const Color white = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFD3DAE8);
  static const Color textMutedColor = Color(0xFF4A5B78);
  static const Color disabledColor = Color(0xFF9AA7BD);

  // --- Structural Navy Aliases ---
  static const Color brandNavy = navy800;
  static const Color brandNavyDark = navy900;
  static const Color brandNavyLight = navy600;
  static const Color navyTint = navy100;
  static const Color primaryNavy = navy800;
  static const Color primaryNavyLight = navy600;
  static const Color primaryNavyDark = navy900;

  // --- Brand Accent Orange Aliases ---
  static const Color keraOrange = orange500;
  static const Color brandOrange = orange500;
  static const Color orangeTint = orange100;
  static const Color keraOrangeDark = orange600;
  static const Color keraOrangeTint = orange100;

  // --- Surface & Canvas Hierarchy ---
  static const Color surfaceCanvas = navy50;
  static const Color surfacePure = white;
  static const Color surfaceMuted = navy100;
  static const Color surfaceSubtle = navy50;
  static const Color surfaceContainer = navy50;
  static const Color surfaceContainerLow = navy50;
  static const Color surfaceContainerHigh = navy100;
  static const Color surfaceContainerHighest = navy100;
  static const Color backgroundLight = navy50;
  static const Color surfaceCard = white;

  // --- Outlines & Dividers ---
  static const Color outlineBorder = border;
  static const Color borderOpaque = border;
  static const Color outlineVariant = border;
  static const Color borderVariant = border;
  static const Color borderNeutral = border;
  static const Color borderLight = border;

  // --- High-Contrast Typography ---
  static const Color textPrimary = navy800;
  static const Color textSecondary = textMutedColor;
  static const Color textMuted = textMutedColor;
  static const Color textWhite = white;

  // --- Re-mapped Interactive & Structural Hues (Strictly Navy / Orange) ---
  static const Color actionBlue = navy800;
  static const Color actionBluePressed = navy900;
  static const Color actionBlueTint = navy100;

  static const Color utilityTeal = navy800;
  static const Color utilityTealPressed = navy900;
  static const Color utilityTealTint = navy100;
  static const Color tealDark = navy800;
  static const Color tealFixed = navy800;
  static const Color tealAccent = orange500;

  // --- Status & Semantic Indicators (2-Color System: No Red / Green / Yellow) ---
  // Synced / Success / In-stock -> Navy soft container with Navy icon & text
  static const Color stockInBg = navy100;
  static const Color stockInText = navy800;
  static const Color stockInBorder = border;
  static const Color syncSuccessBg = navy100;
  static const Color syncSuccessText = navy800;
  static const Color success = navy800;
  static const Color successBg = navy100;
  static const Color successGreen = navy800;

  // Pending / Syncing -> Orange-100 container with Orange-700 text & icon
  static const Color syncPendingBg = orange100;
  static const Color syncPendingText = orange700;

  // Low-Stock / Attention -> Orange-100 container with Orange-700 text & icon
  static const Color stockLowBg = orange100;
  static const Color stockLowText = orange700;
  static const Color warning = orange700;
  static const Color warningBg = orange100;
  static const Color warningAmber = orange700;
  static const Color warningAmberBg = orange100;
  static const Color warningAmberBorder = orange500;

  // Out-of-Stock / Error / Failed / Conflict -> Solid Orange-500 chip with bold Navy-900 text
  static const Color stockOutBg = orange500;
  static const Color stockOutText = navy900;
  static const Color error = orange700;
  static const Color errorBg = orange100;
  static const Color errorLight = orange100;
  static const Color errorRed = orange700;

  // Info -> Navy soft container with Navy-800 text
  static const Color info = navy800;
  static const Color infoBg = navy100;

  // --- Scrim & Shadows ---
  static const Color scrim = Color(0x66061B3F);

  static const BoxShadow shadowLevel1 = BoxShadow(
    color: Color(0x0D0B2A5B),
    blurRadius: 3,
    offset: Offset(0, 1),
  );

  static const BoxShadow shadowLevel2 = BoxShadow(
    color: Color(0x140B2A5B),
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  static const BoxShadow shadowLevel3 = BoxShadow(
    color: Color(0x220B2A5B),
    blurRadius: 18,
    offset: Offset(0, 10),
  );

  // --- Dark Theme Tokens ---
  static const Color darkCanvas = navy900;
  static const Color darkCard = Color(0xFF102138);
  static const Color darkCardElevated = Color(0xFF182D4A);
  static const Color darkBorder = Color(0xFF1E385C);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // --- Theme-Aware Dynamic Resolvers ---
  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkCard : surfacePure;

  static Color canvas(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkCanvas : surfaceCanvas;

  static Color container(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkCardElevated : surfaceCanvas;

  static Color borderOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBorder : outlineBorder;

  static Color text(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextPrimary : textPrimary;

  static Color textSubtle(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextSecondary : textSecondary;

  /// Returns custom 2-color brand tokens from Theme.
  static KeraThemeColors tokensOf(BuildContext context) =>
      Theme.of(context).extension<KeraThemeColors>() ??
      (Theme.of(context).brightness == Brightness.dark
          ? KeraThemeColors.dark
          : KeraThemeColors.light);
}

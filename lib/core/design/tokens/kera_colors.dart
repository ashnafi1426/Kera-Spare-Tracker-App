import 'package:flutter/material.dart';

/// Centralized color palette from Google Stitch Design System
/// for Kera Spare Tracker mobile app.
///
/// Brand specifications:
/// - Brand Navy: #0B2A5B
/// - Accent Orange: #F7941D
class KeraColors {
  KeraColors._();

  // --- Brand & Structural Palette ---
  /// Deep Industrial Navy - Top application bar, master headers, structural anchors.
  static const Color primaryNavy = Color(0xFF0B2A5B);

  /// Deep Navy Light / Secondary container.
  static const Color primaryNavyLight = Color(0xFF163E7D);

  /// Deepest Navy structural anchor.
  static const Color primaryNavyDark = Color(0xFF071B3B);

  /// Brand Accent Orange (CTA buttons, key highlights, active pills)
  static const Color keraOrange = Color(0xFFF7941D);
  static const Color brandOrange = Color(0xFFF7941D);
  static const Color keraOrangeDark = Color(0xFFD67B0E);
  static const Color keraOrangeTint = Color(0x26F7941D); // ~15% alpha

  // Aliases for token consistency across modules
  static const Color backgroundLight = surfaceCanvas;
  static const Color surfaceCard = surfacePure;
  static const Color borderVariant = outlineVariant;
  static const Color borderNeutral = surfaceMuted;
  static const Color borderLight = outlineBorder;
  static const Color successGreen = stockInText;
  static const Color tealDark = utilityTeal;
  static const Color tealFixed = utilityTeal;
  static const Color tealAccent = Color(0xFF6BD8CB);
  static const Color warningAmber = warning;
  static const Color warningAmberBg = warningBg;
  static const Color warningAmberBorder = Color(0xFFFDE68A);
  static const Color errorRed = error;
  static const Color surfaceContainerLow = Color(0xFFF2F4F6);

  /// High-intent interactive elements, primary triggers, focus outlines.
  static const Color actionBlue = Color(0xFF2563EB);

  /// Pressed / focused state for action blue triggers.
  static const Color actionBluePressed = Color(0xFF1D4ED8);

  /// Tint container for blue interactive items (~15% opacity).
  static const Color actionBlueTint = Color(0x262563EB);

  /// POS transaction indicators, cart triggers, sync confirmation.
  static const Color utilityTeal = Color(0xFF0D9488);

  /// Utility teal pressed state.
  static const Color utilityTealPressed = Color(0xFF0F766E);

  /// Utility teal tint container (~15% opacity).
  static const Color utilityTealTint = Color(0x260D9488);

  // --- Surface & Canvas Hierarchy ---
  /// Level 0: Root foundational neutral canvas, low-glare background (Light Mode).
  static const Color surfaceCanvas = Color(0xFFF8FAFC);

  /// Level 1: Cards, list rows, static containers with crisp 1px borders (Light Mode).
  static const Color surfacePure = Color(0xFFFFFFFF);

  /// Level 1.5: Secondary pill surfaces, table headers, inactive rows.
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color surfaceSubtle = surfaceMuted;

  /// Surface container tiers for subtle elevation.
  static const Color surfaceContainer = Color(0xFFECEEF0);
  static const Color surfaceContainerHigh = Color(0xFFE6E8EA);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E5);

  // --- Outlines & Dividers ---
  /// Standard 1px card and container border (Light Mode).
  static const Color outlineBorder = Color(0xFFE2E8F0);

  /// Alias for outlineBorder
  static const Color borderOpaque = outlineBorder;

  /// Subtle divider lines and inactive borders.
  static const Color outlineVariant = Color(0xFFCBD5E1);

  // --- High-Contrast Typography ---
  /// Headers, part titles, primary prices (Light Mode).
  static const Color textPrimary = Color(0xFF0B2A5B);

  /// Part numbers, shelf locations, bilingual subtitles (Light Mode).
  static const Color textSecondary = Color(0xFF5E6D82);

  /// Placeholders, helper hints, disabled labels.
  static const Color textMuted = Color(0xFF94A3B8);

  /// White text on primary buttons and navy app bars.
  static const Color textWhite = Color(0xFFFFFFFF);

  // --- Semantic & Status Colors ---
  /// In-Stock background (በክምችት አለ).
  static const Color stockInBg = Color(0xFFDCFCE7);
  /// In-Stock foreground / text.
  static const Color stockInText = Color(0xFF16A34A);

  /// Low-Stock background (አነስተኛ ክምችት).
  static const Color stockLowBg = Color(0xFFFEF3C7);
  /// Low-Stock foreground / text.
  static const Color stockLowText = Color(0xFFD97706);

  /// Out-of-Stock background (አልቋል).
  static const Color stockOutBg = Color(0xFFFEE2E2);
  /// Out-of-Stock foreground / text.
  static const Color stockOutText = Color(0xFFDC2626);

  /// Offline queue active background (ያልተላከ).
  static const Color syncPendingBg = Color(0xFFFEF3C7);
  /// Offline queue active text / indicator.
  static const Color syncPendingText = Color(0xFFB45309);

  /// Synced online background (የተገናኘ).
  static const Color syncSuccessBg = Color(0xFFDCFCE7);
  /// Synced online text / indicator.
  static const Color syncSuccessText = Color(0xFF15803D);

  /// Error / Alert foreground.
  static const Color error = Color(0xFFDC2626);
  /// Error container background.
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color errorLight = errorBg;

  /// Warning foreground.
  static const Color warning = Color(0xFFD97706);
  /// Warning container background.
  static const Color warningBg = Color(0xFFFEF3C7);

  /// Success foreground.
  static const Color success = Color(0xFF10B981);
  /// Success container background.
  static const Color successBg = Color(0xFFDCFCE7);

  /// Info foreground.
  static const Color info = Color(0xFF2563EB);
  /// Info container background.
  static const Color infoBg = Color(0xFFDBEAFE);

  // --- Scrim & Elevation Shadows ---
  /// Modal backdrop dimming scrim (40% dark slate).
  static const Color scrim = Color(0x660F172A);

  /// Subtle Level 1 card elevation shadow.
  static const BoxShadow shadowLevel1 = BoxShadow(
    color: Color(0x0D0B2A5B), // 5% navy
    blurRadius: 3,
    offset: Offset(0, 1),
  );

  /// Raised Level 2 search bar and FAB elevation shadow.
  static const BoxShadow shadowLevel2 = BoxShadow(
    color: Color(0x140B2A5B), // 8% navy
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  /// Overlay Level 3 modal sheet elevation shadow.
  static const BoxShadow shadowLevel3 = BoxShadow(
    color: Color(0x220B2A5B), // 13% navy
    blurRadius: 18,
    offset: Offset(0, 10),
  );

  // --- Dark Theme Tokens ---
  static const Color darkCanvas = Color(0xFF071322);
  static const Color darkCard = Color(0xFF102138);
  static const Color darkCardElevated = Color(0xFF182D4A);
  static const Color darkBorder = Color(0xFF1E385C);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // --- Theme-Aware Dynamic Color Resolvers ---
  /// Resolves card surface color based on brightness.
  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkCard : surfacePure;

  /// Resolves scaffold canvas background color based on brightness.
  static Color canvas(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkCanvas : surfaceCanvas;

  /// Resolves container/tile surface color based on brightness.
  static Color container(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkCardElevated : surfaceCanvas;

  /// Resolves border outline color based on brightness.
  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBorder : outlineBorder;

  /// Resolves primary text color based on brightness.
  static Color text(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextPrimary : textPrimary;

  /// Resolves secondary subtitle text color based on brightness.
  static Color textSubtle(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextSecondary : textSecondary;
}

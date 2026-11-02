import 'package:flutter/material.dart';

/// Centralized color palette from Google Stitch Design System
/// for Kera Spare Tracker mobile app.
///
/// Tailored for high-density, high-contrast, dust-resilient automotive
/// retail operations in Kera, Addis Ababa.
class KeraColors {
  KeraColors._();

  // --- Brand & Structural Palette ---
  /// Deep Industrial Navy - Top application bar, master headers, structural anchors.
  static const Color primaryNavy = Color(0xFF172B4D);

  /// Deep Navy Light / Secondary container.
  static const Color primaryNavyLight = Color(0xFF1E3A8A);

  /// Deepest Navy structural anchor.
  static const Color primaryNavyDark = Color(0xFF001637);

  // Aliases for token consistency across modules
  static const Color backgroundLight = surfaceCanvas;
  static const Color surfaceCard = surfacePure;
  static const Color borderVariant = outlineVariant;
  static const Color borderNeutral = surfaceMuted;
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
  /// Level 0: Root foundational neutral canvas, low-glare background.
  static const Color surfaceCanvas = Color(0xFFF8FAFC);

  /// Level 1: Cards, list rows, static containers with crisp 1px borders.
  static const Color surfacePure = Color(0xFFFFFFFF);

  /// Level 1.5: Secondary pill surfaces, table headers, inactive rows.
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color surfaceSubtle = surfaceMuted;

  /// Surface container tiers for subtle elevation.
  static const Color surfaceContainer = Color(0xFFECEEF0);
  static const Color surfaceContainerHigh = Color(0xFFE6E8EA);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E5);

  // --- Outlines & Dividers ---
  /// Standard 1px card and container border.
  static const Color outlineBorder = Color(0xFFE2E8F0);

  /// Alias for outlineBorder
  static const Color borderOpaque = outlineBorder;

  /// Subtle divider lines and inactive borders.
  static const Color outlineVariant = Color(0xFFCBD5E1);

  // --- High-Contrast Typography ---
  /// Headers, part titles, primary prices.
  static const Color textPrimary = Color(0xFF191C1E);

  /// Part numbers, shelf locations, bilingual subtitles.
  static const Color textSecondary = Color(0xFF64748B);

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
  static const Color success = Color(0xFF16A34A);
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
    color: Color(0x0D172B4D), // 5% navy
    blurRadius: 2,
    offset: Offset(0, 1),
  );

  /// Raised Level 2 search bar and FAB elevation shadow.
  static const BoxShadow shadowLevel2 = BoxShadow(
    color: Color(0x14172B4D), // 8% navy
    blurRadius: 6,
    offset: Offset(0, 4),
  );

  /// Overlay Level 3 modal sheet elevation shadow.
  static const BoxShadow shadowLevel3 = BoxShadow(
    color: Color(0x1F172B4D), // 12% navy
    blurRadius: 15,
    offset: Offset(0, 10),
  );
}


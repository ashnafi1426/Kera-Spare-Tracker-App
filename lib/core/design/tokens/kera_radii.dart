import 'package:flutter/material.dart';

/// Border radius standards from Google Stitch Design System.
///
/// Hierarchy:
/// - 6px: Status pills, inline tags, small chips.
/// - 10px: Part cards, metric statistic tiles, text fields, buttons.
/// - 16px: Modal bottom sheets, action drawers, floating cards.
/// - 9999px: Fully rounded pills, online/offline status chips.
class KeraRadii {
  KeraRadii._();

  /// 4.0 px - Extra small chip/tag rounding.
  static const double xs = 4.0;

  /// 6.0 px - Status pills, micro chips, quantity counters.
  static const double micro = 6.0;
  static const double sm = 6.0;

  /// 10.0 px - Default for part cards, input fields, buttons.
  static const double md = 10.0;
  static const double defaultRadius = 10.0;

  /// 16.0 px - Bottom sheet top corners, dialog cards.
  static const double lg = 16.0;

  /// 20.0 px - Extra large container rounding.
  static const double xl = 20.0;

  /// 24.0 px - Hero cards and floating banners.
  static const double xxl = 24.0;

  /// 9999.0 px - Pill badges, sync indicator chips.
  static const double full = 9999.0;

  // --- Ready-to-use BorderRadius objects ---
  static const BorderRadius borderMicro = BorderRadius.all(Radius.circular(micro));
  static const BorderRadius borderCard = BorderRadius.all(Radius.circular(defaultRadius));
  static const BorderRadius borderButton = BorderRadius.all(Radius.circular(defaultRadius));
  static const BorderRadius borderInput = BorderRadius.all(Radius.circular(defaultRadius));
  static const BorderRadius borderSheet = BorderRadius.vertical(top: Radius.circular(lg));
  static const BorderRadius borderPill = BorderRadius.all(Radius.circular(full));

  // --- RoundedRectangleBorder objects ---
  static const RoundedRectangleBorder shapeCard = RoundedRectangleBorder(
    borderRadius: borderCard,
  );

  static const RoundedRectangleBorder shapeButton = RoundedRectangleBorder(
    borderRadius: borderButton,
  );

  static const RoundedRectangleBorder shapePill = RoundedRectangleBorder(
    borderRadius: borderPill,
  );
}


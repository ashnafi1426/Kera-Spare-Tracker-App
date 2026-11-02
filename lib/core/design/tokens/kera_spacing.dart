import 'package:flutter/material.dart';

/// Spacing tokens and touch target standards adhering to Google Stitch
/// and Android accessibility guidelines.
class KeraSpacing {
  KeraSpacing._();

  /// 4.0 px - Micro gaps, tag margins.
  static const double xs = 4.0;

  /// 8.0 px - List row separation, icon-to-text spacing.
  static const double sm = 8.0;

  /// 12.0 px - Standard card inner padding, compact gaps.
  static const double md = 12.0;

  /// 16.0 px - Screen gutters, primary container margins.
  static const double lg = 16.0;

  /// 24.0 px - Section separation, dialog padding.
  static const double xl = 24.0;

  /// 32.0 px - Hero spacing, empty-state vertical spacing.
  static const double xxl = 32.0;

  /// Standard screen edge gutter (16.0 px).
  static const double gutter = 16.0;

  /// Standard screen margin (16.0 px).
  static const double margin = 16.0;

  /// Minimum accessible touch target (48.0 px) for counter speed.
  static const double minTouchTarget = 48.0;

  /// BoxConstraints enforcing minimum touch target.
  static const BoxConstraints touchTargetConstraints = BoxConstraints(
    minWidth: minTouchTarget,
    minHeight: minTouchTarget,
  );

  // --- Common Insets ---
  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(16, 8, 16, 16);
  static const EdgeInsets cardPadding = EdgeInsets.all(12.0);
  static const EdgeInsets sheetPadding = EdgeInsets.fromLTRB(16, 8, 16, 24);
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 12);
  static const EdgeInsets badgePadding = EdgeInsets.symmetric(horizontal: 7, vertical: 3);
}


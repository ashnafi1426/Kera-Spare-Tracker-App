import 'package:flutter/material.dart';

/// Spacing and sizing tokens for Admin portal.
class AdminSpacing {
  AdminSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;

  // Corner radiuses
  static const double radiusCard = 12.0;
  static const double radiusChip = 8.0;
  static const double radiusField = 8.0;
  static const double radiusButton = 10.0;
  static const double radiusAvatar = 20.0;

  // Minimum touch target
  static const double minTouchTarget = 48.0;
  static const BoxConstraints touchTargetConstraints = BoxConstraints(
    minWidth: minTouchTarget,
    minHeight: minTouchTarget,
  );

  // Content max width for wide screen (tablets / desktop)
  static const double maxContentWidth = 1100.0;

  // Breakpoints
  static const double tabletBreakpoint = 840.0;
}

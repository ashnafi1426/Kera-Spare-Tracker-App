import 'package:flutter/material.dart';

/// Custom ThemeExtension implementing Kera Spare Tracker's modern executive brand palette.
///
/// Design specifications:
/// - Brand Primary: Deep Navy Blue (#0B2A5B, #061B3F)
/// - Brand Accent: Professional Orange (#F7941D, #E07F00)
/// - Canvas: Clean light grey / off-white (#F8FAFC)
/// - Cards: White (#FFFFFF) with refined subtle elevation
/// - Success / Synced / In-Stock: Professional Green (#10B981, #047857)
/// - Warning / Pending / Low-Stock: Professional Amber (#F59E0B, #B45309)
/// - Alert / Error / Depleted: Professional Red (#EF4444, #B91C1C)
class KeraThemeColors extends ThemeExtension<KeraThemeColors> {
  // Navy Palette
  final Color navy900;
  final Color navy800;
  final Color navy600;
  final Color navy100;
  final Color navy50;

  // Orange Palette
  final Color orange500;
  final Color orange600;
  final Color orange700;
  final Color orange100;

  // Neutrals
  final Color surfaceWhite;
  final Color pageBackground;
  final Color cardBackground;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color disabled;

  // Semantic Status Tokens
  final Color statusSyncedBg;
  final Color statusSyncedText;
  final Color statusSyncedBorder;

  final Color statusPendingBg;
  final Color statusPendingText;
  final Color statusPendingBorder;

  final Color statusLowStockBg;
  final Color statusLowStockText;
  final Color statusLowStockBorder;

  final Color statusAlertBg;
  final Color statusAlertText;
  final Color statusAlertBorder;

  final Color statusOfflineBg;
  final Color statusOfflineText;
  final Color statusOfflineBorder;

  const KeraThemeColors({
    required this.navy900,
    required this.navy800,
    required this.navy600,
    required this.navy100,
    required this.navy50,
    required this.orange500,
    required this.orange600,
    required this.orange700,
    required this.orange100,
    required this.surfaceWhite,
    required this.pageBackground,
    required this.cardBackground,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.disabled,
    required this.statusSyncedBg,
    required this.statusSyncedText,
    required this.statusSyncedBorder,
    required this.statusPendingBg,
    required this.statusPendingText,
    required this.statusPendingBorder,
    required this.statusLowStockBg,
    required this.statusLowStockText,
    required this.statusLowStockBorder,
    required this.statusAlertBg,
    required this.statusAlertText,
    required this.statusAlertBorder,
    required this.statusOfflineBg,
    required this.statusOfflineText,
    required this.statusOfflineBorder,
  });

  /// Light theme tokens.
  static const KeraThemeColors light = KeraThemeColors(
    navy900: Color(0xFF061B3F),
    navy800: Color(0xFF0B2A5B),
    navy600: Color(0xFF1D4A8A),
    navy100: Color(0xFFE8EEF8),
    navy50: Color(0xFFF8FAFC),
    orange500: Color(0xFFF7941D),
    orange600: Color(0xFFE07F00),
    orange700: Color(0xFFB45309),
    orange100: Color(0xFFFFF1DC),
    surfaceWhite: Color(0xFFFFFFFF),
    pageBackground: Color(0xFFF8FAFC),
    cardBackground: Color(0xFFFFFFFF),
    border: Color(0xFFE2E8F0),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    textMuted: Color(0xFF94A3B8),
    disabled: Color(0xFF94A3B8),
    // Synced: Professional Green
    statusSyncedBg: Color(0xFFECFDF5),
    statusSyncedText: Color(0xFF047857),
    statusSyncedBorder: Color(0xFFA7F3D0),
    // Pending: Professional Amber
    statusPendingBg: Color(0xFFFFFBEB),
    statusPendingText: Color(0xFFB45309),
    statusPendingBorder: Color(0xFFFDE68A),
    // Low Stock: Professional Amber
    statusLowStockBg: Color(0xFFFFFBEB),
    statusLowStockText: Color(0xFFB45309),
    statusLowStockBorder: Color(0xFFFDE68A),
    // Out of Stock / Alert: Professional Red
    statusAlertBg: Color(0xFFFEF2F2),
    statusAlertText: Color(0xFFB91C1C),
    statusAlertBorder: Color(0xFFFECACA),
    // Offline: Muted Navy
    statusOfflineBg: Color(0xFFF1F5F9),
    statusOfflineText: Color(0xFF475569),
    statusOfflineBorder: Color(0xFFCBD5E1),
  );

  /// Dark theme tokens.
  static const KeraThemeColors dark = KeraThemeColors(
    navy900: Color(0xFF091424),
    navy800: Color(0xFF0B2A5B),
    navy600: Color(0xFF1D4A8A),
    navy100: Color(0xFF1E385C),
    navy50: Color(0xFF0D1B2E),
    orange500: Color(0xFFF7941D),
    orange600: Color(0xFFE07F00),
    orange700: Color(0xFFB45309),
    orange100: Color(0xFF332314),
    surfaceWhite: Color(0xFF102138),
    pageBackground: Color(0xFF091424),
    cardBackground: Color(0xFF102138),
    border: Color(0xFF1E385C),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    disabled: Color(0xFF475569),
    statusSyncedBg: Color(0xFF064E3B),
    statusSyncedText: Color(0xFF6EE7B7),
    statusSyncedBorder: Color(0xFF059669),
    statusPendingBg: Color(0xFF451A03),
    statusPendingText: Color(0xFFFCD34D),
    statusPendingBorder: Color(0xFFD97706),
    statusLowStockBg: Color(0xFF451A03),
    statusLowStockText: Color(0xFFFCD34D),
    statusLowStockBorder: Color(0xFFD97706),
    statusAlertBg: Color(0xFF450A0A),
    statusAlertText: Color(0xFFFCA5A5),
    statusAlertBorder: Color(0xFFDC2626),
    statusOfflineBg: Color(0xFF1E293B),
    statusOfflineText: Color(0xFF94A3B8),
    statusOfflineBorder: Color(0xFF334155),
  );

  @override
  ThemeExtension<KeraThemeColors> copyWith({
    Color? navy900,
    Color? navy800,
    Color? navy600,
    Color? navy100,
    Color? navy50,
    Color? orange500,
    Color? orange600,
    Color? orange700,
    Color? orange100,
    Color? surfaceWhite,
    Color? pageBackground,
    Color? cardBackground,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? disabled,
    Color? statusSyncedBg,
    Color? statusSyncedText,
    Color? statusSyncedBorder,
    Color? statusPendingBg,
    Color? statusPendingText,
    Color? statusPendingBorder,
    Color? statusLowStockBg,
    Color? statusLowStockText,
    Color? statusLowStockBorder,
    Color? statusAlertBg,
    Color? statusAlertText,
    Color? statusAlertBorder,
    Color? statusOfflineBg,
    Color? statusOfflineText,
    Color? statusOfflineBorder,
  }) {
    return KeraThemeColors(
      navy900: navy900 ?? this.navy900,
      navy800: navy800 ?? this.navy800,
      navy600: navy600 ?? this.navy600,
      navy100: navy100 ?? this.navy100,
      navy50: navy50 ?? this.navy50,
      orange500: orange500 ?? this.orange500,
      orange600: orange600 ?? this.orange600,
      orange700: orange700 ?? this.orange700,
      orange100: orange100 ?? this.orange100,
      surfaceWhite: surfaceWhite ?? this.surfaceWhite,
      pageBackground: pageBackground ?? this.pageBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      disabled: disabled ?? this.disabled,
      statusSyncedBg: statusSyncedBg ?? this.statusSyncedBg,
      statusSyncedText: statusSyncedText ?? this.statusSyncedText,
      statusSyncedBorder: statusSyncedBorder ?? this.statusSyncedBorder,
      statusPendingBg: statusPendingBg ?? this.statusPendingBg,
      statusPendingText: statusPendingText ?? this.statusPendingText,
      statusPendingBorder: statusPendingBorder ?? this.statusPendingBorder,
      statusLowStockBg: statusLowStockBg ?? this.statusLowStockBg,
      statusLowStockText: statusLowStockText ?? this.statusLowStockText,
      statusLowStockBorder: statusLowStockBorder ?? this.statusLowStockBorder,
      statusAlertBg: statusAlertBg ?? this.statusAlertBg,
      statusAlertText: statusAlertText ?? this.statusAlertText,
      statusAlertBorder: statusAlertBorder ?? this.statusAlertBorder,
      statusOfflineBg: statusOfflineBg ?? this.statusOfflineBg,
      statusOfflineText: statusOfflineText ?? this.statusOfflineText,
      statusOfflineBorder: statusOfflineBorder ?? this.statusOfflineBorder,
    );
  }

  @override
  ThemeExtension<KeraThemeColors> lerp(
    covariant ThemeExtension<KeraThemeColors>? other,
    double t,
  ) {
    if (other is! KeraThemeColors) return this;
    return KeraThemeColors(
      navy900: Color.lerp(navy900, other.navy900, t)!,
      navy800: Color.lerp(navy800, other.navy800, t)!,
      navy600: Color.lerp(navy600, other.navy600, t)!,
      navy100: Color.lerp(navy100, other.navy100, t)!,
      navy50: Color.lerp(navy50, other.navy50, t)!,
      orange500: Color.lerp(orange500, other.orange500, t)!,
      orange600: Color.lerp(orange600, other.orange600, t)!,
      orange700: Color.lerp(orange700, other.orange700, t)!,
      orange100: Color.lerp(orange100, other.orange100, t)!,
      surfaceWhite: Color.lerp(surfaceWhite, other.surfaceWhite, t)!,
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      statusSyncedBg: Color.lerp(statusSyncedBg, other.statusSyncedBg, t)!,
      statusSyncedText: Color.lerp(statusSyncedText, other.statusSyncedText, t)!,
      statusSyncedBorder: Color.lerp(statusSyncedBorder, other.statusSyncedBorder, t)!,
      statusPendingBg: Color.lerp(statusPendingBg, other.statusPendingBg, t)!,
      statusPendingText: Color.lerp(statusPendingText, other.statusPendingText, t)!,
      statusPendingBorder: Color.lerp(statusPendingBorder, other.statusPendingBorder, t)!,
      statusLowStockBg: Color.lerp(statusLowStockBg, other.statusLowStockBg, t)!,
      statusLowStockText: Color.lerp(statusLowStockText, other.statusLowStockText, t)!,
      statusLowStockBorder: Color.lerp(statusLowStockBorder, other.statusLowStockBorder, t)!,
      statusAlertBg: Color.lerp(statusAlertBg, other.statusAlertBg, t)!,
      statusAlertText: Color.lerp(statusAlertText, other.statusAlertText, t)!,
      statusAlertBorder: Color.lerp(statusAlertBorder, other.statusAlertBorder, t)!,
      statusOfflineBg: Color.lerp(statusOfflineBg, other.statusOfflineBg, t)!,
      statusOfflineText: Color.lerp(statusOfflineText, other.statusOfflineText, t)!,
      statusOfflineBorder: Color.lerp(statusOfflineBorder, other.statusOfflineBorder, t)!,
    );
  }
}

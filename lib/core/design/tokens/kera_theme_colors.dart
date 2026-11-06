import 'package:flutter/material.dart';

/// Custom ThemeExtension implementing Kera Spare Tracker's strict 2-color brand palette.
///
/// Brand specifications (strictly sampled from logo):
/// - Brand color 1 (NAVY):
///   - navy-900: #061B3F (Dark canvas & high-contrast deep text)
///   - navy-800: #0B2A5B (MAIN navy: structure, app bar, active tab, icons, series 1)
///   - navy-600: #1D4A8A (Mid navy: secondary outlines, focused borders)
///   - navy-100: #E6ECF7 (Soft navy tint: in-stock / synced status chips, active pill fill)
///   - navy-50:  #F3F5FA (Light neutral canvas)
/// - Brand color 2 (ORANGE):
///   - orange-500: #F7941D (MAIN orange: single primary CTA, highlights, attention, series 2)
///   - orange-600: #E07F00 (Orange pressed / hover state)
///   - orange-700: #B35F00 (High-contrast orange text on light surfaces - WCAG AA)
///   - orange-100: #FFF1DC (Soft orange tint: pending / low stock status chips)
/// - Neutrals:
///   - white:     #FFFFFF (Cards, plates, on-navy text)
///   - border:    #D3DAE8 (Crisp 1px card and input outlines)
///   - textMuted: #4A5B78 (Subtitles, part numbers, bilingual captions)
///   - disabled:  #9AA7BD (Disabled buttons, inactive elements)
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

  // Semantic Status Tokens (Strictly 2-color: No red/green/yellow)
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
    navy100: Color(0xFFE6ECF7),
    navy50: Color(0xFFF3F5FA),
    orange500: Color(0xFFF7941D),
    orange600: Color(0xFFE07F00),
    orange700: Color(0xFF9A5000),
    orange100: Color(0xFFFFF1DC),
    surfaceWhite: Color(0xFFFFFFFF),
    pageBackground: Color(0xFFF3F5FA),
    cardBackground: Color(0xFFFFFFFF),
    border: Color(0xFFD3DAE8),
    textPrimary: Color(0xFF0B2A5B),
    textSecondary: Color(0xFF4A5B78),
    textMuted: Color(0xFF4A5B78),
    disabled: Color(0xFF9AA7BD),
    statusSyncedBg: Color(0xFFE6ECF7),
    statusSyncedText: Color(0xFF0B2A5B),
    statusSyncedBorder: Color(0xFFD3DAE8),
    statusPendingBg: Color(0xFFFFF1DC),
    statusPendingText: Color(0xFF9A5000),
    statusPendingBorder: Color(0xFFF7941D),
    statusLowStockBg: Color(0xFFFFF1DC),
    statusLowStockText: Color(0xFF9A5000),
    statusLowStockBorder: Color(0xFFE07F00),
    statusAlertBg: Color(0xFFF7941D),
    statusAlertText: Color(0xFF061B3F),
    statusAlertBorder: Color(0xFF9A5000),
    statusOfflineBg: Color(0xFFFFFFFF),
    statusOfflineText: Color(0xFF0B2A5B),
    statusOfflineBorder: Color(0xFF0B2A5B),
  );

  /// Dark theme tokens.
  static const KeraThemeColors dark = KeraThemeColors(
    navy900: Color(0xFF061B3F),
    navy800: Color(0xFF0B2A5B),
    navy600: Color(0xFF1D4A8A),
    navy100: Color(0xFFE6ECF7),
    navy50: Color(0xFFF3F5FA),
    orange500: Color(0xFFF7941D),
    orange600: Color(0xFFE07F00),
    orange700: Color(0xFF9A5000),
    orange100: Color(0xFFFFF1DC),
    surfaceWhite: Color(0xFF102138),
    pageBackground: Color(0xFF061B3F),
    cardBackground: Color(0xFF102138),
    border: Color(0xFF1E385C),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF94A3B8),
    disabled: Color(0xFF64748B),
    statusSyncedBg: Color(0xFF0B2A5B),
    statusSyncedText: Color(0xFFF1F5F9),
    statusSyncedBorder: Color(0xFF1D4A8A),
    statusPendingBg: Color(0x33F7941D),
    statusPendingText: Color(0xFFF7941D),
    statusPendingBorder: Color(0xFFF7941D),
    statusLowStockBg: Color(0x33F7941D),
    statusLowStockText: Color(0xFFF7941D),
    statusLowStockBorder: Color(0xFFE07F00),
    statusAlertBg: Color(0xFFF7941D),
    statusAlertText: Color(0xFF061B3F),
    statusAlertBorder: Color(0xFF9A5000),
    statusOfflineBg: Color(0xFF061B3F),
    statusOfflineText: Color(0xFFF1F5F9),
    statusOfflineBorder: Color(0xFF1D4A8A),
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


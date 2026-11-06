import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../design/tokens/kera_colors.dart';
import '../design/tokens/kera_theme_colors.dart';

/// Convenient BuildContext extensions for localization and theme access.
extension LocalizationX on BuildContext {
  /// Convenient accessor for localized strings.
  AppLocalizations get l10n {
    final localizations = AppLocalizations.of(this);
    assert(localizations != null, 'No AppLocalizations found in context');
    return localizations!;
  }

  /// Returns true if active locale is Amharic.
  bool get isAmharic => Localizations.localeOf(this).languageCode == 'am';

  /// Resolves string based on active locale (Amharic or English).
  String tr(String amharic, String english) => isAmharic ? amharic : english;

  /// Convenient accessor for current ThemeData.
  ThemeData get theme => Theme.of(this);

  /// Convenient accessor for current ColorScheme.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Returns true if dark mode is active.
  bool get isDark => theme.brightness == Brightness.dark;

  /// Strict 2-color brand theme tokens (Navy, Orange, Neutrals).
  KeraThemeColors get keraTheme =>
      theme.extension<KeraThemeColors>() ??
      (isDark ? KeraThemeColors.dark : KeraThemeColors.light);

  /// Surface color for cards and elevated panels.
  Color get surfaceColor => isDark ? KeraColors.darkCard : KeraColors.surfacePure;

  /// Card background color (theme aware).
  Color get cardBg => isDark ? KeraColors.darkCard : Colors.white;

  /// Scaffold and general canvas background color (theme aware).
  Color get scaffoldBg => theme.scaffoldBackgroundColor;

  /// Sub-container / tile canvas background color (theme aware).
  Color get cardCanvasColor => isDark ? KeraColors.darkCardElevated : KeraColors.surfaceCanvas;

  /// Outline / border color (theme aware).
  Color get borderColor => isDark ? KeraColors.darkBorder : KeraColors.outlineBorder;

  /// Primary high-contrast text color (theme aware).
  Color get textPrimaryColor => isDark ? KeraColors.darkTextPrimary : KeraColors.textPrimary;

  /// Secondary subtitle text color (theme aware).
  Color get textSecondaryColor => isDark ? KeraColors.darkTextSecondary : KeraColors.textSecondary;

  /// Muted / placeholder text color (theme aware).
  Color get textMutedColor => isDark ? KeraColors.darkTextMuted : KeraColors.textMuted;

  /// Convenient accessor for MediaQuery size.
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Displays a brief snackbar message.
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
      ),
    );
  }
}

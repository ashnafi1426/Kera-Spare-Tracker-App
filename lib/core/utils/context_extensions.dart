import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

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

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

  /// Convenient accessor for current ThemeData.
  ThemeData get theme => Theme.of(this);

  /// Convenient accessor for current ColorScheme.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Convenient accessor for MediaQuery size.
  Size get screenSize => MediaQuery.sizeOf(this);
}

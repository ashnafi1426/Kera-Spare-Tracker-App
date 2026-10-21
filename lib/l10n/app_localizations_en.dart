// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Kera Spare Tracker';

  @override
  String get appSubtitle => 'Spare Parts & Sales Management';

  @override
  String get splashLoading => 'Loading your inventory...';

  @override
  String get offlineBadge => 'Offline-First';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get search => 'Search';

  @override
  String get retry => 'Retry';

  @override
  String get filter => 'Filter';

  @override
  String get add => 'Add New';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get confirm => 'Confirm';

  @override
  String get refresh => 'Refresh';

  @override
  String get done => 'Done';

  @override
  String get navParts => 'Parts';

  @override
  String get navSales => 'Sales';

  @override
  String get navStock => 'Stock';

  @override
  String get navReports => 'Reports';

  @override
  String get navSettings => 'Settings';

  @override
  String get navAdmin => 'Admin';

  @override
  String get phoneRequired => 'Phone number is required';

  @override
  String get phoneInvalid =>
      'Enter a valid Ethiopian phone number (e.g. 09... or 07...)';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get quantityRequired => 'Quantity is required';

  @override
  String get quantityPositive => 'Quantity must be greater than 0';

  @override
  String get priceRequired => 'Price is required';

  @override
  String get priceInvalid => 'Price must be 0 or greater';

  @override
  String get noDataTitle => 'No Data Found';

  @override
  String get noDataDesc => 'There is no recorded data yet';

  @override
  String get noPartsFound => 'No Parts Found';

  @override
  String get noPartsDesc => 'Tap \'+\' to add your first spare part';

  @override
  String get noSalesFound => 'No Sales Found';

  @override
  String get noSalesDesc => 'No sales transactions have been recorded yet';

  @override
  String get noStockMovements => 'No Stock Movements Found';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get amharic => 'አማርኛ (Amharic)';

  @override
  String get english => 'English';

  @override
  String get languageChangedNotice => 'Language switched to English';
}

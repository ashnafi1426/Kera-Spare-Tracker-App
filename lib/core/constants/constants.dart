/// Application-wide constants for Kera Spare Tracker.
class AppConstants {
  AppConstants._();

  /// Application name.
  static const String appName = 'Kera Spare Tracker';

  /// Supported language codes.
  static const String defaultLocaleCode = 'am'; // Amharic by default
  static const String englishLocaleCode = 'en';

  /// Default configurable brands for spare parts.
  static const List<String> defaultBrands = [
    'CAT',
    'Doosan',
    'Develon',
    'CTP',
    'IPD',
    'Hitachi',
    'SANY',
  ];

  /// Default shelf options for storage location.
  static const List<String> defaultShelves = [
    'Shelf 1',
    'Shelf 2',
    'Shelf 3',
    'Shelf 4',
    'Shelf 5',
    'Shelf 6',
  ];

  /// Common category suggestions for heavy machinery and automotive parts.
  static const List<String> defaultCategories = [
    'Engine',
    'Hydraulic',
    'Transmission',
    'Electrical',
    'Undercarriage',
    'Filters',
    'Seals & Gaskets',
    'Hardware & Fasteners',
    'Body & Cabin',
  ];

  /// Standard units of measurement.
  static const List<String> defaultUnits = [
    'Pcs',
    'Set',
    'Box',
    'Pair',
    'Meter',
    'Kg',
    'Liter',
  ];

  /// Local storage and secure storage keys.
  static const String secureStorageTokenKey = 'kera_auth_token';
  static const String secureStorageOwnerIdKey = 'kera_owner_id';
  static const String localePreferenceKey = 'kera_user_locale';

  /// Touch targets for low-end Android mobile accessibility.
  static const double minTouchTargetSize = 48.0;
  static const double standardButtonHeight = 52.0;
}

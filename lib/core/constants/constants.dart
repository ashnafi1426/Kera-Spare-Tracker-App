/// Application-wide constants for Kera Spare Tracker.
class AppConstants {

  AppConstants._();

  /// Application name.
  static const String appName = 'Kera Spare Tracker';

  /// Supported language codes.
  static const String defaultLocaleCode = 'am'; // Amharic by default
  static const String englishLocaleCode = 'en';

  /// Application version
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  /// Support contacts (fallbacks)
  static const String fallbackSupportPhone = '+251911000000';
  static const String fallbackSupportTelegram = '@KeraSpareSupport';

  /// Flag to enable sample test parts generator (controllable via --dart-define=ENABLE_DEMO_GENERATOR)
  static const bool enableDemoGenerator = bool.fromEnvironment(
    'ENABLE_DEMO_GENERATOR',
    defaultValue: true,
  );

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
  static const String secureStorageRefreshTokenKey = 'kera_refresh_token';
  static const String secureStorageOwnerIdKey = 'kera_owner_id';
  static const String localePreferenceKey = 'kera_user_locale';
  static const String themeModePreferenceKey = 'kera_user_theme_mode';

  /// Primary production backend deployed on Render cloud - strictly used across the entire app
  static const String defaultProductionBaseUrl =
      'https://kera-spare-tracker-api.onrender.com/api/v1';

  /// Sets the dynamic working API base URL (Locked to Render cloud).
  static void setApiBaseUrl(String url) {
    // Locked to Render cloud
  }

  /// Single production endpoint candidate
  static List<String> get candidateAndroidBaseUrls => const [
        defaultProductionBaseUrl,
      ];

  /// API Configuration strictly locked to live Render Cloud backend
  static String get apiBaseUrl => defaultProductionBaseUrl;


  /// Touch targets for low-end Android mobile accessibility.
  static const double minTouchTargetSize = 48.0;
  static const double standardButtonHeight = 52.0;
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('en'),
  ];

  /// Application display name
  ///
  /// In am, this message translates to:
  /// **'የቄራ መለዋወጫ መከታተያ'**
  String get appName;

  /// Application tagline/subtitle
  ///
  /// In am, this message translates to:
  /// **'የመለዋወጫ ዕቃዎች እና የሽያጭ አስተዳደር'**
  String get appSubtitle;

  /// Splash loading message
  ///
  /// In am, this message translates to:
  /// **'ዕቃዎችን በመጫን ላይ...'**
  String get splashLoading;

  /// Offline-first capability badge
  ///
  /// In am, this message translates to:
  /// **'ኦፍላይን ይሰራል'**
  String get offlineBadge;

  /// Save action button
  ///
  /// In am, this message translates to:
  /// **'አስቀምጥ'**
  String get save;

  /// Cancel action button
  ///
  /// In am, this message translates to:
  /// **'ሰርዝ'**
  String get cancel;

  /// Delete action button
  ///
  /// In am, this message translates to:
  /// **'አጥፋ'**
  String get delete;

  /// Edit action button
  ///
  /// In am, this message translates to:
  /// **'አስተካክል'**
  String get edit;

  /// Search action button or placeholder
  ///
  /// In am, this message translates to:
  /// **'ፈልግ'**
  String get search;

  /// Retry action button
  ///
  /// In am, this message translates to:
  /// **'እንደገና ሞክር'**
  String get retry;

  /// Filter action button
  ///
  /// In am, this message translates to:
  /// **'አጣራ'**
  String get filter;

  /// Add new item action button
  ///
  /// In am, this message translates to:
  /// **'አዲስ ጨምር'**
  String get add;

  /// Back navigation button
  ///
  /// In am, this message translates to:
  /// **'ተመለስ'**
  String get back;

  /// Close modal or screen button
  ///
  /// In am, this message translates to:
  /// **'ዝጋ'**
  String get close;

  /// Confirm action button
  ///
  /// In am, this message translates to:
  /// **'አረጋግጥ'**
  String get confirm;

  /// Refresh data action button
  ///
  /// In am, this message translates to:
  /// **'አድስ'**
  String get refresh;

  /// Done action button
  ///
  /// In am, this message translates to:
  /// **'ተጠናቋል'**
  String get done;

  /// Navigation label for parts inventory
  ///
  /// In am, this message translates to:
  /// **'መለዋወጫዎች'**
  String get navParts;

  /// Navigation label for sales
  ///
  /// In am, this message translates to:
  /// **'ሽያጮች'**
  String get navSales;

  /// Navigation label for stock
  ///
  /// In am, this message translates to:
  /// **'ስቶክ'**
  String get navStock;

  /// Navigation label for reports
  ///
  /// In am, this message translates to:
  /// **'ሪፖርቶች'**
  String get navReports;

  /// Navigation label for settings
  ///
  /// In am, this message translates to:
  /// **'ቅንብሮች'**
  String get navSettings;

  /// Navigation label for admin
  ///
  /// In am, this message translates to:
  /// **'አድሚን'**
  String get navAdmin;

  /// Validation error when phone is empty
  ///
  /// In am, this message translates to:
  /// **'ስልክ ቁጥር ማስገባት ግዴታ ነው'**
  String get phoneRequired;

  /// Validation error for invalid Ethiopian phone number
  ///
  /// In am, this message translates to:
  /// **'ትክክለኛ የኢትዮጵያ ስልክ ቁጥር ያስገቡ (ለምሳሌ 09... ወይም 07...)'**
  String get phoneInvalid;

  /// Validation error when password is empty
  ///
  /// In am, this message translates to:
  /// **'የይለፍ ቃል ማስገባት ግዴታ ነው'**
  String get passwordRequired;

  /// Validation error when password is under 6 characters
  ///
  /// In am, this message translates to:
  /// **'የይለፍ ቃል ቢያንስ 6 ፊደላት/ቁጥሮች መሆን አለበት'**
  String get passwordTooShort;

  /// Generic required field validation error
  ///
  /// In am, this message translates to:
  /// **'ይህ ቦታ መሞላት አለበት'**
  String get fieldRequired;

  /// Validation error when quantity is empty
  ///
  /// In am, this message translates to:
  /// **'ብዛት ማስገባት ግዴታ ነው'**
  String get quantityRequired;

  /// Validation error when quantity is zero or negative
  ///
  /// In am, this message translates to:
  /// **'ብዛት ከ 0 በላይ መሆን አለበት'**
  String get quantityPositive;

  /// Validation error when price is empty
  ///
  /// In am, this message translates to:
  /// **'ዋጋ ማስገባት ግዴታ ነው'**
  String get priceRequired;

  /// Validation error when price is negative
  ///
  /// In am, this message translates to:
  /// **'ዋጋ 0 ወይም ከዚያ በላይ መሆን አለበት'**
  String get priceInvalid;

  /// Empty state title when list is empty
  ///
  /// In am, this message translates to:
  /// **'ምንም መረጃ አልተገኘም'**
  String get noDataTitle;

  /// Empty state description
  ///
  /// In am, this message translates to:
  /// **'እስካሁን የተመዘገበ መረጃ የለም'**
  String get noDataDesc;

  /// Empty state title for parts catalog
  ///
  /// In am, this message translates to:
  /// **'ምንም የተመዘገበ መለዋወጫ የለም'**
  String get noPartsFound;

  /// Empty state instruction for adding first part
  ///
  /// In am, this message translates to:
  /// **'አዲስ መለዋወጫ ዕቃ ለማስገባት \'+\' ይጫኑ'**
  String get noPartsDesc;

  /// Empty state title for sales list
  ///
  /// In am, this message translates to:
  /// **'ምንም የሽያጭ መረጃ የለም'**
  String get noSalesFound;

  /// Empty state description for sales
  ///
  /// In am, this message translates to:
  /// **'እስካሁን የተከናወነ ሽያጭ አልተመዘገበም'**
  String get noSalesDesc;

  /// Empty state title for stock ledger
  ///
  /// In am, this message translates to:
  /// **'ምንም የስቶክ እንቅስቃሴ አልተገኘም'**
  String get noStockMovements;

  /// Language label
  ///
  /// In am, this message translates to:
  /// **'ቋንቋ'**
  String get language;

  /// Prompt to select application language
  ///
  /// In am, this message translates to:
  /// **'ቋንቋ ይምረጡ'**
  String get selectLanguage;

  /// Amharic language name
  ///
  /// In am, this message translates to:
  /// **'አማርኛ'**
  String get amharic;

  /// English language name
  ///
  /// In am, this message translates to:
  /// **'English'**
  String get english;

  /// Notice shown when language changes
  ///
  /// In am, this message translates to:
  /// **'ቋንቋ ወደ አማርኛ ተቀይሯል'**
  String get languageChangedNotice;

  /// Log In button
  ///
  /// In am, this message translates to:
  /// **'ግባ'**
  String get login;

  /// Register button
  ///
  /// In am, this message translates to:
  /// **'ይመዝገቡ'**
  String get register;

  /// Log Out button
  ///
  /// In am, this message translates to:
  /// **'ውጣ'**
  String get logout;

  /// Logout confirmation title
  ///
  /// In am, this message translates to:
  /// **'ከመተግበሪያው መውጣት ይፈልጋሉ?'**
  String get logoutConfirmTitle;

  /// Logout confirmation message
  ///
  /// In am, this message translates to:
  /// **'እንደገና ለመግባት ስልክ ቁጥርዎን እና የይለፍ ቃልዎን ማስገባት ያስፈልግዎታል::'**
  String get logoutConfirmMessage;

  /// Phone number label
  ///
  /// In am, this message translates to:
  /// **'ስልክ ቁጥር'**
  String get phoneNumber;

  /// Phone number hint
  ///
  /// In am, this message translates to:
  /// **'09XXXXXXXX ወይም 07XXXXXXXX'**
  String get phoneNumberHint;

  /// Business name label
  ///
  /// In am, this message translates to:
  /// **'የንግድ ስም'**
  String get businessName;

  /// Business name hint
  ///
  /// In am, this message translates to:
  /// **'ለምሳሌ ቄራ መለዋወጫ መደብር'**
  String get businessNameHint;

  /// Business name validation error
  ///
  /// In am, this message translates to:
  /// **'የንግድ ስም ማስገባት ግዴታ ነው'**
  String get businessNameRequired;

  /// Password label
  ///
  /// In am, this message translates to:
  /// **'የይለፍ ቃል'**
  String get password;

  /// Password hint
  ///
  /// In am, this message translates to:
  /// **'ቢያንስ 6 ፊደላት ወይም ቁጥሮች'**
  String get passwordHint;

  /// Confirm password label
  ///
  /// In am, this message translates to:
  /// **'የይለፍ ቃል ያረጋግጡ'**
  String get confirmPassword;

  /// Passwords mismatch validation error
  ///
  /// In am, this message translates to:
  /// **'የይለፍ ቃሎች አይመሳሰሉም'**
  String get passwordsDoNotMatch;

  /// Prompt for users with existing accounts
  ///
  /// In am, this message translates to:
  /// **'ቀደም ሲል መለያ አለዎት? ይግቡ'**
  String get alreadyHaveAccount;

  /// Prompt for new users to register
  ///
  /// In am, this message translates to:
  /// **'አዲስ ነዎት? ይመዝገቡ'**
  String get dontHaveAccount;

  /// Login screen title
  ///
  /// In am, this message translates to:
  /// **'ወደ መለያዎ ይግቡ'**
  String get loginTitle;

  /// Login screen subtitle
  ///
  /// In am, this message translates to:
  /// **'የመለዋወጫ ዕቃዎችዎን እና ሽያጭዎን ለማስተዳደር ይግቡ'**
  String get loginSubtitle;

  /// Register screen title
  ///
  /// In am, this message translates to:
  /// **'አዲስ የንግድ መለያ ይክፈቱ'**
  String get registerTitle;

  /// Register screen subtitle
  ///
  /// In am, this message translates to:
  /// **'በቀላሉ እና ያለ ኢንተርኔት ዕቃዎን ይከታተሉ'**
  String get registerSubtitle;

  /// Home title
  ///
  /// In am, this message translates to:
  /// **'ዋና ገጽ'**
  String get homeTitle;

  /// Welcome message
  ///
  /// In am, this message translates to:
  /// **'እንኳን ደህና መጡ'**
  String get welcomeUser;

  /// Bottom nav inventory tab
  ///
  /// In am, this message translates to:
  /// **'ዕቃዎች'**
  String get inventoryTab;

  /// Bottom nav sales tab
  ///
  /// In am, this message translates to:
  /// **'ሽያጭ'**
  String get salesTab;

  /// Bottom nav reports tab
  ///
  /// In am, this message translates to:
  /// **'ሪፖርት'**
  String get reportsTab;

  /// Bottom nav settings tab
  ///
  /// In am, this message translates to:
  /// **'ቅንብሮች'**
  String get settingsTab;

  /// Business profile section header
  ///
  /// In am, this message translates to:
  /// **'የንግድ መገለጫ'**
  String get businessProfile;

  /// Offline data indicator notice
  ///
  /// In am, this message translates to:
  /// **'ሁሉም መረጃዎች በስልክዎ ላይ ተቀምጠዋል::'**
  String get offlineStatusNotice;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['am', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

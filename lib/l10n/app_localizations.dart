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

  /// Filter button
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

  /// Brands management title
  ///
  /// In am, this message translates to:
  /// **'ብራንዶች'**
  String get brandsTitle;

  /// Categories management title
  ///
  /// In am, this message translates to:
  /// **'ምድቦች'**
  String get categoriesTitle;

  /// Storage locations management title
  ///
  /// In am, this message translates to:
  /// **'የማስቀመጫ ቦታዎች'**
  String get locationsTitle;

  /// Description for brands settings tile
  ///
  /// In am, this message translates to:
  /// **'መደበኛ እና የራስዎን የዕቃ ብራንዶች ያስተዳድሩ'**
  String get manageBrandsDesc;

  /// Description for categories settings tile
  ///
  /// In am, this message translates to:
  /// **'ዕቃዎችን በተለያዩ ምድቦች ያደራጁ'**
  String get manageCategoriesDesc;

  /// Description for locations settings tile
  ///
  /// In am, this message translates to:
  /// **'መደርደሪያዎች እና የተለዩ የማስቀመጫ ቦታዎች'**
  String get manageLocationsDesc;

  /// Badge for global default system items
  ///
  /// In am, this message translates to:
  /// **'መደበኛ'**
  String get globalDefaultBadge;

  /// Badge for owner-created items
  ///
  /// In am, this message translates to:
  /// **'የራስዎ'**
  String get customBadge;

  /// Add brand button label
  ///
  /// In am, this message translates to:
  /// **'አዲስ ብራንድ ጨምር'**
  String get addBrand;

  /// Edit brand title
  ///
  /// In am, this message translates to:
  /// **'ብራንድ አስተካክል'**
  String get editBrand;

  /// Deactivate brand action
  ///
  /// In am, this message translates to:
  /// **'ብራንድ አቦዝን'**
  String get deactivateBrand;

  /// Deactivate confirmation dialog title
  ///
  /// In am, this message translates to:
  /// **'ዕቃውን ማቦዘን ይፈልጋሉ?'**
  String get deactivateConfirmTitle;

  /// Deactivate confirmation dialog message
  ///
  /// In am, this message translates to:
  /// **'ይህ ዕቃ ከዚህ በኋላ በምርጫ ዝርዝር ውስጥ አይታይም።'**
  String get deactivateConfirmMessage;

  /// Deactivate button text
  ///
  /// In am, this message translates to:
  /// **'አቦዝን'**
  String get deactivate;

  /// Brand name field label
  ///
  /// In am, this message translates to:
  /// **'የብራንድ ስም'**
  String get brandName;

  /// Brand name input hint
  ///
  /// In am, this message translates to:
  /// **'ለምሳሌ፦ ቶዮታ፣ ካት፣ ፐርኪንስ...'**
  String get brandNameHint;

  /// Add category button label
  ///
  /// In am, this message translates to:
  /// **'አዲስ ምድብ ጨምር'**
  String get addCategory;

  /// Edit category title
  ///
  /// In am, this message translates to:
  /// **'ምድብ አስተካክል'**
  String get editCategory;

  /// Deactivate category action
  ///
  /// In am, this message translates to:
  /// **'ምድብ አቦዝን'**
  String get deactivateCategory;

  /// Category name field label
  ///
  /// In am, this message translates to:
  /// **'የምድብ ስም'**
  String get categoryName;

  /// Category name input hint
  ///
  /// In am, this message translates to:
  /// **'ለምሳሌ፦ ሞተር፣ ሃይድሮሊክ፣ ትራንስሚሽን...'**
  String get categoryNameHint;

  /// Add location button label
  ///
  /// In am, this message translates to:
  /// **'አዲስ ቦታ ጨምር'**
  String get addLocation;

  /// Edit location title
  ///
  /// In am, this message translates to:
  /// **'የማስቀመጫ ቦታ አስተካክል'**
  String get editLocation;

  /// Deactivate location action
  ///
  /// In am, this message translates to:
  /// **'የማስቀመጫ ቦታ አቦዝን'**
  String get deactivateLocation;

  /// Location name field label
  ///
  /// In am, this message translates to:
  /// **'የመደርደሪያ ወይም የቦታ ስም'**
  String get locationName;

  /// Location name input hint
  ///
  /// In am, this message translates to:
  /// **'ለምሳሌ፦ መደርደሪያ 6፣ ሳጥን ሀ...'**
  String get locationNameHint;

  /// Error when name already exists
  ///
  /// In am, this message translates to:
  /// **'በዚህ ስም አስቀድሞ የተመዘገበ ዕቃ አለ'**
  String get duplicateNameError;

  /// Error message when attempting to modify default items
  ///
  /// In am, this message translates to:
  /// **'መደበኛ ዕቃዎችን ማስተካከል ወይም ማቦዘን አይቻልም'**
  String get cannotModifyDefault;

  /// Select brand picker title
  ///
  /// In am, this message translates to:
  /// **'ብራንድ ይምረጡ'**
  String get selectBrand;

  /// Select category picker title
  ///
  /// In am, this message translates to:
  /// **'ምድብ ይምረጡ'**
  String get selectCategory;

  /// Select location picker title
  ///
  /// In am, this message translates to:
  /// **'የማስቀመጫ ቦታ ይምረጡ'**
  String get selectLocation;

  /// Empty state text for brands
  ///
  /// In am, this message translates to:
  /// **'ምንም ብራንድ አልተገኘም'**
  String get noBrandsFound;

  /// Empty state text for categories
  ///
  /// In am, this message translates to:
  /// **'ምንም ምድብ አልተገኘም'**
  String get noCategoriesFound;

  /// Empty state text for locations
  ///
  /// In am, this message translates to:
  /// **'ምንም የማስቀመጫ ቦታ አልተገኘም'**
  String get noLocationsFound;

  /// Search brands field hint
  ///
  /// In am, this message translates to:
  /// **'ብራንድ ይፈልጉ...'**
  String get searchBrands;

  /// Search categories field hint
  ///
  /// In am, this message translates to:
  /// **'ምድብ ይፈልጉ...'**
  String get searchCategories;

  /// Search locations field hint
  ///
  /// In am, this message translates to:
  /// **'የማስቀመጫ ቦታ ይፈልጉ...'**
  String get searchLocations;

  /// Quick add new button in picker
  ///
  /// In am, this message translates to:
  /// **'አዲስ ጨምር'**
  String get quickAddNew;

  /// Add spare part screen title and button
  ///
  /// In am, this message translates to:
  /// **'አዲስ የመለዋወጫ ዕቃ መዝግብ'**
  String get addPart;

  /// Edit spare part screen title
  ///
  /// In am, this message translates to:
  /// **'የመለዋወጫ ዕቃውን አስተካክል'**
  String get editPart;

  /// Part details screen title
  ///
  /// In am, this message translates to:
  /// **'የዕቃው ዝርዝር መረጃ'**
  String get partDetails;

  /// Part name field label
  ///
  /// In am, this message translates to:
  /// **'የዕቃው ስም'**
  String get partName;

  /// Part name input hint
  ///
  /// In am, this message translates to:
  /// **'ለምሳሌ፦ ሃይድሮሊክ ፓምፕ፣ የዘይት ፊልተር...'**
  String get partNameHint;

  /// Part number field label
  ///
  /// In am, this message translates to:
  /// **'የዕቃ መለያ ቁጥር (Part No)'**
  String get partNumber;

  /// Part number input hint
  ///
  /// In am, this message translates to:
  /// **'ለምሳሌ፦ 1R-0716፣ 9T-0988...'**
  String get partNumberHint;

  /// Brand label
  ///
  /// In am, this message translates to:
  /// **'ብራንድ'**
  String get brand;

  /// Category label
  ///
  /// In am, this message translates to:
  /// **'ምድብ'**
  String get category;

  /// Storage location label
  ///
  /// In am, this message translates to:
  /// **'የማስቀመጫ መደርደሪያ / ቦታ'**
  String get storageLocation;

  /// Custom spot label
  ///
  /// In am, this message translates to:
  /// **'የተለየ የማስቀመጫ ቦታ'**
  String get customLocation;

  /// Custom spot input hint
  ///
  /// In am, this message translates to:
  /// **'ለምሳሌ፦ የላይኛው ሳጥን፣ ጥግ ላይ...'**
  String get customLocationHint;

  /// Description field label
  ///
  /// In am, this message translates to:
  /// **'ተጨማሪ ማብራሪያ'**
  String get description;

  /// Description input hint
  ///
  /// In am, this message translates to:
  /// **'ስለ ዕቃው አጭር መግለጫ...'**
  String get descriptionHint;

  /// Unit field label
  ///
  /// In am, this message translates to:
  /// **'መለኪያ'**
  String get unit;

  /// Unit input hint
  ///
  /// In am, this message translates to:
  /// **'ለምሳሌ፦ ፍሬ፣ ሴት፣ ሜትር፣ ሊትር...'**
  String get unitHint;

  /// Quantity field label
  ///
  /// In am, this message translates to:
  /// **'በክምችት ያለ ብዛት'**
  String get quantityInStock;

  /// Purchase price field label
  ///
  /// In am, this message translates to:
  /// **'የግዢ ዋጋ (ብር)'**
  String get purchasePrice;

  /// Selling price field label
  ///
  /// In am, this message translates to:
  /// **'የመሸጫ ዋጋ (ብር)'**
  String get sellingPrice;

  /// Estimated profit metric
  ///
  /// In am, this message translates to:
  /// **'የተገመተ ትርፍ'**
  String get estimatedProfit;

  /// Size and specs label
  ///
  /// In am, this message translates to:
  /// **'መጠን ወይም ዝርዝር መረጃ'**
  String get sizeSpecs;

  /// Size and specs input hint
  ///
  /// In am, this message translates to:
  /// **'ለምሳሌ፦ 10 ሚሜ፣ 24 ቮልት...'**
  String get sizeSpecsHint;

  /// Internal notes label
  ///
  /// In am, this message translates to:
  /// **'የግል ማስታወሻ'**
  String get notes;

  /// Internal notes input hint
  ///
  /// In am, this message translates to:
  /// **'ተጨማሪ የግል ማስታወሻ...'**
  String get notesHint;

  /// Take photo action
  ///
  /// In am, this message translates to:
  /// **'ፎቶ አንሳ'**
  String get takePhoto;

  /// Choose from gallery action
  ///
  /// In am, this message translates to:
  /// **'ከጋለሪ ምረጥ'**
  String get chooseFromGallery;

  /// Remove photo action
  ///
  /// In am, this message translates to:
  /// **'ፎቶውን አስወግድ'**
  String get removePhoto;

  /// Unsaved changes dialog title
  ///
  /// In am, this message translates to:
  /// **'ያልተቀመጡ ለውጦች'**
  String get unsavedChangesTitle;

  /// Unsaved changes dialog message
  ///
  /// In am, this message translates to:
  /// **'ያልተቀመጡ ለውጦች አሉ። ገጹን መተው ይፈልጋሉ?'**
  String get unsavedChangesMessage;

  /// Discard changes button
  ///
  /// In am, this message translates to:
  /// **'ተወው'**
  String get discard;

  /// Keep editing button
  ///
  /// In am, this message translates to:
  /// **'ማረም ቀጥል'**
  String get keepEditing;

  /// Delete part action
  ///
  /// In am, this message translates to:
  /// **'ዕቃውን አጥፋ'**
  String get deletePart;

  /// Delete part confirmation title
  ///
  /// In am, this message translates to:
  /// **'ይህንን ዕቃ መሰረዝ ይፈልጋሉ?'**
  String get deletePartConfirmTitle;

  /// Delete part confirmation message
  ///
  /// In am, this message translates to:
  /// **'ዕቃው ከክምችት ይሰረዛል። ከዚህ በፊት የተመዘገቡ የሽያጭ መረጃዎች አይነኩም።'**
  String get deletePartConfirmMessage;

  /// Part saved success message
  ///
  /// In am, this message translates to:
  /// **'የመለዋወጫ ዕቃው በተሳካ ሁኔታ ተቀምጧል'**
  String get partSavedSuccess;

  /// Part deleted success message
  ///
  /// In am, this message translates to:
  /// **'የመለዋወጫ ዕቃው ተሰርዟል'**
  String get partDeletedSuccess;

  /// Negative number validation error
  ///
  /// In am, this message translates to:
  /// **'ዋጋው ወይም ብዛቱ ከዜሮ በታች ሊሆን አይችልም'**
  String get negativeNumberError;

  /// No photo placeholder label
  ///
  /// In am, this message translates to:
  /// **'ፎቶ የለም'**
  String get noPhoto;

  /// Stock status label
  ///
  /// In am, this message translates to:
  /// **'የክምችት ሁኔታ'**
  String get stockStatus;

  /// In stock badge text
  ///
  /// In am, this message translates to:
  /// **'ክምችት አለ'**
  String get inStock;

  /// Out of stock badge text
  ///
  /// In am, this message translates to:
  /// **'ያለቀ'**
  String get outOfStock;

  /// Low stock badge text
  ///
  /// In am, this message translates to:
  /// **'አነስተኛ ክምችት'**
  String get lowStock;

  /// Inventory search bar placeholder
  ///
  /// In am, this message translates to:
  /// **'በስም፣ በፓርት ቁጥር፣ ብራንድ፣ ምድብ፣ መደርደሪያ ፈልግ...'**
  String get searchHint;

  /// Filters dialog title
  ///
  /// In am, this message translates to:
  /// **'ማጣሪያዎች'**
  String get filters;

  /// Sort by label
  ///
  /// In am, this message translates to:
  /// **'ቅደም ተከተል'**
  String get sortBy;

  /// Sort by name option
  ///
  /// In am, this message translates to:
  /// **'በስም (A - Z)'**
  String get sortName;

  /// Sort by newest option
  ///
  /// In am, this message translates to:
  /// **'አዳዲስ መጀመሪያ'**
  String get sortNewest;

  /// Sort by quantity descending
  ///
  /// In am, this message translates to:
  /// **'ብዛት (ከፍተኛ)'**
  String get sortQuantityHigh;

  /// Sort by quantity ascending
  ///
  /// In am, this message translates to:
  /// **'ብዛት (ዝቅተኛ)'**
  String get sortQuantityLow;

  /// Sort by price descending
  ///
  /// In am, this message translates to:
  /// **'ዋጋ (ከፍተኛ)'**
  String get sortPriceHigh;

  /// Sort by price ascending
  ///
  /// In am, this message translates to:
  /// **'ዋጋ (ዝቅተኛ)'**
  String get sortPriceLow;

  /// All filter option
  ///
  /// In am, this message translates to:
  /// **'ሁሉም'**
  String get filterAll;

  /// In stock filter chip
  ///
  /// In am, this message translates to:
  /// **'ክምችት ያለው'**
  String get filterInStock;

  /// Low stock filter chip
  ///
  /// In am, this message translates to:
  /// **'አነስተኛ ክምችት'**
  String get filterLowStock;

  /// Out of stock filter chip
  ///
  /// In am, this message translates to:
  /// **'ያለቀ'**
  String get filterOutOfStock;

  /// Reset filters button
  ///
  /// In am, this message translates to:
  /// **'አጽዳ'**
  String get resetFilters;

  /// Apply filters button
  ///
  /// In am, this message translates to:
  /// **'ተግብር'**
  String get applyFilters;

  /// Active filters count badge
  ///
  /// In am, this message translates to:
  /// **'{count} ማጣሪያዎች ተመርጠዋል'**
  String activeFiltersCount(int count);

  /// Total parts count indicator
  ///
  /// In am, this message translates to:
  /// **'{count} ዕቃዎች'**
  String totalPartsCount(int count);

  /// No matching parts found title
  ///
  /// In am, this message translates to:
  /// **'ምንም የተገኘ ዕቃ የለም'**
  String get noFilteredPartsTitle;

  /// No matching parts found description
  ///
  /// In am, this message translates to:
  /// **'እባክዎ የፍለጋ ቃልዎን ወይም ማጣሪያዎችን ይቀይሩ'**
  String get noFilteredPartsDesc;

  /// Seed test parts title
  ///
  /// In am, this message translates to:
  /// **'2,000 የሙከራ ዕቃዎችን ፍጠር'**
  String get seedParts;

  /// Seed test parts description
  ///
  /// In am, this message translates to:
  /// **'ለፍጥነት እና አፈፃፀም መፈተሻ 2,000 የመለዋወጫ ዕቃዎችን በቅጽበት ይፈጥራል'**
  String get seedPartsDesc;

  /// Seeding in progress snackbar
  ///
  /// In am, this message translates to:
  /// **'2,000 ዕቃዎች እየተፈጠሩ ነው...'**
  String get seedingInProgress;

  /// Seeding success message
  ///
  /// In am, this message translates to:
  /// **'2,000 የሙከራ ዕቃዎች በተሳካ ሁኔታ ተፈጥረዋል!'**
  String get seedSuccess;

  /// Clear test parts title
  ///
  /// In am, this message translates to:
  /// **'የሙከራ ዕቃዎችን አጥፋ'**
  String get clearTestParts;

  /// Clear test parts confirmation dialog
  ///
  /// In am, this message translates to:
  /// **'ሁሉንም በሙከራ የተፈጠሩ ዕቃዎች ማጥፋት ይፈልጋሉ?'**
  String get clearTestPartsConfirm;

  /// Clear test parts success message
  ///
  /// In am, this message translates to:
  /// **'የሙከራ ዕቃዎች ተሰርዘዋል'**
  String get clearTestPartsSuccess;

  /// Update stock action title
  ///
  /// In am, this message translates to:
  /// **'ክምችት አስተካክል'**
  String get updateStock;

  /// Add stock purchase action
  ///
  /// In am, this message translates to:
  /// **'ክምችት ጨምር (ግዢ)'**
  String get addStockPurchase;

  /// Remove stock action
  ///
  /// In am, this message translates to:
  /// **'ክምችት ቀንስ'**
  String get removeStock;

  /// Adjust stock to physical count
  ///
  /// In am, this message translates to:
  /// **'የተቆጠረውን ትክክለኛ ብዛት መዝግብ'**
  String get adjustStockCount;

  /// Stock movement history title
  ///
  /// In am, this message translates to:
  /// **'የእንቅስቃሴ ታሪክ'**
  String get stockMovementHistory;

  /// Quantity to add input label
  ///
  /// In am, this message translates to:
  /// **'የሚጨመረው ብዛት'**
  String get quantityToAdd;

  /// Quantity to remove input label
  ///
  /// In am, this message translates to:
  /// **'የሚቀነሰው ብዛት'**
  String get quantityToRemove;

  /// Counted quantity input label
  ///
  /// In am, this message translates to:
  /// **'የተቆጠረው ብዛት'**
  String get countedQuantity;

  /// Unit cost input label
  ///
  /// In am, this message translates to:
  /// **'የአንዱ ዋጋ (ብር)'**
  String get unitCost;

  /// Reason or note input label
  ///
  /// In am, this message translates to:
  /// **'ምክንያት ወይም ማስታወሻ'**
  String get reasonOrNote;

  /// Reason or note input hint
  ///
  /// In am, this message translates to:
  /// **'ለምሳሌ፦ ከአቅራቢ የገባ፣ የተበላሸ፣ ቆጠራ የተደረገ...'**
  String get reasonOrNoteHint;

  /// Current stock label
  ///
  /// In am, this message translates to:
  /// **'የአሁን ክምችት'**
  String get currentStock;

  /// Difference label
  ///
  /// In am, this message translates to:
  /// **'ልዩነት'**
  String get difference;

  /// Running balance label
  ///
  /// In am, this message translates to:
  /// **'የቀረው ክምችት'**
  String get runningBalance;

  /// Recalculate stock action
  ///
  /// In am, this message translates to:
  /// **'ክምችት እንደገና አስላ'**
  String get recalculateStock;

  /// Recalculate stock description
  ///
  /// In am, this message translates to:
  /// **'የክምችት ትክክለኛነትን ለማረጋገጥ ከእንቅስቃሴ መዝገቡ ላይ እንደገና ያሰላል'**
  String get recalculateStockDesc;

  /// Stock recalculated success message
  ///
  /// In am, this message translates to:
  /// **'የክምችት ብዛት ከመዝገቡ ላይ በተሳካ ሁኔታ ተሰልቷል'**
  String get stockRecalculatedSuccess;

  /// Allow negative stock setting title
  ///
  /// In am, this message translates to:
  /// **'ከዜሮ በታች እንዲሆን ፍቀድ'**
  String get allowNegativeStock;

  /// Allow negative stock setting description
  ///
  /// In am, this message translates to:
  /// **'ዕቃዎችን ሲቀንሱ ወይም ሲሸጡ ክምችቱ ከዜሮ በታች እንዲወርድ ይፈቅዳል'**
  String get allowNegativeStockDesc;

  /// Negative stock warning dialog title
  ///
  /// In am, this message translates to:
  /// **'የክምችት እጥረት ማስጠንቀቂያ'**
  String get negativeStockWarningTitle;

  /// Negative stock warning confirmation message
  ///
  /// In am, this message translates to:
  /// **'ይህንን ብዛት መቀነስ ክምችቱን ከዜሮ በታች ({newStock}) ያደርገዋል። እርግጠኛ ነዎት?'**
  String negativeStockWarningMessage(String newStock);

  /// Negative stock disallowed message
  ///
  /// In am, this message translates to:
  /// **'ክምችት ከዜሮ በታች ሊሆን አይችልም። አስፈላጊ ከሆነ በቅንብሮች ውስጥ ይፍቀዱ።'**
  String get negativeStockNotAllowed;

  /// Low stock items screen title
  ///
  /// In am, this message translates to:
  /// **'አነስተኛ ክምችት ያላቸው ዕቃዎች'**
  String get lowStockListTitle;

  /// Low stock items screen subtitle
  ///
  /// In am, this message translates to:
  /// **'ከዝቅተኛው የመጠን ገደብ በታች የሆኑ ዕቃዎች'**
  String get lowStockListDesc;

  /// Empty state for low stock screen
  ///
  /// In am, this message translates to:
  /// **'ምንም አነስተኛ ክምችት ያለው ዕቃ የለም። ሁሉም በቂ ክምችት አላቸው!'**
  String get noLowStockItems;

  /// Initial stock movement type
  ///
  /// In am, this message translates to:
  /// **'የመጀመሪያ ክምችት'**
  String get movementTypeInitial;

  /// Purchase movement type
  ///
  /// In am, this message translates to:
  /// **'ግዢ'**
  String get movementTypePurchase;

  /// Sale movement type
  ///
  /// In am, this message translates to:
  /// **'ሽያጭ'**
  String get movementTypeSale;

  /// Adjustment movement type
  ///
  /// In am, this message translates to:
  /// **'ማስተካከያ'**
  String get movementTypeAdjustment;

  /// Return movement type
  ///
  /// In am, this message translates to:
  /// **'ተመላሽ'**
  String get movementTypeReturn;

  /// No movements empty state title
  ///
  /// In am, this message translates to:
  /// **'ምንም የክምችት እንቅስቃሴ የለም'**
  String get noMovementsTitle;

  /// No movements empty state description
  ///
  /// In am, this message translates to:
  /// **'ክምችት ሲጨመር፣ ሲቀነስ ወይም ሲስተካከል እንቅስቃሴዎች እዚህ ይታያሉ።'**
  String get noMovementsDesc;

  /// New sale button and title
  ///
  /// In am, this message translates to:
  /// **'አዲስ ሽያጭ'**
  String get newSale;

  /// Record sale title
  ///
  /// In am, this message translates to:
  /// **'ሽያጭ መዝግብ'**
  String get recordSale;

  /// Sale details title
  ///
  /// In am, this message translates to:
  /// **'የሽያጭ ዝርዝር'**
  String get saleDetails;

  /// Add parts to sale button
  ///
  /// In am, this message translates to:
  /// **'ዕቃዎችን ጨምር'**
  String get addPartsToSale;

  /// Empty sale cart title
  ///
  /// In am, this message translates to:
  /// **'ምንም ዕቃ አልተመረጠም'**
  String get cartEmptyTitle;

  /// Empty sale cart description
  ///
  /// In am, this message translates to:
  /// **'ሽያጩን ለመመዝገብ ዕቃዎችን ይፈልጉ እና ይጨምሩ'**
  String get cartEmptyDesc;

  /// Unit price label
  ///
  /// In am, this message translates to:
  /// **'የነጠላ መሸጫ ዋጋ'**
  String get unitPrice;

  /// Line total label
  ///
  /// In am, this message translates to:
  /// **'ጠቅላላ ዋጋ'**
  String get lineTotal;

  /// Line profit label
  ///
  /// In am, this message translates to:
  /// **'ትርፍ'**
  String get lineProfit;

  /// Total estimated profit label
  ///
  /// In am, this message translates to:
  /// **'ጠቅላላ የሚገኝ ትርፍ'**
  String get totalProfit;

  /// Customer notes label
  ///
  /// In am, this message translates to:
  /// **'የደንበኛ ወይም የደረሰኝ ማስታወሻ'**
  String get customerNotes;

  /// Customer notes hint
  ///
  /// In am, this message translates to:
  /// **'አማራጭ ማስታወሻ ወይም የደንበኛ ስም...'**
  String get customerNotesHint;

  /// Total items count label
  ///
  /// In am, this message translates to:
  /// **'ጠቅላላ ዕቃዎች'**
  String get totalItems;

  /// Total cost label
  ///
  /// In am, this message translates to:
  /// **'ጠቅላላ ወጪ'**
  String get totalCost;

  /// Complete sale button
  ///
  /// In am, this message translates to:
  /// **'ሽያጩን ጨርስ'**
  String get completeSale;

  /// Sale success screen title
  ///
  /// In am, this message translates to:
  /// **'ሽያጩ በተሳካ ሁኔታ ተመዝግቧል!'**
  String get saleSuccessTitle;

  /// Receipt number label
  ///
  /// In am, this message translates to:
  /// **'የደረሰኝ ቁጥር'**
  String get receiptNumber;

  /// Sale date and time label
  ///
  /// In am, this message translates to:
  /// **'የተሸጠበት ቀን እና ሰዓት'**
  String get soldAt;

  /// Warning when part has no purchase price
  ///
  /// In am, this message translates to:
  /// **'የግዢ ዋጋ አልተመዘገበም፤ ትርፉ ከተጨባጩ በላይ ሊታይ ይችላል'**
  String get noCostWarning;

  /// Warning when a sale item exceeds stock
  ///
  /// In am, this message translates to:
  /// **'የ\"{partName}\" ብዛት ከአሁን ክምችት ({stock}) ይበልጣል። ቀሪው ክምችት {newStock} ይሆናል።'**
  String saleStockWarningMessage(
    String partName,
    String stock,
    String newStock,
  );

  /// Sale recorded success message
  ///
  /// In am, this message translates to:
  /// **'ሽያጩ በተሳካ ሁኔታ ተመዝግቧል'**
  String get saleRecordedSuccess;

  /// Back to home button
  ///
  /// In am, this message translates to:
  /// **'ወደ ዋና ገጽ ተመለስ'**
  String get backToHome;

  /// Empty sale validation error
  ///
  /// In am, this message translates to:
  /// **'ባዶ ሽያጭ ማስቀመጥ አይቻልም። እባክዎ ቢያንስ አንድ ዕቃ ይጨምሩ።'**
  String get emptySaleError;

  /// Search and add parts button
  ///
  /// In am, this message translates to:
  /// **'ዕቃዎችን ፈልግ እና ጨምር'**
  String get searchAndAddParts;

  /// Filter today
  ///
  /// In am, this message translates to:
  /// **'ዛሬ'**
  String get filterToday;

  /// Filter this week
  ///
  /// In am, this message translates to:
  /// **'በዚህ ሳምንት'**
  String get filterThisWeek;

  /// Filter this month
  ///
  /// In am, this message translates to:
  /// **'በዚህ ወር'**
  String get filterThisMonth;

  /// Filter custom date range
  ///
  /// In am, this message translates to:
  /// **'ብጁ'**
  String get filterCustom;

  /// Select date range dialog title
  ///
  /// In am, this message translates to:
  /// **'የቀን ክልል ይምረጡ'**
  String get selectDateRange;

  /// Search sales input hint
  ///
  /// In am, this message translates to:
  /// **'በዕቃ ስም ወይም ደረሰኝ ቁጥር ፈልግ...'**
  String get searchSalesHint;

  /// Total sales for the day
  ///
  /// In am, this message translates to:
  /// **'የቀኑ ድምር'**
  String get dayTotal;

  /// Item count badge
  ///
  /// In am, this message translates to:
  /// **'{count} ዕቃዎች'**
  String itemsCount(int count);

  /// Empty sales list for filter
  ///
  /// In am, this message translates to:
  /// **'ለተመረጠው ማጣሪያ ምንም ሽያጭ አልተገኘም'**
  String get noSalesForFilter;

  /// Sale details screen title
  ///
  /// In am, this message translates to:
  /// **'የሽያጭ ዝርዝር'**
  String get saleDetailsTitle;

  /// Payment method label
  ///
  /// In am, this message translates to:
  /// **'የክፍያ ዘዴ'**
  String get paymentMethod;

  /// Line cost label
  ///
  /// In am, this message translates to:
  /// **'ወጪ'**
  String get lineCost;

  /// Delete sale button
  ///
  /// In am, this message translates to:
  /// **'ሽያጭ ሰርዝ'**
  String get deleteSale;

  /// Delete sale confirmation dialog
  ///
  /// In am, this message translates to:
  /// **'ይህን ሽያጭ መሰረዝ እርግጠኛ ነዎት?'**
  String get deleteSaleConfirm;

  /// Reports screen title
  ///
  /// In am, this message translates to:
  /// **'ሪፖርት እና ትንታኔ'**
  String get reportsTitle;

  /// Daily report tab
  ///
  /// In am, this message translates to:
  /// **'ዕለታዊ'**
  String get reportDaily;

  /// Weekly report tab
  ///
  /// In am, this message translates to:
  /// **'ሳምንታዊ'**
  String get reportWeekly;

  /// Monthly report tab
  ///
  /// In am, this message translates to:
  /// **'ወርሃዊ'**
  String get reportMonthly;

  /// Sales count metric
  ///
  /// In am, this message translates to:
  /// **'የሽያጭ ብዛት'**
  String get salesCount;

  /// Total revenue metric
  ///
  /// In am, this message translates to:
  /// **'ጠቅላላ ገቢ'**
  String get totalRevenue;

  /// Top 5 selling parts card title
  ///
  /// In am, this message translates to:
  /// **'ከፍተኛ ሽያጭ ያላቸው 5 ዕቃዎች'**
  String get topSellingParts;

  /// Total inventory stock value
  ///
  /// In am, this message translates to:
  /// **'ጠቅላላ የክምችት ዋጋ'**
  String get totalStockValue;

  /// Low stock alert count
  ///
  /// In am, this message translates to:
  /// **'ዝቅተኛ ክምችት ብዛት'**
  String get lowStockCount;

  /// Quantity of parts sold
  ///
  /// In am, this message translates to:
  /// **'{count} ተሽጧል'**
  String unitsSold(String count);

  /// Sales chart title
  ///
  /// In am, this message translates to:
  /// **'የሽያጭ ሂደት'**
  String get salesTrend;

  /// Empty sales report state
  ///
  /// In am, this message translates to:
  /// **'በዚህ ጊዜ ውስጥ ምንም ሽያጭ አልተመዘገበም'**
  String get noSalesInPeriod;

  /// View low stock button
  ///
  /// In am, this message translates to:
  /// **'ዝቅተኛ ክምችቶችን ይመልከቱ'**
  String get viewLowStock;
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

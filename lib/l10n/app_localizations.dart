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

  /// Password too short error
  ///
  /// In am, this message translates to:
  /// **'የይለፍ ቃል ቢያንስ 6 ቁምፊዎች መሆን አለበት'**
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

  /// Account details header
  ///
  /// In am, this message translates to:
  /// **'የመለያ ዝርዝሮች'**
  String get accountDetails;

  /// Edit profile dialog button
  ///
  /// In am, this message translates to:
  /// **'መገለጫ አርትዕ'**
  String get editProfile;

  /// Change password button
  ///
  /// In am, this message translates to:
  /// **'የይለፍ ቃል ቀይር'**
  String get changePassword;

  /// Current password field
  ///
  /// In am, this message translates to:
  /// **'የአሁኑ የይለፍ ቃል'**
  String get currentPassword;

  /// New password field
  ///
  /// In am, this message translates to:
  /// **'አዲስ የይለፍ ቃል'**
  String get newPassword;

  /// Confirm new password field
  ///
  /// In am, this message translates to:
  /// **'አዲሱን የይለፍ ቃል ያረጋግጡ'**
  String get confirmNewPassword;

  /// Password changed success snackbar
  ///
  /// In am, this message translates to:
  /// **'የይለፍ ቃል በተሳካ ሁኔታ ተቀይሯል'**
  String get passwordChangedSuccess;

  /// Incorrect current password error
  ///
  /// In am, this message translates to:
  /// **'የተሳሳተ የአሁኑ የይለፍ ቃል'**
  String get invalidCurrentPassword;

  /// Passwords do not match error
  ///
  /// In am, this message translates to:
  /// **'የይለፍ ቃሎች አይዛመዱም'**
  String get passwordMismatch;

  /// Currency label
  ///
  /// In am, this message translates to:
  /// **'የስርዓቱ ገንዘብ'**
  String get currencyLabel;

  /// Currency explanation description
  ///
  /// In am, this message translates to:
  /// **'ሁሉም የፋይናንስ አሃዞች እና ሪፖርቶች በኢትዮጵያ ብር (ETB) ይሰላሉ።'**
  String get currencyDesc;

  /// About app title
  ///
  /// In am, this message translates to:
  /// **'ስለ ቄራ ስፔር ትራከር'**
  String get aboutTitle;

  /// About app description
  ///
  /// In am, this message translates to:
  /// **'በቄራ አዲስ አበባ ለሚገኙ የመለዋወጫ ንግዶች ከመስመር ውጭ የሚሰራ የእቃ ዝርዝር እና የሽያጭ አስተዳደር።'**
  String get aboutDesc;

  /// App version label
  ///
  /// In am, this message translates to:
  /// **'ስሪት {version}'**
  String appVersion(String version);

  /// Theme selector title
  ///
  /// In am, this message translates to:
  /// **'የመተግበሪያ ገጽታ'**
  String get themeMode;

  /// System theme choice
  ///
  /// In am, this message translates to:
  /// **'የስርዓቱ ነባሪ'**
  String get themeSystem;

  /// Light theme choice
  ///
  /// In am, this message translates to:
  /// **'ብሩህ ገጽታ'**
  String get themeLight;

  /// Dark theme choice
  ///
  /// In am, this message translates to:
  /// **'ጨለማ ገጽታ'**
  String get themeDark;

  /// Data management section header
  ///
  /// In am, this message translates to:
  /// **'የውሂብ አስተዳደር እና ኤክስፖርት'**
  String get dataManagement;

  /// Export inventory CSV button
  ///
  /// In am, this message translates to:
  /// **'የእቃ ዝርዝር ኤክስፖርት (CSV)'**
  String get exportInventoryCsv;

  /// Export inventory CSV description
  ///
  /// In am, this message translates to:
  /// **'የሁሉም መለዋወጫዎች የ CSV ሰንጠረዥ ያመንጩ እና ያጋሩ'**
  String get exportInventoryDesc;

  /// Export sales CSV button
  ///
  /// In am, this message translates to:
  /// **'የሽያጭ ታሪክ ኤክስፖርት (CSV)'**
  String get exportSalesCsv;

  /// Export sales CSV description
  ///
  /// In am, this message translates to:
  /// **'የሽያጭ መዝገቦች የ CSV ሰንጠረዥ ያመንጩ እና ያጋሩ'**
  String get exportSalesDesc;

  /// Backup database button
  ///
  /// In am, this message translates to:
  /// **'የአካባቢ ዳታቤዝ ቅጂ (Backup)'**
  String get backupDatabase;

  /// Backup database description
  ///
  /// In am, this message translates to:
  /// **'የዳታቤዝ ፋይልን ለማጋራት ወይም በደህና ለማስቀመጥ ኤክስፖርት ያድርጉ'**
  String get backupDatabaseDesc;

  /// Restore database button
  ///
  /// In am, this message translates to:
  /// **'ዳታቤዝ ከመጠባበቂያ ፋይል ይመልሱ'**
  String get restoreDatabase;

  /// Restore database description
  ///
  /// In am, this message translates to:
  /// **'ሁሉንም የአካባቢ ውሂብ ከመጠባበቂያ የ SQLite ፋይል ይመልሱ'**
  String get restoreDatabaseDesc;

  /// Restore confirmation title
  ///
  /// In am, this message translates to:
  /// **'ዳታቤዙን መመለስ ይፈልጋሉ?'**
  String get restoreConfirmTitle;

  /// Restore confirmation warning message
  ///
  /// In am, this message translates to:
  /// **'ማስጠንቀቂያ፡ ወደነበረበት መመለስ አሁን ያለውን ሁሉንም የእቃ ዝርዝር፣ የክምችት መዝገብ እና የሽያጭ መረጃዎች በመጠባበቂያ ፋይሉ ውሂብ ይተካዋል። ይህ እርምጃ ሊቀለበስ አይችልም። መቀጠል ይፈልጋሉ?'**
  String get restoreConfirmMessage;

  /// Restore success message
  ///
  /// In am, this message translates to:
  /// **'ዳታቤዙ በተሳካ ሁኔታ ተመልሷል። እንደገና በመጫን ላይ...'**
  String get restoreSuccess;

  /// Restore error message
  ///
  /// In am, this message translates to:
  /// **'ከተመረጠው ፋይል ዳታቤዙን መመለስ አልተቻለም'**
  String get restoreError;

  /// Export file success
  ///
  /// In am, this message translates to:
  /// **'የኤክስፖርት ፋይል ተፈጥሯል፡ {filename}'**
  String exportSuccess(String filename);

  /// Export error message
  ///
  /// In am, this message translates to:
  /// **'ውሂብ ኤክስፖርት ማድረግ አልተቻለም፡ {error}'**
  String exportError(String error);

  /// Save to storage label
  ///
  /// In am, this message translates to:
  /// **'ወደ ማከማቻ አስቀምጥ'**
  String get saveToStorage;

  /// Notice that internet is required for first login
  ///
  /// In am, this message translates to:
  /// **'ለመመዝገብ እና ለመጀመሪያ ጊዜ ለመግባት የበይነመረብ (ኢንተርኔት) ግንኙነት ያስፈልጋል። አንዴ ከገቡ በኋላ መተግበሪያው ሙሉ በሙሉ ከመስመር ውጭ (ኦፍላይን) ይሰራል።'**
  String get authRequiresInternetNotice;

  /// Wrong password error message
  ///
  /// In am, this message translates to:
  /// **'የተሳሳተ ስልክ ቁጥር ወይም የይለፍ ቃል'**
  String get authWrongPassword;

  /// Phone already registered message
  ///
  /// In am, this message translates to:
  /// **'ይህ ስልክ ቁጥር አስቀድሞ ተመዝግቧል'**
  String get authPhoneTaken;

  /// No internet connection message
  ///
  /// In am, this message translates to:
  /// **'የበይነመረብ ግንኙነት የለም። እባክዎ ለመግባት ከበይነመረብ ጋር ይገናኙ።'**
  String get authNoInternet;

  /// Account suspended message
  ///
  /// In am, this message translates to:
  /// **'የንግድ መለያዎ ታግዷል። እባክዎን የስርዓት አስተዳዳሪውን ያነጋግሩ።'**
  String get authAccountSuspended;

  /// Server error message
  ///
  /// In am, this message translates to:
  /// **'የአገልጋይ ችግር አጋጥሟል። እባክዎ ትንሽ ቆይተው እንደገና ይሞክሩ።'**
  String get authServerError;

  /// Update required title
  ///
  /// In am, this message translates to:
  /// **'ማዘመን ያስፈልጋል'**
  String get updateRequiredTitle;

  /// Update required description message
  ///
  /// In am, this message translates to:
  /// **'መተግበሪያውን ለመቀጠል አዲስ ስሪት ያስፈልጋል። እባክዎ ወደ ስሪት {version} ወይም ከዚያ በላይ ያዘምኑ።'**
  String updateRequiredMessage(String version);

  /// Update now button
  ///
  /// In am, this message translates to:
  /// **'አሁን አዘምን'**
  String get updateNow;

  /// Maintenance title
  ///
  /// In am, this message translates to:
  /// **'አገልግሎቱ በጥገና ላይ ነው'**
  String get maintenanceTitle;

  /// Maintenance banner text
  ///
  /// In am, this message translates to:
  /// **'የዳመና ማመሳሰል አገልግሎት ለጊዜው በጥገና ላይ ነው። የመስመር ውጭ የዕቃዎች እና የሽያጭ ስራዎች ሙሉ በሙሉ ይሰራሉ።'**
  String get maintenanceBanner;

  /// Title for suspended account banner
  ///
  /// In am, this message translates to:
  /// **'መለያው ታግዷል'**
  String get accountSuspendedTitle;

  /// Message for suspended account banner
  ///
  /// In am, this message translates to:
  /// **'መለያዎ ታግዷል። ማመሳሰል ቆሟል፤ ነገር ግን የአካባቢዎ መረጃዎች ክፍት ሆነው ይቆያሉ እና መረጃ ማውጣት ይችላሉ።'**
  String get accountSuspendedMessage;

  /// Suspension reason label
  ///
  /// In am, this message translates to:
  /// **'ምክንያት፦ {reason}'**
  String suspensionReasonLabel(String reason);

  /// Contact support label
  ///
  /// In am, this message translates to:
  /// **'እርዳታ ለማግኘት ያግኙን፦'**
  String get contactSupportLabel;

  /// Call support button
  ///
  /// In am, this message translates to:
  /// **'ይደውሉ'**
  String get callSupport;

  /// Telegram support button
  ///
  /// In am, this message translates to:
  /// **'ቴሌግራም'**
  String get telegramSupport;

  /// Must change password title
  ///
  /// In am, this message translates to:
  /// **'የይለፍ ቃል መቀየር ያስፈልጋል'**
  String get mustChangePasswordTitle;

  /// Must change password prompt
  ///
  /// In am, this message translates to:
  /// **'ለመቀጠል እባክዎ መጀመሪያ አዲስ የይለፍ ቃል ያዘጋጁ።'**
  String get mustChangePasswordPrompt;

  /// Dismiss button
  ///
  /// In am, this message translates to:
  /// **'ዝጋ'**
  String get dismiss;

  /// No description provided for @adminAccount.
  ///
  /// In am, this message translates to:
  /// **'የአድሚን መለያ'**
  String get adminAccount;

  /// No description provided for @adminAccountDisabledSuccess.
  ///
  /// In am, this message translates to:
  /// **'የተጠቃሚው አካውንት በተሳካ ሁኔታ ተዘግቷል'**
  String get adminAccountDisabledSuccess;

  /// No description provided for @adminAccountTitle.
  ///
  /// In am, this message translates to:
  /// **'የአድሚን መለያ አስተዳደር'**
  String get adminAccountTitle;

  /// No description provided for @adminActionsHeader.
  ///
  /// In am, this message translates to:
  /// **'የአስተዳዳሪ እርምጃዎች'**
  String get adminActionsHeader;

  /// No description provided for @adminActiveOwners.
  ///
  /// In am, this message translates to:
  /// **'ንቁ ባለቤቶች (30 ቀናት)'**
  String get adminActiveOwners;

  /// No description provided for @adminActor.
  ///
  /// In am, this message translates to:
  /// **'ፈጻሚ አድሚን'**
  String get adminActor;

  /// No description provided for @adminAddBrand.
  ///
  /// In am, this message translates to:
  /// **'አዲስ ዓለም አቀፍ ብራንድ አክል'**
  String get adminAddBrand;

  /// No description provided for @adminAddCategory.
  ///
  /// In am, this message translates to:
  /// **'አዲስ ዓለም አቀፍ ምድብ አክል'**
  String get adminAddCategory;

  /// No description provided for @adminAddUnit.
  ///
  /// In am, this message translates to:
  /// **'አዲስ ዓለም አቀፍ መለኪያ አክል'**
  String get adminAddUnit;

  /// No description provided for @adminAnnouncementActive.
  ///
  /// In am, this message translates to:
  /// **'ማስታወቂያው ይሰራጭ'**
  String get adminAnnouncementActive;

  /// No description provided for @adminAnnouncementActiveDesc.
  ///
  /// In am, this message translates to:
  /// **'ሲበራ ይሄ ማስታወቂያ ለሁሉም የመተግበሪያው ተጠቃሚዎች ይታያል'**
  String get adminAnnouncementActiveDesc;

  /// No description provided for @adminAnnouncementBodyAm.
  ///
  /// In am, this message translates to:
  /// **'የማስታወቂያ ዝርዝር (በአማርኛ)'**
  String get adminAnnouncementBodyAm;

  /// No description provided for @adminAnnouncementBodyEn.
  ///
  /// In am, this message translates to:
  /// **'የማስታወቂያ ዝርዝር (በእንግሊዝኛ)'**
  String get adminAnnouncementBodyEn;

  /// No description provided for @adminAnnouncementDesc.
  ///
  /// In am, this message translates to:
  /// **'ለመተግበሪያ ተጠቃሚዎች ማስታወቂያ ወይም ማንቂያ ማስተላለፊያ'**
  String get adminAnnouncementDesc;

  /// No description provided for @adminAnnouncementSettings.
  ///
  /// In am, this message translates to:
  /// **'አጠቃላይ ማስታወቂያ'**
  String get adminAnnouncementSettings;

  /// No description provided for @adminAnnouncementTitleAm.
  ///
  /// In am, this message translates to:
  /// **'የማስታወቂያ ርዕስ (በአማርኛ)'**
  String get adminAnnouncementTitleAm;

  /// No description provided for @adminAnnouncementTitleEn.
  ///
  /// In am, this message translates to:
  /// **'የማስታወቂያ ርዕስ (በእንግሊዝኛ)'**
  String get adminAnnouncementTitleEn;

  /// No description provided for @adminAppSettingsTitle.
  ///
  /// In am, this message translates to:
  /// **'የመተግበሪያ ቅንብሮች'**
  String get adminAppSettingsTitle;

  /// No description provided for @adminAppVersion.
  ///
  /// In am, this message translates to:
  /// **'የመተግበሪያ ስሪት'**
  String get adminAppVersion;

  /// No description provided for @adminAppVersionsInUse.
  ///
  /// In am, this message translates to:
  /// **'በስራ ላይ ያሉ የመተግበሪያ ስሪቶች'**
  String get adminAppVersionsInUse;

  /// No description provided for @adminAuditDetailTitle.
  ///
  /// In am, this message translates to:
  /// **'የኦዲት መዝገብ ዝርዝር'**
  String get adminAuditDetailTitle;

  /// No description provided for @adminAuditHistoryForUser.
  ///
  /// In am, this message translates to:
  /// **'የዚህ ተጠቃሚ የኦዲት ታሪክ'**
  String get adminAuditHistoryForUser;

  /// No description provided for @adminAuditLogs.
  ///
  /// In am, this message translates to:
  /// **'የኦዲት መዝገቦች'**
  String get adminAuditLogs;

  /// No description provided for @adminAuditLogsEmpty.
  ///
  /// In am, this message translates to:
  /// **'ምንም የኦዲት መዝገብ አልተገኘም'**
  String get adminAuditLogsEmpty;

  /// No description provided for @adminAuditLogsTitle.
  ///
  /// In am, this message translates to:
  /// **'የስርዓቱ ኦዲት መዝገብ'**
  String get adminAuditLogsTitle;

  /// No description provided for @adminCatalog.
  ///
  /// In am, this message translates to:
  /// **'ካታሎግ'**
  String get adminCatalog;

  /// No description provided for @adminCatalogTitle.
  ///
  /// In am, this message translates to:
  /// **'አጠቃላይ የካታሎግ አስተዳደር'**
  String get adminCatalogTitle;

  /// No description provided for @adminConfirmPhoneLabel.
  ///
  /// In am, this message translates to:
  /// **'ስልክ ቁጥሩን በትክክል ያስገቡ'**
  String get adminConfirmPhoneLabel;

  /// No description provided for @adminDashboard.
  ///
  /// In am, this message translates to:
  /// **'ዳሽቦርድ'**
  String get adminDashboard;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In am, this message translates to:
  /// **'የአስተዳዳሪ ዳሽቦርድ'**
  String get adminDashboardTitle;

  /// No description provided for @adminDate.
  ///
  /// In am, this message translates to:
  /// **'ቀን እና ሰዓት'**
  String get adminDate;

  /// No description provided for @adminDisableAccount.
  ///
  /// In am, this message translates to:
  /// **'አካውንት ዝጋ'**
  String get adminDisableAccount;

  /// No description provided for @adminDisableAccountTitle.
  ///
  /// In am, this message translates to:
  /// **'የባለቤቱን አካውንት ሙሉ ለሙሉ መዝጋት'**
  String get adminDisableAccountTitle;

  /// No description provided for @adminDisableConfirm.
  ///
  /// In am, this message translates to:
  /// **'ተረድቻለሁ፣ አካውንቱ ይዘጋ'**
  String get adminDisableConfirm;

  /// Confirmation prompt when disabling account
  ///
  /// In am, this message translates to:
  /// **'አካውንቱን ሙሉ ለሙሉ መዝጋት ለማረጋገጥ፣ የባለቤቱን ስልክ ቁጥር ({phone}) በትክክል ያስገቡ:'**
  String adminDisableWarningPrompt(String phone);

  /// No description provided for @adminEditOwnerTitle.
  ///
  /// In am, this message translates to:
  /// **'የባለቤቱን መረጃ አሻሽል'**
  String get adminEditOwnerTitle;

  /// No description provided for @adminEnforceMinVersion.
  ///
  /// In am, this message translates to:
  /// **'ዝቅተኛ ስሪት አስገድድ'**
  String get adminEnforceMinVersion;

  /// No description provided for @adminEnforceMinVersionDesc.
  ///
  /// In am, this message translates to:
  /// **'ከዚህ ስሪት በታች የሚጠቀሙ ተጠቃሚዎች መተግበሪያውን እንዳይጠቀሙ ያግዳል'**
  String get adminEnforceMinVersionDesc;

  /// No description provided for @adminFailedSyncCount.
  ///
  /// In am, this message translates to:
  /// **'ያልተሳካ ማመሳሰል ብዛት'**
  String get adminFailedSyncCount;

  /// No description provided for @adminFilterActive.
  ///
  /// In am, this message translates to:
  /// **'ንቁ'**
  String get adminFilterActive;

  /// No description provided for @adminFilterAll.
  ///
  /// In am, this message translates to:
  /// **'ሁሉም'**
  String get adminFilterAll;

  /// No description provided for @adminFilterInactive30d.
  ///
  /// In am, this message translates to:
  /// **'የቆሙ (>30 ቀናት)'**
  String get adminFilterInactive30d;

  /// No description provided for @adminFilterSuspended.
  ///
  /// In am, this message translates to:
  /// **'የታገዱ'**
  String get adminFilterSuspended;

  /// No description provided for @adminIpAddress.
  ///
  /// In am, this message translates to:
  /// **'የአይፒ አድራሻ'**
  String get adminIpAddress;

  /// No description provided for @adminLastSync.
  ///
  /// In am, this message translates to:
  /// **'የመጨረሻ ማመሳሰል'**
  String get adminLastSync;

  /// No description provided for @adminMaintenanceActive.
  ///
  /// In am, this message translates to:
  /// **'የጥገና ሁነታ ይብራ'**
  String get adminMaintenanceActive;

  /// No description provided for @adminMaintenanceActiveDesc.
  ///
  /// In am, this message translates to:
  /// **'የደመና ማመሳሰልን ያቆማል እንዲሁም በመተግበሪያዎች ላይ የጥገና መልዕክት ያሳያል'**
  String get adminMaintenanceActiveDesc;

  /// No description provided for @adminMaintenanceDesc.
  ///
  /// In am, this message translates to:
  /// **'የደመና ማመሳሰል የጥገና ሁነታ ቁጥጥር'**
  String get adminMaintenanceDesc;

  /// No description provided for @adminMaintenanceMessageAm.
  ///
  /// In am, this message translates to:
  /// **'የጥገና መልዕክት (በአማርኛ)'**
  String get adminMaintenanceMessageAm;

  /// No description provided for @adminMaintenanceMessageEn.
  ///
  /// In am, this message translates to:
  /// **'የጥገና መልዕክት (በእንግሊዝኛ)'**
  String get adminMaintenanceMessageEn;

  /// No description provided for @adminMaintenanceMode.
  ///
  /// In am, this message translates to:
  /// **'የጥገና ሁነታ'**
  String get adminMaintenanceMode;

  /// No description provided for @adminMinAppVersion.
  ///
  /// In am, this message translates to:
  /// **'ዝቅተኛ የመተግበሪያ ስሪት'**
  String get adminMinAppVersion;

  /// No description provided for @adminMinAppVersionDesc.
  ///
  /// In am, this message translates to:
  /// **'በሲስተሙ የሚፈቀደው ዝቅተኛውን የመተግበሪያ ስሪት ያስቀምጡ'**
  String get adminMinAppVersionDesc;

  /// No description provided for @adminMore.
  ///
  /// In am, this message translates to:
  /// **'ተጨማሪ'**
  String get adminMore;

  /// No description provided for @adminNewThisWeek.
  ///
  /// In am, this message translates to:
  /// **'በዚህ ሳምንት አዲስ'**
  String get adminNewThisWeek;

  /// No description provided for @adminNewValue.
  ///
  /// In am, this message translates to:
  /// **'አዲሱ እሴት'**
  String get adminNewValue;

  /// No description provided for @adminNoAuditLogs.
  ///
  /// In am, this message translates to:
  /// **'ምንም የኦዲት መዝገብ አልተገኘም'**
  String get adminNoAuditLogs;

  /// No description provided for @adminNoOwnersFound.
  ///
  /// In am, this message translates to:
  /// **'ምንም የተመዘገቡ የሱቅ ባለቤቶች አልተገኙም'**
  String get adminNoOwnersFound;

  /// No description provided for @adminNoVersionsRecorded.
  ///
  /// In am, this message translates to:
  /// **'ምንም የመተግበሪያ ስሪት መረጃ አልተመዘገበም'**
  String get adminNoVersionsRecorded;

  /// No description provided for @adminOldValue.
  ///
  /// In am, this message translates to:
  /// **'የነበረው እሴት'**
  String get adminOldValue;

  /// No description provided for @adminOwnerDetailsTitle.
  ///
  /// In am, this message translates to:
  /// **'የባለቤቱ ዝርዝር መረጃ'**
  String get adminOwnerDetailsTitle;

  /// No description provided for @adminOwnerReactivatedSuccess.
  ///
  /// In am, this message translates to:
  /// **'የተጠቃሚው እገዳ በተሳካ ሁኔታ ተነስቷል'**
  String get adminOwnerReactivatedSuccess;

  /// No description provided for @adminOwnerSuspendedSuccess.
  ///
  /// In am, this message translates to:
  /// **'የተጠቃሚው አካውንት በተሳካ ሁኔታ ታግዷል'**
  String get adminOwnerSuspendedSuccess;

  /// No description provided for @adminOwnerUpdatedSuccess.
  ///
  /// In am, this message translates to:
  /// **'የተጠቃሚው መረጃ በተሳካ ሁኔታ ተሻሽሏል'**
  String get adminOwnerUpdatedSuccess;

  /// No description provided for @adminOwners.
  ///
  /// In am, this message translates to:
  /// **'የሱቅ ባለቤቶች'**
  String get adminOwners;

  /// No description provided for @adminOwnersTitle.
  ///
  /// In am, this message translates to:
  /// **'የሱቅ ባለቤቶች ማውጫ'**
  String get adminOwnersTitle;

  /// No description provided for @adminPasswordChangedSuccess.
  ///
  /// In am, this message translates to:
  /// **'የይለፍ ቃል በተሳካ ሁኔታ ተቀይሯል'**
  String get adminPasswordChangedSuccess;

  /// No description provided for @adminPhoneConfirmationMismatch.
  ///
  /// In am, this message translates to:
  /// **'ያስገቡት ስልክ ቁጥር ከባለቤቱ ስልክ ቁጥር ጋር አይመሳሰልም'**
  String get adminPhoneConfirmationMismatch;

  /// No description provided for @adminPortalTitle.
  ///
  /// In am, this message translates to:
  /// **'የአስተዳዳሪ ፖርታል'**
  String get adminPortalTitle;

  /// No description provided for @adminReactivate.
  ///
  /// In am, this message translates to:
  /// **'እገዳ አንሳ'**
  String get adminReactivate;

  /// No description provided for @adminReactivateConfirm.
  ///
  /// In am, this message translates to:
  /// **'እገዳ አንሳ'**
  String get adminReactivateConfirm;

  /// No description provided for @adminReactivateOwnerTitle.
  ///
  /// In am, this message translates to:
  /// **'የተጠቃሚ እገዳ ማንሳት'**
  String get adminReactivateOwnerTitle;

  /// No description provided for @adminReactivatePrompt.
  ///
  /// In am, this message translates to:
  /// **'ይህን ተጠቃሚ እገዳ ማንሳት ይፈልጋሉ? ባለቤቱ ወዲያውኑ አገልግሎቱን ማግኘት ይችላል።'**
  String get adminReactivatePrompt;

  /// No description provided for @adminReason.
  ///
  /// In am, this message translates to:
  /// **'ምክንያት'**
  String get adminReason;

  /// No description provided for @adminReasonRequired.
  ///
  /// In am, this message translates to:
  /// **'እባክዎ ምክንያት ይግለጹ'**
  String get adminReasonRequired;

  /// No description provided for @adminRegisteredDate.
  ///
  /// In am, this message translates to:
  /// **'የተመዘገበበት ቀን'**
  String get adminRegisteredDate;

  /// No description provided for @adminRenameItem.
  ///
  /// In am, this message translates to:
  /// **'ስም ቀይር'**
  String get adminRenameItem;

  /// No description provided for @adminResetPassword.
  ///
  /// In am, this message translates to:
  /// **'የይለፍ ቃል ቀይር'**
  String get adminResetPassword;

  /// No description provided for @adminResetPasswordConfirm.
  ///
  /// In am, this message translates to:
  /// **'ጊዜያዊ የይለፍ ቃል ፍጠር'**
  String get adminResetPasswordConfirm;

  /// No description provided for @adminResetPasswordPrompt.
  ///
  /// In am, this message translates to:
  /// **'ይህ እርምጃ አሁን ያለውን የይለፍ ቃል ይሰርዛል፤ በሚቀጥለው ግባ ጊዜ የሚቀየር ጊዜያዊ የይለፍ ቃል ይሰጣል።'**
  String get adminResetPasswordPrompt;

  /// No description provided for @adminResetPasswordTitle.
  ///
  /// In am, this message translates to:
  /// **'የባለቤቱን የይለፍ ቃል መቀየር'**
  String get adminResetPasswordTitle;

  /// No description provided for @adminSearchOwnersHint.
  ///
  /// In am, this message translates to:
  /// **'በስልክ ቁጥር ወይም በንግድ ስም ይፈልጉ...'**
  String get adminSearchOwnersHint;

  /// No description provided for @adminSettings.
  ///
  /// In am, this message translates to:
  /// **'ቅንብሮች'**
  String get adminSettings;

  /// No description provided for @adminStatusActive.
  ///
  /// In am, this message translates to:
  /// **'ንቁ'**
  String get adminStatusActive;

  /// No description provided for @adminStatusSuspended.
  ///
  /// In am, this message translates to:
  /// **'የታገደ'**
  String get adminStatusSuspended;

  /// No description provided for @adminSuspend.
  ///
  /// In am, this message translates to:
  /// **'አካውንት አግድ'**
  String get adminSuspend;

  /// No description provided for @adminSuspendConfirm.
  ///
  /// In am, this message translates to:
  /// **'አካውንቱን አግድ'**
  String get adminSuspendConfirm;

  /// No description provided for @adminSuspendOwnerTitle.
  ///
  /// In am, this message translates to:
  /// **'የሱቅ ባለቤቱን ማገድ'**
  String get adminSuspendOwnerTitle;

  /// No description provided for @adminSuspendPrompt.
  ///
  /// In am, this message translates to:
  /// **'ተጠቃሚውን ማገድ ወዲያውኑ መግባትና ማመሳሰልን ያግዳል፤ እባክዎ ምክንያቱን ያስገቡ:'**
  String get adminSuspendPrompt;

  /// No description provided for @adminSuspendedOwners.
  ///
  /// In am, this message translates to:
  /// **'የታገዱ ባለቤቶች'**
  String get adminSuspendedOwners;

  /// No description provided for @adminSuspensionReasonHint.
  ///
  /// In am, this message translates to:
  /// **'ለምሳሌ፦ ክፍያ አልተፈጸመም ወይም የተሳሳተ አጠቃቀም'**
  String get adminSuspensionReasonHint;

  /// No description provided for @adminSuspensionReasonLabel.
  ///
  /// In am, this message translates to:
  /// **'የእገዳ ምክንያት'**
  String get adminSuspensionReasonLabel;

  /// Relative sync time in days
  ///
  /// In am, this message translates to:
  /// **'ከ{days} ቀናት በፊት'**
  String adminSyncDaysAgo(String days);

  /// No description provided for @adminSyncHealth.
  ///
  /// In am, this message translates to:
  /// **'የማመሳሰል ጤንነት'**
  String get adminSyncHealth;

  /// No description provided for @adminSyncHealthyMessage.
  ///
  /// In am, this message translates to:
  /// **'ሁሉም የማመሳሰል ሂደቶች ጤናማ ናቸው'**
  String get adminSyncHealthyMessage;

  /// Relative sync time in hours
  ///
  /// In am, this message translates to:
  /// **'ከ{hours} ሰዓታት በፊት'**
  String adminSyncHoursAgo(String hours);

  /// No description provided for @adminSyncJustNow.
  ///
  /// In am, this message translates to:
  /// **'አሁን'**
  String get adminSyncJustNow;

  /// Relative sync time in minutes
  ///
  /// In am, this message translates to:
  /// **'ከ{minutes} ደቂቃ በፊት'**
  String adminSyncMinutesAgo(String minutes);

  /// Relative sync time in months
  ///
  /// In am, this message translates to:
  /// **'ከ{months} ወራት በፊት'**
  String adminSyncMonthsAgo(String months);

  /// No description provided for @adminSyncNever.
  ///
  /// In am, this message translates to:
  /// **'እስካሁን አልተመሳሰለም'**
  String get adminSyncNever;

  /// Count of owners with sync problems
  ///
  /// In am, this message translates to:
  /// **'{count} ባለቤቶች ላይ የማመሳሰል መዘግየት ወይም ችግር አለ'**
  String adminSyncProblemsCount(String count);

  /// No description provided for @adminSystemStatistics.
  ///
  /// In am, this message translates to:
  /// **'አጠቃላይ የስርዓቱ አሃዛዊ መረጃዎች'**
  String get adminSystemStatistics;

  /// No description provided for @adminTabBrands.
  ///
  /// In am, this message translates to:
  /// **'ብራንዶች'**
  String get adminTabBrands;

  /// No description provided for @adminTabCategories.
  ///
  /// In am, this message translates to:
  /// **'ምድቦች'**
  String get adminTabCategories;

  /// No description provided for @adminTabUnits.
  ///
  /// In am, this message translates to:
  /// **'መለኪያዎች'**
  String get adminTabUnits;

  /// No description provided for @adminTargetOwner.
  ///
  /// In am, this message translates to:
  /// **'ተጠቃሚ'**
  String get adminTargetOwner;

  /// No description provided for @adminTempPasswordTitle.
  ///
  /// In am, this message translates to:
  /// **'ጊዜያዊ የይለፍ ቃል ተፈጥሯል'**
  String get adminTempPasswordTitle;

  /// No description provided for @adminTempPasswordWarning.
  ///
  /// In am, this message translates to:
  /// **'ይህንን የይለፍ ቃል በጥንቃቄ ለባለቤቱ ያጋሩ። ደግሞ አይታይም!'**
  String get adminTempPasswordWarning;

  /// No description provided for @adminTenantCountsOnly.
  ///
  /// In am, this message translates to:
  /// **'የስርዓቱ ጠቅላላ ድምር (የተጠቃሚ ዳታ አይታይም)'**
  String get adminTenantCountsOnly;

  /// No description provided for @adminTenantOverview.
  ///
  /// In am, this message translates to:
  /// **'የተጠቃሚዎች አጠቃላይ እይታ'**
  String get adminTenantOverview;

  /// No description provided for @adminTotalOwners.
  ///
  /// In am, this message translates to:
  /// **'ጠቅላላ ባለቤቶች'**
  String get adminTotalOwners;

  /// No description provided for @adminTotalPartsCount.
  ///
  /// In am, this message translates to:
  /// **'ጠቅላላ ዕቃዎች (ድምር)'**
  String get adminTotalPartsCount;

  /// No description provided for @adminTotalSalesCount.
  ///
  /// In am, this message translates to:
  /// **'ጠቅላላ ሽያጭ (ድምር)'**
  String get adminTotalSalesCount;

  /// No description provided for @adminVersionStringLabel.
  ///
  /// In am, this message translates to:
  /// **'የስሪት መለያ ቁጥር (ምሳሌ 1.0.0)'**
  String get adminVersionStringLabel;

  /// No description provided for @copiedToClipboard.
  ///
  /// In am, this message translates to:
  /// **'ኮፒ ተደርጓል'**
  String get copiedToClipboard;

  /// No description provided for @copy.
  ///
  /// In am, this message translates to:
  /// **'ኮፒ አድርግ'**
  String get copy;

  /// No description provided for @error.
  ///
  /// In am, this message translates to:
  /// **'ስህተት'**
  String get error;

  /// No description provided for @logoutConfirmation.
  ///
  /// In am, this message translates to:
  /// **'ከአስተዳዳሪ መለያዎ መውጣት እርግጠኛ ነዎት?'**
  String get logoutConfirmation;

  /// No description provided for @name.
  ///
  /// In am, this message translates to:
  /// **'ስም'**
  String get name;

  /// No description provided for @next.
  ///
  /// In am, this message translates to:
  /// **'ቀጣይ'**
  String get next;

  /// No description provided for @noResultsFound.
  ///
  /// In am, this message translates to:
  /// **'ምንም አልተገኘም'**
  String get noResultsFound;

  /// No description provided for @page.
  ///
  /// In am, this message translates to:
  /// **'ገጽ'**
  String get page;

  /// No description provided for @previous.
  ///
  /// In am, this message translates to:
  /// **'ቀዳሚ'**
  String get previous;

  /// No description provided for @required.
  ///
  /// In am, this message translates to:
  /// **'አስፈላጊ'**
  String get required;

  /// No description provided for @success.
  ///
  /// In am, this message translates to:
  /// **'ተሳክቷል'**
  String get success;

  /// No description provided for @totalEntries.
  ///
  /// In am, this message translates to:
  /// **'ጠቅላላ መዝገቦች'**
  String get totalEntries;

  /// Banner message when refresh token expired or revoked
  ///
  /// In am, this message translates to:
  /// **'ማመሳሰልን ለመቀጠል እባክዎ እንደገና ይግቡ'**
  String get authNeedsLoginBanner;

  /// Action button on needsLogin banner
  ///
  /// In am, this message translates to:
  /// **'ግባ'**
  String get authNeedsLoginAction;

  /// Offline message on register/login
  ///
  /// In am, this message translates to:
  /// **'ለመመዝገብ ወይም ለመግባት የበይነመረብ ግንኙነት ያስፈልጋል።'**
  String get authOfflineInternetRequired;

  /// Title for conflict when logging in as different owner with pending sync
  ///
  /// In am, this message translates to:
  /// **'ያልተመሳሰለ የመለያ ውሂብ'**
  String get authDifferentOwnerConflictTitle;

  /// Message for conflict when logging in as different owner with pending sync
  ///
  /// In am, this message translates to:
  /// **'ይህ ስልክ ካልተመሳሰለ ሌላ መለያ ({ownerName}) ውሂብ ይዟል። ለማመሳሰል እባክዎ በቀዳሚው መለያ ይግቡ ወይም ለመቀጠል ያልተመሳሰለውን ውሂብ ያጥፉ።'**
  String authDifferentOwnerConflictMessage(String ownerName);

  /// Button to discard unsynced data and log in with new owner
  ///
  /// In am, this message translates to:
  /// **'ውሂቡን አጥፋና ግባ'**
  String get authDiscardUnsyncedAndLogin;

  /// Warning message when offline duration exceeds max days
  ///
  /// In am, this message translates to:
  /// **'መተግበሪያው ከመስመር ውጭ ከ{days} ቀናት በላይ ቆይቷል። መለያዎን ለማረጋገጥ እባክዎ ከበይነመረብ ጋር ይገናኙ።'**
  String authOfflineMaxDaysWarning(int days);

  /// Initial sync title
  ///
  /// In am, this message translates to:
  /// **'የእርስዎን እቃዎች በማዘጋጀት ላይ...'**
  String get initialSyncTitle;

  /// Initial sync subtitle
  ///
  /// In am, this message translates to:
  /// **'የእርስዎን የእቃዎች ዝርዝር ከአገልጋይ በማውረድ ላይ'**
  String get initialSyncSubtitle;

  /// Title when logout is blocked due to offline pending changes
  ///
  /// In am, this message translates to:
  /// **'መውጣት አልተቻለም (ኢንተርኔት የለም)'**
  String get logoutBlockedOfflineTitle;

  /// Message explaining why offline logout with pending changes is blocked
  ///
  /// In am, this message translates to:
  /// **'ያልተመሳሰሉ {count} ለውጦች አሉ። ከመስመር ውጭ ሆነው ከወጡ ለውጦችዎ ወደ አገልጋዩ ስለማይላኩ ስራዎ በቋሚነት ይጠፋል።'**
  String logoutBlockedOfflineMessage(int count);

  /// Export data action button in logout blocked dialog
  ///
  /// In am, this message translates to:
  /// **'መረጃን አውጣ (CSV)'**
  String get exportDataAction;

  /// Prompt requiring typing DISCARD
  ///
  /// In am, this message translates to:
  /// **'ያልተመሳሰሉ ለውጦችን አጥፍተው ለመውጣት ከታች DISCARD ብለው ይጻፉ:'**
  String get logoutDiscardPrompt;

  /// Button to confirm discarding unsynced changes and logging out
  ///
  /// In am, this message translates to:
  /// **'አጥፍተህ ውጣ'**
  String get logoutDiscardButton;

  /// Title when logout has pending changes while online
  ///
  /// In am, this message translates to:
  /// **'ያልተመሳሰሉ ለውጦች አሉ'**
  String get logoutPendingOnlineTitle;

  /// Message showing pending count when online
  ///
  /// In am, this message translates to:
  /// **'ወደ አገልጋዩ ያልተላኩ {count} ያልተመሳሰሉ ለውጦች አሉ።'**
  String logoutPendingOnlineMessage(int count);

  /// Button to sync changes then log out
  ///
  /// In am, this message translates to:
  /// **'አሁን አመሳስልና ውጣ'**
  String get syncNowAndLogout;

  /// Notice when sync fails during logout
  ///
  /// In am, this message translates to:
  /// **'ማመሳሰል አልተሳካም: {reason}። ለውጦችዎ እንዳይጠፉ አልወጡም።'**
  String syncFailedLogoutCancelled(String reason);

  /// Settings label for sync status
  ///
  /// In am, this message translates to:
  /// **'የማመሳሰል ሁኔታ'**
  String get syncStatusTitle;

  /// Sync status when queue is empty
  ///
  /// In am, this message translates to:
  /// **'ሁሉም ለውጦች ተመሳስለዋል'**
  String get syncStatusUpToDate;

  /// Sync status when queue has items
  ///
  /// In am, this message translates to:
  /// **'{count} ያልተመሳሰሉ ለውጦች'**
  String syncStatusPending(int count);

  /// Sync status while pushing mutations
  ///
  /// In am, this message translates to:
  /// **'ለውጦች በመመሳሰል ላይ ናቸው...'**
  String get syncStatusSyncing;

  /// Settings label for last online time
  ///
  /// In am, this message translates to:
  /// **'ለመጨረሻ ጊዜ የተገናኘበት'**
  String get lastOnlineTitle;

  /// Settings label for pending changes count
  ///
  /// In am, this message translates to:
  /// **'ያልተላኩ ለውጦች'**
  String get pendingChangesCount;

  /// Title for password changed remotely banner
  ///
  /// In am, this message translates to:
  /// **'የይለፍ ቃል በሌላ ቦታ ተቀይሯል'**
  String get passwordChangedRemotelyTitle;

  /// Message for password changed remotely banner
  ///
  /// In am, this message translates to:
  /// **'የይለፍ ቃልዎ በሌላ ስልክ ተቀይሯል። ማመሳሰልን ለማስቀጠል በአዲሱ የይለፍ ቃል ይግቡ። የአካባቢ መረጃዎ ደህንነቱ የተጠበቀ ነው።'**
  String get passwordChangedRemotelyMessage;

  /// No description provided for @appLockTitle.
  ///
  /// In am, this message translates to:
  /// **'መተግበሪያ ቆልፍ'**
  String get appLockTitle;

  /// No description provided for @appLockSubtitle.
  ///
  /// In am, this message translates to:
  /// **'መተግበሪያውን በፒን ወይም በባዮሜትሪክስ ይጠብቁ'**
  String get appLockSubtitle;

  /// No description provided for @appLockEnabled.
  ///
  /// In am, this message translates to:
  /// **'የመተግበሪያ መቆለፊያ ነቅቷል'**
  String get appLockEnabled;

  /// No description provided for @appLockDisabled.
  ///
  /// In am, this message translates to:
  /// **'የመተግበሪያ መቆለፊያ ጠፍቷል'**
  String get appLockDisabled;

  /// No description provided for @appLockBiometrics.
  ///
  /// In am, this message translates to:
  /// **'ባዮሜትሪክስ መክፈቻ'**
  String get appLockBiometrics;

  /// No description provided for @appLockBiometricsDesc.
  ///
  /// In am, this message translates to:
  /// **'ለመክፈት የጣት አሻራ ወይም የፊት ገጽታ ይጠቀሙ'**
  String get appLockBiometricsDesc;

  /// No description provided for @appLockTimeout.
  ///
  /// In am, this message translates to:
  /// **'ራስ-ሰር የመቆለፊያ ጊዜ'**
  String get appLockTimeout;

  /// No description provided for @appLockTimeoutImmediately.
  ///
  /// In am, this message translates to:
  /// **'ወዲያውኑ'**
  String get appLockTimeoutImmediately;

  /// No description provided for @appLockTimeout1Min.
  ///
  /// In am, this message translates to:
  /// **'ከ1 ደቂቃ በኋላ'**
  String get appLockTimeout1Min;

  /// No description provided for @appLockTimeout5Min.
  ///
  /// In am, this message translates to:
  /// **'ከ5 ደቂቃ በኋላ'**
  String get appLockTimeout5Min;

  /// No description provided for @changePin.
  ///
  /// In am, this message translates to:
  /// **'ፒን ይቀይሩ'**
  String get changePin;

  /// No description provided for @setPinTitle.
  ///
  /// In am, this message translates to:
  /// **'የመተግበሪያ ፒን ያዘጋጁ'**
  String get setPinTitle;

  /// No description provided for @enterNewPin.
  ///
  /// In am, this message translates to:
  /// **'ከ4 እስከ 6 አሃዝ ፒን ያስገቡ'**
  String get enterNewPin;

  /// No description provided for @confirmPinTitle.
  ///
  /// In am, this message translates to:
  /// **'የመተግበሪያ ፒን ያረጋግጡ'**
  String get confirmPinTitle;

  /// No description provided for @reenterPin.
  ///
  /// In am, this message translates to:
  /// **'ፒንዎን በድጋሚ ያስገቡ'**
  String get reenterPin;

  /// No description provided for @pinsDoNotMatch.
  ///
  /// In am, this message translates to:
  /// **'ፒኖቹ አይመሳሰሉም። እባክዎ እንደገና ይሞክሩ።'**
  String get pinsDoNotMatch;

  /// No description provided for @pinLengthError.
  ///
  /// In am, this message translates to:
  /// **'ፒኑ ከ4 እስከ 6 አሃዝ መሆን አለበት።'**
  String get pinLengthError;

  /// No description provided for @pinSetSuccess.
  ///
  /// In am, this message translates to:
  /// **'የመተግበሪያ ፒን በተሳካ ሁኔታ ተቀይሯል።'**
  String get pinSetSuccess;

  /// No description provided for @enterPinToUnlock.
  ///
  /// In am, this message translates to:
  /// **'ለመክፈት ፒን ያስገቡ'**
  String get enterPinToUnlock;

  /// No description provided for @wrongPin.
  ///
  /// In am, this message translates to:
  /// **'የተሳሳተ ፒን ነው። {remaining} ሙከራዎች ቀርተዋል።'**
  String wrongPin(int remaining);

  /// No description provided for @lockoutCooldown.
  ///
  /// In am, this message translates to:
  /// **'ብዙ የተሳሳቱ ሙከራዎች። ከ{seconds} ሰከንድ በኋላ እንደገና ይሞክሩ።'**
  String lockoutCooldown(int seconds);

  /// No description provided for @lockoutMaxReached.
  ///
  /// In am, this message translates to:
  /// **'ከፍተኛ የተሳሳቱ ሙከራዎች ተደርገዋል። በመስመር ላይ መግባት ያስፈልጋል።'**
  String get lockoutMaxReached;

  /// No description provided for @forgotPin.
  ///
  /// In am, this message translates to:
  /// **'ፒን ረሱ?'**
  String get forgotPin;

  /// No description provided for @forgotPinTitle.
  ///
  /// In am, this message translates to:
  /// **'የመተግበሪያ ፒን ዳግም ያስጀምሩ'**
  String get forgotPinTitle;

  /// No description provided for @forgotPinDesc.
  ///
  /// In am, this message translates to:
  /// **'ፒንዎን ዳግም ለማስጀመር በስልክ ቁጥርዎ እና በይለፍ ቃልዎ ይግቡ። የአካባቢዎ መረጃ ይጠበቃል።'**
  String get forgotPinDesc;

  /// No description provided for @biometricPromptReason.
  ///
  /// In am, this message translates to:
  /// **'ኬራ ስፔር ትራከርን ለመክፈት የጣት አሻራዎን ወይም ፊትዎን ያረጋግጡ'**
  String get biometricPromptReason;

  /// No description provided for @unlockWithBiometrics.
  ///
  /// In am, this message translates to:
  /// **'በባዮሜትሪክስ ይክፈቱ'**
  String get unlockWithBiometrics;

  /// No description provided for @loginToResetPin.
  ///
  /// In am, this message translates to:
  /// **'ያረጋግጡ እና ፒን ዳግም ያስጀምሩ'**
  String get loginToResetPin;

  /// No description provided for @adminAuditActionUserSuspended.
  ///
  /// In am, this message translates to:
  /// **'ተጠቃሚ ታግዷል'**
  String get adminAuditActionUserSuspended;

  /// No description provided for @adminAuditActionUserReactivated.
  ///
  /// In am, this message translates to:
  /// **'እገዳ ተነስቷል'**
  String get adminAuditActionUserReactivated;

  /// No description provided for @adminAuditActionPasswordReset.
  ///
  /// In am, this message translates to:
  /// **'የይለፍ ቃል ተቀይሯል'**
  String get adminAuditActionPasswordReset;

  /// No description provided for @adminAuditActionUserDeleted.
  ///
  /// In am, this message translates to:
  /// **'አካውንት ተዘግቷል'**
  String get adminAuditActionUserDeleted;

  /// No description provided for @adminAuditActionBrandCreated.
  ///
  /// In am, this message translates to:
  /// **'ብራንድ ተፈጠረ'**
  String get adminAuditActionBrandCreated;

  /// No description provided for @adminAuditActionBrandUpdated.
  ///
  /// In am, this message translates to:
  /// **'ብራንድ ተሻሻለ'**
  String get adminAuditActionBrandUpdated;

  /// No description provided for @adminAuditActionCategoryCreated.
  ///
  /// In am, this message translates to:
  /// **'ምድብ ተፈጠረ'**
  String get adminAuditActionCategoryCreated;

  /// No description provided for @adminAuditActionCategoryUpdated.
  ///
  /// In am, this message translates to:
  /// **'ምድብ ተሻሻለ'**
  String get adminAuditActionCategoryUpdated;

  /// No description provided for @adminAuditActionUnitCreated.
  ///
  /// In am, this message translates to:
  /// **'መለኪያ ተፈጠረ'**
  String get adminAuditActionUnitCreated;

  /// No description provided for @adminAuditActionUnitUpdated.
  ///
  /// In am, this message translates to:
  /// **'መለኪያ ተሻሻለ'**
  String get adminAuditActionUnitUpdated;

  /// No description provided for @adminAuditActionSettingsUpdated.
  ///
  /// In am, this message translates to:
  /// **'ቅንብሮች ተሻሻሉ'**
  String get adminAuditActionSettingsUpdated;

  /// No description provided for @adminAuditDetailsTitle.
  ///
  /// In am, this message translates to:
  /// **'የኦዲት መዝገብ ዝርዝር'**
  String get adminAuditDetailsTitle;

  /// No description provided for @adminAuditActor.
  ///
  /// In am, this message translates to:
  /// **'ፈፃሚ'**
  String get adminAuditActor;

  /// No description provided for @adminAuditTarget.
  ///
  /// In am, this message translates to:
  /// **'ዒላማ'**
  String get adminAuditTarget;

  /// No description provided for @adminAuditNoChanges.
  ///
  /// In am, this message translates to:
  /// **'ምንም የተቀየረ እሴት የለም'**
  String get adminAuditNoChanges;

  /// No description provided for @adminAuditToday.
  ///
  /// In am, this message translates to:
  /// **'ዛሬ'**
  String get adminAuditToday;

  /// No description provided for @adminAuditYesterday.
  ///
  /// In am, this message translates to:
  /// **'ትናንት'**
  String get adminAuditYesterday;

  /// No description provided for @adminSyncHealthy.
  ///
  /// In am, this message translates to:
  /// **'ጥሩ ሁኔታ'**
  String get adminSyncHealthy;

  /// No description provided for @adminSyncNeverStarted.
  ///
  /// In am, this message translates to:
  /// **'ገና አልተመሳሰለም'**
  String get adminSyncNeverStarted;

  /// No description provided for @adminSyncNeedsAttention.
  ///
  /// In am, this message translates to:
  /// **'ክትትል ያስፈልገዋል'**
  String get adminSyncNeedsAttention;

  /// No description provided for @adminAppVersionsTitle.
  ///
  /// In am, this message translates to:
  /// **'የተጠቃሚ መተግበሪያ ስሪቶች'**
  String get adminAppVersionsTitle;

  /// No description provided for @adminLastUpdated.
  ///
  /// In am, this message translates to:
  /// **'የመጨረሻ ማሻሻያ'**
  String get adminLastUpdated;

  /// No description provided for @adminNoMoreOwners.
  ///
  /// In am, this message translates to:
  /// **'ሁሉም ባለቤቶች ተጭነዋል'**
  String get adminNoMoreOwners;

  /// No description provided for @adminSortBy.
  ///
  /// In am, this message translates to:
  /// **'አስተካክል በ'**
  String get adminSortBy;

  /// No description provided for @adminSortNewest.
  ///
  /// In am, this message translates to:
  /// **'አዳዲሶች መጀመሪያ'**
  String get adminSortNewest;

  /// No description provided for @adminSortBusinessName.
  ///
  /// In am, this message translates to:
  /// **'የንግድ ስም'**
  String get adminSortBusinessName;

  /// No description provided for @adminSortLastSync.
  ///
  /// In am, this message translates to:
  /// **'የመጨረሻ ማመሳሰል'**
  String get adminSortLastSync;

  /// No description provided for @adminNeverSynced.
  ///
  /// In am, this message translates to:
  /// **'አልተመሳሰለም'**
  String get adminNeverSynced;

  /// No description provided for @adminCatalogItemsCount.
  ///
  /// In am, this message translates to:
  /// **'{count} ዝርዝሮች'**
  String adminCatalogItemsCount(int count);

  /// No description provided for @adminCatalogActiveCount.
  ///
  /// In am, this message translates to:
  /// **'{active} ከ {total} ንቁ'**
  String adminCatalogActiveCount(int active, int total);

  /// No description provided for @adminActiveLabel.
  ///
  /// In am, this message translates to:
  /// **'ንቁ'**
  String get adminActiveLabel;

  /// No description provided for @adminInactiveLabel.
  ///
  /// In am, this message translates to:
  /// **'ቦዝኗል'**
  String get adminInactiveLabel;

  /// No description provided for @adminConfirmDeactivateTitle.
  ///
  /// In am, this message translates to:
  /// **'ዝርዝሩን አቦዝን'**
  String get adminConfirmDeactivateTitle;

  /// No description provided for @adminConfirmDeactivateMessage.
  ///
  /// In am, this message translates to:
  /// **'{name}ን ማቦዘን ይፈልጋሉ? ከባለቤቶች ካታሎግ ውስጥ አይታይም።'**
  String adminConfirmDeactivateMessage(String name);

  /// No description provided for @adminSortAtoZ.
  ///
  /// In am, this message translates to:
  /// **'ከሀ - ፐ'**
  String get adminSortAtoZ;

  /// No description provided for @adminLivePreview.
  ///
  /// In am, this message translates to:
  /// **'የቅድመ እይታ ማሳያ'**
  String get adminLivePreview;

  /// No description provided for @adminUnsavedChangesTitle.
  ///
  /// In am, this message translates to:
  /// **'ያልተቀመጡ ለውጦች'**
  String get adminUnsavedChangesTitle;

  /// No description provided for @adminUnsavedChangesMessage.
  ///
  /// In am, this message translates to:
  /// **'ያልተቀመጡ ለውጦች አሉ። ይቅር ይባሉ?'**
  String get adminUnsavedChangesMessage;

  /// No description provided for @adminDiscard.
  ///
  /// In am, this message translates to:
  /// **'ይቅር'**
  String get adminDiscard;

  /// No description provided for @adminSaveSuccess.
  ///
  /// In am, this message translates to:
  /// **'ቅንብሮቹ በተሳካ ሁኔታ ተቀምጠዋል'**
  String get adminSaveSuccess;

  /// No description provided for @adminVersionHelper.
  ///
  /// In am, this message translates to:
  /// **'አስገዳጅ የሆነው ዝቅተኛ የመተግበሪያ ስሪት (ለምሳሌ 1.0.0)'**
  String get adminVersionHelper;
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

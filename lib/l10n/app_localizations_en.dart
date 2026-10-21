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

  @override
  String get login => 'Log In';

  @override
  String get register => 'Register';

  @override
  String get logout => 'Log Out';

  @override
  String get logoutConfirmTitle => 'Log out of your account?';

  @override
  String get logoutConfirmMessage =>
      'You will need to enter your phone number and password to log in again.';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get phoneNumberHint => '09XXXXXXXX or 07XXXXXXXX';

  @override
  String get businessName => 'Business Name';

  @override
  String get businessNameHint => 'e.g. Kera Spare Parts Store';

  @override
  String get businessNameRequired => 'Business name is required';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'At least 6 characters';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get alreadyHaveAccount => 'Already have an account? Log In';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Register';

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get loginSubtitle => 'Manage your spare parts inventory and sales';

  @override
  String get registerTitle => 'Create Business Account';

  @override
  String get registerSubtitle => 'Track parts and sales seamlessly offline';

  @override
  String get homeTitle => 'Home';

  @override
  String get welcomeUser => 'Welcome';

  @override
  String get inventoryTab => 'Inventory';

  @override
  String get salesTab => 'Sales';

  @override
  String get reportsTab => 'Reports';

  @override
  String get settingsTab => 'Settings';

  @override
  String get businessProfile => 'Business Profile';

  @override
  String get offlineStatusNotice =>
      'All data is securely saved on your device.';

  @override
  String get brandsTitle => 'Brands';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get locationsTitle => 'Storage Locations';

  @override
  String get manageBrandsDesc =>
      'View default brands and manage your custom brands';

  @override
  String get manageCategoriesDesc => 'Organize spare parts into categories';

  @override
  String get manageLocationsDesc => 'Shelves and custom storage locations';

  @override
  String get globalDefaultBadge => 'Default';

  @override
  String get customBadge => 'Custom';

  @override
  String get addBrand => 'Add Brand';

  @override
  String get editBrand => 'Edit Brand';

  @override
  String get deactivateBrand => 'Deactivate Brand';

  @override
  String get deactivateConfirmTitle => 'Deactivate Item?';

  @override
  String get deactivateConfirmMessage =>
      'This item will no longer appear in selection lists.';

  @override
  String get deactivate => 'Deactivate';

  @override
  String get brandName => 'Brand Name';

  @override
  String get brandNameHint => 'e.g. Toyota, CAT, Perkins...';

  @override
  String get addCategory => 'Add Category';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get deactivateCategory => 'Deactivate Category';

  @override
  String get categoryName => 'Category Name';

  @override
  String get categoryNameHint => 'e.g. Engine, Hydraulic, Transmission...';

  @override
  String get addLocation => 'Add Storage Location';

  @override
  String get editLocation => 'Edit Storage Location';

  @override
  String get deactivateLocation => 'Deactivate Storage Location';

  @override
  String get locationName => 'Location / Shelf Name';

  @override
  String get locationNameHint => 'e.g. Shelf 6, Drawer A, Backroom...';

  @override
  String get duplicateNameError => 'An item with this name already exists';

  @override
  String get cannotModifyDefault =>
      'Default items cannot be modified or deactivated';

  @override
  String get selectBrand => 'Select Brand';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get selectLocation => 'Select Location';

  @override
  String get noBrandsFound => 'No brands found';

  @override
  String get noCategoriesFound => 'No categories found';

  @override
  String get noLocationsFound => 'No storage locations found';

  @override
  String get searchBrands => 'Search brands...';

  @override
  String get searchCategories => 'Search categories...';

  @override
  String get searchLocations => 'Search locations...';

  @override
  String get quickAddNew => 'Add New';
}

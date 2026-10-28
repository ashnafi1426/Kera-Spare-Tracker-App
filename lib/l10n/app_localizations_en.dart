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

  @override
  String get addPart => 'Add Spare Part';

  @override
  String get editPart => 'Edit Spare Part';

  @override
  String get partDetails => 'Part Details';

  @override
  String get partName => 'Part Name';

  @override
  String get partNameHint => 'e.g. Hydraulic Pump, Oil Filter...';

  @override
  String get partNumber => 'Part Number';

  @override
  String get partNumberHint => 'e.g. 1R-0716, 9T-0988...';

  @override
  String get brand => 'Brand';

  @override
  String get category => 'Category';

  @override
  String get storageLocation => 'Storage Location';

  @override
  String get customLocation => 'Custom / Specific Spot';

  @override
  String get customLocationHint => 'e.g. Top drawer, corner basket...';

  @override
  String get description => 'Description';

  @override
  String get descriptionHint => 'Brief notes about the part...';

  @override
  String get unit => 'Unit';

  @override
  String get unitHint => 'e.g. pcs, set, meter, liter';

  @override
  String get quantityInStock => 'Quantity in Stock';

  @override
  String get purchasePrice => 'Purchase Price (ETB)';

  @override
  String get sellingPrice => 'Selling Price (ETB)';

  @override
  String get estimatedProfit => 'Estimated Profit';

  @override
  String get sizeSpecs => 'Size / Specifications';

  @override
  String get sizeSpecsHint => 'e.g. 10mm, 24V, Standard...';

  @override
  String get notes => 'Internal Notes';

  @override
  String get notesHint => 'Any additional private notes...';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get removePhoto => 'Remove Photo';

  @override
  String get unsavedChangesTitle => 'Unsaved Changes';

  @override
  String get unsavedChangesMessage =>
      'You have unsaved changes. Are you sure you want to discard them?';

  @override
  String get discard => 'Discard';

  @override
  String get keepEditing => 'Keep Editing';

  @override
  String get deletePart => 'Delete Part';

  @override
  String get deletePartConfirmTitle => 'Delete this spare part?';

  @override
  String get deletePartConfirmMessage =>
      'The part will be removed from active inventory. Past sales records will be preserved.';

  @override
  String get partSavedSuccess => 'Spare part saved successfully';

  @override
  String get partDeletedSuccess => 'Spare part deleted';

  @override
  String get negativeNumberError => 'Value cannot be negative';

  @override
  String get noPhoto => 'No Photo';

  @override
  String get stockStatus => 'Stock Status';

  @override
  String get inStock => 'In Stock';

  @override
  String get outOfStock => 'Out of Stock';

  @override
  String get lowStock => 'Low Stock';

  @override
  String get searchHint => 'Search by name, part #, brand, category, shelf...';

  @override
  String get filters => 'Filters';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortName => 'Name (A - Z)';

  @override
  String get sortNewest => 'Newest first';

  @override
  String get sortQuantityHigh => 'Quantity (Highest first)';

  @override
  String get sortQuantityLow => 'Quantity (Lowest first)';

  @override
  String get sortPriceHigh => 'Price (Highest first)';

  @override
  String get sortPriceLow => 'Price (Lowest first)';

  @override
  String get filterAll => 'All';

  @override
  String get filterInStock => 'In Stock';

  @override
  String get filterLowStock => 'Low Stock';

  @override
  String get filterOutOfStock => 'Out of Stock';

  @override
  String get resetFilters => 'Reset';

  @override
  String get applyFilters => 'Apply';

  @override
  String activeFiltersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filters applied',
      one: '1 filter applied',
    );
    return '$_temp0';
  }

  @override
  String totalPartsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count parts',
      one: '1 part',
    );
    return '$_temp0';
  }

  @override
  String get noFilteredPartsTitle => 'No matching parts found';

  @override
  String get noFilteredPartsDesc =>
      'Try adjusting your search query or filters';

  @override
  String get seedParts => 'Generate 2,000 Test Parts';

  @override
  String get seedPartsDesc =>
      'Instantly generates 2,000 realistic spare parts to test search speed and list performance';

  @override
  String get seedingInProgress => 'Generating 2,000 test parts...';

  @override
  String get seedSuccess => 'Successfully created 2,000 test parts!';

  @override
  String get clearTestParts => 'Clear Test Parts';

  @override
  String get clearTestPartsConfirm =>
      'Are you sure you want to delete all generated test parts?';

  @override
  String get clearTestPartsSuccess => 'Test parts removed successfully';

  @override
  String get updateStock => 'Update Stock';

  @override
  String get addStockPurchase => 'Add Stock (Purchase)';

  @override
  String get removeStock => 'Remove Stock';

  @override
  String get adjustStockCount => 'Adjust to Counted Number';

  @override
  String get stockMovementHistory => 'Movement History';

  @override
  String get quantityToAdd => 'Quantity to Add';

  @override
  String get quantityToRemove => 'Quantity to Remove';

  @override
  String get countedQuantity => 'Counted Quantity';

  @override
  String get unitCost => 'Unit Cost (ETB)';

  @override
  String get reasonOrNote => 'Reason or Note';

  @override
  String get reasonOrNoteHint =>
      'e.g. Supplier delivery, Damaged part, Physical count...';

  @override
  String get currentStock => 'Current Stock';

  @override
  String get difference => 'Difference';

  @override
  String get runningBalance => 'Running Balance';

  @override
  String get recalculateStock => 'Recalculate Stock';

  @override
  String get recalculateStockDesc =>
      'Recalculates cached quantity from the ledger movements for data integrity';

  @override
  String get stockRecalculatedSuccess =>
      'Stock quantity recalculated successfully from ledger';

  @override
  String get allowNegativeStock => 'Allow Negative Stock';

  @override
  String get allowNegativeStockDesc =>
      'Permit stock to go below zero when removing items or recording sales';

  @override
  String get negativeStockWarningTitle => 'Negative Stock Warning';

  @override
  String negativeStockWarningMessage(String newStock) {
    return 'Removing this quantity will result in a negative stock level ($newStock). Do you confirm?';
  }

  @override
  String get negativeStockNotAllowed =>
      'Stock cannot go below zero. Enable negative stock in Settings if needed.';

  @override
  String get lowStockListTitle => 'Low Stock Items';

  @override
  String get lowStockListDesc => 'Items at or below their reorder threshold';

  @override
  String get noLowStockItems =>
      'No low stock items. All inventory levels are healthy!';

  @override
  String get movementTypeInitial => 'Initial Stock';

  @override
  String get movementTypePurchase => 'Purchase';

  @override
  String get movementTypeSale => 'Sale';

  @override
  String get movementTypeAdjustment => 'Adjustment';

  @override
  String get movementTypeReturn => 'Return';

  @override
  String get noMovementsTitle => 'No Movements Yet';

  @override
  String get noMovementsDesc =>
      'Stock movements will appear here when stock is added, removed, or adjusted.';

  @override
  String get newSale => 'New Sale';

  @override
  String get recordSale => 'Record Sale';

  @override
  String get saleDetails => 'Sale Details';

  @override
  String get addPartsToSale => 'Add Parts';

  @override
  String get cartEmptyTitle => 'No Items in Sale';

  @override
  String get cartEmptyDesc => 'Search and add parts to record a sale';

  @override
  String get unitPrice => 'Unit Price';

  @override
  String get lineTotal => 'Total';

  @override
  String get lineProfit => 'Profit';

  @override
  String get totalProfit => 'Total Estimated Profit';

  @override
  String get customerNotes => 'Customer / Receipt Notes';

  @override
  String get customerNotesHint => 'Optional note or customer name...';

  @override
  String get totalItems => 'Total Items';

  @override
  String get totalCost => 'Total Cost';

  @override
  String get completeSale => 'Complete Sale';

  @override
  String get saleSuccessTitle => 'Sale Recorded Successfully!';

  @override
  String get receiptNumber => 'Receipt #';

  @override
  String get soldAt => 'Date & Time';

  @override
  String get noCostWarning => 'No purchase price set; profit may be overstated';

  @override
  String saleStockWarningMessage(
    String partName,
    String stock,
    String newStock,
  ) {
    return 'Quantity for \"$partName\" exceeds current stock ($stock). Stock will become $newStock.';
  }

  @override
  String get saleRecordedSuccess => 'Sale recorded successfully';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get emptySaleError =>
      'Cannot save an empty sale. Please add at least one part.';

  @override
  String get searchAndAddParts => 'Search & Add Parts';

  @override
  String get filterToday => 'Today';

  @override
  String get filterThisWeek => 'This Week';

  @override
  String get filterThisMonth => 'This Month';

  @override
  String get filterCustom => 'Custom';

  @override
  String get selectDateRange => 'Select Date Range';

  @override
  String get searchSalesHint => 'Search by part name or receipt...';

  @override
  String get dayTotal => 'Day Total';

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get noSalesForFilter => 'No sales found for the selected filter';

  @override
  String get saleDetailsTitle => 'Sale Details';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get lineCost => 'Cost';

  @override
  String get deleteSale => 'Delete Sale';

  @override
  String get deleteSaleConfirm => 'Are you sure you want to delete this sale?';

  @override
  String get reportsTitle => 'Reports & Analytics';

  @override
  String get reportDaily => 'Daily';

  @override
  String get reportWeekly => 'Weekly';

  @override
  String get reportMonthly => 'Monthly';

  @override
  String get salesCount => 'Number of Sales';

  @override
  String get totalRevenue => 'Total Revenue';

  @override
  String get topSellingParts => 'Top 5 Selling Parts';

  @override
  String get totalStockValue => 'Total Stock Value';

  @override
  String get lowStockCount => 'Low Stock Count';

  @override
  String unitsSold(String count) {
    return '$count sold';
  }

  @override
  String get salesTrend => 'Sales Trend';

  @override
  String get noSalesInPeriod => 'No sales recorded for this period';

  @override
  String get viewLowStock => 'View Low Stock';

  @override
  String get accountDetails => 'Account Details';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get changePassword => 'Change Password';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get passwordChangedSuccess => 'Password changed successfully';

  @override
  String get invalidCurrentPassword => 'Incorrect current password';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get currencyLabel => 'System Currency';

  @override
  String get currencyDesc =>
      'All financial figures and reports are calculated in Ethiopian Birr (ETB).';

  @override
  String get aboutTitle => 'About Kera Spare Tracker';

  @override
  String get aboutDesc =>
      'Offline-first inventory and sales management for spare parts businesses in Kera, Addis Ababa.';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get themeMode => 'App Theme';

  @override
  String get themeSystem => 'System Default';

  @override
  String get themeLight => 'Light Mode';

  @override
  String get themeDark => 'Dark Mode';

  @override
  String get dataManagement => 'Data Management & Export';

  @override
  String get exportInventoryCsv => 'Export Inventory (CSV)';

  @override
  String get exportInventoryDesc =>
      'Generate and share CSV spreadsheet of all parts';

  @override
  String get exportSalesCsv => 'Export Sales History (CSV)';

  @override
  String get exportSalesDesc =>
      'Generate and share CSV spreadsheet of sales records';

  @override
  String get backupDatabase => 'Backup Local Database';

  @override
  String get backupDatabaseDesc =>
      'Export database file to share or store safely';

  @override
  String get restoreDatabase => 'Restore Database from Backup';

  @override
  String get restoreDatabaseDesc =>
      'Restore all local data from a backup SQLite file';

  @override
  String get restoreConfirmTitle => 'Restore Database?';

  @override
  String get restoreConfirmMessage =>
      'WARNING: Restoring will overwrite all current inventory, stock ledger, and sales records with data from the backup file. This cannot be undone. Do you wish to continue?';

  @override
  String get restoreSuccess => 'Database restored successfully. Reloading...';

  @override
  String get restoreError => 'Failed to restore database from selected file';

  @override
  String exportSuccess(String filename) {
    return 'Export file created: $filename';
  }

  @override
  String exportError(String error) {
    return 'Failed to export data: $error';
  }

  @override
  String get saveToStorage => 'Save to Storage';

  @override
  String get authRequiresInternetNotice =>
      'An active internet connection is required for registration and the first login. Once logged in, the app works 100% offline.';

  @override
  String get authWrongPassword => 'Incorrect phone number or password';

  @override
  String get authPhoneTaken => 'This phone number is already registered';

  @override
  String get authNoInternet =>
      'No internet connection. Please connect to the internet to authenticate.';

  @override
  String get authAccountSuspended =>
      'Your business account has been suspended. Please contact the administrator.';

  @override
  String get authServerError =>
      'Server error occurred. Please try again later.';

  @override
  String get updateRequiredTitle => 'Update Required';

  @override
  String updateRequiredMessage(String version) {
    return 'A new version of Kera Spare Tracker is required to continue. Please update to version $version or newer.';
  }

  @override
  String get updateNow => 'Update Now';

  @override
  String get maintenanceTitle => 'Service Under Maintenance';

  @override
  String get maintenanceBanner =>
      'Cloud sync is temporarily undergoing maintenance. Offline inventory and sales remain fully functional.';

  @override
  String get accountSuspendedTitle => 'Account Suspended';

  @override
  String get accountSuspendedMessage =>
      'Your account has been suspended. Sync is paused, but your local records remain accessible and can be exported.';

  @override
  String suspensionReasonLabel(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get contactSupportLabel => 'Contact Support:';

  @override
  String get callSupport => 'Call Support';

  @override
  String get telegramSupport => 'Telegram';

  @override
  String get mustChangePasswordTitle => 'Password Change Required';

  @override
  String get mustChangePasswordPrompt =>
      'An immediate password update is required for your account before you can proceed.';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get adminAccount => 'Admin Account';

  @override
  String get adminAccountDisabledSuccess =>
      'Owner account disabled successfully';

  @override
  String get adminAccountTitle => 'Administrator Account';

  @override
  String get adminActionsHeader => 'Administrative Actions';

  @override
  String get adminActiveOwners => 'Active Owners (30d)';

  @override
  String get adminActor => 'Performed By';

  @override
  String get adminAddBrand => 'Add Global Brand';

  @override
  String get adminAddCategory => 'Add Global Category';

  @override
  String get adminAddUnit => 'Add Global Unit';

  @override
  String get adminAnnouncementActive => 'Announcement Active';

  @override
  String get adminAnnouncementActiveDesc =>
      'When active, this banner is displayed to all app users';

  @override
  String get adminAnnouncementBodyAm => 'Announcement Body (Amharic)';

  @override
  String get adminAnnouncementBodyEn => 'Announcement Body (English)';

  @override
  String get adminAnnouncementDesc =>
      'Broadcast announcements or alerts to all connected app instances';

  @override
  String get adminAnnouncementSettings => 'Global Announcement';

  @override
  String get adminAnnouncementTitleAm => 'Announcement Title (Amharic)';

  @override
  String get adminAnnouncementTitleEn => 'Announcement Title (English)';

  @override
  String get adminAppSettingsTitle => 'Application Settings';

  @override
  String get adminAppVersion => 'App Version';

  @override
  String get adminAppVersionsInUse => 'Client App Versions in Use';

  @override
  String get adminAuditDetailTitle => 'Audit Log Detail';

  @override
  String get adminAuditHistoryForUser => 'Audit History for this Owner';

  @override
  String get adminAuditLogs => 'Audit Logs';

  @override
  String get adminAuditLogsEmpty => 'No audit records found matching criteria';

  @override
  String get adminAuditLogsTitle => 'System Audit Log';

  @override
  String get adminCatalog => 'Catalog';

  @override
  String get adminCatalogTitle => 'Global Catalog Management';

  @override
  String get adminConfirmPhoneLabel => 'Confirm Phone Number';

  @override
  String get adminDashboard => 'Dashboard';

  @override
  String get adminDashboardTitle => 'Admin Dashboard';

  @override
  String get adminDate => 'Date & Time';

  @override
  String get adminDisableAccount => 'Disable Account';

  @override
  String get adminDisableAccountTitle => 'Permanently Disable Owner Account';

  @override
  String get adminDisableConfirm => 'I understand, disable this account';

  @override
  String adminDisableWarningPrompt(String phone) {
    return 'To confirm soft-disabling this account, type the owner\'s phone number ($phone) exactly:';
  }

  @override
  String get adminEditOwnerTitle => 'Edit Owner Details';

  @override
  String get adminEnforceMinVersion => 'Enforce Minimum Version';

  @override
  String get adminEnforceMinVersionDesc =>
      'Block app access for clients running versions below this threshold';

  @override
  String get adminFailedSyncCount => 'Failed Sync Count';

  @override
  String get adminFilterActive => 'Active';

  @override
  String get adminFilterAll => 'All';

  @override
  String get adminFilterInactive30d => 'Inactive (>30d)';

  @override
  String get adminFilterSuspended => 'Suspended';

  @override
  String get adminIpAddress => 'IP Address';

  @override
  String get adminLastSync => 'Last Synced';

  @override
  String get adminMaintenanceActive => 'Maintenance Mode Enabled';

  @override
  String get adminMaintenanceActiveDesc =>
      'Halt cloud sync and display maintenance banner across client apps';

  @override
  String get adminMaintenanceDesc =>
      'Control scheduled maintenance mode for cloud synchronization';

  @override
  String get adminMaintenanceMessageAm => 'Maintenance Message (Amharic)';

  @override
  String get adminMaintenanceMessageEn => 'Maintenance Message (English)';

  @override
  String get adminMaintenanceMode => 'Maintenance Mode';

  @override
  String get adminMinAppVersion => 'Minimum App Version';

  @override
  String get adminMinAppVersionDesc =>
      'Set the minimum required client version supported by the backend';

  @override
  String get adminMore => 'More';

  @override
  String get adminNewThisWeek => 'New This Week';

  @override
  String get adminNewValue => 'New Value';

  @override
  String get adminNoAuditLogs => 'No audit records found';

  @override
  String get adminNoOwnersFound => 'No business owners found';

  @override
  String get adminNoVersionsRecorded => 'No client version data recorded yet';

  @override
  String get adminOldValue => 'Previous Value';

  @override
  String get adminOwnerDetailsTitle => 'Owner Details';

  @override
  String get adminOwnerReactivatedSuccess =>
      'Owner account successfully reactivated';

  @override
  String get adminOwnerSuspendedSuccess =>
      'Owner account successfully suspended';

  @override
  String get adminOwnerUpdatedSuccess => 'Owner details updated successfully';

  @override
  String get adminOwners => 'Owners';

  @override
  String get adminOwnersTitle => 'Business Owners Directory';

  @override
  String get adminPasswordChangedSuccess => 'Password changed successfully';

  @override
  String get adminPhoneConfirmationMismatch =>
      'Phone number does not match confirmation';

  @override
  String get adminPortalTitle => 'Admin Portal';

  @override
  String get adminReactivate => 'Reactivate Account';

  @override
  String get adminReactivateConfirm => 'Reactivate';

  @override
  String get adminReactivateOwnerTitle => 'Reactivate Business Owner';

  @override
  String get adminReactivatePrompt =>
      'Are you sure you want to reactivate this account? The owner will regain immediate access.';

  @override
  String get adminReason => 'Reason';

  @override
  String get adminReasonRequired => 'Please specify a reason';

  @override
  String get adminRegisteredDate => 'Registered Date';

  @override
  String get adminRenameItem => 'Rename Item';

  @override
  String get adminResetPassword => 'Reset Password';

  @override
  String get adminResetPasswordConfirm => 'Generate Temporary Password';

  @override
  String get adminResetPasswordPrompt =>
      'This will invalidate the current password and generate a temporary password that must be changed on next login.';

  @override
  String get adminResetPasswordTitle => 'Reset Owner Password';

  @override
  String get adminSearchOwnersHint => 'Search by phone or business name...';

  @override
  String get adminSettings => 'Settings';

  @override
  String get adminStatusActive => 'Active';

  @override
  String get adminStatusSuspended => 'Suspended';

  @override
  String get adminSuspend => 'Suspend Account';

  @override
  String get adminSuspendConfirm => 'Suspend Owner';

  @override
  String get adminSuspendOwnerTitle => 'Suspend Business Owner';

  @override
  String get adminSuspendPrompt =>
      'Suspending this owner will block login and sync access immediately. Enter a clear reason below:';

  @override
  String get adminSuspendedOwners => 'Suspended Owners';

  @override
  String get adminSuspensionReasonHint =>
      'e.g. Inactive business or account misuse';

  @override
  String get adminSuspensionReasonLabel => 'Suspension Reason';

  @override
  String adminSyncDaysAgo(String days) {
    return '$days days ago';
  }

  @override
  String get adminSyncHealth => 'Sync Status Health';

  @override
  String get adminSyncHealthyMessage => 'All business sync queues are healthy';

  @override
  String adminSyncHoursAgo(String hours) {
    return '$hours hours ago';
  }

  @override
  String get adminSyncJustNow => 'Just now';

  @override
  String adminSyncMinutesAgo(String minutes) {
    return '$minutes min ago';
  }

  @override
  String adminSyncMonthsAgo(String months) {
    return '$months months ago';
  }

  @override
  String get adminSyncNever => 'Never synced';

  @override
  String adminSyncProblemsCount(String count) {
    return '$count owner(s) have sync delays or failures';
  }

  @override
  String get adminSystemStatistics => 'System-Wide Statistics';

  @override
  String get adminTabBrands => 'Brands';

  @override
  String get adminTabCategories => 'Categories';

  @override
  String get adminTabUnits => 'Units';

  @override
  String get adminTargetOwner => 'Target Owner';

  @override
  String get adminTempPasswordTitle => 'Temporary Password Generated';

  @override
  String get adminTempPasswordWarning =>
      'Share this password securely with the owner. It will NOT be shown again.';

  @override
  String get adminTenantCountsOnly =>
      'System Aggregate Counts (Zero Row Exposure)';

  @override
  String get adminTenantOverview => 'Tenant Overview';

  @override
  String get adminTotalOwners => 'Total Owners';

  @override
  String get adminTotalPartsCount => 'Total Parts (Count)';

  @override
  String get adminTotalSalesCount => 'Total Sales (Count)';

  @override
  String get adminVersionStringLabel => 'Version String (e.g. 1.0.0)';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get copy => 'Copy';

  @override
  String get error => 'Error';

  @override
  String get logoutConfirmation =>
      'Are you sure you want to log out of your administrator account?';

  @override
  String get name => 'Name';

  @override
  String get next => 'Next';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get page => 'Page';

  @override
  String get previous => 'Previous';

  @override
  String get required => 'Required';

  @override
  String get success => 'Success';

  @override
  String get totalEntries => 'total entries';

  @override
  String get authNeedsLoginBanner => 'Please log in again to continue syncing';

  @override
  String get authNeedsLoginAction => 'Log In';

  @override
  String get authOfflineInternetRequired =>
      'Internet is required to register or log in.';

  @override
  String get authDifferentOwnerConflictTitle => 'Unsynced Account Data';

  @override
  String authDifferentOwnerConflictMessage(String ownerName) {
    return 'This phone has unsynced data from another account ($ownerName). Please log in as the original account to sync, or discard the unsynced data to continue.';
  }

  @override
  String get authDiscardUnsyncedAndLogin => 'Discard & Log In';

  @override
  String authOfflineMaxDaysWarning(int days) {
    return 'The app has been offline for more than $days days. Please connect to the internet to verify your account.';
  }

  @override
  String get initialSyncTitle => 'Setting up your inventory...';

  @override
  String get initialSyncSubtitle =>
      'Downloading your parts catalog from the server';

  @override
  String get logoutBlockedOfflineTitle => 'Logout Blocked (Offline)';

  @override
  String logoutBlockedOfflineMessage(int count) {
    return 'You have $count unsynced change(s). Logging out while offline would permanently lose your work because changes cannot be saved to the server.';
  }

  @override
  String get exportDataAction => 'Export Data (CSV)';

  @override
  String get logoutDiscardPrompt =>
      'To permanently discard unsynced changes and log out, type DISCARD below:';

  @override
  String get logoutDiscardButton => 'Log Out & Discard';

  @override
  String get logoutPendingOnlineTitle => 'Unsynced Changes Pending';

  @override
  String logoutPendingOnlineMessage(int count) {
    return 'You have $count pending change(s) not yet synced with the server.';
  }

  @override
  String get syncNowAndLogout => 'Sync Now & Log Out';

  @override
  String syncFailedLogoutCancelled(String reason) {
    return 'Sync failed: $reason. You remain logged in to protect your changes.';
  }

  @override
  String get syncStatusTitle => 'Sync Status';

  @override
  String get syncStatusUpToDate => 'All changes saved to server';

  @override
  String syncStatusPending(int count) {
    return '$count changes pending sync';
  }

  @override
  String get syncStatusSyncing => 'Syncing changes...';

  @override
  String get lastOnlineTitle => 'Last Online';

  @override
  String get pendingChangesCount => 'Pending Changes';

  @override
  String get passwordChangedRemotelyTitle => 'Password Changed Elsewhere';

  @override
  String get passwordChangedRemotelyMessage =>
      'Your password was updated on another device. Please log in with your new password to resume syncing. Local records remain safe.';

  @override
  String get appLockTitle => 'App Lock';

  @override
  String get appLockSubtitle => 'Protect access with a PIN or biometrics';

  @override
  String get appLockEnabled => 'App Lock is enabled';

  @override
  String get appLockDisabled => 'App Lock is disabled';

  @override
  String get appLockBiometrics => 'Biometric Unlock';

  @override
  String get appLockBiometricsDesc =>
      'Use fingerprint or face recognition to unlock';

  @override
  String get appLockTimeout => 'Auto-lock Timeout';

  @override
  String get appLockTimeoutImmediately => 'Immediately';

  @override
  String get appLockTimeout1Min => 'After 1 minute';

  @override
  String get appLockTimeout5Min => 'After 5 minutes';

  @override
  String get changePin => 'Change PIN';

  @override
  String get setPinTitle => 'Set App Lock PIN';

  @override
  String get enterNewPin => 'Enter 4 to 6 digit PIN';

  @override
  String get confirmPinTitle => 'Confirm App Lock PIN';

  @override
  String get reenterPin => 'Re-enter your PIN';

  @override
  String get pinsDoNotMatch => 'PINs do not match. Please try again.';

  @override
  String get pinLengthError => 'PIN must be between 4 and 6 digits.';

  @override
  String get pinSetSuccess => 'App Lock PIN updated successfully.';

  @override
  String get enterPinToUnlock => 'Enter PIN to unlock';

  @override
  String wrongPin(int remaining) {
    return 'Incorrect PIN. $remaining attempt(s) remaining.';
  }

  @override
  String lockoutCooldown(int seconds) {
    return 'Too many attempts. Try again in ${seconds}s.';
  }

  @override
  String get lockoutMaxReached =>
      'Too many failed attempts. Online login required.';

  @override
  String get forgotPin => 'Forgot PIN?';

  @override
  String get forgotPinTitle => 'Reset App PIN';

  @override
  String get forgotPinDesc =>
      'Verify with your phone number and password to reset your PIN. Your local data will remain safe.';

  @override
  String get biometricPromptReason =>
      'Scan fingerprint or face to unlock Kera Spare Tracker';

  @override
  String get unlockWithBiometrics => 'Unlock with Biometrics';

  @override
  String get loginToResetPin => 'Log In to Reset PIN';

  @override
  String get adminAuditActionUserSuspended => 'User Suspended';

  @override
  String get adminAuditActionUserReactivated => 'User Reactivated';

  @override
  String get adminAuditActionPasswordReset => 'Password Reset';

  @override
  String get adminAuditActionUserDeleted => 'Account Disabled';

  @override
  String get adminAuditActionBrandCreated => 'Brand Created';

  @override
  String get adminAuditActionBrandUpdated => 'Brand Updated';

  @override
  String get adminAuditActionCategoryCreated => 'Category Created';

  @override
  String get adminAuditActionCategoryUpdated => 'Category Updated';

  @override
  String get adminAuditActionUnitCreated => 'Unit Created';

  @override
  String get adminAuditActionUnitUpdated => 'Unit Updated';

  @override
  String get adminAuditActionSettingsUpdated => 'Settings Updated';

  @override
  String get adminAuditDetailsTitle => 'Audit Record Details';

  @override
  String get adminAuditActor => 'Actor';

  @override
  String get adminAuditTarget => 'Target';

  @override
  String get adminAuditNoChanges => 'No recorded value diff';

  @override
  String get adminAuditToday => 'Today';

  @override
  String get adminAuditYesterday => 'Yesterday';

  @override
  String get adminSyncHealthy => 'Healthy';

  @override
  String get adminSyncNeverStarted => 'Never synced';

  @override
  String get adminSyncNeedsAttention => 'Needs attention';

  @override
  String get adminAppVersionsTitle => 'Client App Versions';

  @override
  String get adminLastUpdated => 'Last updated';

  @override
  String get adminNoMoreOwners => 'All owners loaded';

  @override
  String get adminSortBy => 'Sort by';

  @override
  String get adminSortNewest => 'Newest first';

  @override
  String get adminSortBusinessName => 'Business Name';

  @override
  String get adminSortLastSync => 'Last Synced';

  @override
  String get adminNeverSynced => 'Never synced';

  @override
  String adminCatalogItemsCount(int count) {
    return '$count items';
  }

  @override
  String adminCatalogActiveCount(int active, int total) {
    return '$active of $total active';
  }

  @override
  String get adminActiveLabel => 'Active';

  @override
  String get adminInactiveLabel => 'Inactive';

  @override
  String get adminConfirmDeactivateTitle => 'Deactivate Item';

  @override
  String adminConfirmDeactivateMessage(String name) {
    return 'Are you sure you want to deactivate $name? It will no longer appear in owner catalogs.';
  }

  @override
  String get adminSortAtoZ => 'A - Z';

  @override
  String get adminLivePreview => 'Live Preview';

  @override
  String get adminUnsavedChangesTitle => 'Unsaved Changes';

  @override
  String get adminUnsavedChangesMessage =>
      'You have unsaved configuration changes. Discard them?';

  @override
  String get adminDiscard => 'Discard';

  @override
  String get adminSaveSuccess => 'Settings saved successfully';

  @override
  String get adminVersionHelper =>
      'Current minimum required semver version (e.g. 1.0.0)';
}

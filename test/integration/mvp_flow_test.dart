import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/providers/locale_provider.dart';
import 'package:kera_spare_tracker/core/services/storage_service.dart';
import 'package:kera_spare_tracker/core/utils/password_hasher.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/data/local/database_provider.dart';
import 'package:kera_spare_tracker/data/local/tables/enums.dart';
import 'package:kera_spare_tracker/features/auth/data/repositories/local_auth_repository.dart';
import 'package:kera_spare_tracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:kera_spare_tracker/features/home/presentation/screens/home_screen.dart';
import 'package:kera_spare_tracker/features/parts/presentation/screens/part_form_screen.dart';
import 'package:kera_spare_tracker/features/sales/presentation/screens/new_sale_screen.dart';
import 'package:kera_spare_tracker/features/sales/presentation/screens/sale_success_screen.dart';
import 'package:kera_spare_tracker/main.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late MockSecureStorage mockSecureStorage;
  late Map<String, String> secureStorageMap;
  late LocalStorageService localStorageService;
  late LocalAuthRepository authRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    mockSecureStorage = MockSecureStorage();
    secureStorageMap = <String, String>{};

    when(() => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        )).thenAnswer((inv) async {
      final key = inv.namedArguments[#key] as String;
      final val = inv.namedArguments[#value] as String?;
      if (val != null) secureStorageMap[key] = val;
    });

    when(() => mockSecureStorage.read(key: any(named: 'key')))
        .thenAnswer((inv) async {
      final key = inv.namedArguments[#key] as String;
      return secureStorageMap[key];
    });

    when(() => mockSecureStorage.delete(key: any(named: 'key')))
        .thenAnswer((inv) async {
      final key = inv.namedArguments[#key] as String;
      secureStorageMap.remove(key);
    });

    localStorageService = LocalStorageService(storage: mockSecureStorage);
    authRepo = LocalAuthRepository(
      db: db,
      storage: mockSecureStorage,
      hasher: PasswordHasher(iterations: 10), // Fast hashing in test
    );
  });

  tearDown(() async {
    authRepo.dispose();
    await db.close();
  });

  testWidgets(
      'Full Offline MVP Flow: Register Owner -> Add Part with Stock -> Record Sale -> Verify Ledger & Stock Deduction',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Launch app with real in-memory SQLite Drift database
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          storageServiceProvider.overrideWithValue(localStorageService),
          authRepositoryProvider.overrideWithValue(authRepo),
        ],
        child: const KeraSpareTrackerApp(),
      ),
    );

    // Initial load settled
    await tester.pumpAndSettle();

    // ==========================================
    // STEP 1: REGISTER NEW OWNER
    // ==========================================
    // App redirects to Login screen in Amharic by default
    expect(find.text('ወደ መለያዎ ይግቡ'), findsOneWidget);

    // Tap to switch to English for clearer assertions
    final englishButton = find.text('English');
    if (englishButton.evaluate().isNotEmpty) {
      await tester.tap(englishButton);
      await tester.pumpAndSettle();
    }

    // Tap "Don't have an account? Register"
    final registerLink = find.text("Don't have an account? Register");
    expect(registerLink, findsOneWidget);
    await tester.tap(registerLink);
    await tester.pumpAndSettle();

    // On Register screen
    expect(find.text('Create Business Account'), findsOneWidget);

    // Fill registration form (4 text form fields: business name, phone, password, confirm password)
    final registerFields = find.byType(TextFormField);
    expect(registerFields, findsNWidgets(4));

    await tester.enterText(registerFields.at(0), 'Kera Genuine Parts');
    await tester.enterText(registerFields.at(1), '0911223344');
    await tester.enterText(registerFields.at(2), 'Password123');
    await tester.enterText(registerFields.at(3), 'Password123');
    await tester.pumpAndSettle();

    // Tap Register button
    final registerButton = find.widgetWithText(ElevatedButton, 'Register');
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    // Verify user navigated to HomeScreen
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Inventory'), findsWidgets);

    // Verify owner was created in SQLite database
    final profiles = await db.select(db.profiles).get();
    expect(profiles.length, 1);
    expect(profiles.first.businessName, 'Kera Genuine Parts');
    expect(profiles.first.phoneNumber, '+251911223344');

    // ==========================================
    // STEP 2: ADD A SPARE PART WITH INITIAL STOCK
    // ==========================================
    // Tap the Add Part FAB on the inventory tab
    final addPartFab = find.byType(FloatingActionButton);
    expect(addPartFab, findsOneWidget);
    await tester.tap(addPartFab);
    await tester.pumpAndSettle();

    // Verify on PartFormScreen
    expect(find.byType(PartFormScreen), findsOneWidget);

    // Enter Part Name
    final partNameField = find.widgetWithText(TextFormField, 'Part Name');
    await tester.enterText(partNameField, 'CAT Hydraulic Filter 1R-0716');

    // Enter Part Number
    final partNumberField = find.widgetWithText(TextFormField, 'Part Number');
    if (partNumberField.evaluate().isNotEmpty) {
      await tester.enterText(partNumberField, '1R-0716');
    }

    // Scroll to stock & pricing section
    final formScrollable = find.byType(Scrollable).first;
    final quantityField = find.widgetWithText(TextFormField, 'Quantity in Stock');
    await tester.scrollUntilVisible(quantityField, 200, scrollable: formScrollable);
    await tester.enterText(quantityField, '10');

    final purchasePriceField = find.widgetWithText(TextFormField, 'Purchase Price (ETB)');
    await tester.scrollUntilVisible(purchasePriceField, 200, scrollable: formScrollable);
    await tester.enterText(purchasePriceField, '600');

    final sellingPriceField = find.widgetWithText(TextFormField, 'Selling Price (ETB)');
    await tester.scrollUntilVisible(sellingPriceField, 200, scrollable: formScrollable);
    await tester.enterText(sellingPriceField, '850');

    await tester.pumpAndSettle();

    // Tap Save button (in AppBar actions)
    final saveButton = find.widgetWithText(TextButton, 'Save');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verify part was saved in SQLite database
    final partsInDb = await db.select(db.spareParts).get();
    expect(partsInDb.length, 1);
    final savedPart = partsInDb.first;
    expect(savedPart.name, 'CAT Hydraulic Filter 1R-0716');
    expect(savedPart.cachedQuantity, 10.0);
    expect(savedPart.purchasePrice, 600.0);
    expect(savedPart.sellingPrice, 850.0);

    // Verify initial stock movement in ledger
    final initialMovements = await db.select(db.stockMovements).get();
    expect(initialMovements.length, 1);
    expect(initialMovements.first.quantityChange, 10.0);
    expect(initialMovements.first.type, MovementType.initial);

    // ==========================================
    // STEP 3: RECORD A POINT-OF-SALE TRANSACTION
    // ==========================================
    // Dismiss any snackbar before interacting with bottom bar
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Switch to Sales tab (index 1 in NavigationBar)
    final salesNav = find.byType(NavigationDestination).at(1);
    expect(salesNav, findsOneWidget);
    await tester.tap(salesNav);
    await tester.pumpAndSettle();

    // Tap New Sale FAB or button
    final newSaleFab = find.widgetWithText(FloatingActionButton, 'New Sale');
    expect(newSaleFab, findsOneWidget);
    await tester.tap(newSaleFab);
    await tester.pumpAndSettle();

    // Verify on NewSaleScreen
    expect(find.byType(NewSaleScreen), findsOneWidget);
    expect(find.text('New Sale'), findsWidgets);

    // Tap "Add Parts" / search button
    final addPartsBtn = find.text('Add Parts');
    expect(addPartsBtn, findsOneWidget);
    await tester.tap(addPartsBtn);
    await tester.pumpAndSettle();

    // In bottom sheet, select the part
    final partItemInSheet = find.text('CAT Hydraulic Filter 1R-0716');
    expect(partItemInSheet, findsOneWidget);
    await tester.tap(partItemInSheet);
    await tester.pumpAndSettle();

    // Line item is in cart with default quantity 1
    // Increase quantity to 2 by tapping "+" icon button
    final addQtyButton = find.byIcon(Icons.add);
    expect(addQtyButton, findsOneWidget);
    await tester.tap(addQtyButton);
    await tester.pumpAndSettle();

    // Live total is 2 * 850 = 1,700 ETB
    // Profit is 2 * (850 - 600) = 500 ETB
    expect(find.textContaining('1700'), findsWidgets);

    // Tap Complete Sale
    final completeSaleBtn = find.widgetWithText(ElevatedButton, 'Complete Sale');
    await tester.tap(completeSaleBtn);
    await tester.pumpAndSettle();

    // Verify navigated to SaleSuccessScreen
    expect(find.byType(SaleSuccessScreen), findsOneWidget);
    expect(find.text('Sale Recorded Successfully!'), findsWidgets);
    expect(find.textContaining('1700'), findsWidgets);

    // ==========================================
    // VERIFY DATABASE INTEGRITY & LEDGER
    // ==========================================
    // 1. Verify sale recorded
    final sales = await db.select(db.sales).get();
    expect(sales.length, 1);
    expect(sales.first.totalAmount, 1700.0);
    expect(sales.first.totalProfit, 500.0);

    // 2. Verify sale items snapshot
    final saleItems = await db.select(db.saleItems).get();
    expect(saleItems.length, 1);
    expect(saleItems.first.quantity, 2.0);
    expect(saleItems.first.unitPrice, 850.0);
    expect(saleItems.first.unitCost, 600.0);
    expect(saleItems.first.lineTotal, 1700.0);
    expect(saleItems.first.lineProfit, 500.0);

    // 3. Verify stock movements ledger:
    // Movement 1: purchase (+10)
    // Movement 2: sale (-2)
    final allMovements = await db.select(db.stockMovements).get();
    expect(allMovements.length, 2);
    final saleMovement =
        allMovements.firstWhere((m) => m.type == MovementType.sale);
    expect(saleMovement.quantityChange, -2.0);
    expect(saleMovement.referenceId, sales.first.id);

    // 4. Verify part cachedQuantity was decremented in the same transaction
    final updatedPart = await (db.select(db.spareParts)
          ..where((p) => p.id.equals(savedPart.id)))
        .getSingle();
    expect(updatedPart.cachedQuantity, 8.0);

    // 5. Verify sync queue has queued actions for offline sync
    final syncQueue = await db.select(db.syncQueue).get();
    expect(syncQueue.isNotEmpty, true);

    // Cleanly unmount widget tree and drain Drift stream query cleanup timers
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/errors/failure.dart';
import 'package:kera_spare_tracker/core/providers/locale_provider.dart';
import 'package:kera_spare_tracker/core/services/storage_service.dart';
import 'package:kera_spare_tracker/core/utils/result.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/data/local/database_provider.dart';
import 'package:kera_spare_tracker/features/auth/domain/models/auth_user.dart';
import 'package:kera_spare_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:kera_spare_tracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:kera_spare_tracker/features/auth/presentation/screens/login_screen.dart';
import 'package:kera_spare_tracker/features/home/presentation/screens/home_screen.dart';
import 'package:kera_spare_tracker/features/parts/presentation/providers/inventory_providers.dart';
import 'package:kera_spare_tracker/features/parts/presentation/providers/parts_providers.dart';
import 'package:kera_spare_tracker/features/reports/domain/models/inventory_valuation.dart';
import 'package:kera_spare_tracker/features/reports/domain/models/sales_summary.dart';
import 'package:kera_spare_tracker/features/reports/presentation/providers/reports_providers.dart';
import 'package:kera_spare_tracker/features/sales/presentation/providers/sales_providers.dart';
import 'package:kera_spare_tracker/main.dart';
import 'package:mocktail/mocktail.dart';

class MockLocalStorageService extends Mock implements LocalStorageService {}

class MockAuthRepository extends Mock implements AuthRepository {}

class _FakeInventoryListNotifier extends InventoryListNotifier {
  @override
  InventoryListState build() => const InventoryListState();
  @override
  Future<void> refresh() async {}
  @override
  Future<void> loadNextPage() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLocalStorageService mockStorage;
  late MockAuthRepository mockAuth;

  setUp(() {
    mockStorage = MockLocalStorageService();
    mockAuth = MockAuthRepository();

    when(() => mockStorage.saveLocaleCode(any())).thenAnswer((_) async {});
    when(() => mockStorage.getSavedLocaleCode()).thenAnswer((_) async => null);

    // Default mock: unauthenticated
    when(() => mockAuth.currentUser())
        .thenAnswer((_) async => const Result.success(null));
    when(() => mockAuth.watchCurrentUser()).thenAnswer((_) => Stream.value(null));
    when(() => mockAuth.precheckLogout()).thenAnswer(
        (_) async => const LogoutPrecheck(pendingCount: 0, isOnline: true));
    when(() => mockAuth.logout())
        .thenAnswer((_) async => const Result.success(null));
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(mockStorage),
        authRepositoryProvider.overrideWithValue(mockAuth),
        partsStreamProvider.overrideWith((ref) => Stream.value([])),
        activeSalesStreamProvider.overrideWith((ref) => Stream.value([])),
        filteredSalesStreamProvider.overrideWith((ref) => Stream.value([])),
        salesSummaryProvider.overrideWith((ref) async => SalesSummary.zero),
        chartPointsProvider.overrideWith((ref) async => []),
        topSellingPartsProvider.overrideWith((ref) async => []),
        inventoryValuationProvider
            .overrideWith((ref) async => InventoryValuation.zero),
        inventoryListProvider.overrideWith(_FakeInventoryListNotifier.new),
      ],
      child: const KeraSpareTrackerApp(),
    );
  }

  testWidgets('1. Login screen renders all Stitch UI elements in Amharic by default',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('ኬራ ስፔር / Kera Spare'), findsOneWidget);
    expect(find.text('ወደ መለያዎ ይግቡ'), findsOneWidget);
    expect(find.text('ስልክ ቁጥር'), findsOneWidget);
    expect(find.text('+251'), findsOneWidget);
    expect(find.text('የይለፍ ቃል'), findsOneWidget);
    expect(find.text('ግባ'), findsOneWidget);
    expect(find.text('Fill Admin Credentials'), findsOneWidget);
  });

  testWidgets('2. Empty form triggers validation errors', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Tap Login button with empty inputs
    final loginBtn = find.text('ግባ');
    await tester.ensureVisible(loginBtn);
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    expect(find.text('ስልክ ቁጥር ማስገባት ግዴታ ነው'), findsOneWidget);
    expect(find.text('የይለፍ ቃል ማስገባት ግዴታ ነው'), findsOneWidget);
  });

  testWidgets('3. Invalid phone format triggers validation error',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), '12345');
    await tester.enterText(textFields.at(1), 'password123');

    final loginBtn = find.text('ግባ');
    await tester.ensureVisible(loginBtn);
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    expect(
        find.text('ትክክለኛ የኢትዮጵያ ስልክ ቁጥር ያስገቡ (ለምሳሌ 09... ወይም 07...)'),
        findsOneWidget);
  });

  testWidgets('4. Password visibility toggle works', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final visibilityOffIcon = find.byIcon(Icons.visibility_off_outlined);
    expect(visibilityOffIcon, findsOneWidget);

    await tester.tap(visibilityOffIcon);
    await tester.pumpAndSettle();

    final visibilityOnIcon = find.byIcon(Icons.visibility_outlined);
    expect(visibilityOnIcon, findsOneWidget);
  });

  testWidgets('5. Invalid credentials displays localized error banner',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    when(() => mockAuth.login(
          phoneNumber: any(named: 'phoneNumber'),
          password: any(named: 'password'),
          forceDiscardUnsynced: any(named: 'forceDiscardUnsynced'),
        )).thenAnswer((_) async => const Result.failure(
          AuthFailure(
            message: 'Invalid credentials',
            code: 'INVALID_CREDENTIALS',
          ),
        ));

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), '0911223344');
    await tester.enterText(textFields.at(1), 'WrongPassword123');

    final loginBtn = find.text('ግባ');
    await tester.ensureVisible(loginBtn);
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    expect(find.text('የተሳሳተ ስልክ ቁጥር ወይም የይለፍ ቃል'), findsOneWidget);
  });

  testWidgets('6. Network/server unreachable displays server settings action',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    when(() => mockAuth.login(
          phoneNumber: any(named: 'phoneNumber'),
          password: any(named: 'password'),
          forceDiscardUnsynced: any(named: 'forceDiscardUnsynced'),
        )).thenAnswer((_) async => const Result.failure(
          NetworkFailure(
            message: 'Server is currently unreachable at http://127.0.0.1:7000',
            code: 'SERVER_UNREACHABLE',
          ),
        ));

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), '0911223344');
    await tester.enterText(textFields.at(1), 'ValidPassword123');

    final loginBtn = find.text('ግባ');
    await tester.ensureVisible(loginBtn);
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    expect(find.text('Server Settings'), findsOneWidget);
    expect(find.text('እንደገና ሞክር'), findsOneWidget); // Retry button
  });

  testWidgets('7. Quick Admin Credentials fill button works', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final adminBtn = find.text('Fill Admin Credentials');
    await tester.ensureVisible(adminBtn);
    await tester.tap(adminBtn);
    await tester.pumpAndSettle();

    expect(find.text('0900000000'), findsOneWidget);
    expect(find.text('AdminPassword123!'), findsOneWidget);
  });

  testWidgets('8. Server settings icon opens Server Settings dialog',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final settingsIcon = find.byIcon(Icons.settings_ethernet_rounded).first;
    await tester.tap(settingsIcon);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Server Settings'), findsOneWidget);
  });
}

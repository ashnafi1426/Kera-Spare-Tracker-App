import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/providers/locale_provider.dart';
import 'package:kera_spare_tracker/core/services/storage_service.dart';
import 'package:kera_spare_tracker/core/utils/result.dart';
import 'package:kera_spare_tracker/core/widgets/language_selector_widget.dart';
import 'package:kera_spare_tracker/features/auth/domain/models/auth_user.dart';
import 'package:kera_spare_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:kera_spare_tracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:kera_spare_tracker/features/auth/presentation/screens/login_screen.dart';
import 'package:kera_spare_tracker/features/auth/presentation/screens/register_screen.dart';
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
  @override
  Future<bool> seedTestParts({int count = 2000}) async => true;
  @override
  Future<bool> clearTestParts() async => true;
}

void main() {
  late MockLocalStorageService mockStorage;
  late MockAuthRepository mockAuth;

  setUp(() {
    mockStorage = MockLocalStorageService();
    mockAuth = MockAuthRepository();

    when(() => mockStorage.saveLocaleCode(any())).thenAnswer((_) async {});
    when(() => mockStorage.getSavedLocaleCode()).thenAnswer((_) async => null);

    // Default mock: unauthenticated
    when(() => mockAuth.currentUser()).thenAnswer((_) async => const Result.success(null));
    when(() => mockAuth.watchCurrentUser()).thenAnswer((_) => Stream.value(null));
    when(() => mockAuth.precheckLogout()).thenAnswer(
        (_) async => const LogoutPrecheck(pendingCount: 0, isOnline: true));
    when(() => mockAuth.logout()).thenAnswer((_) async => const Result.success(null));
  });

  testWidgets('Unauthenticated user is redirected to LoginScreen with Amharic by default',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorage),
          authRepositoryProvider.overrideWithValue(mockAuth),
        ],
        child: const KeraSpareTrackerApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify redirected to LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(LanguageSegmentedSwitch), findsOneWidget);

    // Verify Amharic texts by default
    expect(find.text('ወደ መለያዎ ይግቡ'), findsOneWidget); // loginTitle
    expect(find.text('ስልክ ቁጥር'), findsOneWidget); // phoneNumber
    expect(find.text('የይለፍ ቃል'), findsOneWidget); // password
    expect(find.text('ግባ'), findsOneWidget); // login button

    // Tap "English" switch
    final englishBtn = find.text('English');
    expect(englishBtn, findsOneWidget);
    await tester.tap(englishBtn);
    await tester.pumpAndSettle();

    // Verify UI switched live to English
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });

  testWidgets('Navigation from Login to Register screen and form validation',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorage),
          authRepositoryProvider.overrideWithValue(mockAuth),
        ],
        child: const KeraSpareTrackerApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap "Don't have an account? Register"
    final registerLink = find.text('አዲስ ነዎት? ይመዝገቡ');
    expect(registerLink, findsOneWidget);
    await tester.ensureVisible(registerLink);
    await tester.tap(registerLink);
    await tester.pumpAndSettle();

    // Verify on RegisterScreen
    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.text('አዲስ የንግድ መለያ ይክፈቱ'), findsOneWidget);
    expect(find.text('የንግድ ስም'), findsOneWidget);

    // Tap submit button with empty fields to trigger validation
    final registerBtn = find.widgetWithText(ElevatedButton, 'ይመዝገቡ');
    await tester.ensureVisible(registerBtn);
    await tester.tap(registerBtn);
    await tester.pumpAndSettle();

    // Verify validation error messages
    expect(find.text('የንግድ ስም ማስገባት ግዴታ ነው'), findsOneWidget);
    expect(find.text('ስልክ ቁጥር ማስገባት ግዴታ ነው'), findsOneWidget);
    expect(find.text('የይለፍ ቃል ማስገባት ግዴታ ነው'), findsOneWidget);
  });

  testWidgets('Authenticated user is redirected to HomeScreen with bottom navigation and can log out',
      (WidgetTester tester) async {
    const user = AuthUser(
      id: 'owner_123',
      ownerId: 'owner_123',
      phoneNumber: '+251911223344',
      businessName: 'Kera Turbo Spares',
    );

    when(() => mockAuth.currentUser()).thenAnswer((_) async => const Result.success(user));
    when(() => mockAuth.watchCurrentUser()).thenAnswer((_) => Stream.value(user));
    when(() => mockAuth.logout()).thenAnswer((_) async => const Result.success(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorage),
          authRepositoryProvider.overrideWithValue(mockAuth),
          partsStreamProvider.overrideWith((ref) => Stream.value([])),
          activeSalesStreamProvider.overrideWith((ref) => Stream.value([])),
          filteredSalesStreamProvider.overrideWith((ref) => Stream.value([])),
          salesSummaryProvider.overrideWith((ref) async => SalesSummary.zero),
          chartPointsProvider.overrideWith((ref) async => []),
          topSellingPartsProvider.overrideWith((ref) async => []),
          inventoryValuationProvider.overrideWith((ref) async => InventoryValuation.zero),
          inventoryListProvider.overrideWith(_FakeInventoryListNotifier.new),
        ],
        child: const KeraSpareTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify user lands on HomeScreen
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('ዕቃዎች'), findsWidgets);
    expect(find.text('ሽያጭ'), findsOneWidget);
    expect(find.text('ሪፖርት'), findsOneWidget);
    expect(find.text('ቅንብሮች'), findsOneWidget);

    // Tap Settings destination
    await tester.tap(find.text('ቅንብሮች'));
    await tester.pumpAndSettle();

    // Verify business name & phone are displayed
    expect(find.text('Kera Turbo Spares'), findsOneWidget);
    expect(find.text('+251911223344'), findsOneWidget);

    // Scroll to and tap Logout button
    final logoutBtn = find.widgetWithText(OutlinedButton, 'ውጣ');
    await tester.scrollUntilVisible(logoutBtn, 500);
    await tester.ensureVisible(logoutBtn);
    await tester.pumpAndSettle();
    expect(logoutBtn, findsOneWidget);
    await tester.tap(logoutBtn);
    await tester.pumpAndSettle();

    // Confirm dialog appears
    expect(find.text('ከመተግበሪያው መውጣት ይፈልጋሉ?'), findsOneWidget);

    // Tap confirm logout button in dialog
    final confirmDialogBtn = find.widgetWithText(ElevatedButton, 'ውጣ');
    await tester.tap(confirmDialogBtn);
    await tester.pumpAndSettle();

    // Verify logout was called
    verify(() => mockAuth.logout()).called(1);
  });
}

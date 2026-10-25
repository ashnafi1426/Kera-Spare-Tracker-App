import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/providers/locale_provider.dart';
import 'package:kera_spare_tracker/core/utils/result.dart';
import 'package:kera_spare_tracker/features/admin/domain/models/admin_models.dart';
import 'package:kera_spare_tracker/features/admin/domain/repositories/admin_repository.dart';
import 'package:kera_spare_tracker/features/admin/presentation/providers/admin_providers.dart';
import 'package:kera_spare_tracker/features/admin/presentation/screens/admin_owners_list_screen.dart';
import 'package:kera_spare_tracker/l10n/app_localizations.dart';

class MockAdminRepository implements AdminRepository {
  List<AdminOwnerSummary> mockOwners = [];
  String? lastSearch;
  String? lastStatus;
  int? lastInactiveDays;
  int lastPage = 1;

  MockAdminRepository({List<AdminOwnerSummary>? owners}) {
    if (owners != null) {
      mockOwners = owners;
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getOwners({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    int? inactiveDays,
    String? sortBy,
  }) async {
    lastPage = page;
    lastSearch = search;
    lastStatus = status;
    lastInactiveDays = inactiveDays;

    var filtered = List<AdminOwnerSummary>.from(mockOwners);
    if (search != null && search.isNotEmpty) {
      filtered = filtered
          .where((o) =>
              o.businessName.toLowerCase().contains(search.toLowerCase()) ||
              o.phoneNumber.contains(search))
          .toList();
    }
    if (status != null && status != 'ALL') {
      filtered = filtered.where((o) => o.status == status).toList();
    }

    return Result.success({
      'owners': filtered,
      'pagination': {
        'page': page,
        'limit': limit,
        'total': filtered.length,
        'totalPages': 1,
      },
    });
  }

  @override
  Future<Result<AdminDashboardStats>> getDashboard() async =>
      throw UnimplementedError();
  @override
  Future<Result<AdminOwnerDetails>> getOwnerDetails(String ownerId) async =>
      throw UnimplementedError();
  @override
  Future<Result<void>> suspendOwner(String ownerId, {required String reason}) async =>
      throw UnimplementedError();
  @override
  Future<Result<void>> reactivateOwner(String ownerId) async =>
      throw UnimplementedError();
  @override
  Future<Result<Map<String, dynamic>>> resetOwnerPassword(String ownerId) async =>
      throw UnimplementedError();
  @override
  Future<Result<void>> updateOwner(String ownerId, {String? businessName, String? phoneNumber}) async =>
      throw UnimplementedError();
  @override
  Future<Result<void>> disableOwner(String ownerId, {required String phoneConfirmation}) async =>
      throw UnimplementedError();
  @override
  Future<Result<List<GlobalCatalogItem>>> getBrands() async =>
      throw UnimplementedError();
  @override
  Future<Result<GlobalCatalogItem>> createBrand(String name) async =>
      throw UnimplementedError();
  @override
  Future<Result<GlobalCatalogItem>> updateBrand(String id, {String? name, bool? isActive}) async =>
      throw UnimplementedError();
  @override
  Future<Result<List<GlobalCatalogItem>>> getCategories() async =>
      throw UnimplementedError();
  @override
  Future<Result<GlobalCatalogItem>> createCategory(String name) async =>
      throw UnimplementedError();
  @override
  Future<Result<GlobalCatalogItem>> updateCategory(String id, {String? name, bool? isActive}) async =>
      throw UnimplementedError();
  @override
  Future<Result<List<GlobalCatalogItem>>> getUnits() async =>
      throw UnimplementedError();
  @override
  Future<Result<GlobalCatalogItem>> createUnit(String name) async =>
      throw UnimplementedError();
  @override
  Future<Result<GlobalCatalogItem>> updateUnit(String id, {String? name, bool? isActive}) async =>
      throw UnimplementedError();
  @override
  Future<Result<dynamic>> getSetting(String key) async =>
      throw UnimplementedError();
  @override
  Future<Result<dynamic>> updateSetting(String key, dynamic value) async =>
      throw UnimplementedError();
  @override
  Future<Result<Map<String, dynamic>>> getAuditLogs({
    int page = 1,
    int limit = 50,
    String? action,
    String? targetUserId,
    String? adminId,
    String? startDate,
    String? endDate,
  }) async =>
      throw UnimplementedError();
}

Widget buildTestScreen(AdminRepository repo, {Locale locale = const Locale('en')}) {
  return ProviderScope(
    overrides: [
      adminRepositoryProvider.overrideWithValue(repo),
      initialLocaleCodeProvider.overrideWithValue(locale.languageCode),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AdminOwnersListScreen(),
    ),
  );
}

void main() {
  final sampleOwners = [
    AdminOwnerSummary(
      id: 'owner-1',
      businessName: 'Abyssinia Auto Spares',
      phoneNumber: '0911223344',
      status: 'ACTIVE',
      lastSyncAt: DateTime.now().subtract(const Duration(minutes: 5)),
      failedSyncCount: 0,
      appVersion: '1.2.0',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    AdminOwnerSummary(
      id: 'owner-2',
      businessName: 'Red Sea Toyota Parts',
      phoneNumber: '0922334455',
      status: 'SUSPENDED',
      lastSyncAt: DateTime.now().subtract(const Duration(days: 4)),
      failedSyncCount: 6,
      suspendedReason: 'Account misuse',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    AdminOwnerSummary(
      id: 'owner-3',
      businessName: 'Merkato Heavy Parts',
      phoneNumber: '0933445566',
      status: 'ACTIVE',
      lastSyncAt: null, // Never synced
      failedSyncCount: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  group('AdminOwnersListScreen Widget Tests', () {
    testWidgets('1. Displays search field, filter chips, and loaded owner list', (tester) async {
      final mockRepo = MockAdminRepository(owners: sampleOwners);
      await tester.pumpWidget(buildTestScreen(mockRepo));
      await tester.pumpAndSettle();

      // Verify app bar title
      expect(find.text('Business Owners Directory'), findsOneWidget);

      // Verify search input
      expect(find.byType(TextField), findsOneWidget);

      // Verify filter chips
      expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Active'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Suspended'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Inactive (>30d)'), findsOneWidget);

      // Verify owner business names
      expect(find.text('Abyssinia Auto Spares'), findsOneWidget);
      expect(find.text('Red Sea Toyota Parts'), findsOneWidget);
      expect(find.text('Merkato Heavy Parts'), findsOneWidget);

      // Verify relative sync times
      expect(find.text('5 min ago'), findsOneWidget);
      expect(find.text('4 days ago'), findsOneWidget);
      expect(find.text('Never synced'), findsOneWidget);

      // Verify status badge on Card
      expect(find.widgetWithText(Card, 'Suspended'), findsOneWidget);
    });

    testWidgets('2. Debounced search filters owners list', (tester) async {
      final mockRepo = MockAdminRepository(owners: sampleOwners);
      await tester.pumpWidget(buildTestScreen(mockRepo));
      await tester.pumpAndSettle();

      // Enter search term
      await tester.enterText(find.byType(TextField), 'Toyota');
      // Wait for 350ms debounce
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Only Toyota parts should remain
      expect(find.text('Red Sea Toyota Parts'), findsOneWidget);
      expect(find.text('Abyssinia Auto Spares'), findsNothing);
      expect(find.text('Merkato Heavy Parts'), findsNothing);
      expect(mockRepo.lastSearch, 'Toyota');
    });

    testWidgets('3. Selecting Suspended chip filters to suspended owners', (tester) async {
      final mockRepo = MockAdminRepository(owners: sampleOwners);
      await tester.pumpWidget(buildTestScreen(mockRepo));
      await tester.pumpAndSettle();

      // Tap 'Suspended' filter chip
      await tester.tap(find.widgetWithText(FilterChip, 'Suspended'));
      await tester.pumpAndSettle();

      expect(find.text('Red Sea Toyota Parts'), findsOneWidget);
      expect(find.text('Abyssinia Auto Spares'), findsNothing);
      expect(mockRepo.lastStatus, 'SUSPENDED');
    });

    testWidgets('4. Renders Amharic localization seamlessly', (tester) async {
      final mockRepo = MockAdminRepository(owners: sampleOwners);
      await tester.pumpWidget(buildTestScreen(mockRepo, locale: const Locale('am')));
      await tester.pumpAndSettle();

      // Verify Amharic title and chips
      expect(find.text('የሱቅ ባለቤቶች ማውጫ'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'ሁሉም'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'ንቁ'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'የታገዱ'), findsOneWidget);
      expect(find.text('እስካሁን አልተመሳሰለም'), findsOneWidget);
    });
  });
}

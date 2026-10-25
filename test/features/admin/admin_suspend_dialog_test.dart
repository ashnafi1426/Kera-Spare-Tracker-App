import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/providers/locale_provider.dart';
import 'package:kera_spare_tracker/core/utils/result.dart';
import 'package:kera_spare_tracker/features/admin/domain/models/admin_models.dart';
import 'package:kera_spare_tracker/features/admin/domain/repositories/admin_repository.dart';
import 'package:kera_spare_tracker/features/admin/presentation/providers/admin_providers.dart';
import 'package:kera_spare_tracker/features/admin/presentation/screens/admin_owner_details_screen.dart';
import 'package:kera_spare_tracker/l10n/app_localizations.dart';

class MockOwnerDetailsAdminRepository implements AdminRepository {
  final AdminOwnerDetails details;
  String? suspendedOwnerId;
  String? suspendedReason;

  MockOwnerDetailsAdminRepository(this.details);

  @override
  Future<Result<AdminOwnerDetails>> getOwnerDetails(String ownerId) async {
    return Result.success(details);
  }

  @override
  Future<Result<void>> suspendOwner(String ownerId, {required String reason}) async {
    suspendedOwnerId = ownerId;
    suspendedReason = reason;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> reactivateOwner(String ownerId) async =>
      const Result.success(null);

  @override
  Future<Result<Map<String, dynamic>>> resetOwnerPassword(String ownerId) async =>
      const Result.success({'temporaryPassword': 'TEMP-123-PASS'});

  @override
  Future<Result<void>> updateOwner(String ownerId, {String? businessName, String? phoneNumber}) async =>
      const Result.success(null);

  @override
  Future<Result<void>> disableOwner(String ownerId, {required String phoneConfirmation}) async =>
      const Result.success(null);

  @override
  Future<Result<AdminDashboardStats>> getDashboard() async => throw UnimplementedError();
  @override
  Future<Result<Map<String, dynamic>>> getOwners({int page = 1, int limit = 20, String? search, String? status, int? inactiveDays, String? sortBy}) async {
    return const Result.success({
      'owners': <AdminOwnerSummary>[],
      'pagination': {'page': 1, 'limit': 20, 'total': 0, 'totalPages': 1},
    });
  }
  @override
  Future<Result<List<GlobalCatalogItem>>> getBrands() async => throw UnimplementedError();
  @override
  Future<Result<GlobalCatalogItem>> createBrand(String name) async => throw UnimplementedError();
  @override
  Future<Result<GlobalCatalogItem>> updateBrand(String id, {String? name, bool? isActive}) async => throw UnimplementedError();
  @override
  Future<Result<List<GlobalCatalogItem>>> getCategories() async => throw UnimplementedError();
  @override
  Future<Result<GlobalCatalogItem>> createCategory(String name) async => throw UnimplementedError();
  @override
  Future<Result<GlobalCatalogItem>> updateCategory(String id, {String? name, bool? isActive}) async => throw UnimplementedError();
  @override
  Future<Result<List<GlobalCatalogItem>>> getUnits() async => throw UnimplementedError();
  @override
  Future<Result<GlobalCatalogItem>> createUnit(String name) async => throw UnimplementedError();
  @override
  Future<Result<GlobalCatalogItem>> updateUnit(String id, {String? name, bool? isActive}) async => throw UnimplementedError();
  @override
  Future<Result<dynamic>> getSetting(String key) async => throw UnimplementedError();
  @override
  Future<Result<dynamic>> updateSetting(String key, dynamic value) async => throw UnimplementedError();
  @override
  Future<Result<Map<String, dynamic>>> getAuditLogs({int page = 1, int limit = 50, String? action, String? targetUserId, String? adminId, String? startDate, String? endDate}) async => throw UnimplementedError();
}

Widget buildDetailsScreen(AdminRepository repo, {String ownerId = 'owner-test-1'}) {
  return ProviderScope(
    overrides: [
      adminRepositoryProvider.overrideWithValue(repo),
      initialLocaleCodeProvider.overrideWithValue('en'),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AdminOwnerDetailsScreen(ownerId: ownerId),
    ),
  );
}

void main() {
  final sampleDetails = AdminOwnerDetails(
    owner: AdminOwnerSummary(
      id: 'owner-test-1',
      businessName: 'Addis Gear Spares',
      phoneNumber: '0911556677',
      status: 'ACTIVE',
      lastSyncAt: DateTime.now().subtract(const Duration(hours: 2)),
      failedSyncCount: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
    totalParts: 142,
    totalSales: 89,
    auditLogs: [],
  );

  group('Admin Suspend Dialog Widget Tests', () {
    testWidgets('1. Suspend button opens confirmation dialog requiring reason', (tester) async {
      final mockRepo = MockOwnerDetailsAdminRepository(sampleDetails);
      await tester.pumpWidget(buildDetailsScreen(mockRepo));
      await tester.pumpAndSettle();

      // Verify screen loaded
      expect(find.text('Addis Gear Spares'), findsOneWidget);
      expect(find.text('0911556677'), findsOneWidget);

      // Verify aggregate counts only (no parts rows)
      expect(find.text('142'), findsOneWidget);
      expect(find.text('89'), findsOneWidget);

      // Tap Suspend Account button
      final suspendBtn = find.text('Suspend Account');
      expect(suspendBtn, findsOneWidget);
      await tester.tap(suspendBtn);
      await tester.pumpAndSettle();

      // Dialog is open
      expect(find.text('Suspend Business Owner'), findsOneWidget);
      expect(find.text('Suspend Owner'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Try submitting without a reason
      await tester.tap(find.text('Suspend Owner'));
      await tester.pumpAndSettle();

      // Validation error appears
      expect(find.text('Please specify a reason'), findsOneWidget);
      expect(mockRepo.suspendedOwnerId, isNull);

      // Enter valid reason
      final reasonField = find.byType(TextFormField);
      await tester.enterText(reasonField, 'Violation of payment policy');
      await tester.pumpAndSettle();

      // Tap Suspend Owner
      await tester.tap(find.text('Suspend Owner'));
      await tester.pumpAndSettle();

      // Verify API was called with ownerId and reason
      expect(mockRepo.suspendedOwnerId, 'owner-test-1');
      expect(mockRepo.suspendedReason, 'Violation of payment policy');

      // Verify success snackbar
      expect(find.text('Owner account successfully suspended'), findsOneWidget);
    });

    testWidgets('2. Cancel button closes dialog without suspending', (tester) async {
      final mockRepo = MockOwnerDetailsAdminRepository(sampleDetails);
      await tester.pumpWidget(buildDetailsScreen(mockRepo));
      await tester.pumpAndSettle();

      // Open suspend dialog
      await tester.tap(find.text('Suspend Account'));
      await tester.pumpAndSettle();

      expect(find.text('Suspend Business Owner'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.text('Suspend Business Owner'), findsNothing);
      expect(mockRepo.suspendedOwnerId, isNull);
    });
  });
}

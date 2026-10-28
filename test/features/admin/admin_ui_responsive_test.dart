import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kera_spare_tracker/core/design/widgets/list_card.dart';
import 'package:kera_spare_tracker/core/theme/app_theme.dart';
import 'package:kera_spare_tracker/core/utils/result.dart';
import 'package:kera_spare_tracker/features/admin/domain/models/admin_models.dart';
import 'package:kera_spare_tracker/features/admin/domain/repositories/admin_repository.dart';
import 'package:kera_spare_tracker/features/admin/presentation/providers/admin_providers.dart';
import 'package:kera_spare_tracker/features/admin/presentation/screens/admin_audit_log_screen.dart';
import 'package:kera_spare_tracker/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:kera_spare_tracker/features/admin/presentation/screens/admin_owners_list_screen.dart';
import 'package:kera_spare_tracker/features/admin/presentation/widgets/admin_scaffold.dart';
import 'package:kera_spare_tracker/l10n/app_localizations.dart';

class _FakeAdminRepo implements AdminRepository {
  @override
  Future<Result<AdminDashboardStats>> getDashboard() async {
    return const Result.success(
      AdminDashboardStats(
        totalOwners: 200,
        newOwnersThisWeek: 15,
        activeOwners: 180,
        suspendedOwners: 10,
        inactiveOwners: 10,
        totalParts: 4500,
        totalSales: 12000,
        ownersWithSyncProblems: 2,
        appVersionDistribution: {'1.0.0': 150, '1.1.0': 50},
      ),
    );
  }

  @override
  Future<Result<Map<String, dynamic>>> getAuditLogs({
    int page = 1,
    int limit = 50,
    String? action,
    String? targetUserId,
    String? adminId,
    String? startDate,
    String? endDate,
  }) async {
    return Result.success({
      'logs': [
        AdminAuditLogEntry(
          id: 'log-1',
          adminId: 'admin-uuid-12345678',
          adminPhone: '+251911223344',
          action: 'USER_SUSPENDED',
          targetUserId: 'target-uuid-long-string-identifier-123',
          targetBusinessName: 'Kera Very Long Auto Spare Parts Enterprise PLC',
          targetPhone: '+251922334455',
          ipAddress: '::ffff:192.168.137.149',
          reason: 'Non-payment of subscription fee for past 60 days',
          oldValue: {'status': 'ACTIVE'},
          newValue: {'status': 'SUSPENDED'},
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        AdminAuditLogEntry(
          id: 'log-2',
          adminId: 'admin-uuid-12345678',
          action: 'SETTINGS_UPDATED',
          ipAddress: '192.168.1.100',
          reason: 'Updated minimum version',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
      'pagination': {
        'page': 1,
        'limit': 20,
        'total': 2,
        'totalPages': 1,
      },
    });
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
    return Result.success({
      'owners': [
        AdminOwnerSummary(
          id: 'owner-1',
          phoneNumber: '+251911002233',
          businessName: 'Addis Super Duper Long Auto Parts and Accessories Wholesaler PLC',
          status: 'ACTIVE',
          failedSyncCount: 0,
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          lastSyncAt: DateTime.now().subtract(const Duration(minutes: 15)),
          appVersion: '1.2.0',
        ),
        AdminOwnerSummary(
          id: 'owner-2',
          phoneNumber: '+251922334455',
          businessName: 'Bole Auto Parts',
          status: 'SUSPENDED',
          failedSyncCount: 3,
          createdAt: DateTime.now().subtract(const Duration(days: 100)),
          lastSyncAt: null,
          appVersion: null,
        ),
      ],
      'pagination': {
        'page': 1,
        'limit': 20,
        'total': 2,
        'totalPages': 1,
      },
    });
  }

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
      const Result.success([]);
  @override
  Future<Result<GlobalCatalogItem>> createBrand(String name) async =>
      throw UnimplementedError();
  @override
  Future<Result<GlobalCatalogItem>> updateBrand(String id, {String? name, bool? isActive}) async =>
      throw UnimplementedError();
  @override
  Future<Result<List<GlobalCatalogItem>>> getCategories() async =>
      const Result.success([]);
  @override
  Future<Result<GlobalCatalogItem>> createCategory(String name) async =>
      throw UnimplementedError();
  @override
  Future<Result<GlobalCatalogItem>> updateCategory(String id, {String? name, bool? isActive}) async =>
      throw UnimplementedError();
  @override
  Future<Result<List<GlobalCatalogItem>>> getUnits() async =>
      const Result.success([]);
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
}

Widget _wrapTestWidget({
  required Widget child,
  required double width,
  required double height,
  double textScale = 1.0,
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [
      adminRepositoryProvider.overrideWithValue(_FakeAdminRepo()),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('am'),
      ],
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          textScaler: TextScaler.linear(textScale),
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  group('Admin Portal Responsive & No-Overflow Verification', () {
    testWidgets('Audit log screen renders at 320dp (narrow phone) with 0 overflows', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrapTestWidget(
          child: const AdminAuditLogScreen(),
          width: 320,
          height: 700,
          textScale: 1.0,
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no overflow errors
      expect(tester.takeException(), isNull);
      expect(find.text('User Suspended'), findsAtLeastNWidgets(1));
    });

    testWidgets('Audit log screen renders at 390dp with 1.5x font scale in Amharic with 0 overflows', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrapTestWidget(
          child: const AdminAuditLogScreen(),
          width: 390,
          height: 844,
          textScale: 1.5,
          locale: const Locale('am'),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('ተጠቃሚ ታግዷል'), findsAtLeastNWidgets(1));
    });

    testWidgets('Dashboard renders cleanly at 360dp with high contrast metrics', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrapTestWidget(
          child: const AdminDashboardScreen(),
          width: 360,
          height: 800,
          textScale: 1.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('200'), findsOneWidget);
      expect(find.text('180'), findsOneWidget);
    });

    testWidgets('Owners list renders long names at 320dp without overflowing', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrapTestWidget(
          child: const AdminOwnersListScreen(),
          width: 320,
          height: 700,
          textScale: 1.2,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ListCard), findsWidgets);
    });

    testWidgets('Admin scaffold switches between mobile NavigationBar and wide NavigationRail', (tester) async {
      // 1. Mobile (width 400 < 840)
      await tester.pumpWidget(
        _wrapTestWidget(
          child: const AdminScaffold(
            currentRoute: '/admin',
            child: Text('Admin Content'),
          ),
          width: 400,
          height: 800,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      // 2. Wide tablet (width 900 >= 840)
      await tester.pumpWidget(
        _wrapTestWidget(
          child: const AdminScaffold(
            currentRoute: '/admin',
            child: Text('Admin Content'),
          ),
          width: 900,
          height: 800,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });
  });
}

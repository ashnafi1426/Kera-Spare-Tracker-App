import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kera_spare_tracker/core/theme/app_theme.dart';
import 'package:kera_spare_tracker/core/utils/result.dart';
import 'package:kera_spare_tracker/features/admin/domain/models/admin_models.dart';
import 'package:kera_spare_tracker/features/admin/domain/repositories/admin_repository.dart';
import 'package:kera_spare_tracker/features/admin/presentation/providers/admin_providers.dart';
import 'package:kera_spare_tracker/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:kera_spare_tracker/features/admin/presentation/widgets/admin_metric_tile.dart';
import 'package:kera_spare_tracker/l10n/app_localizations.dart';

class _FakeAdminRepo extends Fake implements AdminRepository {
  @override
  Future<Result<AdminDashboardStats>> getDashboard() async {
    return const Result.success(
      AdminDashboardStats(
        totalOwners: 81,
        newOwnersThisWeek: 51,
        activeOwners: 4,
        suspendedOwners: 23,
        inactiveOwners: 0,
        totalParts: 76,
        totalSales: 80300,
        ownersWithSyncProblems: 79,
        appVersionDistribution: {'1.0.0': 60, '1.2.0': 21},
      ),
    );
  }

  @override
  Future<Result<AdminReportSummary>> getReportsSummary({String period = 'month'}) async =>
      const Result.success(AdminReportSummary(
        period: 'month',
        totalRevenue: 80300.0,
        totalProfit: 29800.0,
        transactionsCount: 120,
        activeOwnersCount: 4,
        totalPartsCount: 76,
        points: [],
        topSellingItems: [],
      ));
}

Widget _buildTestApp({
  required double width,
  required double height,
  ThemeData? theme,
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [
      adminRepositoryProvider.overrideWithValue(_FakeAdminRepo()),
    ],
    child: MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
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
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: const AdminDashboardScreen(),
        ),
      ),
    ),
  );
}

void main() {
  group('Admin Dashboard Figma Implementation Verification', () {
    testWidgets('Renders all Figma sections cleanly without overflows at 393x852 (Figma baseline)', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(width: 393, height: 852));
      await tester.pumpAndSettle();

      final error = tester.takeException();
      if (error is FlutterError) {
        debugPrint('FLUTTER ERROR MESSAGE: ${error.message}');
        for (final d in error.diagnostics) {
          debugPrint('${d.name}: ${d.toDescription()}');
        }
      }
      expect(error, isNull);

      // 1. Header elements
      expect(find.text('KS'), findsOneWidget);
      expect(find.text('Kera Spare Tracker'), findsOneWidget);
      expect(find.text('Admin Console · Manager'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.text('Search owners, phones...'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
      expect(find.text('ADMIN DASHBOARD'), findsOneWidget);

      // 2. Hero Card
      expect(find.text('Total Registered Owners'), findsOneWidget);
      expect(find.text('81'), findsOneWidget);
      expect(find.text('+51 this week'), findsOneWidget);

      // 3. 4 Quick Actions
      expect(find.text('Add Owner'), findsOneWidget);
      expect(find.text('Approvals'), findsOneWidget);
      expect(find.text('Brands'), findsOneWidget);
      expect(find.text('Backup'), findsOneWidget);

      // 4. Platform Overview Section (2x3 Grid)
      expect(find.text('Platform overview'), findsOneWidget);
      expect(find.byType(AdminMetricTile), findsNWidgets(6));
      expect(find.text('Active Owners'), findsOneWidget);
      expect(find.text('Pending Approval'), findsOneWidget);
      expect(find.text('Total Parts'), findsOneWidget);
      expect(find.text('Sync Health'), findsOneWidget);
      expect(find.text('Total Revenue'), findsOneWidget);
      expect(find.text('Estimated Profit'), findsOneWidget);

      // 5. Administration Modules Section
      expect(find.text('Administration Modules'), findsOneWidget);
      expect(find.text('Sales Analytics & Reports'), findsOneWidget);
      expect(find.text('Revenue and profit analytics across stores'), findsOneWidget);
      expect(find.text('Sync Queue & Conflict Monitor'), findsOneWidget);
      expect(find.text('Resolve device conflicts & offline queues'), findsOneWidget);
    });

    testWidgets('Renders with 0 overflows at 320dp (narrow phone viewport)', (tester) async {
      tester.view.physicalSize = const Size(320, 680);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(width: 320, height: 680));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('81'), findsOneWidget);
      expect(find.text('Add Owner'), findsOneWidget);
      expect(find.text('Platform overview'), findsOneWidget);
    });

    testWidgets('Renders with 0 overflows in Dark Mode', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(width: 393, height: 852, theme: AppTheme.darkTheme),
      );
      await tester.pumpAndSettle();

      final error = tester.takeException();
      if (error is FlutterError) {
        debugPrint('FLUTTER ERROR MESSAGE: ${error.message}');
        for (final d in error.diagnostics) {
          debugPrint('${d.name}: ${d.toDescription()}');
        }
      }
      expect(error, isNull);
      expect(find.text('81'), findsOneWidget);
    });
  });
}

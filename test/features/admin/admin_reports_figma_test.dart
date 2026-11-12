import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kera_spare_tracker/core/theme/app_theme.dart';
import 'package:kera_spare_tracker/core/utils/result.dart';
import 'package:kera_spare_tracker/features/admin/domain/models/admin_models.dart';
import 'package:kera_spare_tracker/features/admin/domain/repositories/admin_repository.dart';
import 'package:kera_spare_tracker/features/admin/presentation/providers/admin_providers.dart';
import 'package:kera_spare_tracker/features/admin/presentation/screens/admin_reports_screen.dart';
import 'package:kera_spare_tracker/l10n/app_localizations.dart';

class _FakeAdminReportsRepo extends Fake implements AdminRepository {
  final bool returnPopulated;
  String lastRequestedPeriod = '';

  _FakeAdminReportsRepo({this.returnPopulated = false});

  @override
  Future<Result<AdminReportSummary>> getReportsSummary({String period = 'month'}) async {
    lastRequestedPeriod = period;

    if (returnPopulated) {
      return const Result.success(
        AdminReportSummary(
          period: 'month',
          totalRevenue: 7350.0,
          totalProfit: 2550.0,
          transactionsCount: 5,
          activeOwnersCount: 14,
          totalPartsCount: 76,
          points: [
            AdminReportPoint(label: 'Mon', revenue: 1200.0, profit: 450.0),
            AdminReportPoint(label: 'Tue', revenue: 2100.0, profit: 800.0),
            AdminReportPoint(label: 'Wed', revenue: 1550.0, profit: 500.0),
            AdminReportPoint(label: 'Thu', revenue: 2500.0, profit: 800.0),
          ],
          topSellingItems: [
            AdminTopSellingItem(
              partId: 'p1',
              name: 'Toyota Brake Pad Genuine',
              units: 24,
              totalAmount: 4800.0,
            ),
            AdminTopSellingItem(
              partId: 'p2',
              name: 'Oil Filter Standard 90915',
              units: 18,
              totalAmount: 1800.0,
            ),
          ],
        ),
      );
    }

    // Default matching Figma screenshot (media_1794778732566_84f95155.png)
    return const Result.success(
      AdminReportSummary(
        period: 'day',
        totalRevenue: 0.0,
        totalProfit: 0.0,
        transactionsCount: 0,
        activeOwnersCount: 81,
        totalPartsCount: 76,
        points: [],
        topSellingItems: [],
      ),
    );
  }
}

class _CompleterAdminReportsRepo extends Fake implements AdminRepository {
  final Completer<Result<AdminReportSummary>> completer;
  _CompleterAdminReportsRepo(this.completer);

  @override
  Future<Result<AdminReportSummary>> getReportsSummary({String period = 'month'}) =>
      completer.future;
}

Widget _buildTestApp({
  required double width,
  required double height,
  ThemeData? theme,
  Locale locale = const Locale('en'),
  AdminRepository? repo,
}) {
  return ProviderScope(
    overrides: [
      adminRepositoryProvider.overrideWithValue(repo ?? _FakeAdminReportsRepo()),
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
        Locale('en', ''),
        Locale('am', ''),
      ],
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          devicePixelRatio: 2.0,
          padding: const EdgeInsets.only(top: 24, bottom: 20),
        ),
        child: const SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: AdminReportsScreen(),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Admin System Reports & Analytics Figma Implementation Verification', () {
    testWidgets('Renders all Figma sections cleanly without overflows at 393x852 (Figma baseline)',
        (tester) async {
      tester.view.physicalSize = const Size(393 * 2.0, 852 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp(width: 393, height: 852));
      await tester.pumpAndSettle();

      // 1. Header Verification
      expect(find.text('System Reports'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);

      // 2. Period Selector Tabs
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);

      // 3. Financial Overview Card
      expect(find.text('Financial overview'), findsOneWidget);
      expect(find.text('Today'), findsAtLeastNWidgets(2)); // in header pill and transactions card
      expect(find.text('Total revenue'), findsOneWidget);
      expect(find.text('Est. profit'), findsOneWidget);
      expect(find.text('ETB '), findsNWidgets(2));

      // 4. Secondary KPI Cards
      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Platform-wide'), findsOneWidget);
      expect(find.text('81'), findsOneWidget);
      expect(find.text('Active owners'), findsOneWidget);

      // 5. Chart Card with Legend & Figma Empty State
      expect(find.text('Revenue & Profit Trend'), findsOneWidget);
      expect(find.text('Revenue'), findsOneWidget);
      expect(find.text('Profit'), findsOneWidget);
      expect(find.text('No financial activity yet'), findsOneWidget);
      expect(find.textContaining('Revenue and profit are both ETB 0'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders with 0 overflows at 320dp (narrow phone viewport)',
        (tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp(width: 320, height: 640));
      await tester.pumpAndSettle();

      expect(find.text('System Reports'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Financial overview'), findsOneWidget);
      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Active owners'), findsOneWidget);
      expect(find.text('Revenue & Profit Trend'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders with 0 overflows in Dark Mode', (tester) async {
      tester.view.physicalSize = const Size(393 * 2.0, 852 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp(
        width: 393,
        height: 852,
        theme: AppTheme.darkTheme,
      ));
      await tester.pumpAndSettle();

      expect(find.text('System Reports'), findsOneWidget);
      expect(find.text('Financial overview'), findsOneWidget);
      expect(find.text('Revenue & Profit Trend'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Period selector switches tabs and invalidates data dynamically',
        (tester) async {
      tester.view.physicalSize = const Size(393 * 2.0, 852 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = _FakeAdminReportsRepo();
      await tester.pumpWidget(_buildTestApp(width: 393, height: 852, repo: repo));
      await tester.pumpAndSettle();

      // Tap Weekly Tab
      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();
      expect(repo.lastRequestedPeriod, equals('weekly'));
      expect(find.text('This Week'), findsAtLeastNWidgets(1));

      // Tap Monthly Tab
      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();
      expect(repo.lastRequestedPeriod, equals('monthly'));
      expect(find.text('This Month'), findsAtLeastNWidgets(1));

      expect(tester.takeException(), isNull);
    });

    testWidgets('Populated state renders trend data and top selling parts with 0 overflows',
        (tester) async {
      tester.view.physicalSize = const Size(393 * 2.0, 852 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = _FakeAdminReportsRepo(returnPopulated: true);
      await tester.pumpWidget(_buildTestApp(width: 393, height: 852, repo: repo));
      await tester.pumpAndSettle();

      // Verifies populated metrics
      expect(find.text('7,350'), findsOneWidget);
      expect(find.text('2,550'), findsOneWidget);
      expect(find.text('5'), findsOneWidget); // 5 transactions
      expect(find.text('14'), findsOneWidget); // 14 active owners

      // Verifies top selling parts leaderboard
      expect(find.text('Top Selling Parts'), findsOneWidget);
      expect(find.text('Toyota Brake Pad Genuine'), findsOneWidget);
      expect(find.text('Oil Filter Standard 90915'), findsOneWidget);

      // Verifies chart points labels
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('Loading skeleton displays branded indicator with message', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final completer = Completer<Result<AdminReportSummary>>();
      final repo = _CompleterAdminReportsRepo(completer);

      await tester.pumpWidget(_buildTestApp(width: 393, height: 852, repo: repo));
      await tester.pump();

      // Verifies loading state
      expect(find.text('Loading financial analytics...'), findsOneWidget);

      // Complete future to clean up state
      completer.complete(const Result.success(AdminReportSummary(
        period: 'daily',
        totalRevenue: 0.0,
        totalProfit: 0.0,
        transactionsCount: 0,
        activeOwnersCount: 0,
        totalPartsCount: 0,
        points: [],
        topSellingItems: [],
      )));
      await tester.pumpAndSettle();
    });
  });
}

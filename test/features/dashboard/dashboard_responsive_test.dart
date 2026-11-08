import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/providers/theme_provider.dart';
import 'package:kera_spare_tracker/features/auth/domain/models/auth_user.dart';
import 'package:kera_spare_tracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:kera_spare_tracker/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:kera_spare_tracker/features/dashboard/presentation/screens/business_dashboard_screen.dart';
import 'package:kera_spare_tracker/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:kera_spare_tracker/features/parts/domain/models/part_item.dart';
import 'package:kera_spare_tracker/features/parts/presentation/providers/parts_providers.dart';
import 'package:kera_spare_tracker/features/reports/domain/models/chart_point.dart';
import 'package:kera_spare_tracker/features/reports/domain/models/date_range_filter.dart';
import 'package:kera_spare_tracker/features/reports/domain/models/report_period.dart';
import 'package:kera_spare_tracker/features/reports/domain/models/sales_summary.dart';
import 'package:kera_spare_tracker/features/reports/domain/models/top_selling_part.dart';
import 'package:kera_spare_tracker/features/sales/domain/models/sale_item_model.dart';
import 'package:kera_spare_tracker/features/sales/domain/models/sale_model.dart';
import 'package:kera_spare_tracker/features/sales/presentation/providers/sales_providers.dart';

class _FakeAuthController extends AuthController {
  final AuthUser? user;
  _FakeAuthController(this.user);
  @override
  Future<AuthUser?> build() async => user;
}

class _FakeThemeModeNotifier extends ThemeModeController {
  @override
  ThemeMode build() => ThemeMode.light;
}

class _FakeDateRangeNotifier extends DashboardDateRangeNotifier {
  @override
  DateRange build() => DateRange.forType(DateRangeType.today);
}

class _FakeChartPeriodNotifier extends DashboardChartPeriodNotifier {
  @override
  ReportPeriod build() => ReportPeriod.daily;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mockUser = AuthUser(
    id: 'user_1',
    ownerId: 'owner_1',
    phoneNumber: '+251911223344',
    businessName: 'Kera Spare Tracker Turbo Automotive Center',
    role: 'owner',
  );

  const mockMetrics = BusinessDashboardMetrics(
    totalQuantity: 523,
    totalSkus: 84,
    inventoryValue: 2850000,
    inventorySellingValue: 3873150,
    todayRevenue: 11000,
    todayProfit: 3800,
    profitMargin: 34.5,
    lowStockCount: 3,
    outOfStockCount: 1,
    hasItems: true,
  );

  const mockSalesSummary = SalesSummary(
    totalRevenue: 11000,
    totalProfit: 3800,
    salesCount: 14,
  );

  final mockSales = [
    SaleModel(
      id: 'sale_001_long_uuid_abcdef',
      ownerId: 'owner_1',
      receiptNumber: 'REC-2026-0089',
      soldAt: DateTime.now().subtract(const Duration(hours: 1)),
      subtotal: 4500,
      totalAmount: 4500,
      totalProfit: 1200,
      paymentMethod: 'Bank Transfer',
      items: const [
        SaleItemModel(
          id: 'item_1',
          saleId: 'sale_001_long_uuid_abcdef',
          partId: 'part_1',
          partNameSnapshot: 'Toyota Hilux Brake Rotor Ventilated Disc OEM-43512',
          quantity: 2,
          unitCost: 1650,
          unitPrice: 2250,
          lineTotal: 4500,
          lineProfit: 1200,
        ),
      ],
    ),
  ];

  final mockParts = [
    PartItem(
      id: 'part_1',
      ownerId: 'owner_1',
      name: 'Heavy Duty Truck Front Brake Pad Kit OEM-90919',
      partNumber: 'OEM-90919-02240',
      cachedQuantity: 2,
      lowStockLevel: 6,
      sellingPrice: 1850,
      purchasePrice: 1200,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    PartItem(
      id: 'part_2',
      ownerId: 'owner_1',
      name: 'High Performance Synthetic Engine Oil 5W-30 4L',
      partNumber: 'OIL-5W30-SYN',
      cachedQuantity: 0,
      lowStockLevel: 10,
      sellingPrice: 3200,
      purchasePrice: 2400,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
  ];

  final mockChartPoints = [
    ChartPoint(label: 'Mon', date: DateTime.now(), revenue: 3500, profit: 1200),
    ChartPoint(label: 'Tue', date: DateTime.now(), revenue: 4200, profit: 1500),
    ChartPoint(label: 'Wed', date: DateTime.now(), revenue: 2100, profit: 700),
    ChartPoint(label: 'Thu', date: DateTime.now(), revenue: 5800, profit: 2100),
    ChartPoint(label: 'Fri', date: DateTime.now(), revenue: 7400, profit: 2800),
  ];

  const mockTopSelling = [
    TopSellingPart(
      partId: 'part_1',
      partName: 'Toyota Land Cruiser Brake Pad OEM-04465',
      quantitySold: 42,
      totalRevenue: 84000,
    ),
    TopSellingPart(
      partId: 'part_2',
      partName: 'Isuzu NPR Clutch Disc Assembly 300mm',
      quantitySold: 28,
      totalRevenue: 67200,
    ),
  ];

  Widget buildTestWidget({required double width, required double height}) {
    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(mockUser)),
        themeModeControllerProvider.overrideWith(_FakeThemeModeNotifier.new),
        unreadNotificationsCountProvider.overrideWith((ref) => 2),
        businessDashboardMetricsProvider.overrideWithValue(const AsyncData(mockMetrics)),
        dashboardSalesSummaryProvider.overrideWith((ref) async => mockSalesSummary),
        activeSalesStreamProvider.overrideWith((ref) => Stream.value(mockSales)),
        partsStreamProvider.overrideWith((ref) => Stream.value(mockParts)),
        dashboardChartPointsProvider.overrideWith((ref) async => mockChartPoints),
        dashboardTopSellingPartsProvider.overrideWith((ref) async => mockTopSelling),
        dashboardDateRangeProvider.overrideWith(_FakeDateRangeNotifier.new),
        dashboardChartPeriodProvider.overrideWith(_FakeChartPeriodNotifier.new),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, height),
            padding: const EdgeInsets.only(top: 24, bottom: 16),
          ),
          child: SizedBox(
            width: width,
            height: height,
            child: const BusinessDashboardScreen(),
          ),
        ),
      ),
    );
  }

  group('Dashboard Zero RenderFlex Overflow Responsive Tests', () {
    setUp(() {
      FlutterError.onError = (FlutterErrorDetails details) {
        debugPrint('*** OVERFLOW DETAILS: ${details.exceptionAsString()}');
        if (details.informationCollector != null) {
          for (final node in details.informationCollector!()) {
            debugPrint('*** NODE: $node');
          }
        }
      };
    });
    final testSizes = [
      {'name': '320px (Ultra Compact Android)', 'width': 320.0, 'height': 640.0},
      {'name': '360px (Compact Android / Samsung A-Series)', 'width': 360.0, 'height': 800.0},
      {'name': '375px (Standard iPhone / Android)', 'width': 375.0, 'height': 812.0},
      {'name': '393px (Modern Android / Pixel 7)', 'width': 393.0, 'height': 852.0},
      {'name': '412px (Larger Android / Galaxy S23)', 'width': 412.0, 'height': 915.0},
      {'name': '600px (Tablet Portrait)', 'width': 600.0, 'height': 960.0},
    ];

    for (final size in testSizes) {
      testWidgets('renders cleanly without overflow on ${size['name']}', (tester) async {
        final width = size['width'] as double;
        final height = size['height'] as double;

        tester.view.physicalSize = Size(width, height);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget(width: width, height: height));
        await tester.pumpAndSettle();

        void findOverflowing(RenderObject node) {
          if (node is RenderFlex && node.toString().contains('OVERFLOWING')) {
            debugPrint('*** OVERFLOWING RENDERFLEX: ${node.debugCreator}');
          }
          node.visitChildren(findOverflowing);
        }
        for (final renderView in tester.binding.renderViews) {
          findOverflowing(renderView);
        }

        // Verify key dashboard widgets are mounted
        expect(find.text('Kera Spare Tracker'), findsWidgets);
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Total Stock'), findsOneWidget);
        expect(find.text('Stock Value'), findsOneWidget);
        expect(find.text('Record Sale'), findsOneWidget);
        expect(find.text('Sales Performance'), findsOneWidget);

        // Verify zero overflow exceptions
        final exception = tester.takeException();
        if (exception != null) {
          if (exception is FlutterError) {
            debugPrint(exception.toStringDeep(minLevel: DiagnosticLevel.debug));
          }
          debugPrint('>>> EXCEPTION ON $width px: $exception');
        }
        expect(exception, isNull);
      });
    }

    testWidgets('Header stays completely fixed at top when scrolling body content', (tester) async {
      tester.view.physicalSize = const Size(393.0, 852.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(width: 393.0, height: 852.0));
      await tester.pumpAndSettle();

      // Find the header title initial position
      final titleFinder = find.text('Kera Spare Tracker').first;
      final initialTitlePosition = tester.getTopLeft(titleFinder);

      // Verify search input initial position
      final searchFinder = find.textContaining('Search part');
      expect(searchFinder, findsOneWidget);
      final initialSearchPosition = tester.getTopLeft(searchFinder);

      // Find scroll view and body item before scroll
      final scrollFinder = find.byType(CustomScrollView);
      expect(scrollFinder, findsOneWidget);

      final reportsFinder = find.text('Reports');
      expect(reportsFinder, findsOneWidget);
      final initialReportsPosition = tester.getTopLeft(reportsFinder);

      // Scroll the body down by 300 pixels
      await tester.drag(scrollFinder, const Offset(0, -300));
      await tester.pumpAndSettle();

      // Verify header title has NOT moved (remains fixed at the top)
      final scrolledTitlePosition = tester.getTopLeft(titleFinder);
      expect(scrolledTitlePosition.dy, equals(initialTitlePosition.dy));

      // Verify search input has NOT moved (remains fixed)
      final scrolledSearchPosition = tester.getTopLeft(searchFinder);
      expect(scrolledSearchPosition.dy, equals(initialSearchPosition.dy));

      // Verify body item DID move up as body scrolled
      final scrolledReportsPosition = tester.getTopLeft(reportsFinder);
      expect(scrolledReportsPosition.dy, lessThan(initialReportsPosition.dy));

      // Verify no exceptions
      expect(tester.takeException(), isNull);
    });
  });
}

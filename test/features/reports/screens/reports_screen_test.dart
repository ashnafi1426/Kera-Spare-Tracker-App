import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/theme/app_theme.dart';
import 'package:kera_spare_tracker/features/reports/domain/models/chart_point.dart';
import 'package:kera_spare_tracker/features/reports/domain/models/inventory_valuation.dart';
import 'package:kera_spare_tracker/features/reports/domain/models/sales_summary.dart';
import 'package:kera_spare_tracker/features/reports/domain/models/top_selling_part.dart';
import 'package:kera_spare_tracker/features/reports/presentation/providers/reports_providers.dart';
import 'package:kera_spare_tracker/features/reports/presentation/screens/reports_screen.dart';
import 'package:kera_spare_tracker/l10n/app_localizations.dart';

void main() {
  Widget createWidget({
    SalesSummary summary = const SalesSummary(
      salesCount: 15,
      totalRevenue: 45000.0,
      totalProfit: 12500.0,
    ),
    List<ChartPoint>? points,
    List<TopSellingPart> topParts = const [
      TopSellingPart(partId: 'p1', partName: 'Cat Filter', quantitySold: 20, totalRevenue: 10000),
      TopSellingPart(partId: 'p2', partName: 'Doosan Pin', quantitySold: 12, totalRevenue: 6000),
    ],
    InventoryValuation valuation = const InventoryValuation(
      totalStockValue: 250000.0,
      lowStockCount: 3,
      totalActiveParts: 45,
    ),
  }) {
    final effectivePoints = points ??
        [
          ChartPoint(label: 'Mon', date: DateTime(2026, 10, 19), revenue: 5000, profit: 1500),
          ChartPoint(label: 'Tue', date: DateTime(2026, 10, 20), revenue: 8000, profit: 2400),
        ];

    return ProviderScope(
      overrides: [
        salesSummaryProvider.overrideWith((ref) async => summary),
        chartPointsProvider.overrideWith((ref) async => effectivePoints),
        topSellingPartsProvider.overrideWith((ref) async => topParts),
        inventoryValuationProvider.overrideWith((ref) async => valuation),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const ReportsScreen(),
      ),
    );
  }

  group('ReportsScreen Widget Tests', () {
    testWidgets('renders segmented buttons for Daily, Weekly, Monthly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
    });

    testWidgets('renders summary cards with formatted ETB amounts', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Number of Sales'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('Total Revenue'), findsWidgets);
      expect(find.text('ETB 45,000.00'), findsOneWidget);
      expect(find.text('Estimated Profit'), findsOneWidget);
      expect(find.text('ETB 12,500.00'), findsOneWidget);
    });

    testWidgets('renders top selling parts and inventory valuation cards', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Top 5 Selling Parts'), findsOneWidget);
      expect(find.text('Cat Filter'), findsOneWidget);
      expect(find.text('Doosan Pin'), findsOneWidget);

      expect(find.text('Total Stock Value'), findsOneWidget);
      expect(find.text('ETB 250,000.00'), findsOneWidget);

      expect(find.text('Low Stock Count'), findsOneWidget);
      expect(find.text('3 items at or below reorder limit'), findsOneWidget);
    });
  });
}

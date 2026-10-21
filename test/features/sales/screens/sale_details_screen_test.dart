import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/theme/app_theme.dart';
import 'package:kera_spare_tracker/features/sales/domain/models/sale_item_model.dart';
import 'package:kera_spare_tracker/features/sales/domain/models/sale_model.dart';
import 'package:kera_spare_tracker/features/sales/presentation/providers/sales_providers.dart';
import 'package:kera_spare_tracker/features/sales/presentation/screens/sale_details_screen.dart';
import 'package:kera_spare_tracker/l10n/app_localizations.dart';

void main() {
  final testSale = SaleModel(
    id: 'sale-det-1',
    ownerId: 'owner-1',
    receiptNumber: 'REC-998877',
    soldAt: DateTime(2026, 10, 21, 14, 30),
    subtotal: 5000.0,
    discount: 0.0,
    totalAmount: 5000.0,
    totalProfit: 1500.0,
    notes: 'Walk-in customer',
    items: [
      const SaleItemModel(
        id: 'item-1',
        saleId: 'sale-det-1',
        partId: 'part-1',
        partNameSnapshot: 'Turbo Hose 3-Inch',
        quantity: 2.0,
        unitCost: 1750.0,
        unitPrice: 2500.0,
        lineTotal: 5000.0,
        lineProfit: 1500.0,
      ),
    ],
  );

  Widget createWidget() {
    return ProviderScope(
      overrides: [
        saleByIdProvider('sale-det-1').overrideWith((ref) async => testSale),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const SaleDetailsScreen(saleId: 'sale-det-1'),
      ),
    );
  }

  group('SaleDetailsScreen Widget Tests', () {
    testWidgets('renders receipt details, line item snapshots, and profit', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('#REC-998877'), findsOneWidget);
      expect(find.text('Walk-in customer'), findsOneWidget);

      expect(find.text('Turbo Hose 3-Inch'), findsOneWidget);
      expect(find.text('2 × ETB 2,500.00'), findsOneWidget);
      expect(find.text('Profit: ETB 1,500.00'), findsOneWidget);

      expect(find.text('ETB 5,000.00'), findsWidgets);
      expect(find.text('ETB 3,500.00'), findsOneWidget); // total cost: 5000 - 1500
      expect(find.text('ETB 1,500.00'), findsWidgets); // total profit
    });
  });
}

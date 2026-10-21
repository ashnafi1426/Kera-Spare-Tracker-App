import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/utils/result.dart';
import 'package:kera_spare_tracker/features/parts/domain/models/part_item.dart';
import 'package:kera_spare_tracker/features/parts/presentation/providers/metadata_providers.dart';
import 'package:kera_spare_tracker/features/parts/presentation/providers/parts_providers.dart';
import 'package:kera_spare_tracker/features/sales/domain/models/sale_item_model.dart';
import 'package:kera_spare_tracker/features/sales/domain/models/sale_line_item.dart';
import 'package:kera_spare_tracker/features/sales/domain/models/sale_model.dart';
import 'package:kera_spare_tracker/features/sales/domain/repositories/sales_repository.dart';
import 'package:kera_spare_tracker/features/sales/presentation/providers/sales_providers.dart';
import 'package:kera_spare_tracker/features/sales/presentation/screens/new_sale_screen.dart';
import 'package:kera_spare_tracker/features/sales/presentation/screens/sale_success_screen.dart';
import 'package:kera_spare_tracker/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockSalesRepository extends Mock implements SalesRepository {}

class _PrepopulatedCartNotifier extends NewSaleCartNotifier {
  final PartItem initialPart;
  _PrepopulatedCartNotifier(this.initialPart);

  @override
  List<SaleLineItem> build() => [SaleLineItem.fromPart(initialPart)];
}

void main() {
  late MockSalesRepository mockSalesRepo;
  const ownerId = 'test_owner_sales';

  setUp(() {
    mockSalesRepo = MockSalesRepository();
  });

  Widget createTestWidget({
    required Widget child,
    List<dynamic> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        salesRepositoryProvider.overrideWithValue(mockSalesRepo),
        currentOwnerIdProvider.overrideWithValue(ownerId),
        partsStreamProvider.overrideWith((ref) => Stream.value(<PartItem>[])),
        ...overrides,
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('NewSaleScreen renders empty cart state when no parts added',
      (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        child: const NewSaleScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('New Sale'), findsOneWidget);
    expect(find.text('No Items in Sale'), findsOneWidget);
    expect(find.text('Search and add parts to record a sale'), findsOneWidget);
    expect(find.text('Complete Sale'), findsNothing);
  });

  testWidgets('NewSaleScreen displays line item and live totals when cart has items',
      (tester) async {
    final part = PartItem(
      id: 'part_p1',
      ownerId: ownerId,
      name: 'Fuel Injector Nozzle',
      cachedQuantity: 10.0,
      purchasePrice: 200.0,
      sellingPrice: 350.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      createTestWidget(
        overrides: [
          newSaleCartProvider.overrideWith(
            () => _PrepopulatedCartNotifier(part),
          ),
        ],
        child: const NewSaleScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fuel Injector Nozzle'), findsOneWidget);
    expect(find.text('Complete Sale'), findsOneWidget);
    expect(find.text('350.00 ብር'), findsWidgets);
  });

  testWidgets('SaleSuccessScreen renders receipt details and itemized summary',
      (tester) async {
    final sampleSale = SaleModel(
      id: 'sale_999',
      ownerId: ownerId,
      receiptNumber: 'REC-261021-TEST',
      soldAt: DateTime(2026, 10, 21, 14, 30),
      subtotal: 700.0,
      totalAmount: 700.0,
      totalProfit: 300.0,
      notes: 'Customer: John Doe',
      items: const [
        SaleItemModel(
          id: 'item_1',
          saleId: 'sale_999',
          partId: 'part_p1',
          partNameSnapshot: 'Fuel Injector Nozzle',
          quantity: 2.0,
          unitCost: 200.0,
          unitPrice: 350.0,
          lineTotal: 700.0,
          lineProfit: 300.0,
        ),
      ],
    );

    when(() => mockSalesRepo.getSaleById(ownerId: ownerId, saleId: 'sale_999'))
        .thenAnswer((_) async => Result.success(sampleSale));

    await tester.pumpWidget(
      createTestWidget(
        child: const SaleSuccessScreen(saleId: 'sale_999'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sale Recorded Successfully!'), findsWidgets);
    expect(find.text('REC-261021-TEST'), findsOneWidget);
    expect(find.text('Customer: John Doe'), findsOneWidget);
    expect(find.text('Fuel Injector Nozzle'), findsOneWidget);
    expect(find.text('700.00 ብር'), findsWidgets);
    expect(find.text('New Sale'), findsOneWidget);
    expect(find.text('Back to Home'), findsOneWidget);
  });
}

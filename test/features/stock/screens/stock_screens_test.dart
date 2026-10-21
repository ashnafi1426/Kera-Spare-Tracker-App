import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/features/parts/domain/models/part_item.dart';
import 'package:kera_spare_tracker/features/parts/presentation/providers/metadata_providers.dart';
import 'package:kera_spare_tracker/features/parts/presentation/providers/parts_providers.dart';
import 'package:kera_spare_tracker/features/stock/domain/models/stock_movement_item.dart';
import 'package:kera_spare_tracker/features/stock/domain/repositories/stock_repository.dart';
import 'package:kera_spare_tracker/features/stock/presentation/dialogs/update_stock_dialog.dart';
import 'package:kera_spare_tracker/features/stock/presentation/providers/stock_providers.dart';
import 'package:kera_spare_tracker/features/stock/presentation/screens/low_stock_screen.dart';
import 'package:kera_spare_tracker/features/stock/presentation/screens/stock_history_screen.dart';
import 'package:kera_spare_tracker/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockStockRepository extends Mock implements StockRepository {}

void main() {
  late MockStockRepository mockStockRepo;
  const ownerId = 'test_owner_101';

  setUp(() {
    mockStockRepo = MockStockRepository();
    when(() => mockStockRepo.getAllowNegativeStock())
        .thenAnswer((_) async => false);
  });

  Widget createTestWidget({
    required Widget child,
    List<dynamic> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        stockRepositoryProvider.overrideWithValue(mockStockRepo),
        currentOwnerIdProvider.overrideWithValue(ownerId),
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

  testWidgets('UpdateStockDialog renders segmented choices (Add, Remove, Adjust)',
      (tester) async {
    final part = PartItem(
      id: 'part_123',
      ownerId: ownerId,
      name: 'Brake Disc',
      cachedQuantity: 15.0,
      purchasePrice: 400.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      createTestWidget(
        child: UpdateStockDialog(part: part),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Part Name
    expect(find.text('Update Stock'), findsOneWidget);
    expect(find.text('Brake Disc'), findsOneWidget);
    expect(find.text('15.0'), findsOneWidget);

    // Verify 3 segmented options exist
    expect(find.text('Add Stock (Purchase)'), findsWidgets);
    expect(find.text('Remove Stock'), findsOneWidget);
    expect(find.text('Adjust to Counted Number'), findsOneWidget);

    // Default is Add Stock
    expect(find.text('Quantity to Add'), findsOneWidget);

    // Tap Remove Stock tab
    await tester.tap(find.text('Remove Stock'));
    await tester.pumpAndSettle();
    expect(find.text('Quantity to Remove'), findsOneWidget);

    // Tap Adjust tab
    await tester.tap(find.text('Adjust to Counted Number'));
    await tester.pumpAndSettle();
    expect(find.text('Counted Quantity'), findsOneWidget);
  });

  testWidgets('StockHistoryScreen renders empty state when no movements exist',
      (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        overrides: [
          partByIdProvider('part_no_movements')
              .overrideWith((ref) async => null),
          partMovementsStreamProvider('part_no_movements')
              .overrideWith((ref) => Stream.value(<StockMovementItem>[])),
        ],
        child: const StockHistoryScreen(partId: 'part_no_movements'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Movement History'), findsOneWidget);
    expect(find.text('No Movements Yet'), findsOneWidget);
  });

  testWidgets('LowStockScreen renders empty state when all inventory is healthy',
      (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        overrides: [
          lowStockPartsStreamProvider
              .overrideWith((ref) => Stream.value(<PartItem>[])),
        ],
        child: const LowStockScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Low Stock Items'), findsOneWidget);
    expect(
      find.text('No low stock items. All inventory levels are healthy!'),
      findsOneWidget,
    );
  });
}

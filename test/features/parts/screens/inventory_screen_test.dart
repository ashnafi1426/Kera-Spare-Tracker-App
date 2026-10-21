import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/utils/result.dart';
import 'package:kera_spare_tracker/features/parts/domain/models/inventory_filter.dart';
import 'package:kera_spare_tracker/features/parts/domain/models/paged_result.dart';
import 'package:kera_spare_tracker/features/parts/domain/models/part_item.dart';
import 'package:kera_spare_tracker/features/parts/domain/repositories/parts_repository.dart';
import 'package:kera_spare_tracker/features/parts/presentation/providers/metadata_providers.dart';
import 'package:kera_spare_tracker/features/parts/presentation/providers/parts_providers.dart';
import 'package:kera_spare_tracker/features/parts/presentation/screens/inventory_screen.dart';
import 'package:kera_spare_tracker/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockPartsRepository extends Mock implements PartsRepository {}

Widget _buildTestApp({
  required Widget child,
  required MockPartsRepository mockRepo,
}) {
  return ProviderScope(
    overrides: [
      partsRepositoryProvider.overrideWithValue(mockRepo),
      currentOwnerIdProvider.overrideWithValue('test_owner'),
      brandsStreamProvider.overrideWith((ref) => Stream.value([])),
      categoriesStreamProvider.overrideWith((ref) => Stream.value([])),
      locationsStreamProvider.overrideWith((ref) => Stream.value([])),
    ],
    child: MaterialApp(
      locale: const Locale('am'),
      supportedLocales: const [Locale('am'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
  );
}

void main() {
  late MockPartsRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(const InventoryFilter());
  });

  setUp(() {
    mockRepo = MockPartsRepository();
  });

  testWidgets('InventoryScreen renders search bar, stock chips, and paged parts',
      (WidgetTester tester) async {
    final sampleParts = [
      PartItem(
        id: 'p1',
        ownerId: 'test_owner',
        name: 'Oil Filter CAT',
        partNumber: '1R-0716',
        brandName: 'CAT',
        sellingPrice: 1200.0,
        cachedQuantity: 15.0,
        unit: 'pcs',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      PartItem(
        id: 'p2',
        ownerId: 'test_owner',
        name: 'Brake Pad Set',
        partNumber: 'BP-2020',
        brandName: 'CTP',
        sellingPrice: 2400.0,
        cachedQuantity: 2.0,
        lowStockLevel: 5.0,
        unit: 'set',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    when(() => mockRepo.getPagedParts(
          ownerId: any(named: 'ownerId'),
          filter: any(named: 'filter'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        )).thenAnswer((_) async => Result.success(PagedResult(
          items: sampleParts,
          totalCount: 2,
          offset: 0,
          limit: 40,
        )));

    await tester.pumpWidget(
      _buildTestApp(
        child: const InventoryScreen(),
        mockRepo: mockRepo,
      ),
    );
    await tester.pumpAndSettle();

    // Verify Search bar
    expect(find.byType(TextField), findsOneWidget);

    // Verify Quick Stock Chips
    expect(find.text('ሁሉም'), findsOneWidget);
    expect(find.text('ክምችት ያለው'), findsOneWidget);
    expect(find.text('አነስተኛ ክምችት'), findsOneWidget);
    expect(find.text('ያለቀ'), findsOneWidget);

    // Verify Parts rendered
    expect(find.text('Oil Filter CAT'), findsOneWidget);
    expect(find.text('#1R-0716'), findsOneWidget);
    expect(find.text('CAT'), findsOneWidget);
    expect(find.text('1200 ብር'), findsOneWidget);
    expect(find.text('15 pcs'), findsOneWidget);

    expect(find.text('Brake Pad Set'), findsOneWidget);
    expect(find.text('#BP-2020'), findsOneWidget);
    expect(find.text('2400 ብር'), findsOneWidget);
  });

  testWidgets('InventoryScreen debounces search input and refreshes list',
      (WidgetTester tester) async {
    when(() => mockRepo.getPagedParts(
          ownerId: any(named: 'ownerId'),
          filter: any(named: 'filter'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        )).thenAnswer((_) async => const Result.success(PagedResult(
          items: [],
          totalCount: 0,
          offset: 0,
          limit: 40,
        )));

    await tester.pumpWidget(
      _buildTestApp(
        child: const InventoryScreen(),
        mockRepo: mockRepo,
      ),
    );
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'hydraulic');
    await tester.pump(const Duration(milliseconds: 100)); // Within debounce

    // Not yet called with 'hydraulic'
    verifyNever(() => mockRepo.getPagedParts(
          ownerId: any(named: 'ownerId'),
          filter: any(
            named: 'filter',
            that: isA<InventoryFilter>()
                .having((f) => f.query, 'query', equals('hydraulic')),
          ),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ));

    // Fast forward past 300ms debounce
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    verify(() => mockRepo.getPagedParts(
          ownerId: 'test_owner',
          filter: any(
            named: 'filter',
            that: isA<InventoryFilter>()
                .having((f) => f.query, 'query', equals('hydraulic')),
          ),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        )).called(1);
  });
}

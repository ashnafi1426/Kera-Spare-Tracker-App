import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/features/auth/domain/models/auth_user.dart';
import 'package:kera_spare_tracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:kera_spare_tracker/features/parts/domain/models/part_item.dart';
import 'package:kera_spare_tracker/features/parts/presentation/providers/metadata_providers.dart';
import 'package:kera_spare_tracker/features/parts/presentation/providers/parts_providers.dart';
import 'package:kera_spare_tracker/features/sales/domain/models/sale_line_item.dart';
import 'package:kera_spare_tracker/features/sales/domain/models/sale_model.dart';
import 'package:kera_spare_tracker/features/sales/domain/repositories/sales_repository.dart';
import 'package:kera_spare_tracker/features/sales/presentation/providers/sales_providers.dart';
import 'package:kera_spare_tracker/features/sales/presentation/screens/sales_pos_screen.dart';
import 'package:kera_spare_tracker/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockSalesRepository extends Mock implements SalesRepository {}

class _PrepopulatedCartNotifier extends NewSaleCartNotifier {
  final List<SaleLineItem> initialItems;
  _PrepopulatedCartNotifier(this.initialItems);

  @override
  List<SaleLineItem> build() => initialItems;
}

class _FakeAuthController extends AuthController {
  final AuthUser? user;
  _FakeAuthController(this.user);

  @override
  Future<AuthUser?> build() async => user;
}

void main() {
  late MockSalesRepository mockSalesRepo;
  const ownerId = 'test_owner_sales_pos';

  const sampleUser = AuthUser(
    id: 'user_1',
    businessName: 'Kera Spare Tracker',
    role: 'owner',
    status: 'active',
    ownerId: ownerId,
    phoneNumber: '+251911000000',
  );

  final sampleParts = [
    PartItem(
      id: 'part_1',
      ownerId: ownerId,
      name: 'Brake Disc',
      partNumber: 'CAT-1000',
      cachedQuantity: 15.0,
      purchasePrice: 15000.0,
      sellingPrice: 21000.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    PartItem(
      id: 'part_2',
      ownerId: ownerId,
      name: 'Alternator',
      partNumber: 'CAT-1011',
      cachedQuantity: 8.0,
      purchasePrice: 500.0,
      sellingPrice: 700.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  final sampleSales = [
    SaleModel(
      id: 'sale_1',
      ownerId: ownerId,
      receiptNumber: 'REC-261108-0001',
      soldAt: DateTime.now(),
      subtotal: 21000.0,
      totalAmount: 21000.0,
      totalProfit: 6000.0,
      items: const [],
    ),
  ];

  setUp(() {
    mockSalesRepo = MockSalesRepository();
  });

  Widget createTestWidget({
    required Widget child,
    List<dynamic> overrides = const [],
    Size size = const Size(390, 844),
  }) {
    return ProviderScope(
      overrides: [
        salesRepositoryProvider.overrideWithValue(mockSalesRepo),
        currentOwnerIdProvider.overrideWithValue(ownerId),
        authControllerProvider.overrideWith(() => _FakeAuthController(sampleUser)),
        partsStreamProvider.overrideWith((ref) => Stream.value(sampleParts)),
        activeSalesStreamProvider.overrideWith((ref) => Stream.value(sampleSales)),
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
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: child,
        ),
      ),
    );
  }

  testWidgets('SalesPosScreen renders top masthead, title row, and 3 KPI cards',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      createTestWidget(child: const SalesPosScreen()),
    );
    await tester.pumpAndSettle();

    // Verify Brand Masthead
    expect(find.text('Kera Spare Tracker'), findsWidgets);
    expect(find.text('Track • Manage • Grow'), findsOneWidget);

    // Verify Title & Period
    expect(find.text('Sales'), findsOneWidget);
    expect(find.text('Record and manage your sales'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);

    // Verify 3 KPI Cards
    expect(find.text('Today Sales'), findsOneWidget);
    expect(find.text('Total Revenue'), findsOneWidget);
    expect(find.text('Profit'), findsOneWidget);

    // Verify Search Bar
    expect(find.text('Search for parts...'), findsOneWidget);
    expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);

    // Verify Empty Cart State (Mockup Match)
    expect(find.text('No items in cart yet!'), findsOneWidget);
    expect(find.text('Search and add parts to record a sale'), findsOneWidget);
    expect(find.text('Browse Parts'), findsOneWidget);

    // Verify Recent Sales Section
    expect(find.text('Recent Sales'), findsOneWidget);
    expect(find.text('View All'), findsOneWidget);

    // Verify Floating Button
    expect(find.text('New Sale'), findsOneWidget);
  });

  testWidgets('SalesPosScreen renders interactive cart with stepper controls when items added',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final cartItem = SaleLineItem.fromPart(sampleParts.first, quantity: 2.0);

    await tester.pumpWidget(
      createTestWidget(
        overrides: [
          newSaleCartProvider.overrideWith(
            () => _PrepopulatedCartNotifier([cartItem]),
          ),
        ],
        child: const SalesPosScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Cart Title & Part Name
    expect(find.text('Shopping Cart (1 part)'), findsOneWidget);
    expect(find.text('Brake Disc'), findsWidgets);

    // Verify Stepper shows quantity 2
    expect(find.text('2'), findsOneWidget);

    // Verify Subtotal (2 * 21000 = 42000 ETB)
    expect(find.text('Subtotal: 42,000.00 ETB'), findsOneWidget);

    // Verify Customer selector & Payment Method
    expect(find.text('Walk-in Customer'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('Grand Total'), findsOneWidget);
    expect(find.text('42,000.00 ETB'), findsWidgets);

    // Verify Complete Sale Button
    expect(find.textContaining('Complete Sale · 42,000.00 ETB'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/utils/result.dart';
import 'package:kera_spare_tracker/features/auth/domain/models/auth_user.dart';
import 'package:kera_spare_tracker/features/auth/presentation/controllers/auth_controller.dart';
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

class _FakeAuthController extends AuthController {
  final AuthUser? user;
  _FakeAuthController(this.user);
  @override
  Future<AuthUser?> build() async => user;
}

const mockUser = AuthUser(
  id: 'test_owner',
  ownerId: 'test_owner',
  phoneNumber: '+251911000000',
  role: 'OWNER',
  businessName: 'Kera Spare Tracker',
  status: 'ACTIVE',
);

Widget _buildTestApp({
  required Widget child,
  required MockPartsRepository mockRepo,
  List<PartItem> parts = const [],
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => _FakeAuthController(mockUser)),
      partsRepositoryProvider.overrideWithValue(mockRepo),
      partsStreamProvider.overrideWith((ref) => Stream.value(parts)),
      pendingSyncCountProvider.overrideWith((ref) => Stream.value(44)),
      currentOwnerIdProvider.overrideWithValue('test_owner'),
      brandsStreamProvider.overrideWith((ref) => Stream.value([])),
      categoriesStreamProvider.overrideWith((ref) => Stream.value([])),
      locationsStreamProvider.overrideWith((ref) => Stream.value([])),
    ],
    child: MaterialApp(
      locale: locale,
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

  final sampleParts = [
    PartItem(
      id: 'p1',
      ownerId: 'test_owner',
      name: 'Brake pad set',
      partNumber: '04465-0K240',
      categoryName: 'CAT-1000',
      customLocation: 'Shelf 4',
      brandName: 'Toyota Genuine',
      sellingPrice: 21000.0,
      cachedQuantity: 0.0,
      unit: 'pcs',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    PartItem(
      id: 'p2',
      ownerId: 'test_owner',
      name: 'Engine air filter',
      partNumber: '28113-1R100',
      categoryName: 'CAT-1011',
      customLocation: 'Shelf 1',
      brandName: 'Hyundai Genuine',
      sellingPrice: 1850.0,
      cachedQuantity: 13.0,
      unit: 'pcs',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  void stubRepo() {
    when(() => mockRepo.getPagedParts(
          ownerId: any(named: 'ownerId'),
          filter: any(named: 'filter'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        )).thenAnswer((_) async => Result.success(PagedResult(
          items: sampleParts,
          totalCount: 25,
          offset: 0,
          limit: 40,
        )));
  }

  final testBreakpoints = [
    (width: 320.0, height: 600.0, name: '320px (Ultra-compact Android)'),
    (width: 360.0, height: 740.0, name: '360px (Standard Budget Android / Samsung A)'),
    (width: 375.0, height: 812.0, name: '375px (Compact iPhone)'),
    (width: 393.0, height: 852.0, name: '393px (Modern Android / Pixel 7)'),
    (width: 412.0, height: 915.0, name: '412px (Galaxy S23 / Pixel 8 Pro)'),
    (width: 600.0, height: 960.0, name: '600px (Tablet portrait)'),
  ];

  for (final bp in testBreakpoints) {
    testWidgets('InventoryScreen renders without overflow on ${bp.name}',
        (WidgetTester tester) async {
      tester.view.physicalSize = Size(bp.width, bp.height);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      stubRepo();

      await tester.pumpWidget(
        _buildTestApp(
          child: const InventoryScreen(),
          mockRepo: mockRepo,
          parts: sampleParts,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Zero RenderFlex overflows
      expect(tester.takeException(), isNull);

      // Verify header and inventory title
      expect(find.text('Kera Spare Tracker'), findsOneWidget);
      expect(find.text('Inventory'), findsOneWidget);
    });
  }

  testWidgets('InventoryScreen Amharic localization renders without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    stubRepo();

    await tester.pumpWidget(
      _buildTestApp(
        child: const InventoryScreen(),
        mockRepo: mockRepo,
        parts: sampleParts,
        locale: const Locale('am'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('Kera Spare Tracker'), findsOneWidget);
    expect(find.textContaining('ዕቃዎች'), findsWidgets);
  });
}

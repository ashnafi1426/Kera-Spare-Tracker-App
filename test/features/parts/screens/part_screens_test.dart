import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/utils/result.dart';
import 'package:kera_spare_tracker/features/parts/domain/models/part_item.dart';
import 'package:kera_spare_tracker/features/parts/domain/repositories/parts_repository.dart';
import 'package:kera_spare_tracker/features/parts/presentation/providers/metadata_providers.dart';
import 'package:kera_spare_tracker/features/parts/presentation/providers/parts_providers.dart';
import 'package:kera_spare_tracker/features/parts/presentation/screens/part_details_screen.dart';
import 'package:kera_spare_tracker/features/parts/presentation/screens/part_form_screen.dart';
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

  setUp(() {
    mockRepo = MockPartsRepository();
  });

  testWidgets('PartFormScreen allows saving a part with only name provided',
      (WidgetTester tester) async {
    when(() => mockRepo.createPart(
          ownerId: any(named: 'ownerId'),
          name: any(named: 'name'),
          partNumber: any(named: 'partNumber'),
          photoLocalPath: any(named: 'photoLocalPath'),
          photoUrl: any(named: 'photoUrl'),
          brandId: any(named: 'brandId'),
          categoryId: any(named: 'categoryId'),
          locationId: any(named: 'locationId'),
          customLocation: any(named: 'customLocation'),
          description: any(named: 'description'),
          unit: any(named: 'unit'),
          purchasePrice: any(named: 'purchasePrice'),
          sellingPrice: any(named: 'sellingPrice'),
          sizeSpecs: any(named: 'sizeSpecs'),
          notes: any(named: 'notes'),
          initialQuantity: any(named: 'initialQuantity'),
        )).thenAnswer((_) async => Result.success(PartItem(
          id: 'new_part_id',
          ownerId: 'test_owner',
          name: 'Oil Filter Standard',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )));

    await tester.pumpWidget(
      _buildTestApp(
        child: const PartFormScreen(),
        mockRepo: mockRepo,
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('አዲስ የመለዋወጫ ዕቃ መዝግብ'), findsOneWidget);

    // Enter only Part Name
    final nameField = find.widgetWithText(TextFormField, 'የዕቃው ስም');
    await tester.enterText(nameField, 'Oil Filter Standard');
    await tester.pumpAndSettle();

    // Tap Save button in AppBar
    final saveBtn = find.text('አስቀምጥ');
    expect(saveBtn, findsOneWidget);
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    verify(() => mockRepo.createPart(
          ownerId: 'test_owner',
          name: 'Oil Filter Standard',
          partNumber: any(named: 'partNumber'),
          photoLocalPath: any(named: 'photoLocalPath'),
          photoUrl: any(named: 'photoUrl'),
          brandId: any(named: 'brandId'),
          categoryId: any(named: 'categoryId'),
          locationId: any(named: 'locationId'),
          customLocation: any(named: 'customLocation'),
          description: any(named: 'description'),
          unit: any(named: 'unit'),
          purchasePrice: any(named: 'purchasePrice'),
          sellingPrice: any(named: 'sellingPrice'),
          sizeSpecs: any(named: 'sizeSpecs'),
          notes: any(named: 'notes'),
          initialQuantity: any(named: 'initialQuantity'),
        )).called(1);
  });

  testWidgets('PartDetailsScreen renders details, metrics, and triggers delete confirmation',
      (WidgetTester tester) async {
    final part = PartItem(
      id: 'part_123',
      ownerId: 'test_owner',
      name: 'Turbine Bearing',
      partNumber: 'TB-9901',
      unit: 'pcs',
      cachedQuantity: 8.0,
      purchasePrice: 2000.0,
      sellingPrice: 3200.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    when(() => mockRepo.getPartById(
          ownerId: any(named: 'ownerId'),
          id: 'part_123',
        )).thenAnswer((_) async => Result.success(part));

    when(() => mockRepo.deletePart(
          ownerId: any(named: 'ownerId'),
          id: 'part_123',
        )).thenAnswer((_) async => const Result.success(null));

    await tester.pumpWidget(
      _buildTestApp(
        child: const PartDetailsScreen(partId: 'part_123'),
        mockRepo: mockRepo,
      ),
    );
    await tester.pumpAndSettle();

    // Verify displayed data
    expect(find.text('Turbine Bearing'), findsOneWidget);
    expect(find.text('TB-9901'), findsOneWidget);
    expect(find.text('8 pcs'), findsOneWidget);
    expect(find.text('2000.00 ብር'), findsOneWidget);
    expect(find.text('3200.00 ብር'), findsOneWidget);
    expect(find.text('1200.00 ብር'), findsOneWidget); // Profit

    // Tap Delete button in AppBar
    final deleteIcon = find.byIcon(Icons.delete_outline_rounded);
    expect(deleteIcon, findsOneWidget);
    await tester.tap(deleteIcon);
    await tester.pumpAndSettle();

    // Verify Delete confirmation dialog
    expect(find.text('ይህንን ዕቃ መሰረዝ ይፈልጋሉ?'), findsOneWidget);
    expect(find.text('ዕቃው ከክምችት ይሰረዛል። ከዚህ በፊት የተመዘገቡ የሽያጭ መረጃዎች አይነኩም።'),
        findsOneWidget);

    // Tap confirm delete in dialog
    final confirmBtn = find.widgetWithText(ElevatedButton, 'አጥፋ');
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    verify(() => mockRepo.deletePart(ownerId: 'test_owner', id: 'part_123'))
        .called(1);
  });
}

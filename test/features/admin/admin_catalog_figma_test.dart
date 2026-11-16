import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kera_spare_tracker/core/design/widgets/list_card.dart';
import 'package:kera_spare_tracker/core/theme/app_theme.dart';
import 'package:kera_spare_tracker/core/utils/result.dart';
import 'package:kera_spare_tracker/features/admin/domain/models/admin_models.dart';
import 'package:kera_spare_tracker/features/admin/domain/repositories/admin_repository.dart';
import 'package:kera_spare_tracker/features/admin/presentation/providers/admin_providers.dart';
import 'package:kera_spare_tracker/features/admin/presentation/screens/admin_global_catalog_screen.dart';
import 'package:kera_spare_tracker/l10n/app_localizations.dart';

class _FakeAdminRepo extends Fake implements AdminRepository {
  @override
  Future<Result<List<GlobalCatalogItem>>> getBrands() async {
    final list = [
      const GlobalCatalogItem(
        id: 'brand-1',
        name: 'Brand_1793813333726',
        isActive: false,
      ),
      const GlobalCatalogItem(
        id: 'brand-2',
        name: 'Brand_1793817388145',
        isActive: false,
      ),
      const GlobalCatalogItem(
        id: 'brand-3',
        name: 'Brand_1793890772473',
        isActive: false,
      ),
      const GlobalCatalogItem(
        id: 'brand-4',
        name: 'Toyota Genuine Parts',
        isActive: true,
      ),
    ];
    return Result.success(list);
  }

  @override
  Future<Result<List<GlobalCatalogItem>>> getCategories() async {
    return const Result.success([
      GlobalCatalogItem(id: 'cat-1', name: 'Engine Components', isActive: true),
      GlobalCatalogItem(id: 'cat-2', name: 'Brake Systems', isActive: true),
    ]);
  }

  @override
  Future<Result<List<GlobalCatalogItem>>> getUnits() async {
    return const Result.success([
      GlobalCatalogItem(id: 'unit-1', name: 'Piece (pcs)', isActive: true),
      GlobalCatalogItem(id: 'unit-2', name: 'Set', isActive: true),
    ]);
  }

  @override
  Future<Result<GlobalCatalogItem>> createBrand(String name) async {
    return Result.success(GlobalCatalogItem(id: 'new-id', name: name));
  }

  @override
  Future<Result<GlobalCatalogItem>> updateBrand(String id, {String? name, bool? isActive}) async {
    return Result.success(GlobalCatalogItem(id: id, name: name ?? 'Updated', isActive: isActive ?? true));
  }
}

Widget _buildTestApp({
  required double width,
  required double height,
  ThemeData? theme,
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [
      adminRepositoryProvider.overrideWithValue(_FakeAdminRepo()),
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
        Locale('en'),
        Locale('am'),
      ],
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: const AdminGlobalCatalogScreen(),
        ),
      ),
    ),
  );
}

void main() {
  group('Global Catalog Management Figma Implementation Verification', () {
    testWidgets('Renders all Figma sections cleanly without overflows at 393x852 (Figma baseline)', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(width: 393, height: 852));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // 1. Header elements
      expect(find.text('KERA / SPARE TRACKER'), findsOneWidget);
      expect(find.text('Global Catalog Management'), findsOneWidget);
      expect(find.text('Brands'), findsWidgets);
      expect(find.text('Categories'), findsWidgets);
      expect(find.text('Units'), findsWidgets);

      // 2. Section Title & CTA Row
      expect(find.text('Shared across all locations'), findsOneWidget);
      expect(find.text('Add New'), findsOneWidget);

      // 3. Search & Filter
      expect(find.text('Search brands...'), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

      // 4. Status Filter Segments
      expect(find.textContaining('All'), findsWidgets);
      expect(find.textContaining('Active'), findsWidgets);
      expect(find.textContaining('Inactive'), findsWidgets);

      // 5. Item Cards
      expect(find.byType(ListCard), findsWidgets);
      expect(find.text('Brand_1793813333726'), findsOneWidget);
      expect(find.text('Toyota Genuine Parts'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(4));
    });

    testWidgets('Renders with 0 overflows at 320dp (narrow phone viewport)', (tester) async {
      tester.view.physicalSize = const Size(320, 680);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(width: 320, height: 680));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Global Catalog Management'), findsOneWidget);
      expect(find.text('Add New'), findsOneWidget);
      expect(find.byType(ListCard), findsWidgets);
    });

    testWidgets('Renders with 0 overflows in Dark Mode', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(width: 393, height: 852, theme: AppTheme.darkTheme),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Global Catalog Management'), findsOneWidget);
      expect(find.byType(ListCard), findsWidgets);
    });

    testWidgets('Switches tabs between Brands, Categories and Units cleanly', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(width: 393, height: 852));
      await tester.pumpAndSettle();

      // Tap Categories tab
      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Engine Components'), findsOneWidget);
      expect(find.text('Brake Systems'), findsOneWidget);

      // Tap Units tab
      await tester.tap(find.text('Units'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Piece (pcs)'), findsOneWidget);
      expect(find.text('Set'), findsOneWidget);
    });
  });
}


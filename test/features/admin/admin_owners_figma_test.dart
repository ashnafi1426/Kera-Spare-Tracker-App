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
import 'package:kera_spare_tracker/features/admin/presentation/screens/admin_owners_list_screen.dart';
import 'package:kera_spare_tracker/l10n/app_localizations.dart';

class _FakeAdminRepo extends Fake implements AdminRepository {
  @override
  Future<Result<Map<String, dynamic>>> getOwners({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    int? inactiveDays,
    String? sortBy,
  }) async {
    final list = [
      AdminOwnerSummary(
        id: 'owner-1',
        phoneNumber: '+251911223706',
        businessName: 'Password Change Test Auto',
        status: 'ACTIVE',
        partsCount: 0,
        salesCount: 0,
        failedSyncCount: 0,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        lastSyncAt: null,
      ),
      AdminOwnerSummary(
        id: 'owner-2',
        phoneNumber: '+251922334367',
        businessName: 'Suspended Motors',
        status: 'SUSPENDED',
        partsCount: 0,
        salesCount: 0,
        failedSyncCount: 5,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        lastSyncAt: null,
      ),
      AdminOwnerSummary(
        id: 'owner-3',
        phoneNumber: '+251933445566',
        businessName: 'Kera Genuine Motors',
        status: 'ACTIVE',
        partsCount: 45,
        salesCount: 120,
        failedSyncCount: 0,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastSyncAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
    ];

    return Result.success({
      'owners': list,
      'pagination': {
        'page': 1,
        'limit': 20,
        'total': 81,
        'totalPages': 5,
      },
    });
  }

  @override
  Future<Result<Map<String, dynamic>>> resetOwnerPassword(String ownerId) async {
    return const Result.success({'temporaryPassword': 'TEST-TEMP-999'});
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
          child: const AdminOwnersListScreen(),
        ),
      ),
    ),
  );
}

void main() {
  group('Business Owners Directory Figma Implementation Verification', () {
    testWidgets('Renders all Figma sections cleanly without overflows at 393x852 (Figma baseline)', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(width: 393, height: 852));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // 1. Header elements
      expect(find.text('KS'), findsOneWidget);
      expect(find.text('Kera Spare Tracker'), findsOneWidget);
      expect(find.text('Admin Console · Manager'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.text('Search owners, phones, stores...'), findsOneWidget);
      expect(find.text('BUSINESS OWNERS'), findsOneWidget);

      // 2. Title & Action Row
      expect(find.text('Business Owners Directory'), findsOneWidget);
      expect(find.text('81 registered store accounts'), findsOneWidget);
      expect(find.text('Add Owner'), findsOneWidget);

      // 3. 4 Filter Chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Suspended'), findsWidgets);
      expect(find.text('Inactive (>30d)'), findsOneWidget);

      // 4. Results Toolbar
      expect(find.text('Showing 3 / 81'), findsOneWidget);
      expect(find.text('Sort: Newest'), findsOneWidget);

      // 5. Owner Cards
      expect(find.byType(ListCard), findsNWidgets(3));
      expect(find.text('Password Change Test Auto'), findsOneWidget);
      expect(find.text('Suspended Motors'), findsOneWidget);
      expect(find.text('Kera Genuine Motors'), findsOneWidget);

      // 6. Action buttons on cards
      expect(find.text('View Details'), findsNWidgets(3));
      expect(find.text('Reset Password'), findsNWidgets(3));
    });

    testWidgets('Renders with 0 overflows at 320dp (narrow phone viewport)', (tester) async {
      tester.view.physicalSize = const Size(320, 680);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(width: 320, height: 680));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Business Owners Directory'), findsOneWidget);
      expect(find.text('Add Owner'), findsOneWidget);
      expect(find.byType(ListCard), findsNWidgets(3));
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
      expect(find.text('Business Owners Directory'), findsOneWidget);
      expect(find.byType(ListCard), findsNWidgets(3));
    });
  });
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/theme/app_theme.dart';
import 'package:kera_spare_tracker/core/utils/result.dart';
import 'package:kera_spare_tracker/features/auth/domain/models/auth_user.dart';
import 'package:kera_spare_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:kera_spare_tracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:kera_spare_tracker/features/settings/presentation/screens/settings_screen.dart';
import 'package:kera_spare_tracker/features/stock/domain/repositories/stock_repository.dart';
import 'package:kera_spare_tracker/features/stock/presentation/providers/stock_providers.dart';
import 'package:kera_spare_tracker/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockStockRepository extends Mock implements StockRepository {}

void main() {
  const testUser = AuthUser(
    id: 'user-settings-1',
    ownerId: 'owner-settings-1',
    phoneNumber: '+251911223344',
    businessName: 'Kera Diesel Heavy Spares',
    role: 'owner',
  );

  late MockAuthRepository mockAuthRepo;
  late MockStockRepository mockStockRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockStockRepo = MockStockRepository();

    when(() => mockAuthRepo.currentUser()).thenAnswer((_) async => const Result.success(testUser));
    when(() => mockAuthRepo.watchCurrentUser()).thenAnswer((_) => Stream.value(testUser));
    when(() => mockStockRepo.getAllowNegativeStock()).thenAnswer((_) async => false);
  });

  Widget createWidget() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        stockRepositoryProvider.overrideWithValue(mockStockRepo),
        lowStockPartsStreamProvider.overrideWith((ref) => Stream.value([])),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const SettingsScreen(),
      ),
    );
  }

  group('SettingsScreen Widget Tests', () {
    testWidgets('renders account details, business name, and role badge', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Kera Diesel Heavy Spares'), findsOneWidget);
      expect(find.text('+251911223344'), findsOneWidget);
      expect(find.text('OWNER'), findsOneWidget);
    });

    testWidgets('renders preferences, currency, and theme selector', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('App Theme'), findsOneWidget);
      expect(find.text('System Currency'), findsOneWidget);
      expect(find.text('ETB'), findsOneWidget);
    });

    testWidgets('renders data management and CSV export actions', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Export Inventory (CSV)'), 250);
      expect(find.text('Export Inventory (CSV)'), findsOneWidget);
      expect(find.text('Export Sales History (CSV)'), findsOneWidget);
      expect(find.text('Backup Local Database'), findsOneWidget);
      expect(find.text('Restore Database from Backup'), findsOneWidget);
    });

    testWidgets('opens change password dialog when change password button is tapped', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final changePassBtn = find.text('Change Password');
      expect(changePassBtn, findsOneWidget);

      await tester.tap(changePassBtn);
      await tester.pumpAndSettle();

      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
    });

    testWidgets('renders version and logout button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Kera Spare Tracker'), 300, scrollable: scrollable);
      expect(find.text('Kera Spare Tracker'), findsWidgets);
      expect(find.text('Version 1.0.0 (Build 1)'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Log Out'), 300, scrollable: scrollable);
      expect(find.text('Log Out'), findsOneWidget);
    });
  });
}

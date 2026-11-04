import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/providers/theme_provider.dart';
import 'package:kera_spare_tracker/core/services/storage_service.dart';
import 'package:kera_spare_tracker/core/theme/app_theme.dart';
import 'package:kera_spare_tracker/core/utils/result.dart';
import 'package:kera_spare_tracker/features/admin/presentation/screens/admin_settings_screen.dart';
import 'package:kera_spare_tracker/features/admin/presentation/widgets/admin_scaffold.dart';
import 'package:kera_spare_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:kera_spare_tracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:kera_spare_tracker/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:kera_spare_tracker/features/auth/presentation/screens/login_screen.dart';
import 'package:kera_spare_tracker/features/auth/presentation/screens/pending_approval_screen.dart';
import 'package:kera_spare_tracker/features/auth/presentation/screens/register_screen.dart';
import 'package:kera_spare_tracker/features/reports/domain/models/inventory_valuation.dart';
import 'package:kera_spare_tracker/features/reports/domain/models/sales_summary.dart';
import 'package:kera_spare_tracker/features/reports/presentation/providers/reports_providers.dart';
import 'package:kera_spare_tracker/features/reports/presentation/screens/reports_screen.dart';
import 'package:kera_spare_tracker/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockLocalStorageService extends Mock implements LocalStorageService {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockLocalStorageService mockStorage;
  late MockAuthRepository mockAuth;

  setUp(() {
    mockStorage = MockLocalStorageService();
    mockAuth = MockAuthRepository();

    when(() => mockStorage.getSavedLocaleCode()).thenAnswer((_) async => null);
    when(() => mockStorage.saveLocaleCode(any())).thenAnswer((_) async {});
    when(() => mockStorage.getSavedThemeMode()).thenAnswer((_) async => null);
    when(() => mockStorage.saveThemeMode(any())).thenAnswer((_) async {});

    when(() => mockAuth.currentUser()).thenAnswer((_) async => const Result.success(null));
    when(() => mockAuth.watchCurrentUser()).thenAnswer((_) => Stream.value(null));
  });

  Widget createTestWidget({
    required Widget child,
    required Locale locale,
    required ThemeMode themeMode,
  }) {
    return ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(mockStorage),
        authRepositoryProvider.overrideWithValue(mockAuth),
        salesSummaryProvider.overrideWith((ref) => Future.value(SalesSummary.zero)),
        chartPointsProvider.overrideWith((ref) => Future.value([])),
        topSellingPartsProvider.overrideWith((ref) => Future.value([])),
        brandBreakdownProvider.overrideWith((ref) => Future.value([])),
        inventoryValuationProvider.overrideWith((ref) => Future.value(InventoryValuation.zero)),
      ],
      child: MaterialApp(
        locale: locale,
        themeMode: themeMode,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  group('Localization and Theme Comprehensive Tests', () {
    testWidgets('ReportsScreen renders cleanly in English and Light Theme', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      await tester.pumpWidget(
        createTestWidget(
          child: const ReportsScreen(),
          locale: const Locale('en'),
          themeMode: ThemeMode.light,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify English title appears
      expect(find.text('Financial Reports'), findsOneWidget);
      expect(find.text('Export'), findsOneWidget);
    });

    testWidgets('ReportsScreen renders cleanly in Amharic and Dark Theme', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      await tester.pumpWidget(
        createTestWidget(
          child: const ReportsScreen(),
          locale: const Locale('am'),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify Amharic title appears
      expect(find.text('የፋይናንስ ሪፖርቶች'), findsOneWidget);
      expect(find.text('አውርድ'), findsOneWidget);
    });

    testWidgets('AdminSettingsScreen renders all sections in English and Dark Theme', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1200));
      await tester.pumpWidget(
        createTestWidget(
          child: const AdminSettingsScreen(),
          locale: const Locale('en'),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify Admin Settings sections in English
      expect(find.text('Admin Settings & System'), findsOneWidget);
      expect(find.text('Super Administrator'), findsOneWidget);
      expect(find.text('App Lock & Security'), findsOneWidget);
    });

    testWidgets('AdminSettingsScreen renders all sections in Amharic and Light Theme', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1200));
      await tester.pumpWidget(
        createTestWidget(
          child: const AdminSettingsScreen(),
          locale: const Locale('am'),
          themeMode: ThemeMode.light,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify Admin Settings sections in Amharic
      expect(find.text('ቅንብሮች · Settings'), findsOneWidget);
      expect(find.text('ዋና አስተዳዳሪ'), findsOneWidget);
      expect(find.text('የመተግበሪያ ቁልፍ · App Lock'), findsOneWidget);
    });

    testWidgets('LoginScreen renders in English and Light Theme', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      await tester.pumpWidget(
        createTestWidget(
          child: const LoginScreen(),
          locale: const Locale('en'),
          themeMode: ThemeMode.light,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Welcome to Kera Spare'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('LoginScreen renders in Amharic and Dark Theme', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      await tester.pumpWidget(
        createTestWidget(
          child: const LoginScreen(),
          locale: const Locale('am'),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('እንኳን ደህና መጡ'), findsOneWidget);
      expect(find.text('ይግቡ'), findsOneWidget);
    });

    testWidgets('RegisterScreen renders in English and Dark Theme', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1000));
      await tester.pumpWidget(
        createTestWidget(
          child: const RegisterScreen(),
          locale: const Locale('en'),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Create Business Account'), findsOneWidget);
      expect(find.text('Register Business'), findsOneWidget);
    });

    testWidgets('RegisterScreen renders in Amharic and Light Theme', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1000));
      await tester.pumpWidget(
        createTestWidget(
          child: const RegisterScreen(),
          locale: const Locale('am'),
          themeMode: ThemeMode.light,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('አዲስ የንግድ መለያ ይክፈቱ'), findsOneWidget);
      expect(find.text('ይመዝገቡ'), findsOneWidget);
    });

    testWidgets('PendingApprovalScreen renders in English and Light Theme', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      await tester.pumpWidget(
        createTestWidget(
          child: const PendingApprovalScreen(),
          locale: const Locale('en'),
          themeMode: ThemeMode.light,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Account Pending Approval'), findsOneWidget);
      expect(find.text('Check Status'), findsOneWidget);
    });

    testWidgets('ForgotPasswordScreen renders in English and Dark Theme', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      await tester.pumpWidget(
        createTestWidget(
          child: const ForgotPasswordScreen(),
          locale: const Locale('en'),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Reset Forgotten Password'), findsOneWidget);
      expect(find.text('Send Verification Code'), findsOneWidget);
    });

    testWidgets('AdminScaffold bottom navigation translates to English', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      await tester.pumpWidget(
        createTestWidget(
          child: const AdminScaffold(
            currentRoute: '/admin/dashboard',
            child: Center(child: Text('Admin Content')),
          ),
          locale: const Locale('en'),
          themeMode: ThemeMode.light,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Destinations in English
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Owners'), findsWidgets);
      expect(find.text('Brands'), findsWidgets);
      expect(find.text('Settings'), findsWidgets);
    });

    testWidgets('AdminScaffold bottom navigation translates to Amharic', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      await tester.pumpWidget(
        createTestWidget(
          child: const AdminScaffold(
            currentRoute: '/admin/dashboard',
            child: Center(child: Text('Admin Content')),
          ),
          locale: const Locale('am'),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Destinations in Amharic
      expect(find.text('ዳሽቦርድ'), findsWidgets);
      expect(find.text('ባለቤቶች'), findsWidgets);
      expect(find.text('ብራንዶች'), findsWidgets);
      expect(find.text('ቅንብሮች'), findsWidgets);
    });
  });
}

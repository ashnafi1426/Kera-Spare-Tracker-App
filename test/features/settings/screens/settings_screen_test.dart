import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/theme/app_theme.dart';
import 'package:kera_spare_tracker/core/utils/result.dart';
import 'package:kera_spare_tracker/features/auth/domain/models/auth_user.dart';
import 'package:kera_spare_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:kera_spare_tracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:kera_spare_tracker/features/settings/domain/models/business_profile.dart';
import 'package:kera_spare_tracker/features/settings/presentation/providers/business_profile_provider.dart';
import 'package:kera_spare_tracker/features/settings/presentation/screens/business_profile_screen.dart';
import 'package:kera_spare_tracker/features/settings/presentation/screens/language_selection_screen.dart';
import 'package:kera_spare_tracker/features/settings/presentation/screens/security_sessions_screen.dart';
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
    when(() => mockAuthRepo.precheckLogout()).thenAnswer(
        (_) async => const LogoutPrecheck(pendingCount: 0, isOnline: true));
    when(() => mockStockRepo.getAllowNegativeStock()).thenAnswer((_) async => false);
  });

  Widget createSettingsWidget({int pendingCount = 0, bool isOnline = true}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        stockRepositoryProvider.overrideWithValue(mockStockRepo),
        lowStockPartsStreamProvider.overrideWith((ref) => Stream.value([])),
        pendingSyncCountProvider.overrideWith((ref) => Stream.value(pendingCount)),
        lastOnlineTimestampProvider.overrideWith((ref) async => DateTime.now()),
        businessProfileProvider.overrideWith(() => _MockBusinessProfileNotifier()),
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

  group('SettingsScreen Stitch Tests', () {
    testWidgets('renders merchant hero profile card with business name and hub badge', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createSettingsWidget());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Kera Diesel Heavy Spares'), findsOneWidget);
      expect(find.text('+251911223344'), findsOneWidget);
      expect(find.text('Kera Hub #14'), findsOneWidget);
      expect(find.text('Pro Merchant'), findsOneWidget);
    });

    testWidgets('renders all 5 Stitch grouped sections and rows', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createSettingsWidget());
      await tester.pumpAndSettle();

      // Section 1
      expect(find.text('Account & Business'), findsOneWidget);
      expect(find.text('Business Profile'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);

      // Section 2
      expect(find.text('Preferences'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);

      // Section 3
      expect(find.text('Inventory Defaults'), findsOneWidget);
      expect(find.text('Low Stock Threshold'), findsOneWidget);
      expect(find.text('Default Unit'), findsOneWidget);
      expect(find.text('Sorting'), findsOneWidget);

      // Section 4
      expect(find.text('Cloud Sync & Storage'), findsOneWidget);
      expect(find.text('Sync Now'), findsOneWidget);
    });

    testWidgets('shows confirmation dialog when logging out with 0 pending changes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockAuthRepo.precheckLogout()).thenAnswer(
          (_) async => const LogoutPrecheck(pendingCount: 0, isOnline: true));
      when(() => mockAuthRepo.logout()).thenAnswer((_) async => const Result.success(null));

      await tester.pumpWidget(createSettingsWidget(pendingCount: 0));
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      final logoutBtnFinder = find.text('ከመለያ ውጣ (Sign Out / Logout)');
      await tester.scrollUntilVisible(logoutBtnFinder, 500, scrollable: scrollable);
      await tester.ensureVisible(logoutBtnFinder);
      await tester.pumpAndSettle();

      await tester.tap(logoutBtnFinder);
      await tester.pumpAndSettle();

      expect(find.text('Log out of your account?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Log Out'));
      await tester.pumpAndSettle();

      verify(() => mockAuthRepo.logout()).called(1);
    });

    testWidgets('blocks logout when offline with pending changes and offers DISCARD double-confirmation', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockAuthRepo.precheckLogout()).thenAnswer(
          (_) async => const LogoutPrecheck(pendingCount: 2, isOnline: false));
      when(() => mockAuthRepo.forceDiscardAndLogout()).thenAnswer((_) async => const Result.success(null));

      await tester.pumpWidget(createSettingsWidget(pendingCount: 2, isOnline: false));
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      final logoutBtnFinder = find.text('ከመለያ ውጣ (Sign Out / Logout)');
      await tester.scrollUntilVisible(logoutBtnFinder, 500, scrollable: scrollable);
      await tester.ensureVisible(logoutBtnFinder);
      await tester.pumpAndSettle();

      await tester.tap(logoutBtnFinder);
      await tester.pumpAndSettle();

      expect(find.text('Logout Blocked (Offline)'), findsOneWidget);
      expect(find.text('Log Out & Discard'), findsOneWidget);

      await tester.tap(find.text('Log Out & Discard'));
      await tester.pumpAndSettle();

      expect(find.text('To permanently discard unsynced changes and log out, type DISCARD below:'), findsOneWidget);

      final discardBtnFinder = find.widgetWithText(ElevatedButton, 'Log Out & Discard');
      expect(tester.widget<ElevatedButton>(discardBtnFinder).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'DISCARD');
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(discardBtnFinder).onPressed, isNotNull);

      await tester.tap(discardBtnFinder);
      await tester.pumpAndSettle();

      verify(() => mockAuthRepo.forceDiscardAndLogout()).called(1);
    });
  });

  group('LanguageSelectionScreen Tests', () {
    testWidgets('renders Amharic, English, and Afaan Oromoo options', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LanguageSelectionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('የቋንቋ ምርጫ / Language'), findsOneWidget);
      expect(find.text('አማርኛ'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Afaan Oromoo'), findsOneWidget);
      expect(find.text('ቋንቋውን አረጋግጥ (Apply & Save Language)'), findsOneWidget);
    });
  });

  group('SecuritySessionsScreen Tests', () {
    testWidgets('renders security health, password change, active sessions, and additional controls', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SecuritySessionsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ደህንነት እና የይለፍ ቃል'), findsOneWidget);
      expect(find.text('የመለያዎ ደህንነት አስተማማኝ ነው'), findsOneWidget);
      expect(find.text('የይለፍ ቃል ለውጥ'), findsOneWidget);
      expect(find.text('ገቢር ክፍለ-ጊዜዎች'), findsOneWidget);
      expect(find.text('Samsung Galaxy A54'), findsOneWidget);
      expect(find.text('ተጨማሪ የደህንነት አማራጮች'), findsOneWidget);
      expect(find.text('የጣት አሻራ / ባዮሜትሪክ መግቢያ'), findsOneWidget);
    });
  });

  group('BusinessProfileScreen Tests', () {
    testWidgets('renders verified badge, branding, store details, owner contacts, and receipt settings', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            businessProfileProvider.overrideWith(() => _MockBusinessProfileNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const BusinessProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('የንግድ መረጃ / Business Profile'), findsOneWidget);
      expect(find.text('የተረጋገጠ የንግድ መደብር (Verified Merchant)'), findsOneWidget);
      expect(find.text('የንግድ ምልክት እና ሎጎ (Business Logo)'), findsOneWidget);
      expect(find.text('የመደብሩ ዋና መረጃ (Store Details)'), findsOneWidget);
      expect(find.text('የባለቤት እና አድራሻ መረጃ (Owner & Contact)'), findsOneWidget);
      expect(find.text('የመደብሩ አድራሻ እና መገኛ (Store Location & Hub)'), findsOneWidget);
      expect(find.text('የደረሰኝ እና ታክስ ቅንብር (Receipt & Tax)'), findsOneWidget);
      expect(find.text('ለውጦችን መዝግብ (Save Business Changes)'), findsOneWidget);
    });
  });
}

class _MockBusinessProfileNotifier extends BusinessProfileNotifier {
  @override
  Future<BusinessProfile> build() async {
    return BusinessProfile.defaultProfile(
      businessName: 'Kera Diesel Heavy Spares',
      phoneNumber: '+251911223344',
    );
  }

  @override
  Future<void> saveProfile(BusinessProfile profile) async {
    state = AsyncValue.data(profile);
  }
}

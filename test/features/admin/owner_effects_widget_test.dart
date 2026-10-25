import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/providers/app_config_provider.dart';
import 'package:kera_spare_tracker/core/services/app_config_service.dart';
import 'package:kera_spare_tracker/core/widgets/announcement_banner_widget.dart';
import 'package:kera_spare_tracker/core/widgets/maintenance_banner_widget.dart';
import 'package:kera_spare_tracker/core/widgets/suspended_account_banner_widget.dart';
import 'package:kera_spare_tracker/features/auth/domain/models/auth_user.dart';
import 'package:kera_spare_tracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:kera_spare_tracker/features/auth/presentation/screens/change_password_screen.dart';
import 'package:kera_spare_tracker/features/splash/presentation/update_required_screen.dart';
import 'package:kera_spare_tracker/l10n/app_localizations.dart';

import 'package:kera_spare_tracker/core/providers/locale_provider.dart';

Widget createTestableWidget({
  required Widget child,
  List<dynamic> overrides = const [],
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [
      initialLocaleCodeProvider.overrideWithValue(locale.languageCode),
      ...overrides.cast(),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Owner Reactions & Admin Effects Widget Tests', () {
    testWidgets('1. UpdateRequiredScreen renders blocking screen with version info and button', (tester) async {
      const config = AppConfig(
        minAppVersion: MinAppVersionConfig(
          version: '2.5.0',
          enforce: true,
          downloadUrl: 'https://keraspare.et/download',
        ),
        maintenanceMode: MaintenanceModeConfig(
          enabled: false,
          messageAm: '',
          messageEn: '',
        ),
        announcement: AnnouncementConfig(
          active: false,
          titleAm: '',
          titleEn: '',
          bodyAm: '',
          bodyEn: '',
        ),
        supportContact: SupportContactConfig(
          phone: '+251911000000',
          telegram: '@KeraSpareSupport',
        ),
        installedVersion: '1.0.0',
      );

      await tester.pumpWidget(
        createTestableWidget(
          child: const UpdateRequiredScreen(),
          overrides: [
            appConfigNotifierProvider.overrideWith(() => FakeAppConfigNotifier(config)),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Update Required'), findsOneWidget);
      expect(find.textContaining('2.5.0'), findsOneWidget);
      expect(find.text('Update Now'), findsOneWidget);
      expect(find.byIcon(Icons.system_update_rounded), findsOneWidget);
    });

    testWidgets('2. MaintenanceBannerWidget displays when maintenance is active and hides when disabled', (tester) async {
      const activeConfig = AppConfig(
        minAppVersion: MinAppVersionConfig(
          version: '1.0.0',
          enforce: false,
          downloadUrl: '',
        ),
        maintenanceMode: MaintenanceModeConfig(
          enabled: true,
          messageAm: 'ጥገና ላይ ነን',
          messageEn: 'Scheduled system maintenance in progress',
        ),
        announcement: AnnouncementConfig(
          active: false,
          titleAm: '',
          titleEn: '',
          bodyAm: '',
          bodyEn: '',
        ),
        supportContact: SupportContactConfig(
          phone: '+251911000000',
          telegram: '@KeraSpareSupport',
        ),
        installedVersion: '1.0.0',
      );

      await tester.pumpWidget(
        createTestableWidget(
          child: const MaintenanceBannerWidget(),
          overrides: [
            appConfigNotifierProvider.overrideWith(() => FakeAppConfigNotifier(activeConfig)),
          ],
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Scheduled system maintenance in progress'), findsOneWidget);

      const disabledConfig = AppConfig(
        minAppVersion: MinAppVersionConfig(
          version: '1.0.0',
          enforce: false,
          downloadUrl: '',
        ),
        maintenanceMode: MaintenanceModeConfig(
          enabled: false,
          messageAm: '',
          messageEn: '',
        ),
        announcement: AnnouncementConfig(
          active: false,
          titleAm: '',
          titleEn: '',
          bodyAm: '',
          bodyEn: '',
        ),
        supportContact: SupportContactConfig(
          phone: '+251911000000',
          telegram: '@KeraSpareSupport',
        ),
        installedVersion: '1.0.0',
      );

      await tester.pumpWidget(
        createTestableWidget(
          child: const MaintenanceBannerWidget(),
          overrides: [
            appConfigNotifierProvider.overrideWith(() => FakeAppConfigNotifier(disabledConfig)),
          ],
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Scheduled system maintenance in progress'), findsNothing);
    });

    testWidgets('3. AnnouncementBannerWidget displays active notice and dismisses on tap', (tester) async {
      const configWithAnnouncement = AppConfig(
        minAppVersion: MinAppVersionConfig(
          version: '1.0.0',
          enforce: false,
          downloadUrl: '',
        ),
        maintenanceMode: MaintenanceModeConfig(
          enabled: false,
          messageAm: '',
          messageEn: '',
        ),
        announcement: AnnouncementConfig(
          active: true,
          titleAm: 'አስቸኳይ ማስታወቂያ',
          titleEn: 'System Upgrade Notice',
          bodyAm: 'መተግበሪያው ቅዳሜ ማታ ይሻሻላል',
          bodyEn: 'App will be upgraded this Saturday evening.',
        ),
        supportContact: SupportContactConfig(
          phone: '+251911000000',
          telegram: '@KeraSpareSupport',
        ),
        installedVersion: '1.0.0',
      );

      await tester.pumpWidget(
        createTestableWidget(
          child: const AnnouncementBannerWidget(),
          overrides: [
            appConfigNotifierProvider.overrideWith(() => FakeAppConfigNotifier(configWithAnnouncement)),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('System Upgrade Notice'), findsOneWidget);
      expect(find.text('App will be upgraded this Saturday evening.'), findsOneWidget);

      // Tap dismiss icon button
      final closeBtn = find.byIcon(Icons.close_rounded);
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      // Announcement dismissed
      expect(find.text('System Upgrade Notice'), findsNothing);
    });

    testWidgets('4. SuspendedAccountBannerWidget displays reason and support contact buttons', (tester) async {
      const suspendedUser = AuthUser(
        id: 'user-suspended-123',
        ownerId: 'owner-123',
        phoneNumber: '+251911223344',
        businessName: 'Alpha Spares',
        status: 'SUSPENDED',
        suspendedReason: 'Annual subscription lapsed',
      );

      const config = AppConfig(
        minAppVersion: MinAppVersionConfig(
          version: '1.0.0',
          enforce: false,
          downloadUrl: '',
        ),
        maintenanceMode: MaintenanceModeConfig(
          enabled: false,
          messageAm: '',
          messageEn: '',
        ),
        announcement: AnnouncementConfig(
          active: false,
          titleAm: '',
          titleEn: '',
          bodyAm: '',
          bodyEn: '',
        ),
        supportContact: SupportContactConfig(
          phone: '+251911998877',
          telegram: '@KeraAdminSupport',
        ),
        installedVersion: '1.0.0',
      );

      await tester.pumpWidget(
        createTestableWidget(
          child: const SuspendedAccountBannerWidget(),
          overrides: [
            authControllerProvider.overrideWith(() => FakeAuthController(suspendedUser)),
            appConfigNotifierProvider.overrideWith(() => FakeAppConfigNotifier(config)),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Account Suspended'), findsOneWidget);
      expect(find.text('Reason: Annual subscription lapsed'), findsOneWidget);
      expect(find.text('Call Support'), findsOneWidget);
      expect(find.text('Telegram'), findsOneWidget);
      expect(find.byIcon(Icons.block_rounded), findsOneWidget);
    });

    testWidgets('5. ChangePasswordScreen shows forced banner when isForced is true', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: const ChangePasswordScreen(isForced: true),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Password Change Required'), findsOneWidget);
      expect(find.text('An immediate password update is required for your account before you can proceed.'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3));
    });
  });
}

class FakeAppConfigNotifier extends AppConfigNotifier {
  final AppConfig _initialConfig;
  FakeAppConfigNotifier(this._initialConfig);

  @override
  Future<AppConfigState> build() async {
    return AppConfigState(config: _initialConfig);
  }

  void updateConfig(AppConfig newConfig) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(
      current.copyWith(config: newConfig),
    );
  }

  @override
  Future<void> dismissAnnouncement() async {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(
      current.copyWith(
        dismissedAnnouncementHash: current.config.announcement.uniqueHash,
      ),
    );
  }
}

class FakeAuthController extends AuthController {
  final AuthUser? _initialUser;
  FakeAuthController(this._initialUser);

  @override
  Future<AuthUser?> build() async {
    return _initialUser;
  }
}

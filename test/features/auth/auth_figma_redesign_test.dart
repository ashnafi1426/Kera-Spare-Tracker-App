import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kera_spare_tracker/core/providers/locale_provider.dart';
import 'package:kera_spare_tracker/core/theme/app_theme.dart';
import 'package:kera_spare_tracker/core/utils/result.dart';
import 'package:kera_spare_tracker/features/auth/domain/models/auth_user.dart';
import 'package:kera_spare_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:kera_spare_tracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:kera_spare_tracker/features/auth/presentation/screens/login_screen.dart';
import 'package:kera_spare_tracker/features/auth/presentation/screens/register_screen.dart';
import 'package:kera_spare_tracker/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}

Widget _buildAuthTestApp({
  required Widget child,
  required double width,
  required double height,
  ThemeData? theme,
  Locale locale = const Locale('en'),
  _MockAuthRepo? mockRepo,
}) {
  final repo = mockRepo ?? _MockAuthRepo();
  when(() => repo.currentUser()).thenAnswer((_) async => const Result.success(null));
  when(() => repo.watchCurrentUser()).thenAnswer((_) => Stream.value(null));
  when(() => repo.precheckLogout()).thenAnswer(
      (_) async => const LogoutPrecheck(pendingCount: 0, isOnline: true));

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      initialLocaleCodeProvider.overrideWithValue('en'),
    ],
    child: MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          devicePixelRatio: 2.0,
          padding: const EdgeInsets.only(top: 24, bottom: 20),
        ),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Auth Figma Redesign Verification Suite', () {
    testWidgets('1. Login screen renders all approved Figma elements at 393x852 without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(393 * 2.0, 852 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _buildAuthTestApp(child: const LoginScreen(), width: 393, height: 852),
      );
      await tester.pumpAndSettle();

      // Header Elements
      expect(find.text('KERA SPARE'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);
      expect(find.byIcon(Icons.headset_mic_outlined), findsOneWidget);

      // Brand Intro
      expect(find.text('BUILT FOR YOUR BUSINESS'), findsOneWidget);
      expect(find.text('እንኳን ደህና መጡ!'), findsOneWidget);
      expect(find.text('WELCOME BACK'), findsOneWidget);
      expect(find.text('Log in to manage your inventory & sales.'), findsOneWidget);

      // Form Elements
      expect(find.text('+251'), findsOneWidget);
      expect(find.text('Phone number'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Remember me'), findsOneWidget);
      expect(find.text('Forgot PIN?'), findsOneWidget);

      // Buttons & Links
      expect(find.text('Log in'), findsOneWidget);
      expect(find.text('Log in with Touch ID'), findsOneWidget);
      expect(find.text('Create a merchant account'), findsOneWidget);
      expect(find.text('Secure & private'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('2. Login screen renders with 0 overflows at 320dp narrow viewport',
        (tester) async {
      FlutterErrorDetails? errorDetails;
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errorDetails = details;
        oldOnError?.call(details);
      };

      tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        FlutterError.onError = oldOnError;
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(
        _buildAuthTestApp(child: const LoginScreen(), width: 320, height: 640),
      );
      await tester.pumpAndSettle();

      if (errorDetails != null) {
        // ignore: avoid_print
        print('LOGIN 320DP ERROR: ${errorDetails.toString()}');
      }

      expect(find.text('KERA SPARE'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. Merchant Registration renders all approved Figma elements at 393x852 without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(393 * 2.0, 852 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _buildAuthTestApp(child: const RegisterScreen(), width: 393, height: 852),
      );
      await tester.pumpAndSettle();

      // Header Elements
      expect(find.text('KERA SPARE'), findsOneWidget);
      expect(find.text('Merchant registration'), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);
      expect(find.byIcon(Icons.headset_mic_outlined), findsOneWidget);

      // Stepper & Offline Badge
      expect(find.text('1'), findsOneWidget);
      expect(find.text('of 2'), findsOneWidget);
      expect(find.text('Offline ready'), findsOneWidget);

      // Page Intro
      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('የመመዝገቢያ ፎርም'), findsOneWidget);

      // Sections
      expect(find.text('Personal information'), findsOneWidget);
      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('+251'), findsOneWidget);

      expect(find.text('Business information'), findsOneWidget);
      expect(find.text('Business name'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm password'), findsOneWidget);

      // Action Button & Footer
      expect(find.text('Sign up'), findsOneWidget);
      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('4. Merchant Registration renders with 0 overflows at 320dp narrow viewport',
        (tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _buildAuthTestApp(child: const RegisterScreen(), width: 320, height: 640),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('Sign up'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('5. Merchant Registration validates password matching and required fields',
        (tester) async {
      tester.view.physicalSize = const Size(393 * 2.0, 852 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = _MockAuthRepo();
      await tester.pumpWidget(
        _buildAuthTestApp(
          child: const RegisterScreen(),
          width: 393,
          height: 852,
          mockRepo: mockRepo,
        ),
      );
      await tester.pumpAndSettle();

      // Enter mismatching passwords
      final textFields = find.byType(TextFormField);
      // 0: Full name, 1: Phone, 2: Business name, 3: Password, 4: Confirm password
      await tester.enterText(textFields.at(0), 'Abebe Kebede');
      await tester.enterText(textFields.at(1), '0911223344');
      await tester.enterText(textFields.at(2), 'Abebe Auto Parts');
      await tester.enterText(textFields.at(3), 'secret123');
      await tester.enterText(textFields.at(4), 'different123');

      final signUpBtn = find.text('Sign up');
      await tester.ensureVisible(signUpBtn);
      await tester.tap(signUpBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('match'), findsWidgets);
    });

    testWidgets('6. Language Selector toggles locale reactively in AuthHeader',
        (tester) async {
      tester.view.physicalSize = const Size(393 * 2.0, 852 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _buildAuthTestApp(child: const LoginScreen(), width: 393, height: 852),
      );
      await tester.pumpAndSettle();

      expect(find.text('EN'), findsOneWidget);

      // Tap language selector
      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();

      expect(find.text('አማ'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/errors/failure.dart';
import 'package:kera_spare_tracker/core/theme/app_theme.dart';
import 'package:kera_spare_tracker/core/utils/result.dart';
import 'package:kera_spare_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:kera_spare_tracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:kera_spare_tracker/features/auth/presentation/screens/login_screen.dart';
import 'package:kera_spare_tracker/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository mockAuth;

  setUp(() {
    mockAuth = MockAuthRepository();

    when(() => mockAuth.currentUser())
        .thenAnswer((_) async => const Result.success(null));
    when(() => mockAuth.watchCurrentUser()).thenAnswer((_) => Stream.value(null));
    when(() => mockAuth.precheckLogout()).thenAnswer(
        (_) async => const LogoutPrecheck(pendingCount: 0, isOnline: true));
    when(() => mockAuth.logout())
        .thenAnswer((_) async => const Result.success(null));
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuth),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const LoginScreen(),
      ),
    );
  }

  testWidgets('1. Modern Login screen renders all branded UI elements',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('KERA SPARE'), findsOneWidget);
    expect(find.text('WELCOME BACK'), findsOneWidget);
    expect(find.text('+251'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byType(ElevatedButton), findsWidgets);
  });

  testWidgets('2. Empty form triggers validation errors', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Tap Login button with empty inputs
    final loginBtn = find.byType(ElevatedButton).first;
    await tester.ensureVisible(loginBtn);
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    // Form validation triggers required messages
    expect(find.textContaining('required'), findsWidgets);
  });

  testWidgets('3. Password visibility toggle works', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(1), 'mysecretpassword');

    // Find visibility icon and toggle
    final visibilityIcon = find.byIcon(Icons.visibility_outlined);
    expect(visibilityIcon, findsOneWidget);

    await tester.tap(visibilityIcon);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('4. Error banner is shown when credentials fail',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    when(() => mockAuth.login(
          phoneNumber: any(named: 'phoneNumber'),
          password: any(named: 'password'),
          forceDiscardUnsynced: any(named: 'forceDiscardUnsynced'),
        )).thenAnswer((_) async => const Result.failure(
          AuthFailure(
            message: 'Invalid phone number or password',
            code: 'INVALID_CREDENTIALS',
          ),
        ));

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), '977777777');
    await tester.enterText(textFields.at(1), 'WrongPassword123');

    final loginBtn = find.byType(ElevatedButton).first;
    await tester.ensureVisible(loginBtn);
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    expect(find.text('Incorrect phone number or password'), findsOneWidget);
  });

  testWidgets('5. Server Settings icon is completely removed from Login header',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify Server Settings ethernet icon is NOT in the UI
    expect(find.byIcon(Icons.settings_ethernet_rounded), findsNothing);
    expect(find.text('Server Settings'), findsNothing);
  });
}

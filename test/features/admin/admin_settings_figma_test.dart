import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kera_spare_tracker/core/theme/app_theme.dart';
import 'package:kera_spare_tracker/core/utils/result.dart';
import 'package:kera_spare_tracker/features/admin/domain/models/admin_models.dart';
import 'package:kera_spare_tracker/features/admin/domain/repositories/admin_repository.dart';
import 'package:kera_spare_tracker/features/admin/presentation/providers/admin_providers.dart';
import 'package:kera_spare_tracker/features/admin/presentation/screens/admin_settings_screen.dart';
import 'package:kera_spare_tracker/features/auth/domain/models/auth_user.dart';
import 'package:kera_spare_tracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:kera_spare_tracker/l10n/app_localizations.dart';

class _FakeAdminRepo extends Fake implements AdminRepository {
  @override
  Future<Result<List<GlobalCatalogItem>>> getBrands() async => const Result.success([]);
  @override
  Future<Result<List<GlobalCatalogItem>>> getCategories() async => const Result.success([]);
  @override
  Future<Result<List<GlobalCatalogItem>>> getUnits() async => const Result.success([]);
}

class _TestAuthController extends AuthController {
  @override
  Future<AuthUser?> build() async => const AuthUser(
        id: 'admin-1',
        ownerId: 'owner-1',
        phoneNumber: '+251 911 234 567',
        businessName: 'Admin Tesfa',
        role: 'admin',
      );

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return const Result.success(null);
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
      authControllerProvider.overrideWith(_TestAuthController.new),
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
          child: const AdminSettingsScreen(),
        ),
      ),
    ),
  );
}

void main() {
  group('Admin Settings & System Figma Implementation Verification', () {
    testWidgets('Renders all Figma sections cleanly without overflows at 393x852 (Figma baseline)', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(width: 393, height: 852));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // 1. Header elements
      expect(find.text('KERA'), findsOneWidget);
      expect(find.text('SPARE TRACKER'), findsOneWidget);
      expect(find.text('Admin Settings & System'), findsOneWidget);
      expect(find.text('Complete system administration & security.'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);

      // 2. Profile Card
      expect(find.text('KS'), findsOneWidget);
      expect(find.text('Admin Tesfa'), findsOneWidget);
      expect(find.text('+251 911 234 567'), findsOneWidget);
      expect(find.text('Super Administrator'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      // 3. Language Selector Card
      expect(find.text('Language / ቋንቋ'), findsOneWidget);
      expect(find.text('አማርኛ (የአገር)'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      // 4. Appearance Card
      expect(find.text('Appearance / Theme Mode'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);

      // 5. App Lock & Security
      expect(find.text('App Lock & Security'), findsOneWidget);
      expect(find.text('App Lock'), findsOneWidget);
      expect(find.text('Account Password'), findsOneWidget);
      expect(find.text('Change admin login password & strength check'), findsOneWidget);
    });

    testWidgets('Renders with 0 overflows at 320dp (narrow phone viewport)', (tester) async {
      tester.view.physicalSize = const Size(320, 680);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(width: 320, height: 680));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Admin Settings & System'), findsOneWidget);
      expect(find.text('Admin Tesfa'), findsOneWidget);
      expect(find.text('App Lock & Security'), findsOneWidget);
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
      expect(find.text('Admin Settings & System'), findsOneWidget);
      expect(find.text('Admin Tesfa'), findsOneWidget);
    });

    testWidgets('Language selector toggles locale reactively', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(width: 393, height: 852));
      await tester.pumpAndSettle();

      // Tap Amharic option
      await tester.tap(find.text('አማርኛ (የአገር)'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Tap English option back
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Tapping avatar camera badge opens photo picker bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestApp(width: 393, height: 852));
      await tester.pumpAndSettle();

      // Find camera icon on avatar and tap it
      final cameraBadge = find.byIcon(Icons.camera_alt_rounded);
      expect(cameraBadge, findsOneWidget);
      await tester.tap(cameraBadge);
      await tester.pumpAndSettle();

      // Bottom sheet should appear with photo options
      expect(find.text('Take Photo (Camera)'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
    });
  });
}

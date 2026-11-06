import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kera_spare_tracker/core/providers/locale_provider.dart';
import 'package:kera_spare_tracker/core/theme/app_theme.dart';
import 'package:kera_spare_tracker/features/auth/domain/models/auth_user.dart';
import 'package:kera_spare_tracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:kera_spare_tracker/features/auth/presentation/screens/register_screen.dart';
import 'package:kera_spare_tracker/l10n/app_localizations.dart';

class StaticLocaleNotifier extends LocaleController {
  final Locale _fixedLocale;
  StaticLocaleNotifier(this._fixedLocale);

  @override
  Locale build() => _fixedLocale;

  @override
  Future<void> setLocale(Locale newLocale) async {}

  @override
  Future<void> toggleLocale() async {}
}

class StaticAuthController extends AuthController {
  @override
  Future<AuthUser?> build() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final outDir = Directory('docs/ui-check/screen2_login_register');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  Future<void> captureOne(
    WidgetTester tester, {
    required bool isDark,
    required Locale locale,
    required String fileName,
  }) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;

    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localeControllerProvider.overrideWith(() => StaticLocaleNotifier(locale)),
          authControllerProvider.overrideWith(StaticAuthController.new),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          home: RepaintBoundary(
            key: boundaryKey,
            child: const RegisterScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final boundary = boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary != null && boundary.hasSize) {
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final file = File('docs/ui-check/screen2_login_register/$fileName');
        file.writeAsBytesSync(byteData.buffer.asUint8List());
        // ignore: avoid_print
        print('📸 Captured $fileName (${byteData.lengthInBytes} bytes)');
      }
    }
  }

  testWidgets('Capture register_light_am', (tester) async {
    await captureOne(
      tester,
      isDark: false,
      locale: const Locale('am'),
      fileName: 'register_light_am.png',
    );
    exit(0);
  });

  testWidgets('Capture register_light_en', (tester) async {
    await captureOne(
      tester,
      isDark: false,
      locale: const Locale('en'),
      fileName: 'register_light_en.png',
    );
    exit(0);
  });

  testWidgets('Capture register_dark_am', (tester) async {
    await captureOne(
      tester,
      isDark: true,
      locale: const Locale('am'),
      fileName: 'register_dark_am.png',
    );
    exit(0);
  });

  testWidgets('Capture register_dark_en', (tester) async {
    await captureOne(
      tester,
      isDark: true,
      locale: const Locale('en'),
      fileName: 'register_dark_en.png',
    );
    exit(0);
  });
}

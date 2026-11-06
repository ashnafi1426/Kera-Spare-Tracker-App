import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kera_spare_tracker/core/providers/locale_provider.dart';
import 'package:kera_spare_tracker/core/theme/app_theme.dart';
import 'package:kera_spare_tracker/features/splash/presentation/splash_screen.dart';
import 'package:kera_spare_tracker/l10n/app_localizations.dart';

class StaticLocaleNotifier extends LocaleController {
  final Locale _fixedLocale;
  StaticLocaleNotifier(this._fixedLocale);

  @override
  Locale build() => _fixedLocale;

  @override
  Future<void> setLocale(Locale newLocale) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final outDir = Directory('docs/ui-check/screen1_splash_onboarding');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  Future<void> captureOne(
    WidgetTester tester, {
    required Widget widget,
    required bool isDark,
    required Locale locale,
    required String fileName,
  }) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2.0;

    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localeControllerProvider.overrideWith(() => StaticLocaleNotifier(locale)),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          home: RepaintBoundary(
            key: boundaryKey,
            child: widget,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    final boundary = boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary != null && boundary.hasSize) {
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final file = File('docs/ui-check/screen1_splash_onboarding/$fileName');
        file.writeAsBytesSync(byteData.buffer.asUint8List());
        // ignore: avoid_print
        print('📸 Captured $fileName (${byteData.lengthInBytes} bytes)');
      }
    }
  }

  testWidgets('Capture splash_dark_am', (tester) async {
    await captureOne(
      tester,
      widget: const SplashScreen(progressValue: 0.65),
      isDark: true,
      locale: const Locale('am'),
      fileName: 'splash_dark_am.png',
    );
    exit(0);
  });
}

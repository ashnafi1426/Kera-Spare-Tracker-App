import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kera_spare_tracker/core/providers/locale_provider.dart';
import 'package:kera_spare_tracker/core/theme/app_theme.dart';
import 'package:kera_spare_tracker/features/auth/presentation/screens/welcome_screen.dart';
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

  testWidgets('Capture welcome_dark_am', (tester) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2.0;

    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localeControllerProvider.overrideWith(() => StaticLocaleNotifier(const Locale('am'))),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('am'),
          home: RepaintBoundary(
            key: boundaryKey,
            child: const WelcomeScreen(),
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
        final file = File('docs/ui-check/screen1_splash_onboarding/welcome_dark_am.png');
        file.writeAsBytesSync(byteData.buffer.asUint8List());
        // ignore: avoid_print
        print('📸 Captured: welcome_dark_am.png (${byteData.lengthInBytes} bytes)');
      }
    }
    exit(0);
  });
}

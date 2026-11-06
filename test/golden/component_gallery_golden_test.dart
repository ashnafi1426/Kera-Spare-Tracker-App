import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/design/screens/component_gallery_screen.dart';
import 'package:kera_spare_tracker/core/theme/app_theme.dart';
import 'package:kera_spare_tracker/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final outDir = Directory('docs/ui-check/components');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  Future<void> captureScreen({
    required WidgetTester tester,
    required bool isDark,
    required Locale locale,
    required String fileName,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;

    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          home: RepaintBoundary(
            key: boundaryKey,
            child: const ComponentGalleryScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null) {
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final file = File('docs/ui-check/components/$fileName');
        file.writeAsBytesSync(byteData.buffer.asUint8List());
        debugPrint('Saved screenshot to: ${file.path}');
      }
    }

    // Allow frame to settle
    await tester.pump(const Duration(milliseconds: 50));
  }

  group('Component Gallery Screenshot Capture', () {
    testWidgets('Capture Light Mode (English)', (tester) async {
      await captureScreen(
        tester: tester,
        isDark: false,
        locale: const Locale('en'),
        fileName: 'gallery_light_en.png',
      );
    });

    testWidgets('Capture Light Mode (Amharic)', (tester) async {
      await captureScreen(
        tester: tester,
        isDark: false,
        locale: const Locale('am'),
        fileName: 'gallery_light_am.png',
      );
    });

    testWidgets('Capture Dark Mode (English)', (tester) async {
      await captureScreen(
        tester: tester,
        isDark: true,
        locale: const Locale('en'),
        fileName: 'gallery_dark_en.png',
      );
    });

    testWidgets('Capture Dark Mode (Amharic)', (tester) async {
      await captureScreen(
        tester: tester,
        isDark: true,
        locale: const Locale('am'),
        fileName: 'gallery_dark_am.png',
      );
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persisted user locale preference
  const storage = LocalStorageService();
  final savedLocaleCode = await storage.getSavedLocaleCode();

  runApp(
    ProviderScope(
      overrides: [
        if (savedLocaleCode != null)
          initialLocaleCodeProvider.overrideWithValue(savedLocaleCode),
      ],
      child: const KeraSpareTrackerApp(),
    ),
  );
}

/// Root widget for Kera Spare Tracker application.
class KeraSpareTrackerApp extends ConsumerWidget {
  const KeraSpareTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeControllerProvider);

    return MaterialApp.router(
      title: 'Kera Spare Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

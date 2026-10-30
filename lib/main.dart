import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'core/constants/constants.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/session_store.dart';
import 'core/theme/app_theme.dart';
import 'features/security/presentation/widgets/app_lock_lifecycle_wrapper.dart';
import 'l10n/app_localizations.dart';


Future<void> main() async {
  final totalStartupStopwatch = Stopwatch()..start();
  final stepStopwatch = Stopwatch()..start();
  
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[STARTUP] WidgetsFlutterBinding.ensureInitialized: ${stepStopwatch.elapsedMilliseconds}ms');

  stepStopwatch.reset();
  // Global Flutter error boundary - prevents crashes and logs gracefully
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Global Flutter Error: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught Platform Error: $error\n$stack');
    return true; // Prevents process termination
  };
  // User-friendly custom ErrorWidget for widget tree errors
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.amber, size: 40),
              const SizedBox(height: 8),
              const Text(
                'Something unexpected occurred',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  };
  debugPrint('[STARTUP] Error boundaries configured: ${stepStopwatch.elapsedMilliseconds}ms');

  // Launch UI immediately without blocking on asynchronous disk or keystore access
  runApp(
    const ProviderScope(
      child: KeraSpareTrackerApp(),
    ),
  );
  debugPrint('[STARTUP] runApp() called: ${stepStopwatch.elapsedMilliseconds}ms (Total before runApp: ${totalStartupStopwatch.elapsedMilliseconds}ms)');

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    debugPrint('[STARTUP] First frame rendered (PostFrameCallback): ${totalStartupStopwatch.elapsedMilliseconds}ms');
    try {
      final savedUrl = await SessionStore().getSavedApiBaseUrl();
      if (savedUrl != null && savedUrl.isNotEmpty) {
        AppConstants.setApiBaseUrl(savedUrl);
      }
    } catch (_) {}
  });
}

/// Root widget for Kera Spare Tracker application.
class KeraSpareTrackerApp extends ConsumerWidget {
  const KeraSpareTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildStopwatch = Stopwatch()..start();
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeControllerProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    debugPrint('[STARTUP] KeraSpareTrackerApp build & watched providers: ${buildStopwatch.elapsedMilliseconds}ms');

    return MaterialApp.router(
      title: 'Kera Spare Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return AppLockLifecycleWrapper(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

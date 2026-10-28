import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/app_lock_service.dart';
import '../screens/app_lock_screen.dart';

/// Wraps the application to monitor lifecycle states (paused/resumed),
/// evaluate auto-lock timeouts, and render the AppLockScreen overlay
/// whenever the app is locked.
class AppLockLifecycleWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const AppLockLifecycleWrapper({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AppLockLifecycleWrapper> createState() =>
      _AppLockLifecycleWrapperState();
}

class _AppLockLifecycleWrapperState
    extends ConsumerState<AppLockLifecycleWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lockService = ref.read(appLockServiceProvider);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      lockService.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      lockService.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockStateProvider);

    if (lockState.isEnabled && lockState.isLocked) {
      return Navigator(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => const AppLockScreen(),
        ),
      );
    }

    return widget.child;
  }
}

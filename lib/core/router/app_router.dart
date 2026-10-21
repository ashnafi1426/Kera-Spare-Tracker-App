import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/settings/presentation/screens/brands_management_screen.dart';
import '../../features/settings/presentation/screens/categories_management_screen.dart';
import '../../features/settings/presentation/screens/locations_management_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

/// Helper ChangeNotifier that notifies GoRouter when Riverpod auth state changes.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

/// App routing table managed via GoRouter with authentication route guards.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);

      // Allow splash to render during initial auth check
      if (authState.isLoading) {
        return null;
      }

      final isAuthenticated = authState.value != null;
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' || location == '/register';

      // Unauthenticated users are redirected to /login
      if (!isAuthenticated) {
        return isAuthRoute ? null : '/login';
      }

      // Authenticated users trying to access login, register or splash go to /home
      if (isAuthRoute || location == '/') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/settings/brands',
        name: 'settings-brands',
        builder: (context, state) => const BrandsManagementScreen(),
      ),
      GoRoute(
        path: '/settings/categories',
        name: 'settings-categories',
        builder: (context, state) => const CategoriesManagementScreen(),
      ),
      GoRoute(
        path: '/settings/locations',
        name: 'settings-locations',
        builder: (context, state) => const LocationsManagementScreen(),
      ),
    ],
  );
});

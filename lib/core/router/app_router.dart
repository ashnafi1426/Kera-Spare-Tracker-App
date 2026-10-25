import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/parts/presentation/screens/part_details_screen.dart';
import '../../features/parts/presentation/screens/part_form_screen.dart';
import '../../features/sales/presentation/screens/new_sale_screen.dart';
import '../../features/sales/presentation/screens/sale_details_screen.dart';
import '../../features/sales/presentation/screens/sale_success_screen.dart';
import '../../features/settings/presentation/screens/brands_management_screen.dart';
import '../../features/settings/presentation/screens/categories_management_screen.dart';
import '../../features/settings/presentation/screens/locations_management_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/splash/presentation/update_required_screen.dart';
import '../../features/stock/presentation/screens/low_stock_screen.dart';
import '../../features/stock/presentation/screens/stock_history_screen.dart';
import '../providers/app_config_provider.dart';

/// Helper ChangeNotifier that notifies GoRouter when Riverpod auth or config state changes.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
    ref.listen(appConfigNotifierProvider, (_, _) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final configState = ref.read(appConfigNotifierProvider);
      final location = state.matchedLocation;

      // 1. Force update takes precedence over all other routes
      final isUpdateRequired =
          configState.value?.config.isUpdateRequired ?? false;
      if (isUpdateRequired) {
        return location == '/update-required' ? null : '/update-required';
      } else if (location == '/update-required') {
        return '/';
      }

      final authState = ref.read(authControllerProvider);

      // Allow splash to render during initial auth check
      if (authState.isLoading) {
        return null;
      }

      final user = authState.value;
      final isAuthenticated = user != null;
      final isAuthRoute = location == '/login' || location == '/register';

      // Unauthenticated users are redirected to /login
      if (!isAuthenticated) {
        return isAuthRoute ? null : '/login';
      }

      // 2. Forced password change flow
      if (user.mustChangePassword) {
        return location == '/change-password' ? null : '/change-password';
      }

      // Authenticated users trying to access login, register or splash go to /home
      if (isAuthRoute ||
          location == '/' ||
          (location == '/change-password' && !user.mustChangePassword)) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/update-required',
        name: 'update-required',
        builder: (context, state) => const UpdateRequiredScreen(),
      ),
      GoRoute(
        path: '/change-password',
        name: 'change-password',
        builder: (context, state) {
          final isForced = ref.read(authControllerProvider).value?.mustChangePassword ?? false;
          return ChangePasswordScreen(isForced: isForced);
        },
      ),
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
      GoRoute(
        path: '/parts/add',
        name: 'parts-add',
        builder: (context, state) => const PartFormScreen(),
      ),
      GoRoute(
        path: '/parts/:id',
        name: 'parts-details',
        builder: (context, state) => PartDetailsScreen(
          partId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/parts/:id/edit',
        name: 'parts-edit',
        builder: (context, state) => PartFormScreen(
          partId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/parts/:id/history',
        name: 'parts-history',
        builder: (context, state) => StockHistoryScreen(
          partId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/stock/low',
        name: 'stock-low',
        builder: (context, state) => const LowStockScreen(),
      ),
      GoRoute(
        path: '/sales/new',
        name: 'sales-new',
        builder: (context, state) => const NewSaleScreen(),
      ),
      GoRoute(
        path: '/sales/success/:id',
        name: 'sales-success',
        builder: (context, state) => SaleSuccessScreen(
          saleId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/sales/:id',
        name: 'sales-details',
        builder: (context, state) => SaleDetailsScreen(
          saleId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/stock/low-stock',
        name: 'stock-low-stock',
        builder: (context, state) => const LowStockScreen(),
      ),
    ],
  );
});


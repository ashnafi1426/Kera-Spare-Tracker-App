import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_account_screen.dart';
import '../../features/admin/presentation/screens/admin_add_owner_screen.dart';
import '../../features/admin/presentation/screens/admin_audit_log_screen.dart';
import '../../features/admin/presentation/screens/admin_backup_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_global_catalog_screen.dart';
import '../../features/admin/presentation/screens/admin_notifications_screen.dart';
import '../../features/admin/presentation/screens/admin_owner_details_screen.dart';
import '../../features/admin/presentation/screens/admin_owners_list_screen.dart';
import '../../features/admin/presentation/screens/admin_plans_screen.dart';
import '../../features/admin/presentation/screens/admin_reports_screen.dart';
import '../../features/admin/presentation/screens/admin_settings_screen.dart';
import '../../features/admin/presentation/screens/admin_sync_monitor_screen.dart';
import '../../features/admin/presentation/widgets/admin_scaffold.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/pending_approval_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/dashboard/presentation/screens/business_dashboard_screen.dart';
import '../../features/notifications/presentation/screens/notification_center_screen.dart';
import '../../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../../features/parts/presentation/screens/inventory_screen.dart';
import '../../features/parts/presentation/screens/part_details_screen.dart';
import '../../features/parts/presentation/screens/part_form_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/sales/presentation/screens/sale_details_screen.dart';
import '../../features/sales/presentation/screens/sale_success_screen.dart';
import '../../features/sales/presentation/screens/sales_pos_screen.dart';
import '../../features/settings/presentation/screens/brands_management_screen.dart';
import '../../features/settings/presentation/screens/business_profile_screen.dart';
import '../../features/settings/presentation/screens/categories_management_screen.dart';
import '../../features/settings/presentation/screens/language_selection_screen.dart';
import '../../features/settings/presentation/screens/locations_management_screen.dart';
import '../../features/settings/presentation/screens/security_sessions_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/splash/presentation/update_required_screen.dart';
import '../../features/stock/presentation/screens/low_stock_screen.dart';
import '../../features/stock/presentation/screens/stock_history_screen.dart';
import '../../features/sync/presentation/screens/conflict_resolution_screen.dart';
import '../../features/sync/presentation/screens/initial_sync_screen.dart';
import '../../features/sync/presentation/screens/offline_dashboard_screen.dart';
import '../../features/sync/presentation/screens/sync_center_screen.dart';
import '../../features/sync/presentation/screens/sync_diagnostics_screen.dart';
import '../design/screens/component_gallery_screen.dart';
import '../design/widgets/bottom_nav.dart';
import '../providers/app_config_provider.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');

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
    navigatorKey: _rootNavigatorKey,
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
      final isAuthRoute = location == '/login' ||
          location == '/register' ||
          location == '/welcome' ||
          location == '/forgot-password' ||
          location == '/pending-approval';

      // Unauthenticated users are redirected to /login
      if (!isAuthenticated) {
        return isAuthRoute ? null : '/login';
      }

      // 2. Forced password change flow
      if (user.mustChangePassword) {
        return location == '/change-password' ? null : '/change-password';
      }

      // 3. Admin user mutual guard
      if (user.isAdmin) {
        if (isAuthRoute || location == '/' || !location.startsWith('/admin')) {
          if (location == '/change-password' && !user.mustChangePassword) {
            return '/admin';
          }
          if (!location.startsWith('/admin')) {
            return '/admin';
          }
        }
        return null;
      }

      // 4. Non-admin (owner) mutual guard
      if (location.startsWith('/admin')) {
        return '/home';
      }

      // Authenticated owners trying to access login, register or splash go to /home
      if (isAuthRoute ||
          location == '/' ||
          (location == '/change-password' && !user.mustChangePassword)) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/update-required',
        name: 'update-required',
        builder: (context, state) => const UpdateRequiredScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/change-password',
        name: 'change-password',
        builder: (context, state) {
          final isForced = ref.read(authControllerProvider).value?.mustChangePassword ?? false;
          return ChangePasswordScreen(isForced: isForced);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/pending-approval',
        name: 'pending-approval',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PendingApprovalScreen(
            businessName: extra?['businessName'] as String?,
            phoneNumber: extra?['phoneNumber'] as String?,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // =======================================================================
      // OWNER SHELL: 5 Stateful Branches (Home, Inventory, Reports, More, Sell)
      // Matches modern POS architecture: Sell is a primary branch with BottomNav
      // =======================================================================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: BottomNav(
              currentIndex: navigationShell.currentIndex,
              onTabSelected: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
              onSellPressed: () {
                navigationShell.goBranch(
                  4,
                  initialLocation: 4 == navigationShell.currentIndex,
                );
              },
            ),
          );
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => BusinessDashboardScreen(
                  onSwitchToInventory: () => StatefulNavigationShell.of(context).goBranch(1),
                  onSwitchToReports: () => StatefulNavigationShell.of(context).goBranch(2),
                  onSwitchToSales: () => StatefulNavigationShell.of(context).goBranch(4),
                ),
              ),
            ],
          ),
          // Branch 1: Inventory
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inventory',
                name: 'inventory',
                builder: (context, state) => const InventoryScreen(),
              ),
            ],
          ),
          // Branch 2: Reports
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                name: 'reports',
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),
          // Branch 3: More (Settings)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
          // Branch 4: Sell / POS (Sales)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/sales',
                name: 'sales',
                builder: (context, state) => SalesPosScreen(
                  onSwitchToInventory: () => StatefulNavigationShell.of(context).goBranch(1),
                ),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: 'sales-new',
                    builder: (context, state) => SalesPosScreen(
                      onSwitchToInventory: () => StatefulNavigationShell.of(context).goBranch(1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Owner secondary routes (pushed above shell)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/initial-sync',
        name: 'initial-sync',
        builder: (context, state) => const InitialSyncScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/sync',
        name: 'sync-center',
        builder: (context, state) => const SyncCenterScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/sync/conflicts',
        name: 'sync-conflicts',
        builder: (context, state) => const ConflictResolutionScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/sync/diagnostics',
        name: 'sync-diagnostics',
        builder: (context, state) => const SyncDiagnosticsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/sync/offline',
        name: 'sync-offline',
        builder: (context, state) => const OfflineDashboardScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/settings/profile',
        name: 'settings-profile',
        builder: (context, state) => const BusinessProfileScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/settings/security',
        name: 'settings-security',
        builder: (context, state) => const SecuritySessionsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/settings/language',
        name: 'settings-language',
        builder: (context, state) => const LanguageSelectionScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationCenterScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/notifications/settings',
        name: 'notifications-settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/settings/brands',
        name: 'settings-brands',
        builder: (context, state) => const BrandsManagementScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/settings/categories',
        name: 'settings-categories',
        builder: (context, state) => const CategoriesManagementScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/settings/locations',
        name: 'settings-locations',
        builder: (context, state) => const LocationsManagementScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/parts/add',
        name: 'parts-add',
        builder: (context, state) => const PartFormScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/parts/:id',
        name: 'parts-details',
        builder: (context, state) => PartDetailsScreen(
          partId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/parts/:id/edit',
        name: 'parts-edit',
        builder: (context, state) => PartFormScreen(
          partId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/parts/:id/history',
        name: 'parts-history',
        builder: (context, state) => StockHistoryScreen(
          partId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/stock/low',
        name: 'stock-low',
        builder: (context, state) => const LowStockScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/stock/low-stock',
        name: 'stock-low-stock',
        builder: (context, state) => const LowStockScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/sales/success/:id',
        name: 'sales-success',
        builder: (context, state) => SaleSuccessScreen(
          saleId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/sales/:id',
        name: 'sales-details',
        builder: (context, state) => SaleDetailsScreen(
          saleId: state.pathParameters['id']!,
        ),
      ),

      // Debug-only Component Gallery screen (not in release builds)
      if (kDebugMode)
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/debug/component-gallery',
          name: 'component-gallery',
          builder: (context, state) => const ComponentGalleryScreen(),
        ),

      // =======================================================================
      // ADMIN SHELL: 5 Stateful Branches (Dashboard, Owners, Catalog, Reports, Settings)
      // =======================================================================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AdminScaffold(
          currentRoute: state.matchedLocation,
          child: navigationShell,
        ),
        branches: [
          // Branch 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin',
                name: 'admin-dashboard',
                builder: (context, state) => const AdminDashboardScreen(),
              ),
            ],
          ),
          // Branch 1: Owners
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/owners',
                name: 'admin-owners',
                builder: (context, state) => const AdminOwnersListScreen(),
              ),
            ],
          ),
          // Branch 2: Catalog
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/catalog',
                name: 'admin-catalog',
                builder: (context, state) => const AdminGlobalCatalogScreen(),
              ),
            ],
          ),
          // Branch 3: Reports
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/reports',
                name: 'admin-reports',
                builder: (context, state) => const AdminReportsScreen(),
              ),
            ],
          ),
          // Branch 4: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/settings',
                name: 'admin-settings',
                builder: (context, state) => const AdminSettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Admin secondary sub-routes (pushed to root navigator)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/admin/owners/add',
        name: 'admin-owners-add',
        builder: (context, state) => const AdminAddOwnerScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/admin/owners/:id',
        name: 'admin-owner-details',
        builder: (context, state) => AdminOwnerDetailsScreen(
          ownerId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/admin/audit-logs',
        name: 'admin-audit-logs',
        builder: (context, state) => const AdminAuditLogScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/admin/account',
        name: 'admin-account',
        builder: (context, state) => const AdminAccountScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/admin/sync',
        name: 'admin-sync-monitor',
        builder: (context, state) => const AdminSyncMonitorScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/admin/notifications',
        name: 'admin-notifications',
        builder: (context, state) => const AdminNotificationsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/admin/plans',
        name: 'admin-plans',
        builder: (context, state) => const AdminPlansScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/admin/backup',
        name: 'admin-backup',
        builder: (context, state) => const AdminBackupScreen(),
      ),
    ],
  );
});

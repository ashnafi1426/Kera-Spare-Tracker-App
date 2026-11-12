import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/admin_spacing.dart';
import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/language_selector_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Responsive administrative layout shell supporting both mobile 5-branch bottom navigation
/// and wide-screen NavigationRail navigation with automatic 15-minute
/// session inactivity security logout.
class AdminScaffold extends ConsumerStatefulWidget {
  final Widget child;
  final String currentRoute;
  final Duration inactivityTimeout;

  const AdminScaffold({
    super.key,
    required this.child,
    required this.currentRoute,
    this.inactivityTimeout = const Duration(minutes: 15),
  });

  @override
  ConsumerState<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends ConsumerState<AdminScaffold> {
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    _resetInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(widget.inactivityTimeout, _handleInactivityTimeout);
  }

  Future<void> _handleInactivityTimeout() async {
    if (!mounted) return;
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) {
      context.go('/login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired due to inactivity. Please log in again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onUserInteraction([dynamic _]) {
    _resetInactivityTimer();
  }

  int _getSelectedIndex() {
    if (widget.currentRoute.startsWith('/admin/owners')) return 1;
    if (widget.currentRoute.startsWith('/admin/catalog')) return 2;
    if (widget.currentRoute.startsWith('/admin/reports') ||
        widget.currentRoute.startsWith('/admin/sync')) {
      return 3;
    }
    if (widget.currentRoute.startsWith('/admin/settings') ||
        widget.currentRoute.startsWith('/admin/audit-logs') ||
        widget.currentRoute.startsWith('/admin/account') ||
        widget.currentRoute.startsWith('/admin/backup') ||
        widget.currentRoute.startsWith('/admin/plans') ||
        widget.currentRoute.startsWith('/admin/notifications')) {
      return 4;
    }
    return 0; // /admin
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/admin');
        break;
      case 1:
        context.go('/admin/owners');
        break;
      case 2:
        context.go('/admin/catalog');
        break;
      case 3:
        context.go('/admin/reports');
        break;
      case 4:
        context.go('/admin/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWide = MediaQuery.of(context).size.width >= AdminSpacing.tabletBreakpoint;
    final selectedIndex = _getSelectedIndex();
    final activeColor = context.isDark ? KeraColors.orange500 : KeraColors.navy800;

    final destinations = [
      NavigationRailDestination(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard_rounded),
        label: Text(l10n.adminDashboard),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.people_outline_rounded),
        selectedIcon: const Icon(Icons.people_alt_rounded),
        label: Text(l10n.adminOwners),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.category_outlined),
        selectedIcon: const Icon(Icons.category_rounded),
        label: Text(l10n.adminCatalog),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.bar_chart_outlined),
        selectedIcon: const Icon(Icons.bar_chart_rounded),
        label: Text(l10n.tabReports),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings_suggest_rounded),
        label: Text(l10n.adminSettings),
      ),
    ];

    final scaffold = isWide
        ? Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (idx) => _onDestinationSelected(context, idx),
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AdminSpacing.lg),
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: KeraColors.navy100,
                            borderRadius: BorderRadius.circular(AdminSpacing.radiusCard),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: AdminSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: KeraColors.orange100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ADMIN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: KeraColors.navy900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: const Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: AdminSpacing.lg),
                        child: LanguageSegmentedSwitch(),
                      ),
                    ),
                  ),
                  destinations: destinations,
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: AdminSpacing.maxContentWidth),
                      child: widget.child,
                    ),
                  ),
                ),
              ],
            ),
          )
        : Scaffold(
            backgroundColor: context.scaffoldBg,
            body: widget.child,
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: context.cardBg,
                border: Border(
                  top: BorderSide(color: context.borderColor, width: 1.0),
                ),
              ),
              child: NavigationBar(
                backgroundColor: context.cardBg,
                surfaceTintColor: Colors.transparent,
                indicatorColor: activeColor.withValues(alpha: 0.15),
                selectedIndex: selectedIndex,
                onDestinationSelected: (idx) => _onDestinationSelected(context, idx),
                destinations: [
                  NavigationDestination(
                    icon: Icon(Icons.grid_view_outlined, color: context.textSecondaryColor),
                    selectedIcon: Icon(Icons.grid_view_rounded, color: activeColor),
                    label: l10n.adminDashboard,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.people_outline_rounded, color: context.textSecondaryColor),
                    selectedIcon: Icon(Icons.people_alt_rounded, color: activeColor),
                    label: l10n.adminOwners,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.category_outlined, color: context.textSecondaryColor),
                    selectedIcon: Icon(Icons.category_rounded, color: activeColor),
                    label: l10n.adminCatalog,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.bar_chart_outlined, color: context.textSecondaryColor),
                    selectedIcon: Icon(Icons.bar_chart_rounded, color: activeColor),
                    label: l10n.tabReports,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined, color: context.textSecondaryColor),
                    selectedIcon: Icon(Icons.settings_rounded, color: activeColor),
                    label: l10n.adminSettings,
                  ),
                ],
              ),
            ),
          );

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onUserInteraction,
      onPointerMove: _onUserInteraction,
      child: scaffold,
    );
  }
}

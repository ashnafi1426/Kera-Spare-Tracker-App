import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../../../../core/design/tokens/admin_spacing.dart';
import '../../../../core/widgets/language_selector_widget.dart';
import '../../../../core/widgets/server_config_dialog.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Responsive administrative layout shell supporting both mobile bottom navigation
/// and wide-screen (web/tablet) NavigationRail navigation with automatic 15-minute
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
    if (widget.currentRoute.startsWith('/admin/settings')) return 3;
    if (widget.currentRoute.startsWith('/admin/audit-logs')) return 4;
    if (widget.currentRoute.startsWith('/admin/account')) return 5;
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
        context.go('/admin/settings');
        break;
      case 4:
        context.go('/admin/audit-logs');
        break;
      case 5:
        context.go('/admin/account');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWide = MediaQuery.of(context).size.width >= AdminSpacing.tabletBreakpoint;
    final selectedIndex = _getSelectedIndex();

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
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings_suggest_rounded),
        label: Text(l10n.adminSettings),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.history_edu_outlined),
        selectedIcon: const Icon(Icons.history_edu_rounded),
        label: Text(l10n.adminAuditLogs),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.manage_accounts_outlined),
        selectedIcon: const Icon(Icons.manage_accounts_rounded),
        label: Text(l10n.adminAccount),
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
                            color: AdminColors.primary.withValues(alpha: 0.12),
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
                            color: AdminColors.infoTint,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ADMIN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AdminColors.primary,
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
            appBar: AppBar(
              title: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.adminPortalTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_ethernet_rounded),
                  tooltip: 'Server Settings',
                  onPressed: () => showServerConfigDialog(context, ref),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: LanguageSegmentedSwitch(),
                ),
              ],
            ),
            body: widget.child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex > 4 ? 4 : selectedIndex,
              onDestinationSelected: (idx) {
                if (idx == 4) {
                  // More / Settings & Account modal or navigation
                  _showMobileMoreMenu(context, l10n);
                } else {
                  _onDestinationSelected(context, idx);
                }
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.dashboard_outlined),
                  selectedIcon: const Icon(Icons.dashboard_rounded),
                  label: l10n.adminDashboard,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.people_outline_rounded),
                  selectedIcon: const Icon(Icons.people_alt_rounded),
                  label: l10n.adminOwners,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.category_outlined),
                  selectedIcon: const Icon(Icons.category_rounded),
                  label: l10n.adminCatalog,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings_suggest_rounded),
                  label: l10n.adminSettings,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.more_horiz_rounded),
                  selectedIcon: const Icon(Icons.more_horiz_rounded),
                  label: l10n.adminMore,
                ),
              ],
            ),
          );

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onUserInteraction,
      onPointerMove: _onUserInteraction,
      child: scaffold,
    );
  }

  void _showMobileMoreMenu(BuildContext context, AppLocalizations l10n) {

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.history_edu_rounded),
                  title: Text(l10n.adminAuditLogs),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.go('/admin/audit-logs');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_ethernet_rounded),
                  title: const Text('Server Connection'),
                  subtitle: const Text('Configure IP / Port for API connectivity'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    showServerConfigDialog(context, ref);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.manage_accounts_rounded),
                  title: Text(l10n.adminAccount),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.go('/admin/account');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

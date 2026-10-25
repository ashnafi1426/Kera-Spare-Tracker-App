import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/language_selector_widget.dart';
import '../../../../l10n/app_localizations.dart';

/// Responsive administrative layout shell supporting both mobile bottom navigation
/// and wide-screen (web/tablet) NavigationRail navigation.
class AdminScaffold extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const AdminScaffold({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  int _getSelectedIndex() {
    if (currentRoute.startsWith('/admin/owners')) return 1;
    if (currentRoute.startsWith('/admin/catalog')) return 2;
    if (currentRoute.startsWith('/admin/settings')) return 3;
    if (currentRoute.startsWith('/admin/audit-logs')) return 4;
    if (currentRoute.startsWith('/admin/account')) return 5;
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isWide = MediaQuery.of(context).size.width >= 720;
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

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (idx) => _onDestinationSelected(context, idx),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ADMIN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
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
                    padding: EdgeInsets.only(bottom: 20.0),
                    child: LanguageSegmentedSwitch(),
                  ),
                ),
              ),
              destinations: destinations,
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    // Compact screen (Phone layout)
    return Scaffold(
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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: LanguageSegmentedSwitch(),
          ),
        ],
      ),
      body: child,
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

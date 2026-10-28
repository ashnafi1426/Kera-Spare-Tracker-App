import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/context_extensions.dart';
import '../../../auth/presentation/widgets/session_banners.dart';
import '../../../parts/presentation/screens/inventory_screen.dart';
import '../../../reports/presentation/screens/reports_screen.dart';
import '../../../sales/presentation/screens/sales_list_tab.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

/// Main container screen with bottom navigation for Inventory, Sales, Reports, and Settings.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final tabs = [
      const InventoryScreen(),
      const SalesListTab(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const NeedsLoginBanner(),
            const OfflineMaxDaysBanner(),
            const AccountSuspendedBanner(),
            const PasswordChangedBanner(),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: tabs,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.inventory_2_outlined),
            selectedIcon: const Icon(Icons.inventory_2_rounded),
            label: l10n.inventoryTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.point_of_sale_outlined),
            selectedIcon: const Icon(Icons.point_of_sale_rounded),
            label: l10n.salesTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart_rounded),
            label: l10n.reportsTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: l10n.settingsTab,
          ),
        ],
      ),
    );
  }
}

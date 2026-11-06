import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/context_extensions.dart';
import '../../../auth/presentation/widgets/session_banners.dart';
import '../../../dashboard/presentation/screens/business_dashboard_screen.dart';
import '../../../parts/presentation/screens/inventory_screen.dart';
import '../../../reports/presentation/screens/reports_screen.dart';
import '../../../sales/presentation/screens/sales_list_tab.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

/// Main container screen with bottom navigation for Dashboard, Inventory, Sales, Reports, and Settings.
/// Supports dark mode and live bilingual (Amharic/English) translation.
class HomeScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const HomeScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final activeIconColor = isDark ? const Color(0xFFF7941D) : const Color(0xFF0B2A5B);
    final inactiveIconColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF5E6D82);

    final tabs = [
      BusinessDashboardScreen(
        onSwitchToInventory: () => setState(() => _currentIndex = 1),
        onSwitchToSales: () => setState(() => _currentIndex = 2),
        onSwitchToReports: () => setState(() => _currentIndex = 3),
      ),
      const InventoryScreen(),
      const SalesListTab(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
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
          indicatorColor: activeIconColor.withValues(alpha: 0.15),
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: inactiveIconColor),
              selectedIcon: Icon(Icons.home_rounded, color: activeIconColor),
              label: context.tr('ዳሽቦርድ', 'Dashboard'),
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined, color: inactiveIconColor),
              selectedIcon: Icon(Icons.inventory_2_rounded, color: activeIconColor),
              label: context.tr('ዕቃዎች', 'Inventory'),
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined, color: inactiveIconColor),
              selectedIcon: Icon(Icons.receipt_long_rounded, color: activeIconColor),
              label: context.tr('ሽያጭ', 'Sales'),
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined, color: inactiveIconColor),
              selectedIcon: Icon(Icons.bar_chart_rounded, color: activeIconColor),
              label: context.tr('ሪፖርት', 'Reports'),
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined, color: inactiveIconColor),
              selectedIcon: Icon(Icons.settings_rounded, color: activeIconColor),
              label: context.tr('ቅንብር', 'Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

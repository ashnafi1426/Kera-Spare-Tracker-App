import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../../../auth/presentation/widgets/session_banners.dart';
import '../../../dashboard/presentation/screens/business_dashboard_screen.dart';
import '../../../parts/presentation/screens/inventory_screen.dart';
import '../../../reports/presentation/screens/reports_screen.dart';
import '../../../sales/presentation/screens/sales_list_tab.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

/// Main container screen with bottom navigation for Dashboard, Inventory, Sales, Reports, and Settings.
/// Faithfully updated to match Owner App designs.
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
    final tabs = [
      BusinessDashboardScreen(
        onSwitchToInventory: () => setState(() => _currentIndex = 1),
        onSwitchToSales: () => setState(() => _currentIndex = 2),
      ),
      const InventoryScreen(),
      const SalesListTab(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: AdminColors.background,
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
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
          ),
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: const Color(0xFF0C2340).withValues(alpha: 0.12),
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Color(0xFF5E6D82)),
              selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF0C2340)),
              label: 'ዳሽቦርድ',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined, color: Color(0xFF5E6D82)),
              selectedIcon: Icon(Icons.inventory_2_rounded, color: Color(0xFF0C2340)),
              label: 'ዕቃዎች',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined, color: Color(0xFF5E6D82)),
              selectedIcon: Icon(Icons.receipt_long_rounded, color: Color(0xFF0C2340)),
              label: 'ሽያጭ',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined, color: Color(0xFF5E6D82)),
              selectedIcon: Icon(Icons.bar_chart_rounded, color: Color(0xFF0C2340)),
              label: 'ሪፖርት',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined, color: Color(0xFF5E6D82)),
              selectedIcon: Icon(Icons.settings_rounded, color: Color(0xFF0C2340)),
              label: 'ቅንብር',
            ),
          ],
        ),
      ),
    );
  }
}

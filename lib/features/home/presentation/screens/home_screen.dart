import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/widgets/bottom_nav.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../auth/presentation/widgets/session_banners.dart';
import '../../../dashboard/presentation/screens/business_dashboard_screen.dart';
import '../../../parts/presentation/screens/inventory_screen.dart';
import '../../../reports/presentation/screens/reports_screen.dart';
import '../../../sales/presentation/screens/sales_pos_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

/// Main container screen matching Kera Spare Tracker modern navigation:
/// - 4 primary tabs: Home, Inventory, Reports, More (Settings)
/// - Raised center floating action button for instant Sell checkout
/// - Supports dark mode and live bilingual (Amharic/English) translation.
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
        onSwitchToSales: () => setState(() => _currentIndex = 4),
        onSwitchToReports: () => setState(() => _currentIndex = 2),
      ),
      const InventoryScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
      SalesPosScreen(
        onSwitchToInventory: () => setState(() => _currentIndex = 1),
      ),
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
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTabSelected: (index) {
          setState(() => _currentIndex = index);
        },
        onSellPressed: () {
          setState(() => _currentIndex = 4);
        },
      ),
    );
  }
}

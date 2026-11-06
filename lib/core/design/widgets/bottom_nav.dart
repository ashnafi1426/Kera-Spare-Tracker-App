import 'package:flutter/material.dart';
import '../../utils/context_extensions.dart';
import '../tokens/kera_colors.dart';

/// Standard 4-branch mobile navigation bar with raised center orange Sell button.
///
/// Follows strict 2-color design:
/// - 4 branches: 0: Home, 1: Inventory, 2: Reports, 3: More
/// - Center raised orange button triggers full-screen Sell checkout.
class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onSellPressed;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onSellPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final l10n = context.l10n;
    final activeColor = isDark ? KeraColors.orange500 : KeraColors.navy800;
    final inactiveColor = isDark ? KeraColors.disabledColor : KeraColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(
          top: BorderSide(color: context.borderColor, width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: KeraColors.navy800.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              // Tab 0: Home
              _buildNavItem(
                index: 0,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: l10n.tabHome,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),

              // Tab 1: Inventory
              _buildNavItem(
                index: 1,
                icon: Icons.inventory_2_outlined,
                selectedIcon: Icons.inventory_2_rounded,
                label: l10n.tabInventory,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),

              // Center Raised Orange Sell Button
              Expanded(
                child: Center(
                  child: InkWell(
                    onTap: onSellPressed,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: KeraColors.orange500,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: KeraColors.orange500.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.point_of_sale_rounded,
                            color: KeraColors.navy900,
                            size: 22,
                          ),
                          Text(
                            l10n.navSell,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: KeraColors.navy900,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Tab 2: Reports
              _buildNavItem(
                index: 2,
                icon: Icons.bar_chart_rounded,
                selectedIcon: Icons.insert_chart_rounded,
                label: l10n.tabReports,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),

              // Tab 3: More
              _buildNavItem(
                index: 3,
                icon: Icons.menu_rounded,
                selectedIcon: Icons.menu_open_rounded,
                label: l10n.tabMore,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? activeColor : inactiveColor;

    return Expanded(
      child: InkWell(
        onTap: () => onTabSelected(index),
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                size: 24,
                color: color,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


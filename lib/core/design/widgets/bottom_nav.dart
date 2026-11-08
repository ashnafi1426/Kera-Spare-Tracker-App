import 'package:flutter/material.dart';
import '../../utils/context_extensions.dart';

/// Modern Mobile Navigation Bar matching Kera Spare Tracker reference mockup.
///
/// Features:
/// - 4 primary branches: Home, Inventory, Reports, More
/// - Center raised vibrant orange floating action button for instant Sale checkout
/// - Active navigation indicator line
/// - Smooth haptic touch feedback
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
    final activeColor = isDark ? const Color(0xFFF7941D) : const Color(0xFF0B2A5B);
    final inactiveColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
          BoxShadow(
            color: const Color(0xFFF7941D).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              // Tab 0: Home
              _buildNavItem(
                context: context,
                index: 0,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: context.tr('መነሻ', 'Home'),
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),

              // Tab 1: Inventory
              _buildNavItem(
                context: context,
                index: 1,
                icon: Icons.inventory_2_outlined,
                selectedIcon: Icons.inventory_2_rounded,
                label: context.tr('ዕቃዎች', 'Inventory'),
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),

              // Center Raised Floating Orange Sell Button
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: onSellPressed,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFFF9E1B),
                                Color(0xFFFF6D00),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6D00).withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white,
                              width: 2.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.shopping_cart_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                context.tr('ሽጥ', 'Sell'),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Active indicator line matching mockup
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: (currentIndex == 4) ? 22 : 0,
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7941D),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Tab 2: Reports
              _buildNavItem(
                context: context,
                index: 2,
                icon: Icons.bar_chart_outlined,
                selectedIcon: Icons.bar_chart_rounded,
                label: context.tr('ሪፖርት', 'Reports'),
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),

              // Tab 3: More / Settings
              _buildNavItem(
                context: context,
                index: 3,
                icon: Icons.menu_rounded,
                selectedIcon: Icons.menu_open_rounded,
                label: context.tr('ተጨማሪ', 'More'),
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
    required BuildContext context,
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
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: SizedBox(
          height: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                size: 23,
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
              const SizedBox(height: 3),
              // Sleek active line indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 18 : 0,
                height: 2.5,
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

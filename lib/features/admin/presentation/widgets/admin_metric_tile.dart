import 'package:flutter/material.dart';
import '../../../../core/utils/context_extensions.dart';

/// Reusable metric card matching the finalized Figma Admin Dashboard Platform Overview.
class AdminMetricTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String badgeText;
  final Color? iconColor;
  final Color? iconBgColor;
  final Color? badgeColor;
  final Color? badgeBgColor;
  final VoidCallback? onTap;

  const AdminMetricTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.badgeText,
    this.iconColor,
    this.iconBgColor,
    this.badgeColor,
    this.badgeBgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final effectiveIconColor = iconColor ?? const Color(0xFF173655);
    final effectiveIconBgColor = iconBgColor ??
        (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));
    final effectiveBadgeColor = badgeColor ?? const Color(0xFF159B55);
    final effectiveBadgeBgColor = badgeBgColor ??
        (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.borderColor, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? const Color(0x22000000)
                  : const Color(0x060C2340),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Icon Container and Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: effectiveIconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: effectiveIconColor,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: effectiveBadgeBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: effectiveBadgeColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Number value (FittedBox to prevent overflow at narrow viewports)
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: context.textPrimaryColor,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 2),

            // Subtitle label
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: context.textSecondaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../tokens/admin_colors.dart';
import '../tokens/admin_spacing.dart';
import '../tokens/admin_typography.dart';
import 'list_card.dart';

/// Accessible Metric Card designed for the Admin Dashboard.
/// Displays label (caption, secondary), metric number (28pt bold, primary text),
/// small icon in a tinted circular container, and optional trend/detail line.
class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String? trendText;
  final Color? trendColor;
  final VoidCallback? onTap;

  MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    Color? iconColor,
    Color? iconBackgroundColor,
    Color? accentColor,
    this.trendText,
    this.trendColor,
    this.onTap,
  })  : iconColor = accentColor ?? iconColor ?? AdminColors.primary,
        iconBackgroundColor = iconBackgroundColor ?? (accentColor != null ? accentColor.withValues(alpha: 0.16) : AdminColors.primaryTint);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AdminSpacing.md),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Label and Icon Container
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AdminTypography.captionOf(isDark),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AdminSpacing.xs),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: iconColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: AdminSpacing.sm),

          // Metric Number: High contrast primary text color (never dark blue/orange on dark)
          Text(
            value,
            style: AdminTypography.metricNumber(isDark),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Optional Trend or Detail line
          if (trendText != null) ...[
            const SizedBox(height: AdminSpacing.xs),
            Text(
              trendText!,
              style: TextStyle(
                fontFamily: AdminTypography.fontNotoSans,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: trendColor ?? AdminColors.textSecondaryOf(isDark),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

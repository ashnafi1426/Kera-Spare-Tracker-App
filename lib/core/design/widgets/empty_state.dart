import 'package:flutter/material.dart';
import '../tokens/admin_colors.dart';
import '../tokens/admin_spacing.dart';
import '../tokens/admin_typography.dart';

/// Reusable empty state view with icon, title, description, and optional action.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget? actionWidget = action;
    if (actionWidget == null && onAction != null && actionLabel != null) {
      actionWidget = ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminSpacing.radiusButton),
          ),
        ),
        onPressed: onAction,
        child: Text(actionLabel!),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.xl,
          vertical: AdminSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AdminColors.primaryTint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: AdminColors.primary,
              ),
            ),
            const SizedBox(height: AdminSpacing.lg),
            Text(
              title,
              style: AdminTypography.sectionHeader(isDark),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: AdminSpacing.xs),
              Text(
                description!,
                style: AdminTypography.captionOf(isDark),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionWidget != null) ...[
              const SizedBox(height: AdminSpacing.lg),
              actionWidget,
            ],
          ],
        ),
      ),
    );
  }
}

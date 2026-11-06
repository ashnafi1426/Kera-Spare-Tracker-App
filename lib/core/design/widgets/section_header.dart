import 'package:flutter/material.dart';
import '../tokens/admin_spacing.dart';
import '../tokens/admin_typography.dart';
import 'text_action_button.dart';

/// Standard Section Header for mobile and admin portal screens.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.only(
      top: AdminSpacing.lg,
      bottom: AdminSpacing.sm,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget? actionWidget = trailing;
    if (actionWidget == null && actionLabel != null && onAction != null) {
      actionWidget = TextActionButton(
        label: actionLabel!,
        onPressed: onAction,
      );
    }

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: AdminTypography.sectionHeader(isDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ?actionWidget,
        ],
      ),
    );
  }
}

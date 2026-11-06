import 'package:flutter/material.dart';
import '../tokens/kera_colors.dart';
import '../tokens/kera_spacing.dart';
import '../tokens/kera_typography.dart';
import 'kera_button.dart';

/// Reusable empty state view displaying an outline icon in a tonal circle,
/// bilingual title, descriptive subtitle, and primary call-to-action button.
class KeraEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? customAction;
  final double iconSize;

  const KeraEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.customAction,
    this.iconSize = 36.0,
  });

  /// Specialized empty state for zero inventory parts.
  factory KeraEmptyState.inventory({
    Key? key,
    required String title,
    String? description,
    String? actionLabel,
    VoidCallback? onAddPart,
  }) {
    return KeraEmptyState(
      key: key,
      icon: Icons.inventory_2_outlined,
      title: title,
      description: description,
      actionLabel: actionLabel,
      onAction: onAddPart,
    );
  }

  /// Specialized empty state for search results.
  factory KeraEmptyState.searchResults({
    Key? key,
    required String title,
    String? description,
    String? actionLabel,
    VoidCallback? onResetFilters,
  }) {
    return KeraEmptyState(
      key: key,
      icon: Icons.search_off_rounded,
      title: title,
      description: description,
      actionLabel: actionLabel,
      onAction: onResetFilters,
    );
  }

  /// Specialized empty state for empty cart.
  factory KeraEmptyState.cart({
    Key? key,
    required String title,
    String? description,
    String? actionLabel,
    VoidCallback? onBrowseCatalog,
  }) {
    return KeraEmptyState(
      key: key,
      icon: Icons.shopping_cart_outlined,
      title: title,
      description: description,
      actionLabel: actionLabel,
      onAction: onBrowseCatalog,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KeraSpacing.xl,
          vertical: KeraSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon in tonal circle
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: KeraColors.navyTint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: KeraColors.brandNavy,
              ),
            ),
            const SizedBox(height: KeraSpacing.lg),

            // Title
            Text(
              title,
              style: KeraTypography.headlineSmall(),
              textAlign: TextAlign.center,
            ),

            // Subtitle Description
            if (description != null && description!.isNotEmpty) ...[
              const SizedBox(height: KeraSpacing.sm),
              Text(
                description!,
                style: KeraTypography.bodyMedium(color: KeraColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],

            // Call to Action
            if (customAction != null) ...[
              const SizedBox(height: KeraSpacing.xl),
              customAction!,
            ] else if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: KeraSpacing.xl),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: KeraButton.primary(
                  label: actionLabel!,
                  onPressed: onAction,
                  isFullWidth: false,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


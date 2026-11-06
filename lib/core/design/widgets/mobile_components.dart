import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/context_extensions.dart';
import '../tokens/kera_colors.dart';
import '../tokens/kera_radii.dart';
import '../tokens/kera_typography.dart';
import 'status_badge.dart';

// ============================================================================
// 1. PageScaffold
// ============================================================================
/// Safe-area, keyboard-dismissing page wrapper with optional pull-to-refresh.
class PageScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Future<void> Function()? onRefresh;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final EdgeInsetsGeometry padding;

  const PageScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.onRefresh,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: padding,
      child: body,
    );

    if (onRefresh != null) {
      content = RefreshIndicator(
        color: KeraColors.orange500,
        backgroundColor: context.cardBg,
        onRefresh: onRefresh!,
        child: content,
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: backgroundColor ?? context.scaffoldBg,
        appBar: appBar,
        body: SafeArea(child: content),
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      ),
    );
  }
}

// ============================================================================
// 2. CollapsingAppBar
// ============================================================================
/// Modern collapsing sliver app bar with large 24px semibold title.
class CollapsingAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final double expandedHeight;
  final bool pinned;

  const CollapsingAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.expandedHeight = 110,
    this.pinned = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return SliverAppBar(
      pinned: pinned,
      expandedHeight: expandedHeight,
      backgroundColor: context.cardBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: leading,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 14),
        centerTitle: false,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? KeraColors.textWhite : KeraColors.navy900,
            fontFamily: KeraTypography.fontEthiopic,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// ============================================================================
// 3. SyncChip
// ============================================================================
/// Real-time sync indicator chip (Synced / Syncing / Offline).
class SyncChip extends StatelessWidget {
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final VoidCallback? onTap;

  const SyncChip({
    super.key,
    required this.isOnline,
    this.isSyncing = false,
    this.pendingCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOnline) {
      return StatusBadge.offline(
        label: context.tr('ከመስመር ውጭ', 'Offline'),
      );
    }
    if (isSyncing) {
      return StatusBadge.syncing(
        label: context.tr('በማመሳሰል ላይ...', 'Syncing...'),
      );
    }
    if (pendingCount > 0) {
      return StatusBadge.pending(
        count: pendingCount,
        defaultLabel: context.tr('ያልተላከ', 'Pending'),
      );
    }
    return StatusBadge.synced(
      label: context.tr('የተገናኘ', 'Synced'),
    );
  }
}

// ============================================================================
// 4. PrimaryButton
// ============================================================================
/// Solid Orange (#F7941D) with bold Navy text (#061B3F). Exactly ONE per screen.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = 48,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: KeraColors.orange500,
          foregroundColor: KeraColors.navy900,
          disabledBackgroundColor: KeraColors.border,
          disabledForegroundColor: KeraColors.disabledColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KeraRadii.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: isLoading ? null : () {
          HapticFeedback.lightImpact();
          onPressed?.call();
        },
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(KeraColors.navy900),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: KeraColors.navy900),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: KeraColors.navy900,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ============================================================================
// 5. SecondaryButton
// ============================================================================
/// Navy outline button with 48px touch target.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final double? width;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 48,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final color = isDark ? KeraColors.textWhite : KeraColors.navy800;

    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: context.borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KeraRadii.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: () {
          HapticFeedback.selectionClick();
          onPressed?.call();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19, color: color),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 6. TextActionButton
// ============================================================================
/// High-contrast text button.
class TextActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  const TextActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? KeraColors.orange700,
        minimumSize: const Size(48, 48),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color ?? (context.isDark ? KeraColors.orange500 : KeraColors.orange700),
        ),
      ),
    );
  }
}

// ============================================================================
// 8. SummaryCard
// ============================================================================
/// Deep navy overview card (#0B2A5B) with big tabular figures and sparkline.
class SummaryCard extends StatelessWidget {
  final String title;
  final String mainAmount;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SummaryCard({
    super.key,
    required this.title,
    required this.mainAmount,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KeraRadii.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: KeraColors.navy800,
          borderRadius: BorderRadius.circular(KeraRadii.lg),
          boxShadow: const [
            BoxShadow(
              color: Color(0x180B2A5B),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFD3DAE8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 8),
            Text(
              mainAmount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFFD3DAE8),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 9. KpiCard
// ============================================================================
/// Compact metric card with label, bold count/currency, and status chip.
class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KeraRadii.lg),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(KeraRadii.lg),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (icon != null)
                  Icon(icon, size: 18, color: KeraColors.navy800),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 10. StockCard
// ============================================================================
/// Stock card with large quantity, status badge, and Stock In / Out triggers.
class StockCard extends StatelessWidget {
  final double currentQuantity;
  final double minQuantity;
  final String unit;
  final VoidCallback onStockIn;
  final VoidCallback onStockOut;

  const StockCard({
    super.key,
    required this.currentQuantity,
    required this.minQuantity,
    this.unit = 'Pcs',
    required this.onStockIn,
    required this.onStockOut,
  });

  @override
  Widget build(BuildContext context) {
    final isLow = currentQuantity <= minQuantity && currentQuantity > 0;
    final isOut = currentQuantity <= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(KeraRadii.lg),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('የክምችት ሁኔታ', 'Stock Status'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondaryColor,
                ),
              ),
              if (isOut)
                StatusBadge.outOfStock(label: context.tr('አልቋል', 'Out of stock'))
              else if (isLow)
                StatusBadge.lowStock(quantity: currentQuantity, defaultLabel: context.tr('አነስተኛ', 'Low'))
              else
                StatusBadge.inStock(quantity: currentQuantity, unit: unit),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${currentQuantity.toStringAsFixed(currentQuantity % 1 == 0 ? 0 : 1)} $unit',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: context.tr('ዕቃ አስገባ', 'Stock In'),
                  icon: Icons.add_rounded,
                  onPressed: onStockIn,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SecondaryButton(
                  label: context.tr('ዕቃ አውጣ', 'Stock Out'),
                  icon: Icons.remove_rounded,
                  onPressed: onStockOut,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 15. FilterChipRow
// ============================================================================
/// Horizontally scrollable chip row.
class FilterChipRow extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const FilterChipRow({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isSelected = index == selectedIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(labels[index]),
              selected: isSelected,
              onSelected: (_) => onSelected(index),
              selectedColor: KeraColors.orange100,
              backgroundColor: context.cardBg,
              labelStyle: TextStyle(
                color: isSelected ? KeraColors.orange700 : context.textSecondaryColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected ? KeraColors.orange500 : context.borderColor,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ============================================================================
// 17. SearchField (NO Barcode Icon per Correction 1)
// ============================================================================
/// 48px search field with clear action.
class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String hintText;

  const SearchField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onClear,
    this.hintText = 'ፈልግ · Search...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(KeraRadii.md),
        border: Border.all(color: context.borderColor),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: context.textPrimaryColor, fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: context.textSecondaryColor, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: context.textSecondaryColor, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    controller.clear();
                    onClear?.call();
                    onChanged?.call('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// ============================================================================
// 18. QuantityStepper
// ============================================================================
/// Tactile quantity stepper with 48x48 touch targets.
class QuantityStepper extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double? max;
  final double step;

  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max,
    this.step = 1,
  });

  @override
  Widget build(BuildContext context) {
    final canDecrement = value > min;
    final canIncrement = max == null || value < max!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepperButton(
          icon: Icons.remove_rounded,
          enabled: canDecrement,
          onTap: () {
            if (canDecrement) {
              HapticFeedback.selectionClick();
              onChanged((value - step).clamp(min, max ?? double.infinity));
            }
          },
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        _stepperButton(
          icon: Icons.add_rounded,
          enabled: canIncrement,
          onTap: () {
            if (canIncrement) {
              HapticFeedback.selectionClick();
              onChanged(value + step);
            }
          },
        ),
      ],
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 44,
      height: 44,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: const BorderSide(color: KeraColors.border),
        ),
        onPressed: enabled ? onTap : null,
        child: Icon(icon, size: 20, color: enabled ? KeraColors.navy800 : KeraColors.disabledColor),
      ),
    );
  }
}

// ============================================================================
// 19. SectionHeader
// ============================================================================
/// 17px semibold section title with optional action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: context.textPrimaryColor,
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextActionButton(
              label: actionLabel!,
              onPressed: onAction,
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// 20. DateGroupHeader
// ============================================================================
/// Sticky date separator for lists.
class DateGroupHeader extends StatelessWidget {
  final String dateText;
  final String? rightText;

  const DateGroupHeader({
    super.key,
    required this.dateText,
    this.rightText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: context.scaffoldBg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.textSecondaryColor,
            ),
          ),
          if (rightText != null)
            Text(
              rightText!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// 21. EmptyState
// ============================================================================
/// Reusable empty state (Illustration/Icon, headline, button).
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    this.icon = Icons.inventory_2_outlined,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: KeraColors.navy50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: KeraColors.navy800),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: context.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              PrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 22. ErrorState (NO Server Diagnostic Shortcut per Correction 1)
// ============================================================================
/// Reusable error state with retry.
class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateView({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: KeraColors.orange100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: KeraColors.orange700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              SecondaryButton(
                label: context.tr('እንደገና ሞክር', 'Try Again'),
                icon: Icons.refresh_rounded,
                width: 200,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 23. SkeletonBox
// ============================================================================
/// Shimmer skeleton loader box.
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF162544) : const Color(0xFFE6ECF7),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// ============================================================================
// 24. OfflineBanner
// ============================================================================
/// Slim top offline notification banner.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: KeraColors.navy100,
        border: Border(
          bottom: BorderSide(color: KeraColors.navy600, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 16, color: KeraColors.navy800),
          const SizedBox(width: 8),
          Text(
            context.tr('ከመስመር ውጭ — ለውጦች በዚህ ስልክ ላይ ተቀምጠዋል', 'Offline — changes are saved on this phone'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: KeraColors.navy800,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 25. ConfirmSheet
// ============================================================================
/// Bottom confirmation sheet for destructive actions.
class ConfirmSheet extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const ConfirmSheet({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'አረጋግጥ · Confirm',
    required this.onConfirm,
    this.onCancel,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'አረጋግጥ · Confirm',
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ConfirmSheet(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        onConfirm: () => Navigator.pop(ctx, true),
        onCancel: () => Navigator.pop(ctx, false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: context.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: context.tr('ይቅር', 'Cancel'),
                    onPressed: () => onCancel != null ? onCancel!() : Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: confirmLabel,
                    onPressed: onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 30. SettingsGroup & SettingsTile
// ============================================================================
class SettingsGroup extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const SettingsGroup({
    super.key,
    this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.textSecondaryColor,
              ),
            ),
          ),
        ],
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(KeraRadii.lg),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: KeraColors.navy800, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: context.textPrimaryColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
            )
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }
}

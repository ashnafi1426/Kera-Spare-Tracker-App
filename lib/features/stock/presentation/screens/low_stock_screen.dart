import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/kera_logo_widget.dart';
import '../../../parts/domain/models/part_item.dart';
import '../dialogs/update_stock_dialog.dart';
import '../providers/stock_providers.dart';

enum _LowStockFilter { all, outOfStock, lowStock }

/// Stitch Screen 20: Stock Overview & Low Stock Alerts.
///
/// Features deep Navy industrial header, real-time sync status pill,
/// Bento metric summary strip (total alerts, out-of-stock SKUs, low-stock SKUs),
/// filter chips, high-contrast alert cards with shelf locations and threshold ratios,
/// and direct Update Stock quick-action modal integration.
class LowStockScreen extends ConsumerStatefulWidget {
  const LowStockScreen({super.key});

  @override
  ConsumerState<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends ConsumerState<LowStockScreen> {
  _LowStockFilter _selectedFilter = _LowStockFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lowStockAsync = ref.watch(lowStockPartsStreamProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: KeraColors.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const KeraLogoWidget(size: 34, borderRadius: 6),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.lowStockListTitle,
                    style: KeraTypography.headlineSmall(color: Colors.white)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    l10n.lowStockListDesc,
                    style: KeraTypography.labelSmall(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Network Sync Status Pill (Stitch Screen 20)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(KeraRadii.full),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: KeraColors.brandOrange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'የተገናኘ',
                  style: KeraTypography.labelSmall(
                    color: Colors.white,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
      body: lowStockAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (parts) {
          if (parts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: KeraColors.stockInBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 48,
                        color: KeraColors.stockInText,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.noLowStockItems,
                      textAlign: TextAlign.center,
                      style: KeraTypography.headlineSmall(
                        color: KeraColors.textPrimary,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ሁሉም መለዋወጫዎች ከተገቢው የክምችት መጠን በላይ ናቸው።',
                      textAlign: TextAlign.center,
                      style: KeraTypography.bodyMedium(
                        color: KeraColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final outOfStockList =
              parts.where((p) => p.cachedQuantity <= 0).toList();
          final lowStockList =
              parts.where((p) => p.cachedQuantity > 0).toList();

          final filteredParts = _selectedFilter == _LowStockFilter.outOfStock
              ? outOfStockList
              : _selectedFilter == _LowStockFilter.lowStock
                  ? lowStockList
                  : parts;

          return Column(
            children: [
              // Bento Metric Strip (Stitch Screen 20)
              Container(
                color: KeraColors.surfacePure,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Out-of-stock Bento Tile
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: KeraColors.stockOutBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: KeraColors.stockOutText
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'ያለቀባቸው',
                                      style: KeraTypography.labelSmall(
                                        color: KeraColors.stockOutText,
                                      ).copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const Icon(
                                      Icons.report_problem_rounded,
                                      size: 16,
                                      color: KeraColors.stockOutText,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${outOfStockList.length} SKUs',
                                  style: KeraTypography.numericMedium(
                                    color: KeraColors.stockOutText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Out of Stock',
                                  style: KeraTypography.bodySmall(
                                    color: KeraColors.stockOutText
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Low-stock Bento Tile
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: KeraColors.stockLowBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: KeraColors.stockLowText
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'አነስተኛ ክምችት',
                                      style: KeraTypography.labelSmall(
                                        color: KeraColors.stockLowText,
                                      ).copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      size: 16,
                                      color: KeraColors.stockLowText,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${lowStockList.length} SKUs',
                                  style: KeraTypography.numericMedium(
                                    color: KeraColors.stockLowText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Low Stock Alert',
                                  style: KeraTypography.bodySmall(
                                    color: KeraColors.stockLowText
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick Filter Chips Row
                    Row(
                      children: [
                        _buildFilterChip(
                          label: 'ሁሉም / All (${parts.length})',
                          isSelected: _selectedFilter == _LowStockFilter.all,
                          onTap: () => setState(
                              () => _selectedFilter = _LowStockFilter.all),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'ያለቀ (${outOfStockList.length})',
                          isSelected:
                              _selectedFilter == _LowStockFilter.outOfStock,
                          onTap: () => setState(() =>
                              _selectedFilter = _LowStockFilter.outOfStock),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'አነስተኛ (${lowStockList.length})',
                          isSelected:
                              _selectedFilter == _LowStockFilter.lowStock,
                          onTap: () => setState(() =>
                              _selectedFilter = _LowStockFilter.lowStock),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Parts List
              Expanded(
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: filteredParts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final part = filteredParts[index];
                    return _LowStockPartCard(part: part);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? KeraColors.primaryNavy
              : KeraColors.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? KeraColors.primaryNavy
                : KeraColors.outlineBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : KeraColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _LowStockPartCard extends StatelessWidget {
  final PartItem part;

  const _LowStockPartCard({required this.part});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasPhoto =
        part.photoLocalPath != null && File(part.photoLocalPath!).existsSync();
    final threshold = part.lowStockLevel ?? 5.0;
    final isOutOfStock = part.cachedQuantity <= 0;
    final location = part.customLocation ?? part.locationName ?? '';

    return Container(
      decoration: BoxDecoration(
        color: KeraColors.surfacePure,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOutOfStock
              ? KeraColors.stockOutText.withValues(alpha: 0.3)
              : KeraColors.stockLowText.withValues(alpha: 0.3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08172B4D),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/parts/${part.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Thumbnail / Icon with OEM genuine badge
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: isOutOfStock
                      ? KeraColors.stockOutBg
                      : KeraColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: KeraColors.outlineBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasPhoto
                    ? Image.file(
                        File(part.photoLocalPath!),
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        isOutOfStock
                            ? Icons.error_outline_rounded
                            : Icons.warning_amber_rounded,
                        color: isOutOfStock
                            ? KeraColors.stockOutText
                            : KeraColors.stockLowText,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 12),

              // Title and Attributes
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      part.displayName,
                      style: KeraTypography.titleMedium(
                        color: KeraColors.textPrimary,
                      ).copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (part.partNumber != null)
                          Text(
                            part.partNumber!,
                            style: KeraTypography.bodySmall(
                              color: KeraColors.textSecondary,
                            ).copyWith(fontFamily: 'monospace'),
                          ),
                        if (part.partNumber != null && location.isNotEmpty)
                          const Text(' • ',
                              style:
                                  TextStyle(color: KeraColors.textMuted)),
                        if (location.isNotEmpty)
                          Text(
                            location,
                            style: KeraTypography.bodySmall(
                              color: KeraColors.orange700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Threshold ratio pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? KeraColors.stockOutBg
                            : KeraColors.stockLowBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${part.cachedQuantity.toStringAsFixed(0)} / ${threshold.toStringAsFixed(0)} ${part.unit ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isOutOfStock
                              ? KeraColors.stockOutText
                              : KeraColors.stockLowText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Quick Action Button: Update Stock
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  backgroundColor: isOutOfStock
                      ? KeraColors.stockOutBg
                      : KeraColors.stockInBg,
                  foregroundColor: isOutOfStock
                      ? KeraColors.stockOutText
                      : KeraColors.stockInText,
                  minimumSize: const Size(44, 44),
                ),
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                tooltip: l10n.updateStock,
                onPressed: () => UpdateStockDialog.show(context, part),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

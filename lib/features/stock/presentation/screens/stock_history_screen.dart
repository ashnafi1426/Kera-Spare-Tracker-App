import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../data/local/tables/enums.dart';
import '../../../parts/presentation/providers/metadata_providers.dart';
import '../../../parts/presentation/providers/parts_providers.dart';
import '../providers/stock_providers.dart';

/// Stitch Screen 22, 24 & 25: Stock Movement History & Product Ledger.
///
/// Features deep Navy industrial header, real-time sync pill, ledger integrity
/// recalculation action, part showcase banner, category/movement filter chips
/// with live counts, and a timeline audit feed with vertical connector line,
/// colored node bullets, and running balances.
class StockHistoryScreen extends ConsumerStatefulWidget {
  final String partId;

  const StockHistoryScreen({
    super.key,
    required this.partId,
  });

  @override
  ConsumerState<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends ConsumerState<StockHistoryScreen> {
  bool _isRecalculating = false;
  MovementType? _selectedFilterType;

  Future<void> _recalculateStock() async {
    final l10n = context.l10n;
    final ownerId = ref.read(currentOwnerIdProvider);
    final repo = ref.read(stockRepositoryProvider);

    setState(() => _isRecalculating = true);

    final result = await repo.recalculateCachedQuantity(
      ownerId: ownerId,
      partId: widget.partId,
    );

    if (!mounted) return;
    setState(() => _isRecalculating = false);

    if (result.isSuccess) {
      ref.invalidate(partByIdProvider(widget.partId));
      ref.invalidate(partMovementsStreamProvider(widget.partId));
      context.showSnackBar(l10n.stockRecalculatedSuccess);
    } else {
      context.showSnackBar(
        result.failureOrNull?.message ?? 'Failed to recalculate stock',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final partAsync = ref.watch(partByIdProvider(widget.partId));
    final movementsAsync =
        ref.watch(partMovementsStreamProvider(widget.partId));

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      backgroundColor: KeraColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: KeraColors.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.stockMovementHistory,
              style: KeraTypography.headlineSmall(color: Colors.white)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              'የእንቅስቃሴ ታሪክ • Audit Ledger',
              style: KeraTypography.labelSmall(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          // Live Synced Pill
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
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
                    color: Color(0xFF89F5E7),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'የተገናኘ',
                  style: KeraTypography.labelSmall(
                    color: const Color(0xFF89F5E7),
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // Recalculate Button
          IconButton(
            icon: _isRecalculating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync_rounded),
            tooltip: l10n.recalculateStock,
            onPressed: _isRecalculating ? null : _recalculateStock,
          ),
        ],
      ),
      body: Column(
        children: [
          // Part Information Header Banner
          partAsync.when(
            data: (part) {
              if (part == null) return const SizedBox.shrink();
              final hasPhoto = part.photoLocalPath != null &&
                  File(part.photoLocalPath!).existsSync();
              final location = part.customLocation ?? part.locationName ?? '';

              return Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: KeraColors.surfacePure,
                  border: Border(
                    bottom: BorderSide(color: KeraColors.outlineBorder),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: KeraColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: KeraColors.outlineBorder),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: hasPhoto
                          ? Image.file(
                              File(part.photoLocalPath!),
                              fit: BoxFit.cover,
                            )
                          : const Icon(
                              Icons.inventory_2_outlined,
                              color: KeraColors.primaryNavy,
                              size: 24,
                            ),
                    ),
                    const SizedBox(width: 12),
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
                              if (part.partNumber != null &&
                                  location.isNotEmpty)
                                const Text(' • ',
                                    style: TextStyle(
                                        color: KeraColors.textMuted)),
                              if (location.isNotEmpty)
                                Text(
                                  location,
                                  style: KeraTypography.bodySmall(
                                    color: const Color(0xFF92400E),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          l10n.currentStock,
                          style: KeraTypography.labelSmall(
                            color: KeraColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: part.cachedQuantity > 0
                                ? KeraColors.stockInBg
                                : KeraColors.stockOutBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: part.cachedQuantity > 0
                                  ? KeraColors.stockInText
                                      .withValues(alpha: 0.3)
                                  : KeraColors.stockOutText
                                      .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '${part.cachedQuantity.toStringAsFixed(1)} ${part.unit ?? ''}',
                            style: KeraTypography.labelLarge(
                              color: part.cachedQuantity > 0
                                  ? KeraColors.stockInText
                                  : KeraColors.stockOutText,
                            ).copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // Movements Ledger List
          Expanded(
            child: movementsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text(err.toString())),
              data: (movements) {
                if (movements.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: KeraColors.surfaceContainer,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              size: 40,
                              color: KeraColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noMovementsTitle,
                            style: KeraTypography.headlineSmall(
                              color: KeraColors.textPrimary,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.noMovementsDesc,
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

                // Filtered movements based on selected chip
                final filtered = _selectedFilterType == null
                    ? movements
                    : movements
                        .where((m) => m.type == _selectedFilterType)
                        .toList();

                final purchaseCount = movements
                    .where((m) =>
                        m.type == MovementType.purchase ||
                        m.type == MovementType.initial)
                    .length;
                final saleCount = movements
                    .where((m) => m.type == MovementType.sale)
                    .length;
                final adjCount = movements
                    .where((m) => m.type == MovementType.adjustment)
                    .length;
                final retCount = movements
                    .where((m) => m.type == MovementType.returned)
                    .length;

                return Column(
                  children: [
                    // Horizontal Filter Chips Row (Stitch Screen 24)
                    Container(
                      color: KeraColors.surfacePure,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              label: 'ሁሉም (All)',
                              count: movements.length,
                              isSelected: _selectedFilterType == null,
                              onTap: () => setState(
                                  () => _selectedFilterType = null),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              label: 'የገቡ (+Restock)',
                              count: purchaseCount,
                              isSelected: _selectedFilterType ==
                                  MovementType.purchase,
                              onTap: () => setState(() =>
                                  _selectedFilterType =
                                      MovementType.purchase),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              label: 'የተሸጡ (-Sales)',
                              count: saleCount,
                              isSelected:
                                  _selectedFilterType == MovementType.sale,
                              onTap: () => setState(
                                  () => _selectedFilterType = MovementType.sale),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              label: 'ማስተካከያ (Adj)',
                              count: adjCount,
                              isSelected: _selectedFilterType ==
                                  MovementType.adjustment,
                              onTap: () => setState(() =>
                                  _selectedFilterType =
                                      MovementType.adjustment),
                            ),
                            if (retCount > 0) ...[
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: 'ተመላሽ (Return)',
                                count: retCount,
                                isSelected: _selectedFilterType ==
                                    MovementType.returned,
                                onTap: () => setState(() =>
                                    _selectedFilterType =
                                        MovementType.returned),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Timeline Audit Feed
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isPositive = item.quantityChange > 0;
                          final isNeutral = item.quantityChange == 0;
                          final isLast = index == filtered.length - 1;

                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Vertical Connector Line & Bullet Node (Stitch Screen 22)
                                SizedBox(
                                  width: 28,
                                  child: Stack(
                                    alignment: Alignment.topCenter,
                                    children: [
                                      // Vertical line
                                      if (!isLast)
                                        Positioned(
                                          top: 18,
                                          bottom: 0,
                                          child: Container(
                                            width: 2,
                                            color: KeraColors.outlineVariant,
                                          ),
                                        ),
                                      // Node bullet
                                      Container(
                                        width: 14,
                                        height: 14,
                                        margin: const EdgeInsets.only(top: 14),
                                        decoration: BoxDecoration(
                                          color: KeraColors.surfacePure,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _getBulletColor(item.type),
                                            width: 2.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 4,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color:
                                                  _getBulletColor(item.type),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Timeline Entry Card
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: KeraColors.surfacePure,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: KeraColors.outlineBorder),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x08172B4D),
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Top Row: Type name & Delta badge
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  _getMovementIcon(item.type),
                                                  size: 16,
                                                  color: _getBulletColor(
                                                      item.type),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  _getMovementTypeName(
                                                      item.type, l10n),
                                                  style: KeraTypography
                                                      .titleSmall(
                                                    color:
                                                        KeraColors.textPrimary,
                                                  ).copyWith(
                                                      fontWeight:
                                                          FontWeight.w700),
                                                ),
                                                if (item.unitCost != null) ...[
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '(@ ${item.unitCost!.toStringAsFixed(2)} ብር)',
                                                    style: KeraTypography
                                                        .bodySmall(
                                                      color: KeraColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            // Delta Badge
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isPositive
                                                    ? KeraColors.stockInBg
                                                    : isNeutral
                                                        ? KeraColors
                                                            .surfaceContainer
                                                        : KeraColors.stockOutBg,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '${isPositive ? '+' : ''}${item.quantityChange.toStringAsFixed(1)} pcs',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: isPositive
                                                      ? KeraColors.stockInText
                                                      : isNeutral
                                                          ? KeraColors
                                                              .textSecondary
                                                          : KeraColors
                                                              .stockOutText,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Note if present
                                        if (item.note != null &&
                                            item.note!.trim().isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            item.note!,
                                            style: KeraTypography.bodySmall(
                                              color: KeraColors.textPrimary,
                                            ),
                                          ),
                                        ],

                                        const SizedBox(height: 8),

                                        // Bottom Row: Date & Running Balance
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.access_time_rounded,
                                                  size: 13,
                                                  color: KeraColors.textMuted,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  dateFormat
                                                      .format(item.movedAt),
                                                  style: KeraTypography
                                                      .labelSmall(
                                                    color: KeraColors
                                                        .textSecondary,
                                                  ),
                                                ),
                                                if (item.referenceId !=
                                                    null) ...[
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '#${item.referenceId}',
                                                    style: KeraTypography
                                                        .labelSmall(
                                                      color:
                                                          KeraColors.textMuted,
                                                    ).copyWith(
                                                        fontFamily:
                                                            'monospace'),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            if (item.runningBalance !=
                                                null) ...[
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: KeraColors
                                                      .surfaceContainer,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${l10n.runningBalance}: ${item.runningBalance!.toStringAsFixed(1)}',
                                                  style: KeraTypography
                                                      .labelSmall(
                                                    color: KeraColors
                                                        .textSecondary,
                                                  ).copyWith(
                                                      fontWeight:
                                                          FontWeight.w700),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : KeraColors.textPrimary,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : KeraColors.surfacePure,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : KeraColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMovementTypeName(MovementType type, dynamic l10n) {
    switch (type) {
      case MovementType.initial:
        return l10n.movementTypeInitial;
      case MovementType.purchase:
        return l10n.movementTypePurchase;
      case MovementType.sale:
        return l10n.movementTypeSale;
      case MovementType.adjustment:
        return l10n.movementTypeAdjustment;
      case MovementType.returned:
        return l10n.movementTypeReturn;
    }
  }

  IconData _getMovementIcon(MovementType type) {
    switch (type) {
      case MovementType.initial:
        return Icons.inventory_rounded;
      case MovementType.purchase:
        return Icons.add_circle_outline_rounded;
      case MovementType.sale:
        return Icons.point_of_sale_rounded;
      case MovementType.adjustment:
        return Icons.tune_rounded;
      case MovementType.returned:
        return Icons.assignment_return_rounded;
    }
  }

  Color _getBulletColor(MovementType type) {
    switch (type) {
      case MovementType.purchase:
      case MovementType.initial:
        return KeraColors.stockInText;
      case MovementType.sale:
        return KeraColors.stockOutText;
      case MovementType.adjustment:
        return const Color(0xFFD97706);
      case MovementType.returned:
        return const Color(0xFF7C3AED);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/context_extensions.dart';
import '../../../../data/local/tables/enums.dart';
import '../../../parts/presentation/providers/metadata_providers.dart';
import '../../../parts/presentation/providers/parts_providers.dart';
import '../providers/stock_providers.dart';


/// Screen displaying the append-only stock movement ledger for a specific spare part.
///
/// Shows timestamp, movement type badge, quantity change, unit cost,
/// optional note, and accurately calculated chronological running balance.
/// Also features an integrity check action to recalculate cached quantity from the ledger.
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
    final theme = context.theme;
    final colorScheme = context.colorScheme;
    final partAsync = ref.watch(partByIdProvider(widget.partId));
    final movementsAsync = ref.watch(partMovementsStreamProvider(widget.partId));

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.stockMovementHistory),
        actions: [
          IconButton(
            icon: _isRecalculating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
            tooltip: l10n.recalculateStock,
            onPressed: _isRecalculating ? null : _recalculateStock,
          ),
        ],
      ),
      body: Column(
        children: [
          // Part Information Header
          partAsync.when(
            data: (part) {
              if (part == null) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(Icons.inventory_2_outlined,
                          color: colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            part.displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (part.partNumber != null)
                            Text(
                              part.partNumber!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          l10n.currentStock,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${part.cachedQuantity.toStringAsFixed(1)} ${part.unit ?? ''}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: part.cachedQuantity > 0
                                ? Colors.green.shade800
                                : colorScheme.error,
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text(err.toString())),
              data: (movements) {
                if (movements.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 64,
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noMovementsTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.noMovementsDesc,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: movements.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = movements[index];
                    final isPositive = item.quantityChange > 0;
                    final isNeutral = item.quantityChange == 0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Movement Type Indicator Avatar
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: _getMovementBgColor(
                                item.type, colorScheme),
                            child: Icon(
                              _getMovementIcon(item.type),
                              size: 18,
                              color: _getMovementTextColor(
                                  item.type, colorScheme),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Type & Note & Date
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _getMovementTypeName(item.type, l10n),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (item.unitCost != null) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '(@ ${item.unitCost!.toStringAsFixed(2)} ብር)',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (item.note != null &&
                                    item.note!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.note!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  dateFormat.format(item.movedAt),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Quantity Change & Running Balance
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isPositive ? '+' : ''}${item.quantityChange.toStringAsFixed(1)}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isPositive
                                      ? Colors.green.shade700
                                      : isNeutral
                                          ? colorScheme.onSurfaceVariant
                                          : colorScheme.error,
                                ),
                              ),
                              if (item.runningBalance != null) ...[
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${l10n.runningBalance}: ${item.runningBalance!.toStringAsFixed(1)}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
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

  Color _getMovementBgColor(MovementType type, ColorScheme colorScheme) {
    switch (type) {
      case MovementType.purchase:
      case MovementType.initial:
        return Colors.green.withValues(alpha: 0.15);
      case MovementType.sale:
        return Colors.blue.withValues(alpha: 0.15);
      case MovementType.adjustment:
        return Colors.orange.withValues(alpha: 0.15);
      case MovementType.returned:
        return Colors.purple.withValues(alpha: 0.15);
    }
  }

  Color _getMovementTextColor(MovementType type, ColorScheme colorScheme) {
    switch (type) {
      case MovementType.purchase:
      case MovementType.initial:
        return Colors.green.shade800;
      case MovementType.sale:
        return Colors.blue.shade800;
      case MovementType.adjustment:
        return Colors.orange.shade800;
      case MovementType.returned:
        return Colors.purple.shade800;
    }
  }
}

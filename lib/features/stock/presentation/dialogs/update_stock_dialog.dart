import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/context_extensions.dart';
import '../../../parts/domain/models/part_item.dart';
import '../../../parts/presentation/providers/metadata_providers.dart';
import '../../../parts/presentation/providers/parts_providers.dart';
import '../providers/stock_providers.dart';

enum _StockActionType {
  add,
  remove,
  adjust,
}

/// Dialog allowing the user to Add, Remove, or Adjust stock using the movement ledger.
class UpdateStockDialog extends ConsumerStatefulWidget {
  final PartItem part;

  const UpdateStockDialog({
    super.key,
    required this.part,
  });

  static Future<bool?> show(BuildContext context, PartItem part) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UpdateStockDialog(part: part),
    );
  }

  @override
  ConsumerState<UpdateStockDialog> createState() => _UpdateStockDialogState();
}

class _UpdateStockDialogState extends ConsumerState<UpdateStockDialog> {
  final _formKey = GlobalKey<FormState>();
  _StockActionType _selectedAction = _StockActionType.add;

  late final TextEditingController _quantityController;
  late final TextEditingController _unitCostController;
  late final TextEditingController _noteController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController();
    _unitCostController = TextEditingController(
      text: widget.part.purchasePrice != null
          ? widget.part.purchasePrice!.toStringAsFixed(2)
          : '',
    );
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _quantityController.disposeDispose();
    _unitCostController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;
    final qty = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    final unitCost = double.tryParse(_unitCostController.text.trim());
    final note = _noteController.text.trim();
    final ownerId = ref.read(currentOwnerIdProvider);
    final repo = ref.read(stockRepositoryProvider);

    setState(() => _isSubmitting = true);

    try {
      if (_selectedAction == _StockActionType.add) {
        final result = await repo.addStock(
          ownerId: ownerId,
          partId: widget.part.id,
          quantity: qty,
          unitCost: unitCost,
          note: note.isNotEmpty ? note : null,
        );

        if (!mounted) return;
        if (result.isSuccess) {
          _onSuccess();
        } else {
          context.showSnackBar(
            result.failureOrNull?.message ?? 'Failed to add stock',
            isError: true,
          );
        }
      } else if (_selectedAction == _StockActionType.remove) {
        final currentStock = widget.part.cachedQuantity;
        final projectedStock = currentStock - qty;

        // Check negative stock
        if (projectedStock < 0) {
          final allowNegative = await repo.getAllowNegativeStock();
          if (!mounted) return;

          if (!allowNegative) {
            await showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.negativeStockWarningTitle),
                content: Text(l10n.negativeStockNotAllowed),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.cancel),
                  ),
                ],
              ),
            );
            return;
          }

          // Setting allows negative, ask for confirmation
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.negativeStockWarningTitle),
              content: Text(
                l10n.negativeStockWarningMessage(projectedStock.toStringAsFixed(1)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colorScheme.error,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.applyFilters),
                ),
              ],
            ),
          );

          if (confirmed != true) return;
        }

        final result = await repo.removeStock(
          ownerId: ownerId,
          partId: widget.part.id,
          quantity: qty,
          unitCost: unitCost,
          note: note.isNotEmpty ? note : null,
          forceAllowNegative: true,
        );

        if (!mounted) return;
        if (result.isSuccess) {
          _onSuccess();
        } else {
          context.showSnackBar(
            result.failureOrNull?.message ?? 'Failed to remove stock',
            isError: true,
          );
        }
      } else if (_selectedAction == _StockActionType.adjust) {
        final counted = qty;
        if (counted < 0) {
          final allowNegative = await repo.getAllowNegativeStock();
          if (!mounted) return;

          if (!allowNegative) {
            await showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.negativeStockWarningTitle),
                content: Text(l10n.negativeStockNotAllowed),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.cancel),
                  ),
                ],
              ),
            );
            return;
          }

          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.negativeStockWarningTitle),
              content: Text(
                l10n.negativeStockWarningMessage(counted.toStringAsFixed(1)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colorScheme.error,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.applyFilters),
                ),
              ],
            ),
          );

          if (confirmed != true) return;
        }

        final result = await repo.adjustStock(
          ownerId: ownerId,
          partId: widget.part.id,
          countedQuantity: counted,
          unitCost: unitCost,
          note: note.isNotEmpty ? note : null,
          forceAllowNegative: true,
        );

        if (!mounted) return;
        if (result.isSuccess) {
          _onSuccess();
        } else {
          context.showSnackBar(
            result.failureOrNull?.message ?? 'Failed to adjust stock',
            isError: true,
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _onSuccess() {
    ref.invalidate(partByIdProvider(widget.part.id));
    ref.invalidate(partMovementsStreamProvider(widget.part.id));
    context.showSnackBar(context.l10n.partSavedSuccess);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final colorScheme = context.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final currentQty = widget.part.cachedQuantity;
    final unit = widget.part.unit != null && widget.part.unit!.isNotEmpty
        ? ' ${widget.part.unit}'
        : '';

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title & Part name
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(Icons.inventory_2_rounded,
                          color: colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.updateStock,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            widget.part.displayName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Current stock status banner
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.currentStock,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${currentQty.toStringAsFixed(1)}$unit',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: currentQty > 0
                              ? Colors.green.shade700
                              : colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action Segmented Button (Add, Remove, Adjust)
                SegmentedButton<_StockActionType>(
                  segments: [
                    ButtonSegment(
                      value: _StockActionType.add,
                      label: Text(
                        l10n.addStockPurchase,
                        style: const TextStyle(fontSize: 12),
                      ),
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: _StockActionType.remove,
                      label: Text(
                        l10n.removeStock,
                        style: const TextStyle(fontSize: 12),
                      ),
                      icon: const Icon(Icons.remove_circle_outline_rounded,
                          size: 16),
                    ),
                    ButtonSegment(
                      value: _StockActionType.adjust,
                      label: Text(
                        l10n.adjustStockCount,
                        style: const TextStyle(fontSize: 12),
                      ),
                      icon: const Icon(Icons.tune_rounded, size: 16),
                    ),
                  ],
                  selected: {_selectedAction},
                  onSelectionChanged: (set) {
                    setState(() {
                      _selectedAction = set.first;
                      _quantityController.clear();
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Quantity Field with dynamic label
                TextFormField(
                  controller: _quantityController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: _selectedAction == _StockActionType.add
                        ? l10n.quantityToAdd
                        : _selectedAction == _StockActionType.remove
                            ? l10n.quantityToRemove
                            : l10n.countedQuantity,
                    prefixIcon: Icon(
                      _selectedAction == _StockActionType.add
                          ? Icons.add_rounded
                          : _selectedAction == _StockActionType.remove
                              ? Icons.remove_rounded
                              : Icons.format_list_numbered_rounded,
                    ),
                    suffixText: widget.part.unit,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return l10n.negativeNumberError;
                    }
                    final numVal = double.tryParse(val.trim());
                    if (numVal == null) {
                      return l10n.negativeNumberError;
                    }
                    if (_selectedAction != _StockActionType.adjust &&
                        numVal <= 0) {
                      return l10n.negativeNumberError;
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // Real-time calculation preview for remove or adjust
                if (_selectedAction == _StockActionType.remove) ...[
                  Builder(
                    builder: (context) {
                      final inputQty =
                          double.tryParse(_quantityController.text.trim()) ?? 0.0;
                      final projected = currentQty - inputQty;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: projected < 0
                              ? colorScheme.errorContainer.withValues(alpha: 0.3)
                              : colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l10n.runningBalance),
                            Text(
                              '${projected.toStringAsFixed(1)}$unit',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: projected < 0
                                    ? colorScheme.error
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                if (_selectedAction == _StockActionType.adjust) ...[
                  Builder(
                    builder: (context) {
                      final counted =
                          double.tryParse(_quantityController.text.trim()) ??
                              currentQty;
                      final delta = counted - currentQty;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l10n.difference),
                            Text(
                              '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}$unit',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: delta >= 0
                                    ? Colors.green.shade700
                                    : colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // Unit Cost field (optional)
                TextFormField(
                  controller: _unitCostController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.unitCost,
                    prefixIcon: const Icon(Icons.attach_money_rounded),
                    suffixText: 'ETB',
                  ),
                ),
                const SizedBox(height: 12),

                // Reason / Note field
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: l10n.reasonOrNote,
                    hintText: l10n.reasonOrNoteHint,
                    prefixIcon: const Icon(Icons.note_alt_outlined),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _selectedAction == _StockActionType.add
                              ? l10n.addStockPurchase
                              : _selectedAction == _StockActionType.remove
                                  ? l10n.removeStock
                                  : l10n.adjustStockCount,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension on TextEditingController {
  void disposeDispose() {
    dispose();
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_typography.dart';
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

/// Google Stitch Screen 21 & 23: Stock Adjustment Modal & Update Stock.
///
/// Complete industrial stock adjustment engine for retail automotive inventory.
/// Features:
/// 1. Selected Part Industrial Card with thumbnail, OEM code, and shelf location.
/// 2. 3-mode segmented action selection: Stock In (+), Stock Out (−), Audit Count (=).
/// 3. Quantity stepper engine with large controls, quick increment chips (+1, +5, +10, +25),
///    and dynamic Before ➔ Delta ➔ After impact flow calculation.
/// 4. Common automotive reason presets for rapid selection in greasy garage conditions.
/// 5. Unit cost tracking, PO/reference docs, and internal memo.
/// 6. Strict negative stock enforcement preserving tenant configurations.
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
    _quantityController.dispose();
    _unitCostController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _applyQuickQuantity(double delta, {bool replace = false}) {
    final currentVal = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    final newVal = replace ? delta : (currentVal + delta);
    setState(() {
      _quantityController.text =
          newVal % 1 == 0 ? newVal.toInt().toString() : newVal.toStringAsFixed(1);
    });
  }

  void _selectReasonPreset(String preset) {
    setState(() {
      _noteController.text = preset;
    });
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
    final colorScheme = context.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final currentQty = widget.part.cachedQuantity;
    final unit = widget.part.unit != null && widget.part.unit!.isNotEmpty
        ? ' ${widget.part.unit}'
        : '';

    final inputQty = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    double projectedStock = currentQty;
    if (_selectedAction == _StockActionType.add) {
      projectedStock = currentQty + inputQty;
    } else if (_selectedAction == _StockActionType.remove) {
      projectedStock = currentQty - inputQty;
    } else {
      projectedStock = inputQty;
    }

    final hasPhoto = widget.part.photoLocalPath != null &&
        File(widget.part.photoLocalPath!).existsSync();

    final locationDisplay = widget.part.customLocation != null &&
            widget.part.customLocation!.trim().isNotEmpty
        ? widget.part.customLocation!.trim()
        : (widget.part.locationName ?? '');

    return Container(
      decoration: const BoxDecoration(
        color: KeraColors.surfacePure,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: KeraColors.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),

                // Top Header Row
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: KeraColors.primaryNavy.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: KeraColors.primaryNavy,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.updateStock,
                            style: KeraTypography.headlineSmall(
                              color: KeraColors.textPrimary,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'የክምችት ማስተካከያ',
                            style: KeraTypography.bodyMedium(
                              color: KeraColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: KeraColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                      tooltip: l10n.cancel,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // SECTION 1: Selected Part Summary Card (Stitch Screen 21)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KeraColors.surfaceCanvas,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: KeraColors.outlineBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: KeraColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: KeraColors.outlineBorder),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: hasPhoto
                            ? Image.file(
                                File(widget.part.photoLocalPath!),
                                fit: BoxFit.cover,
                              )
                            : const Icon(
                                Icons.settings_suggest_rounded,
                                color: KeraColors.primaryNavy,
                                size: 28,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.part.displayName,
                              style: KeraTypography.titleMedium(
                                color: KeraColors.textPrimary,
                              ).copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (widget.part.partNumber != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: KeraColors.surfaceContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'OEM: ${widget.part.partNumber!}',
                                      style: KeraTypography.labelSmall(
                                        color: KeraColors.textSecondary,
                                      ).copyWith(fontFamily: 'monospace'),
                                    ),
                                  ),
                                if (locationDisplay.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      locationDisplay,
                                      style: KeraTypography.labelSmall(
                                        color: const Color(0xFF92400E),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Current Stock Pill
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
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: currentQty > 0
                                  ? KeraColors.stockInBg
                                  : KeraColors.stockOutBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: currentQty > 0
                                    ? KeraColors.stockInText
                                        .withValues(alpha: 0.3)
                                    : KeraColors.stockOutText
                                        .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '${currentQty.toStringAsFixed(1)}$unit',
                              style: KeraTypography.labelLarge(
                                color: currentQty > 0
                                    ? KeraColors.stockInText
                                    : KeraColors.stockOutText,
                              ).copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // SECTION 2: Adjustment Mode Selector (Add, Remove, Adjust)
                SegmentedButton<_StockActionType>(
                  segments: [
                    ButtonSegment(
                      value: _StockActionType.add,
                      label: Text(
                        l10n.addStockPurchase,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: _StockActionType.remove,
                      label: Text(
                        l10n.removeStock,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      icon: const Icon(Icons.remove_circle_outline_rounded,
                          size: 16),
                    ),
                    ButtonSegment(
                      value: _StockActionType.adjust,
                      label: Text(
                        l10n.adjustStockCount,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
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
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        if (_selectedAction == _StockActionType.add) {
                          return KeraColors.stockInBg;
                        } else if (_selectedAction == _StockActionType.remove) {
                          return KeraColors.stockOutBg;
                        } else {
                          return KeraColors.primaryNavyLight
                              .withValues(alpha: 0.15);
                        }
                      }
                      return KeraColors.surfacePure;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        if (_selectedAction == _StockActionType.add) {
                          return KeraColors.stockInText;
                        } else if (_selectedAction == _StockActionType.remove) {
                          return KeraColors.stockOutText;
                        } else {
                          return KeraColors.primaryNavy;
                        }
                      }
                      return KeraColors.textSecondary;
                    }),
                  ),
                ),
                const SizedBox(height: 14),

                // SECTION 3: Quantity Stepper Engine (Stitch Screen 21)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KeraColors.surfaceCanvas,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: KeraColors.outlineBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Decrement Button
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: KeraColors.surfaceContainerHigh,
                              foregroundColor: KeraColors.primaryNavy,
                              minimumSize: const Size(48, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.remove_rounded, size: 24),
                            onPressed: () {
                              final cur = double.tryParse(
                                      _quantityController.text.trim()) ??
                                  0.0;
                              if (cur > 0) {
                                _applyQuickQuantity(-1);
                              }
                            },
                          ),
                          const SizedBox(width: 8),

                          // Quantity Text Field with Dynamic Label
                          Expanded(
                            child: TextFormField(
                              controller: _quantityController,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              textAlign: TextAlign.center,
                              style: KeraTypography.numericStat(
                                color: KeraColors.textPrimary,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*')),
                              ],
                              decoration: InputDecoration(
                                labelText: _selectedAction == _StockActionType.add
                                    ? l10n.quantityToAdd
                                    : _selectedAction == _StockActionType.remove
                                        ? l10n.quantityToRemove
                                        : l10n.countedQuantity,
                                labelStyle: const TextStyle(fontSize: 13),
                                prefixText: _selectedAction == _StockActionType.add
                                    ? '+ '
                                    : _selectedAction == _StockActionType.remove
                                        ? '− '
                                        : '= ',
                                prefixStyle: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  color: _selectedAction == _StockActionType.add
                                      ? KeraColors.stockInText
                                      : _selectedAction ==
                                              _StockActionType.remove
                                          ? KeraColors.stockOutText
                                          : KeraColors.actionBlue,
                                ),
                                suffixText: widget.part.unit,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: KeraColors.outlineBorder),
                                ),
                                filled: true,
                                fillColor: KeraColors.surfacePure,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 10),
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
                          ),
                          const SizedBox(width: 8),

                          // Increment Button
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: KeraColors.actionBlue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(48, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 24),
                            onPressed: () => _applyQuickQuantity(1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Quick Increment Chips (+1, +5, +10, +25)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildQuickChip('+1', 1),
                          _buildQuickChip('+5', 5),
                          _buildQuickChip('+10', 10),
                          _buildQuickChip('+25', 25),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Before ➔ Delta ➔ After Impact Flow Card
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: projectedStock < 0
                              ? KeraColors.stockOutBg
                              : KeraColors.surfacePure,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: projectedStock < 0
                                ? KeraColors.stockOutText.withValues(alpha: 0.3)
                                : KeraColors.outlineBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'የነበረው / Current',
                                  style: KeraTypography.labelSmall(
                                    color: KeraColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '${currentQty.toStringAsFixed(1)} ${widget.part.unit ?? 'pcs'}',
                                  style: KeraTypography.labelLarge(
                                    color: KeraColors.textPrimary,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.trending_flat_rounded,
                              color: KeraColors.actionBlue,
                              size: 24,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'አዲሱ ክምችት / Result',
                                  style: KeraTypography.labelSmall(
                                    color: projectedStock < 0
                                        ? KeraColors.error
                                        : KeraColors.stockInText,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  '${projectedStock.toStringAsFixed(1)} ${widget.part.unit ?? 'pcs'}',
                                  style: KeraTypography.labelLarge(
                                    color: projectedStock < 0
                                        ? KeraColors.error
                                        : KeraColors.stockInText,
                                  ).copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Real-time calculation preview for remove or adjust
                if (_selectedAction == _StockActionType.remove) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: projectedStock < 0
                          ? colorScheme.errorContainer.withValues(alpha: 0.3)
                          : KeraColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.runningBalance),
                        Text(
                          '${projectedStock.toStringAsFixed(1)}$unit',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: projectedStock < 0
                                ? colorScheme.error
                                : colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (_selectedAction == _StockActionType.adjust) ...[
                  Builder(
                    builder: (context) {
                      final delta = inputQty - currentQty;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: KeraColors.surfaceContainer,
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
                                    ? KeraColors.stockInText
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

                // SECTION 4: Reason Presets (Stitch Screen 21)
                Text(
                  'የማስተካከያ ምክንያት / Reason Presets',
                  style: KeraTypography.labelSmall(
                    color: KeraColors.textSecondary,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildReasonChip('አዲስ የተገዛ ዕቃ (Purchase Restock)'),
                    _buildReasonChip('የቆጠራ ልዩነት (Audit Discrepancy)'),
                    _buildReasonChip('የተበላሸ / የተሰበረ (Damaged)'),
                    _buildReasonChip('የደንበኛ ተመላሽ (Customer Return)'),
                  ],
                ),
                const SizedBox(height: 12),

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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: KeraColors.outlineBorder),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: KeraColors.outlineBorder),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 18),

                // Submit and Cancel Action Row
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed:
                            _isSubmitting ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: const BorderSide(
                              color: KeraColors.outlineBorder),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: KeraTypography.labelLarge(
                            color: KeraColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _selectedAction == _StockActionType.remove
                                  ? KeraColors.error
                                  : KeraColors.actionBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _selectedAction == _StockActionType.add
                                    ? l10n.addStockPurchase
                                    : _selectedAction == _StockActionType.remove
                                        ? l10n.removeStock
                                        : l10n.adjustStockCount,
                                style: KeraTypography.labelLarge(
                                  color: Colors.white,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, double value) {
    return InkWell(
      onTap: () => _applyQuickQuantity(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: KeraColors.surfacePure,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: KeraColors.outlineBorder),
        ),
        child: Text(
          label,
          style: KeraTypography.labelMedium(
            color: KeraColors.actionBlue,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildReasonChip(String preset) {
    final isSelected = _noteController.text.trim() == preset;
    return ChoiceChip(
      label: Text(
        preset,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : KeraColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: KeraColors.primaryNavy,
      backgroundColor: KeraColors.surfaceCanvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: isSelected ? KeraColors.primaryNavy : KeraColors.outlineBorder,
        ),
      ),
      onSelected: (_) => _selectReasonPreset(preset),
    );
  }
}

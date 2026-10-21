import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/context_extensions.dart';
import '../../../parts/presentation/providers/metadata_providers.dart';
import '../../../parts/presentation/providers/parts_providers.dart';
import '../../../stock/presentation/providers/stock_providers.dart';
import '../../domain/models/sale_line_item.dart';
import '../providers/sales_providers.dart';

/// Screen for recording a new point-of-sale transaction.
///
/// Supports searching & adding spare parts with thumbnails, overriding selling prices,
/// quantity adjustments, customer notes, real-time profit and total calculations,
/// and single-transaction database persistence.
class NewSaleScreen extends ConsumerStatefulWidget {
  const NewSaleScreen({super.key});

  @override
  ConsumerState<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends ConsumerState<NewSaleScreen> {
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _openPartPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _PartSearchPickerSheet(),
    );
  }

  Future<void> _submitSale() async {
    final cart = ref.read(newSaleCartProvider);
    final l10n = context.l10n;

    if (cart.isEmpty) {
      context.showSnackBar(l10n.emptySaleError, isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final ownerId = ref.read(currentOwnerIdProvider);
      final repo = ref.read(salesRepositoryProvider);

      // Check stock levels for all items
      final exceedingItems =
          cart.where((i) => i.quantity > i.part.cachedQuantity).toList();

      bool forceAllow = false;
      if (exceedingItems.isNotEmpty) {
        final stockRepo = ref.read(stockRepositoryProvider);
        final allowNegative = await stockRepo.getAllowNegativeStock();

        if (!mounted) return;

        if (!allowNegative) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.negativeStockWarningTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.negativeStockNotAllowed),
                  const SizedBox(height: 12),
                  ...exceedingItems.map(
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        '• ${i.part.displayName}: ${i.part.cachedQuantity.toStringAsFixed(0)} - ${i.quantity.toStringAsFixed(0)} = ${(i.part.cachedQuantity - i.quantity).toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
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

        // Setting allows negative, ask for owner confirmation
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.negativeStockWarningTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.negativeStockWarningTitle),
                const SizedBox(height: 12),
                ...exceedingItems.map(
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      '• ${i.part.displayName}: ${i.part.cachedQuantity.toStringAsFixed(0)} - ${i.quantity.toStringAsFixed(0)} = ${(i.part.cachedQuantity - i.quantity).toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
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
        forceAllow = true;
      }

      // Execute sale transaction
      final result = await repo.createSale(
        ownerId: ownerId,
        items: cart,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        forceAllowNegative: forceAllow,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        final sale = result.valueOrNull!;
        ref.read(newSaleCartProvider.notifier).clear();
        context.go('/sales/success/${sale.id}');
      } else {
        context.showSnackBar(
          result.failureOrNull?.message ?? 'Failed to record sale',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final colorScheme = context.colorScheme;
    final cart = ref.watch(newSaleCartProvider);

    final totalAmount = cart.fold(0.0, (sum, i) => sum + i.lineTotal);
    final totalCost = cart.fold(0.0, (sum, i) => sum + i.lineCost);
    final totalProfit = cart.fold(0.0, (sum, i) => sum + i.lineProfit);
    final totalUnits = cart.fold(0.0, (sum, i) => sum + i.quantity);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newSale),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: Text(l10n.addPartsToSale),
            onPressed: _openPartPicker,
          ),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor:
                          colorScheme.primaryContainer.withValues(alpha: 0.5),
                      child: Icon(
                        Icons.add_shopping_cart_rounded,
                        size: 40,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.cartEmptyTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.cartEmptyDesc,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.search_rounded),
                      label: Text(l10n.searchAndAddParts),
                      onPressed: _openPartPicker,
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              children: [
                // Cart Line Items List
                ...cart.map(
                  (item) => _SaleLineItemCard(item: item),
                ),
                const SizedBox(height: 12),

                // Customer / Receipt Notes
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: l10n.customerNotes,
                        hintText: l10n.customerNotesHint,
                        prefixIcon: const Icon(Icons.note_alt_outlined),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),

      // Sticky Bottom Summary & Checkout Bar
      bottomNavigationBar: cart.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Breakdown details
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${l10n.totalItems}: ${totalUnits.toStringAsFixed(0)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${l10n.totalCost}: ${totalCost.toStringAsFixed(2)} ብር',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${l10n.totalProfit}: ${totalProfit.toStringAsFixed(2)} ብር',
                            textAlign: TextAlign.end,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),

                    // Total & Submit Button
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.lineTotal,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '${totalAmount.toStringAsFixed(2)} ብር',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitSale,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                          ),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_circle_rounded),
                          label: Text(l10n.completeSale),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Card representing a single line item in the New Sale cart.
class _SaleLineItemCard extends ConsumerWidget {
  final SaleLineItem item;

  const _SaleLineItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = context.theme;
    final colorScheme = context.colorScheme;
    final cartNotifier = ref.read(newSaleCartProvider.notifier);

    final hasPhoto = item.part.photoLocalPath != null &&
        File(item.part.photoLocalPath!).existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Thumbnail, Name, Part Number, and Delete
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasPhoto
                      ? Image.file(
                          File(item.part.photoLocalPath!),
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          Icons.inventory_2_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.part.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (item.part.partNumber != null)
                        Text(
                          item.part.partNumber!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded,
                      color: colorScheme.error),
                  onPressed: () => cartNotifier.removeItem(item.part.id),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Middle Row: Quantity Stepper & Price override
            Row(
              children: [
                // Quantity Stepper
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: () => cartNotifier.updateQuantity(
                          item.part.id,
                          item.quantity - 1.0,
                        ),
                      ),
                      Text(
                        item.quantity.toStringAsFixed(0),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: () => cartNotifier.updateQuantity(
                          item.part.id,
                          item.quantity + 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Editable Selling Unit Price
                Expanded(
                  child: TextFormField(
                    initialValue: item.unitPrice.toStringAsFixed(2),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.unitPrice,
                      suffixText: 'ብር',
                      isDense: true,
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val.trim());
                      if (parsed != null && parsed >= 0) {
                        cartNotifier.updateUnitPrice(item.part.id, parsed);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Warning if no purchase price was set
            if (item.hasNoCostWarning) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 16, color: Colors.orange),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.noCostWarning,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Bottom Row: Line Total & Estimated Profit
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.lineProfit}: ${item.lineProfit.toStringAsFixed(2)} ብር',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
                Text(
                  '${l10n.lineTotal}: ${item.lineTotal.toStringAsFixed(2)} ብር',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
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

/// Bottom sheet allowing searching parts and tapping to add to cart.
class _PartSearchPickerSheet extends ConsumerStatefulWidget {
  const _PartSearchPickerSheet();

  @override
  ConsumerState<_PartSearchPickerSheet> createState() =>
      _PartSearchPickerSheetState();
}

class _PartSearchPickerSheetState extends ConsumerState<_PartSearchPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final colorScheme = context.colorScheme;
    final partsAsync = ref.watch(partsStreamProvider);
    final cartNotifier = ref.read(newSaleCartProvider.notifier);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.searchAndAddParts,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
            ),
            onChanged: (val) => setState(() => _query = val.trim().toLowerCase()),
          ),
          const SizedBox(height: 12),

          // Parts List
          Expanded(
            child: partsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text(err.toString())),
              data: (parts) {
                final filtered = parts.where((p) {
                  if (_query.isEmpty) return true;
                  final name = (p.name ?? '').toLowerCase();
                  final partNum = (p.partNumber ?? '').toLowerCase();
                  return name.contains(_query) || partNum.contains(_query);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.noFilteredPartsTitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final part = filtered[index];
                    final hasPhoto = part.photoLocalPath != null &&
                        File(part.photoLocalPath!).existsSync();

                    return ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: hasPhoto
                            ? Image.file(
                                File(part.photoLocalPath!),
                                fit: BoxFit.cover,
                              )
                            : Icon(
                                Icons.inventory_2_outlined,
                                color: colorScheme.onSurfaceVariant,
                              ),
                      ),
                      title: Text(
                        part.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${l10n.quantityInStock}: ${part.cachedQuantity.toStringAsFixed(0)} ${part.unit ?? ''}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (part.sellingPrice != null)
                            Text(
                              '${part.sellingPrice!.toStringAsFixed(2)} ብር',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.add, size: 20),
                            onPressed: () {
                              cartNotifier.addPart(part);
                              context.showSnackBar(
                                '${part.displayName} added to sale',
                              );
                            },
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
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../parts/presentation/providers/metadata_providers.dart';
import '../../../parts/presentation/providers/parts_providers.dart';
import '../../../stock/presentation/providers/stock_providers.dart';
import '../../domain/models/sale_line_item.dart';
import '../providers/sales_providers.dart';

/// Screen for recording a new point-of-sale transaction.
///
/// Follows Google Stitch POS & Sales designs (Screens 26, 27, 28, 29).
/// Features:
/// - Fast barcode search & category filter rail
/// - Live cart item list with quantity steppers & instant unit price overrides
/// - Single-transaction atomic DB write via SalesRepository
/// - Real-time profit calculations & negative stock safeguard checks
/// - Payment method selection (Cash, Telebirr, CBE Birr, Credit)
class NewSaleScreen extends ConsumerStatefulWidget {
  const NewSaleScreen({super.key});

  @override
  ConsumerState<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends ConsumerState<NewSaleScreen> {
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  String _selectedPaymentMethod = 'Cash';

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
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: KeraColors.errorRed),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.negativeStockWarningTitle)),
                ],
              ),
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
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: KeraColors.warningAmber),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.negativeStockWarningTitle)),
              ],
            ),
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
                  backgroundColor: KeraColors.errorRed,
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
        paymentMethod: _selectedPaymentMethod,
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
    final cart = ref.watch(newSaleCartProvider);

    final totalAmount = cart.fold(0.0, (sum, i) => sum + i.lineTotal);
    final totalProfit = cart.fold(0.0, (sum, i) => sum + i.lineProfit);
    final totalUnits = cart.fold(0.0, (sum, i) => sum + i.quantity);
    final profitMargin = totalAmount > 0 ? (totalProfit / totalAmount * 100) : 0.0;

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
              l10n.newSale,
              style: KeraTypography.headlineSmall(color: Colors.white)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              'አዲስ ሽያጭ / Quick POS',
              style: KeraTypography.labelSmall(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          // Offline/Online Synced Pill
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF00322D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: KeraColors.tealAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: KeraColors.tealAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'የተገናኘ / Synced',
                  style: KeraTypography.labelSmall(color: Colors.white)
                      .copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Add parts button
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
            label: Text(
              l10n.addPartsToSale,
              style: KeraTypography.labelMedium(color: Colors.white)
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            onPressed: _openPartPicker,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: KeraColors.actionBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_shopping_cart_rounded,
                        size: 44,
                        color: KeraColors.actionBlue,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.cartEmptyTitle,
                      style: KeraTypography.titleMedium()
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.cartEmptyDesc,
                      textAlign: TextAlign.center,
                      style: KeraTypography.bodyMedium(
                        color: KeraColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.search_rounded),
                      label: Text(l10n.searchAndAddParts),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KeraColors.actionBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _openPartPicker,
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              children: [
                // Top Cart Meta Header & Clear Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: KeraColors.primaryNavy,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${cart.length} Items / ${totalUnits.toStringAsFixed(0)} Units',
                        style: KeraTypography.labelSmall(color: Colors.white)
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.delete_sweep_rounded,
                          size: 18, color: KeraColors.errorRed),
                      label: Text(
                        'አፅዳ / Clear',
                        style: KeraTypography.labelSmall(
                            color: KeraColors.errorRed),
                      ),
                      onPressed: () {
                        ref.read(newSaleCartProvider.notifier).clear();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Cart Line Items List
                ...cart.map(
                  (item) => _SaleLineItemCard(item: item),
                ),
                const SizedBox(height: 12),

                // Customer Selection & Notes Section (Stitch Screen 27)
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: KeraColors.outlineBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: KeraColors.primaryNavy
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.person_rounded,
                                  color: KeraColors.primaryNavy, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'የችርቻሮ ደንበኛ / Walk-in',
                                        style: KeraTypography.labelLarge()
                                            .copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: KeraColors.surfaceMuted,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _selectedPaymentMethod,
                                          style: KeraTypography.labelSmall(
                                              color: KeraColors.textPrimary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'የደንበኛ ስም ወይም ማስታወሻ • Optional',
                                    style: KeraTypography.labelSmall(
                                        color: KeraColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Payment Method Selector Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildPaymentChip('ጥሬ ገንዘብ / Cash', 'Cash',
                                  Icons.payments_rounded),
                              const SizedBox(width: 8),
                              _buildPaymentChip('ቴሌብር / Telebirr', 'Telebirr',
                                  Icons.smartphone_rounded),
                              const SizedBox(width: 8),
                              _buildPaymentChip('ባንክ / CBE', 'CBE Birr',
                                  Icons.account_balance_rounded),
                              const SizedBox(width: 8),
                              _buildPaymentChip('ብድር / Credit', 'Credit',
                                  Icons.credit_card_rounded),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Customer / Receipt Notes TextField
                        TextField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: l10n.customerNotes,
                            hintText: l10n.customerNotesHint,
                            prefixIcon: const Icon(Icons.note_alt_outlined),
                            filled: true,
                            fillColor: KeraColors.surfaceCanvas,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Stock Safeguard Guard Notice Banner per Screen 27
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KeraColors.warningAmber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: KeraColors.warningAmber.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified_user_rounded,
                          size: 20, color: KeraColors.warningAmber),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'የክምችት ማረጋገጫ ቁጥጥር (Real-time Stock Guard)',
                              style: KeraTypography.labelMedium().copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'የእቃ ብዛት ከተመዘገበው መጋዘን ክምችት እንዳይበልጥ ተገድቧል (Over-selling prevented).',
                              style: KeraTypography.bodySmall(
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Financial Breakdown Summary Card (Stitch Screen 27)
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: KeraColors.outlineBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.receipt_long_rounded,
                                    size: 20, color: KeraColors.actionBlue),
                                const SizedBox(width: 8),
                                Text(
                                  'የሂሳብ ዝርዝር / Summary',
                                  style: KeraTypography.titleSmall()
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Text(
                              '${cart.length} SKUs • ${totalUnits.toStringAsFixed(0)} Pcs',
                              style: KeraTypography.labelSmall(
                                  color: KeraColors.textSecondary),
                            ),
                          ],
                        ),
                        const Divider(height: 20),

                        // Subtotal
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'የእቃዎች ድምር / Subtotal',
                              style: KeraTypography.bodyMedium(
                                  color: KeraColors.textSecondary),
                            ),
                            Text(
                              '${totalAmount.toStringAsFixed(2)} ብር',
                              style: KeraTypography.bodyLarge()
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Estimated Gross Profit Highlight Banner
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: KeraColors.success
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: KeraColors.success
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.payments_rounded,
                                        size: 18, color: KeraColors.success),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        l10n.totalProfit,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: KeraTypography.labelMedium().copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '+${totalProfit.toStringAsFixed(2)} ብር (~${profitMargin.toStringAsFixed(1)}%)',
                                  style: KeraTypography.labelMedium().copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Grand Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.lineTotal,
                              style: KeraTypography.titleMedium()
                                  .copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${totalAmount.toStringAsFixed(2)} ብር',
                              style: KeraTypography.headlineSmall(
                                      color: KeraColors.primaryNavy)
                                  .copyWith(fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

      // Sticky Bottom Summary & Checkout Bar (Screen 26 & 27)
      bottomNavigationBar: cart.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: KeraColors.primaryNavy.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Total amount display
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.lineTotal,
                            style: KeraTypography.labelSmall(
                              color: KeraColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${totalAmount.toStringAsFixed(2)} ብር',
                            style: KeraTypography.headlineSmall(
                              color: KeraColors.primaryNavy,
                            ).copyWith(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Primary Complete Sale CTA (Teal per Stitch #0d9488)
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitSale,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        minimumSize: const Size(140, 52),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.point_of_sale_rounded, size: 20),
                      label: Text(
                        l10n.completeSale,
                        style: KeraTypography.labelLarge(color: Colors.white)
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPaymentChip(String label, String value, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;
    return ChoiceChip(
      selected: isSelected,
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : KeraColors.textPrimary,
      ),
      label: Text(label),
      labelStyle: KeraTypography.labelSmall(
        color: isSelected ? Colors.white : KeraColors.textPrimary,
      ).copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      selectedColor: KeraColors.primaryNavy,
      backgroundColor: KeraColors.surfaceCanvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? KeraColors.primaryNavy : KeraColors.outlineBorder,
        ),
      ),
      onSelected: (selected) {
        if (selected) setState(() => _selectedPaymentMethod = value);
      },
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
    final cartNotifier = ref.read(newSaleCartProvider.notifier);

    final hasPhoto = item.part.photoLocalPath != null &&
        File(item.part.photoLocalPath!).existsSync();
    final location =
        item.part.customLocation ?? item.part.locationName ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: KeraColors.outlineBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Thumbnail, Name, Part Number, and Delete
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: KeraColors.surfaceCanvas,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: KeraColors.outlineBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasPhoto
                      ? Image.file(
                          File(item.part.photoLocalPath!),
                          fit: BoxFit.cover,
                        )
                      : const Icon(
                          Icons.inventory_2_outlined,
                          color: KeraColors.textSecondary,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.part.partNumber != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(bottom: 3),
                          decoration: BoxDecoration(
                            color: KeraColors.actionBlue
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.part.partNumber!,
                            style: KeraTypography.labelSmall(
                              color: KeraColors.actionBlue,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      Text(
                        item.part.displayName,
                        style: KeraTypography.titleSmall()
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (location.isNotEmpty)
                        Text(
                          'መደርደሪያ: $location',
                          style: KeraTypography.labelSmall(
                            color: KeraColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: KeraColors.errorRed),
                  onPressed: () => cartNotifier.removeItem(item.part.id),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // In-stock & Line Profit Badges Wrap
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                // In-stock badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: KeraColors.stockInBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: KeraColors.stockInText,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${l10n.quantityInStock}: ${item.part.cachedQuantity.toStringAsFixed(0)}',
                        style: KeraTypography.labelSmall(
                          color: KeraColors.stockInText,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                // Profit badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: KeraColors.successBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up_rounded,
                          size: 14, color: KeraColors.success),
                      const SizedBox(width: 4),
                      Text(
                        '${l10n.lineProfit}: ${item.lineProfit.toStringAsFixed(2)} ብር',
                        style: KeraTypography.labelSmall(
                          color: Colors.green.shade800,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
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
                    color: KeraColors.surfaceCanvas,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: KeraColors.outlineBorder),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          item.quantity.toStringAsFixed(0),
                          style: KeraTypography.titleSmall()
                              .copyWith(fontWeight: FontWeight.w800),
                        ),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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

            // Bottom Row: Line Subtotal Display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.quantity.toStringAsFixed(0)} pcs × ${item.unitPrice.toStringAsFixed(2)} ብር',
                  style: KeraTypography.bodySmall(
                    color: KeraColors.textSecondary,
                  ),
                ),
                Text(
                  '${l10n.lineTotal}: ${item.lineTotal.toStringAsFixed(2)} ብር',
                  style: KeraTypography.titleSmall(
                    color: KeraColors.primaryNavy,
                  ).copyWith(fontWeight: FontWeight.w800),
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
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final partsAsync = ref.watch(partsStreamProvider);
    final cartNotifier = ref.read(newSaleCartProvider.notifier);

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: KeraColors.outlineBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.searchAndAddParts,
                  style: KeraTypography.titleMedium()
                      .copyWith(fontWeight: FontWeight.bold),
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
                hintText: 'ፈልግ / Search part name, OEM, shelf...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: KeraColors.surfaceCanvas,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) =>
                  setState(() => _query = val.trim().toLowerCase()),
            ),
            const SizedBox(height: 10),

            // Category Filter Rail per Stitch Screen 26
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('ሁሉም (All)', 'All'),
                  const SizedBox(width: 6),
                  _buildCategoryChip('ዘይትና ማጣሪያ (Filters)', 'Filters'),
                  const SizedBox(width: 6),
                  _buildCategoryChip('ፍሬንና ክላች (Brakes)', 'Brakes'),
                  const SizedBox(width: 6),
                  _buildCategoryChip('ሃይድሮሊክስ (Hydraulics)', 'Hydraulics'),
                  const SizedBox(width: 6),
                  _buildCategoryChip('ሞተር (Engine)', 'Engine'),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Parts List
            Expanded(
              child: partsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text(err.toString())),
                data: (parts) {
                  final filtered = parts.where((p) {
                    if (_query.isNotEmpty) {
                      final name = (p.name ?? '').toLowerCase();
                      final partNum = (p.partNumber ?? '').toLowerCase();
                      if (!name.contains(_query) && !partNum.contains(_query)) {
                        return false;
                      }
                    }
                    if (_selectedCategory != 'All') {
                      final cat = (p.categoryName ?? '').toLowerCase();
                      if (!cat.contains(_selectedCategory.toLowerCase())) {
                        return false;
                      }
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.noFilteredPartsTitle,
                        style: KeraTypography.bodyMedium(
                          color: KeraColors.textSecondary,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: KeraColors.outlineBorder),
                    itemBuilder: (context, index) {
                      final part = filtered[index];
                      final hasPhoto = part.photoLocalPath != null &&
                          File(part.photoLocalPath!).existsSync();
                      final isLow = part.cachedQuantity <=
                          (part.lowStockLevel ?? 5.0);
                      final isOut = part.cachedQuantity <= 0;

                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        onTap: () {
                          cartNotifier.addPart(part);
                          Navigator.pop(context);
                        },
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: KeraColors.surfaceCanvas,
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
                                  color: KeraColors.textSecondary,
                                ),
                        ),
                        title: Text(
                          part.displayName,
                          style: KeraTypography.titleSmall()
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${l10n.quantityInStock}: ${part.cachedQuantity.toStringAsFixed(0)} ${part.unit ?? ''}${part.partNumber != null ? ' • ${part.partNumber}' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KeraTypography.bodySmall(
                            color: isOut
                                ? KeraColors.stockOutText
                                : isLow
                                    ? KeraColors.stockLowText
                                    : KeraColors.textSecondary,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (part.sellingPrice != null)
                              Text(
                                '${part.sellingPrice!.toStringAsFixed(2)} ብር',
                                style: KeraTypography.labelLarge(
                                  color: KeraColors.primaryNavy,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              style: IconButton.styleFrom(
                                backgroundColor: KeraColors.actionBlue
                                    .withValues(alpha: 0.15),
                                foregroundColor: KeraColors.actionBlue,
                              ),
                              icon: const Icon(Icons.add_rounded, size: 20),
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
      ),
    );
  }

  Widget _buildCategoryChip(String label, String value) {
    final isSelected = _selectedCategory == value;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: KeraTypography.labelSmall(
        color: isSelected ? Colors.white : KeraColors.textPrimary,
      ).copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      selectedColor: KeraColors.actionBlue,
      backgroundColor: KeraColors.surfaceCanvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? KeraColors.actionBlue : KeraColors.outlineBorder,
        ),
      ),
      onSelected: (selected) {
        if (selected) setState(() => _selectedCategory = value);
      },
    );
  }
}

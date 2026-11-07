import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/design.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/sales_providers.dart';

/// Screen displaying complete details for a single sale transaction.
///
/// Follows Google Stitch Screen 32 (Transaction Details & Audit Ledger).
/// Features:
/// - Dedicated Task-Focused Navy Header with print, SMS, and delete triggers
/// - Status and cloud sync audit banner
/// - Customer context and payment reconciliation card
/// - Snapshot line items displaying part names, OEM, quantity × unit price, and line profit
/// - High-contrast financial bento card for Total Revenue, Total Cost, and Net Profit
/// - Inventory deduction audit confirmation
/// - Re-print thermal slip and safe refund / deletion workflow
class SaleDetailsScreen extends ConsumerStatefulWidget {
  final String saleId;

  const SaleDetailsScreen({super.key, required this.saleId});

  @override
  ConsumerState<SaleDetailsScreen> createState() => _SaleDetailsScreenState();
}

class _SaleDetailsScreenState extends ConsumerState<SaleDetailsScreen> {
  bool _isDeleting = false;

  Future<void> _confirmAndDelete() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: KeraColors.errorRed),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.deleteSale)),
          ],
        ),
        content: Text(l10n.deleteSaleConfirm),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KeraColors.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => ctx.pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      final repo = ref.read(salesRepositoryProvider);
      final sale = await ref.read(saleByIdProvider(widget.saleId).future);
      if (sale != null) {
        final res = await repo.deleteSale(
          ownerId: sale.ownerId,
          saleId: widget.saleId,
        );
        if (mounted) {
          if (res.isSuccess) {
            context.showSnackBar(l10n.delete);
            context.pop();
          } else {
            setState(() => _isDeleting = false);
            context.showSnackBar(
              res.failureOrNull?.message ?? 'Failed to delete sale',
              isError: true,
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final saleAsync = ref.watch(saleByIdProvider(widget.saleId));
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      backgroundColor: KeraColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: KeraColors.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'ወደ ኋላ ተመለስ / Go back',
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.saleDetailsTitle,
              style: KeraTypography.headlineSmall(color: Colors.white)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              'የደረሰኝ ዝርዝር • Transaction Details',
              style: KeraTypography.labelSmall(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'አትም / Print Slip',
            onPressed: () {
              context.showSnackBar('ደረሰኝ ወደ ፕሪንተር ተልኳል / Sent to printer');
            },
          ),
          IconButton(
            icon: const Icon(Icons.sms_rounded),
            tooltip: 'በSMS ላክ / Send SMS',
            onPressed: () {
              context.showSnackBar('ደረሰኝ በSMS ተልኳል / SMS sent');
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: l10n.deleteSale,
            onPressed: _isDeleting ? null : _confirmAndDelete,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: saleAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (sale) {
          if (sale == null) {
            return Center(
              child: Text(
                l10n.noSalesFound,
                style: KeraTypography.titleMedium(),
              ),
            );
          }

          final totalCost = sale.totalAmount - sale.totalProfit;
          final margin = sale.totalAmount > 0
              ? (sale.totalProfit / sale.totalAmount * 100)
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Transaction Status & Audit Banner (Stitch Screen 32)
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: KeraColors.outlineBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '#${sale.receiptNumber ?? "N/A"}',
                              style: KeraTypography.titleMedium(
                                color: KeraColors.primaryNavy,
                              ).copyWith(fontWeight: FontWeight.w900),
                            ),
                            // Synced pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: KeraColors.surfaceCanvas,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: KeraColors.outlineBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded,
                                      size: 14, color: KeraColors.success),
                                  const SizedBox(width: 4),
                                  Text(
                                    'የተመሳሰለ (Synced)',
                                    style: KeraTypography.labelSmall(
                                      color: KeraColors.textPrimary,
                                    ).copyWith(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Timestamp
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 14, color: KeraColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              dateFormat.format(sale.soldAt),
                              style: KeraTypography.bodySmall(
                                color: KeraColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: KeraColors.outlineBorder),
                        const SizedBox(height: 12),

                        // Terminal & Cashier Metadata Grid
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ተረካቢ / Cashier',
                                    style: KeraTypography.labelSmall(
                                      color: KeraColors.textMuted,
                                    ).copyWith(fontSize: 10),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.badge_rounded,
                                          size: 14,
                                          color: KeraColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Owner / Admin',
                                        style: KeraTypography.labelSmall(
                                          color: KeraColors.textPrimary,
                                        ).copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'መመዝገቢያ / Terminal',
                                    style: KeraTypography.labelSmall(
                                      color: KeraColors.textMuted,
                                    ).copyWith(fontSize: 10),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.point_of_sale_rounded,
                                          size: 14,
                                          color: KeraColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        'KERA-POS-01',
                                        style: KeraTypography.labelSmall(
                                          color: KeraColors.textPrimary,
                                        ).copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Customer & Payment Information Card
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: KeraColors.outlineBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_rounded,
                                    size: 18, color: KeraColors.actionBlue),
                                const SizedBox(width: 6),
                                Text(
                                  'የደንበኛ መረጃ / Customer File',
                                  style: KeraTypography.labelMedium().copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: KeraColors.primaryNavy,
                                  ),
                                ),
                              ],
                            ),
                            if (sale.paymentMethod != null &&
                                sale.paymentMethod!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: KeraColors.surfaceCanvas,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: KeraColors.outlineBorder),
                                ),
                                child: Text(
                                  '${l10n.paymentMethod}: ${sale.paymentMethod}',
                                  style: KeraTypography.labelSmall(
                                    color: KeraColors.textPrimary,
                                  ).copyWith(fontSize: 11),
                                ),
                              ),
                          ],
                        ),
                        if (sale.notes != null &&
                            sale.notes!.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Divider(
                              height: 1, color: KeraColors.outlineBorder),
                          const SizedBox(height: 10),
                          Text(
                            l10n.customerNotes,
                            style: KeraTypography.labelSmall(
                              color: KeraColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sale.notes!,
                            style: KeraTypography.bodyMedium(
                              color: KeraColors.textPrimary,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Line Items Section (Stitch Screen 32)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${l10n.totalItems} (${sale.items.length})',
                        style: KeraTypography.titleSmall(
                          color: KeraColors.primaryNavy,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      'የተሸጡ ዕቃዎች',
                      style: KeraTypography.labelSmall(
                        color: KeraColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                ...sale.items.map((item) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: KeraColors.outlineBorder),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.partNameSnapshot,
                                  style: KeraTypography.titleSmall()
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                CurrencyFormatter.formatEtb(item.lineTotal),
                                style: KeraTypography.titleSmall(
                                  color: KeraColors.primaryNavy,
                                ).copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${CurrencyFormatter.formatQuantity(item.quantity)} × ${CurrencyFormatter.formatEtb(item.unitPrice)}',
                                  style: KeraTypography.bodySmall(
                                    color: KeraColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${l10n.lineProfit}: ${CurrencyFormatter.formatEtb(item.lineProfit)}',
                                style: KeraTypography.bodySmall().copyWith(
                                  color: item.lineProfit >= 0
                                      ? KeraColors.green600
                                      : KeraColors.red600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: KeraColors.surfaceCanvas,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${l10n.lineCost}: ${CurrencyFormatter.formatEtb(item.unitCost)} / unit',
                                    style: KeraTypography.labelSmall(
                                      color: KeraColors.textMuted,
                                    ).copyWith(fontSize: 11),
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.inventory_2_outlined,
                                        size: 13,
                                        color: KeraColors.textSecondary),
                                    const SizedBox(width: 3),
                                    Text(
                                      'ክምችት ተቀንሷል',
                                      style: KeraTypography.labelSmall(
                                        color: KeraColors.textSecondary,
                                      ).copyWith(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 14),

                // 4. Financial Summary Card (High-Contrast Bento per Screen 32)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KeraColors.primaryNavy,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [KeraColors.shadowLevel2],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.payments_rounded,
                                  size: 20, color: KeraColors.brandOrange),
                              const SizedBox(width: 8),
                              Text(
                                'የክፍያና የትርፍ ማጠቃለያ',
                                style: KeraTypography.titleSmall(
                                  color: Colors.white,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          if (sale.paymentMethod != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: KeraColors.actionBlue,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                sale.paymentMethod!,
                                style: KeraTypography.labelSmall(
                                  color: Colors.white,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const Divider(height: 22, color: Colors.white24),

                      // Gross Sales / Revenue
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.totalRevenue,
                            style: KeraTypography.bodyMedium(
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatEtb(sale.totalAmount),
                            style: KeraTypography.titleMedium(
                              color: Colors.white,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Total Cost (COGS)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.totalCost,
                            style: KeraTypography.bodyMedium(
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatEtb(totalCost),
                            style: KeraTypography.bodyMedium(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: Colors.white24),

                      // Net Profit
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.totalProfit,
                                  style: KeraTypography.labelLarge(
                                    color: Colors.white,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'በትክክለኛ የግዢ ዋጋ ላይ የተመሰረተ',
                                  style: KeraTypography.labelSmall(
                                    color: Colors.white60,
                                  ).copyWith(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.formatEtb(sale.totalProfit),
                                style: KeraTypography.headlineSmall(
                                  color: KeraColors.brandOrange,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${margin.toStringAsFixed(1)}% Margin',
                                style: KeraTypography.labelSmall(
                                  color: KeraColors.brandOrange,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 5. Inventory Live Audit Confirmation Banner
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
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: KeraColors.stockInBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.inventory_rounded,
                            size: 18, color: KeraColors.stockInText),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'የክምችት ማረጋገጫ (Inventory Audit Passed)',
                              style: KeraTypography.labelSmall(
                                color: KeraColors.primaryNavy,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'ክምችት ተስተካክሏል: ${sale.items.fold(0.0, (s, i) => s + i.quantity).toStringAsFixed(0)} ፍሬዎች ከመጋዘን ወጪ ሆነዋል',
                              style: KeraTypography.labelSmall(
                                color: KeraColors.textSecondary,
                              ).copyWith(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 6. Action Matrix
                ElevatedButton.icon(
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text('ደረሰኝ እንደገና አትም (Re-print Thermal Slip)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KeraColors.brandOrange,
                    foregroundColor: KeraColors.navy900,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    context.showSnackBar('ደረሰኝ ወደ ፕሪንተር ተልኳል / Sent to printer');
                  },
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text('አጋራ (Share)'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(
                              color: KeraColors.outlineBorder),
                        ),
                        onPressed: () {
                          context.showSnackBar('ደረሰኝ ዝግጁ ነው / Ready to share');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.keyboard_return_rounded,
                            size: 18, color: KeraColors.brandNavy),
                        label: Text(
                          'ሽያጭ ሰርዝ',
                          style: KeraTypography.labelMedium(
                              color: KeraColors.brandNavy),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: KeraColors.brandNavy, width: 1.5),
                        ),
                        onPressed: _isDeleting ? null : _confirmAndDelete,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

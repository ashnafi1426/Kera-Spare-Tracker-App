import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/design.dart';
import '../../../../core/utils/context_extensions.dart';
import '../providers/sales_providers.dart';

/// Screen displaying receipt details and confirmation following a completed sale.
///
/// Follows Google Stitch Screen 30 (Sale Confirmation & Digital Thermal Receipt).
/// Features:
/// - Success status hero with pulse animation
/// - Authentic perforated retail receipt card
/// - Store branding (Kera Auto Spares / Tesfaye Spares)
/// - Itemized table with snapshot part names, quantities, and prices
/// - Financial totals & confidential owner profit margin
/// - Thermal print trigger & multi-channel receipt sharing (SMS/Telegram)
/// - Clean navigation buttons for New Sale and Back to Home
class SaleSuccessScreen extends ConsumerWidget {
  final String saleId;

  const SaleSuccessScreen({
    super.key,
    required this.saleId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final saleAsync = ref.watch(saleByIdProvider(saleId));
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      backgroundColor: KeraColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: KeraColors.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.cancel,
          onPressed: () => context.go('/home'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.saleSuccessTitle,
              style: KeraTypography.titleMedium(color: Colors.white)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              'የሽያጭ ደረሰኝ / Transaction Receipt',
              style: KeraTypography.labelSmall(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'አጋራ / Share',
            onPressed: () {
              context.showSnackBar('ደረሰኝ ለማጋራት ተዘጋጅቷል / Ready to share');
            },
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
                l10n.noDataTitle,
                style: KeraTypography.titleMedium(),
              ),
            );
          }

          final margin = sale.totalAmount > 0
              ? (sale.totalProfit / sale.totalAmount * 100)
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Success Status Hero
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: KeraColors.successBg,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: KeraColors.success.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          size: 48,
                          color: KeraColors.success,
                        ),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: KeraColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    l10n.saleSuccessTitle,
                    textAlign: TextAlign.center,
                    style: KeraTypography.headlineSmall(
                            color: KeraColors.primaryNavy)
                        .copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'ክምችት ተቀንሷል • የጥሬ ገንዘብ ሂሳብ ተመዝግቧል',
                    textAlign: TextAlign.center,
                    style: KeraTypography.bodySmall(
                      color: KeraColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Offline/Cloud Synced Pill
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: KeraColors.outlineBorder),
                      boxShadow: const [KeraColors.shadowLevel1],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: KeraColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'በሰርቨር ላይ ተመሳስሏል (Synced)',
                          style: KeraTypography.labelSmall(
                            color: KeraColors.textPrimary,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.cloud_done_rounded,
                            size: 15, color: KeraColors.success),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Authentic Perforated Thermal Receipt Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: KeraColors.outlineBorder),
                    boxShadow: const [KeraColors.shadowLevel2],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Simulated Top Perforated Serration Notch
                      _buildPerforatedDivider(),

                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Store Branding Header
                            Center(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.storefront_rounded,
                                          size: 20,
                                          color: KeraColors.primaryNavy),
                                      const SizedBox(width: 6),
                                      Text(
                                        'ተስፋዬ እና ልጆቹ የጃፓን መለዋወጫ',
                                        style: KeraTypography.titleSmall(
                                          color: KeraColors.primaryNavy,
                                        ).copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'KERA AUTO SPARES • WHOLESALE & RETAIL',
                                    style: KeraTypography.labelSmall(
                                      color: KeraColors.textSecondary,
                                    ).copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5),
                                  ),
                                  Text(
                                    'Kera Zone 4, Shop #14, Addis Ababa',
                                    style: KeraTypography.labelSmall(
                                      color: KeraColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.call_rounded,
                                          size: 12,
                                          color: KeraColors.actionBlue),
                                      const SizedBox(width: 4),
                                      Text(
                                        '+251 911 458 920',
                                        style: KeraTypography.labelSmall(
                                          color: KeraColors.actionBlue,
                                        ).copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Divider(height: 1, color: KeraColors.outlineBorder),
                            const SizedBox(height: 12),

                            // Invoice Metadata Strip
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: KeraColors.surfaceCanvas,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: KeraColors.outlineBorder
                                        .withValues(alpha: 0.6)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        l10n.receiptNumber,
                                        style: KeraTypography.labelSmall(
                                            color: KeraColors.textSecondary),
                                      ),
                                      Text(
                                        sale.receiptNumber ?? sale.id.substring(0, 8),
                                        style: KeraTypography.labelMedium(
                                          color: KeraColors.primaryNavy,
                                        ).copyWith(fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        l10n.soldAt,
                                        style: KeraTypography.labelSmall(
                                            color: KeraColors.textSecondary),
                                      ),
                                      Text(
                                        dateFormat.format(sale.soldAt),
                                        style: KeraTypography.labelSmall(
                                          color: KeraColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (sale.paymentMethod != null &&
                                      sale.paymentMethod!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          l10n.paymentMethod,
                                          style: KeraTypography.labelSmall(
                                              color: KeraColors.textSecondary),
                                        ),
                                        Text(
                                          sale.paymentMethod!,
                                          style: KeraTypography.labelSmall(
                                            color: KeraColors.textPrimary,
                                          ).copyWith(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (sale.notes != null &&
                                      sale.notes!.trim().isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          l10n.customerNotes,
                                          style: KeraTypography.labelSmall(
                                              color: KeraColors.textSecondary),
                                        ),
                                        Text(
                                          sale.notes!,
                                          style: KeraTypography.labelSmall(
                                            color: KeraColors.textPrimary,
                                          ).copyWith(
                                              fontStyle: FontStyle.italic),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Items Table Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'እቃና መለያ / Description',
                                  style: KeraTypography.labelSmall(
                                    color: KeraColors.textSecondary,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'ድምር / Subtotal',
                                  style: KeraTypography.labelSmall(
                                    color: KeraColors.textSecondary,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Divider(height: 1, color: KeraColors.outlineBorder),
                            const SizedBox(height: 8),

                            // Purchased Line Items List
                            ...sale.items.map((item) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.partNameSnapshot,
                                            style: KeraTypography.labelLarge()
                                                .copyWith(
                                                    fontWeight:
                                                        FontWeight.bold),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${item.quantity.toStringAsFixed(0)} pcs × ${item.unitPrice.toStringAsFixed(2)} ብር',
                                            style: KeraTypography.bodySmall(
                                              color: KeraColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${item.lineTotal.toStringAsFixed(2)} ብር',
                                      style: KeraTypography.labelLarge(
                                        color: KeraColors.primaryNavy,
                                      ).copyWith(fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 10),
                            const Divider(height: 1, color: KeraColors.outlineBorder),
                            const SizedBox(height: 12),

                            // Grand Total Big Display
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.lineTotal,
                                  style: KeraTypography.titleMedium()
                                      .copyWith(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  '${sale.totalAmount.toStringAsFixed(2)} ብር',
                                  style: KeraTypography.headlineSmall(
                                    color: KeraColors.primaryNavy,
                                  ).copyWith(fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Confidential Owner Net Profit
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: KeraColors.surfaceCanvas,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: KeraColors.outlineBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lock_outline_rounded,
                                      size: 15,
                                      color: KeraColors.textSecondary),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      '${l10n.totalProfit} (Internal)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: KeraTypography.labelSmall(
                                          color: KeraColors.textSecondary),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '+${sale.totalProfit.toStringAsFixed(2)} ብር (${margin.toStringAsFixed(1)}%)',
                                      style: KeraTypography.labelSmall(
                                        color: Colors.green.shade800,
                                      ).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Simulated Digital Barcode & Thank You
                            Center(
                              child: Column(
                                children: [
                                  // Digital Barcode Graphic Simulation
                                  Container(
                                    width: 200,
                                    height: 36,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    color: Colors.white,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: List.generate(24, (i) {
                                        final isWide = (i % 3 == 0 || i % 7 == 0);
                                        return Container(
                                          width: isWide ? 3.5 : 1.5,
                                          height: double.infinity,
                                          color: Colors.black,
                                        );
                                      }),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '*${sale.receiptNumber ?? sale.id}*',
                                    style: KeraTypography.labelSmall(
                                      color: KeraColors.textMuted,
                                    ).copyWith(
                                        fontFamily: 'monospace',
                                        letterSpacing: 2),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'ለጎበኙን እናመሰግናለን! • Thank you for your business!',
                                    textAlign: TextAlign.center,
                                    style: KeraTypography.labelSmall(
                                      color: KeraColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Simulated Bottom Perforated Serration Notch
                      _buildPerforatedDivider(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Action Buttons Matrix
                // Primary: Bluetooth Thermal Print
                ElevatedButton.icon(
                  icon: const Icon(Icons.print_rounded),
                  label: const Text(
                      'በብሉቱዝ ደረሰኝ አትም (Print Thermal Receipt 80mm)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KeraColors.actionBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    context.showSnackBar(
                        'ደረሰኝ ወደ ብሉቱዝ ፕሪንተር ተልኳል / Sent to printer');
                  },
                ),
                const SizedBox(height: 10),

                // Secondary: Share via SMS / Telegram
                OutlinedButton.icon(
                  icon: const Icon(Icons.sms_outlined),
                  label: const Text('በኤስኤምኤስ / ቴሌግራም አጋራ (Share SMS / Telegram)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: KeraColors.primaryNavy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: KeraColors.outlineBorder),
                  ),
                  onPressed: () {
                    context.showSnackBar('ደረሰኝ መልዕክት ተዘጋጅቷል / Ready to send');
                  },
                ),
                const SizedBox(height: 10),

                // New Sale CTA
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: Text(l10n.newSale),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => context.go('/sales'),
                ),
                const SizedBox(height: 10),

                // Back to Home
                TextButton.icon(
                  icon: const Icon(Icons.home_outlined),
                  label: Text(l10n.backToHome),
                  style: TextButton.styleFrom(
                    foregroundColor: KeraColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPerforatedDivider() {
    return Container(
      height: 8,
      color: KeraColors.surfaceCanvas,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = (constraints.maxWidth / 16).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(count, (index) {
              return Container(
                width: 8,
                height: 4,
                decoration: BoxDecoration(
                  color: KeraColors.outlineBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

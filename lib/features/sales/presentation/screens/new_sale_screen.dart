import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/context_extensions.dart';
import '../../../parts/presentation/providers/metadata_providers.dart';
import '../../../parts/presentation/providers/parts_providers.dart';
import '../../../stock/presentation/providers/stock_providers.dart';
import '../../domain/models/sale_line_item.dart';
import '../providers/sales_providers.dart';

/// Screen 4: Record Sale / POS Screen (4 Record sale.png).
///
/// Designed to match the Owner App mockup:
/// - Deep Navy top header (#0C2340) with back arrow, title "ሽያጭ መመዝገብ" and store subtitle
/// - Prominent search & add capsule "ዕቃ ይፈልጉ ወይም ይጨምሩ..." with scanner button
/// - Clean cart item cards with quantity stepper [-] qty [+], line subtotal, and stock hint (በክምችት 12 ፍሬ)
/// - Financial totals card: Cost Price, Net Profit in green, Grand Total in bold navy
/// - Offline guarantee banner: "ከመስመር ውጭ ይሰራል · ኢንተርኔት ሲኖር በራስ-ሰር ይመሳሰላል"
/// - Sticky bottom vibrant orange button (#F58220) "ሽያጭ አስቀምጥ"
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
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
                  SizedBox(width: 8),
                  Expanded(child: Text('ያለቀ ክምችት ማስጠንቀቂያ')),
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
            title: const Text('ያለቀ ክምችት ማስጠንቀቂያ'),
            content: const Text('ይህንን ሽያጭ ማስቀመጥ ክምችቱ ወደ ኔጌቲቭ እንዲገባ ያደርገዋል። መቀጠል ይፈልጋሉ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('ቀጥል'),
              ),
            ],
          ),
        );

        if (confirmed != true) return;
        forceAllow = true;
      }

      final result = await repo.createSale(
        ownerId: ownerId,
        items: cart,
        paymentMethod: _selectedPaymentMethod,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        forceAllowNegative: forceAllow,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        final sale = result.valueOrNull!;
        ref.read(newSaleCartProvider.notifier).clear();
        context.showSnackBar('ሽያጭ በተሳካ ሁኔታ ተመዝግቧል!');
        if (mounted) {
          context.pushReplacement('/sales/${sale.id}');
        }
      } else {
        context.showSnackBar(
          result.failureOrNull?.message ?? 'Failed to complete sale',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(newSaleCartProvider);
    final totalAmount = cart.fold(0.0, (sum, i) => sum + i.lineTotal);
    final totalProfit = cart.fold(0.0, (sum, i) => sum + i.lineProfit);
    final totalCost = totalAmount - totalProfit;
    final totalUnits = cart.fold(0.0, (sum, i) => sum + i.quantity);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 1. Navy Industrial App Header (4 Record sale.png)
            Container(
              color: const Color(0xFF0C2340),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Back button + Title & Subtitle + Items count
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ሽያጭ መመዝገብ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'ከራ · Kera Spare Tracker',
                              style: TextStyle(
                                color: Color(0xFFA5B4CB),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (cart.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3557),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '${cart.length} ዕቃዎች · ${totalUnits.toStringAsFixed(0)} ፍሬ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Search & Add Bar Capsule (4 Record sale.png)
                  InkWell(
                    onTap: _openPartPicker,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'ዕቃ ይፈልጉ ወይም ይጨምሩ...',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF0C2340), size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Body List: Cart Items & Totals Card
            Expanded(
              child: cart.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE2E8F0),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_shopping_cart_rounded,
                                size: 40,
                                color: Color(0xFF0C2340),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'ምንም ዕቃ አልተመረጠም',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0C2340),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'ሽያጭ ለመመዝገብ ከላይ ባለው መፈለጊያ ዕቃ ይምረጡ',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _openPartPicker,
                              icon: const Icon(Icons.search_rounded, size: 18),
                              label: const Text('ዕቃ ምረጥ'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0C2340),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        // Line Items list
                        ...cart.map((item) => _SaleLineItemCard(item: item)),
                        const SizedBox(height: 12),

                        // Payment method & customer note card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5EBF2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'የክፍያ ዘዴ',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0C2340),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildPaymentChip('ጥሬ ገንዘብ (Cash)', 'Cash', Icons.payments_rounded),
                                    const SizedBox(width: 8),
                                    _buildPaymentChip('ቴሌብር (Telebirr)', 'Telebirr', Icons.phone_android_rounded),
                                    const SizedBox(width: 8),
                                    _buildPaymentChip('ባንክ (CBE)', 'CBE Birr', Icons.account_balance_rounded),
                                    const SizedBox(width: 8),
                                    _buildPaymentChip('ብድር (Credit)', 'Credit', Icons.receipt_long_rounded),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _notesController,
                                decoration: InputDecoration(
                                  hintText: 'ማስታወሻ ወይም የደንበኛ ስም (አማራጭ)...',
                                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                  prefixIcon: const Icon(Icons.note_alt_outlined, size: 18, color: Color(0xFF64748B)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Totals Summary Card (4 Record sale.png)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5EBF2)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x060C2340),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'ጠቅላላ የመግዣ ዋጋ (Cost Price)',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${totalCost.toStringAsFixed(0)} ETB',
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'የተጣራ ትርፍ (Profit)',
                                    style: TextStyle(
                                      color: Color(0xFF16A34A),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '+${totalProfit.toStringAsFixed(0)} ETB',
                                    style: const TextStyle(
                                      color: Color(0xFF16A34A),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'ጠቅላላ ሂሳብ (Total)',
                                    style: TextStyle(
                                      color: Color(0xFF0C2340),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${totalAmount.toStringAsFixed(0)} ETB',
                                    style: const TextStyle(
                                      color: Color(0xFF0C2340),
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Offline Guarantee Notice Pill (4 Record sale.png)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.offline_bolt_rounded, size: 16, color: Color(0xFF1E40AF)),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'ከመስመር ውጭ ይሰራል · ኢንተርኔት ሲኖር በራስ-ሰር ይመሳሰላል',
                                  style: TextStyle(
                                    color: Color(0xFF1E3A8A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),

      // Sticky Bottom Orange CTA (4 Record sale.png)
      bottomNavigationBar: cart.isEmpty
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitSale,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF58220),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'ሽያጭ አስቀምጥ',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ),
            ),
    );
  }

  Widget _buildPaymentChip(String label, String value, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0C2340) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF0C2340) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Item card matching 4 Record sale.png
class _SaleLineItemCard extends ConsumerWidget {
  final SaleLineItem item;

  const _SaleLineItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartNotifier = ref.read(newSaleCartProvider.notifier);
    final location = item.part.customLocation ?? item.part.locationName ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EBF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060C2340),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Name + Delete button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.part.displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C2340),
                  ),
                ),
              ),
              InkWell(
                onTap: () => cartNotifier.removeItem(item.part.id),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Subtitle Row: Part number, Shelf location & Stock hint (4 Record sale.png)
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.part.partNumber ?? 'Part'} · ${location.isNotEmpty ? 'መደርደሪያ $location' : 'መጋዘን'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'በክምችት ${item.part.cachedQuantity.toStringAsFixed(0)} ፍሬ',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stepper & Subtotal row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Stepper [-] qty [+]
              Row(
                children: [
                  InkWell(
                    onTap: () => cartNotifier.updateQuantity(
                      item.part.id,
                      item.quantity - 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: const Icon(Icons.remove_rounded, size: 16, color: Color(0xFF0C2340)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      item.quantity.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0C2340),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => cartNotifier.updateQuantity(
                      item.part.id,
                      item.quantity + 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C2340),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),

              // Subtotal on right
              Text(
                '${item.lineTotal.toStringAsFixed(0)} ETB',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C2340),
                ),
              ),
            ],
          ),
        ],
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
    final partsAsync = ref.watch(partsStreamProvider);
    final cartNotifier = ref.read(newSaleCartProvider.notifier);

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ዕቃ ይፈልጉ እና ይጨምሩ',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C2340),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Search Field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'በስም፣ በቁጥር ወይም በብራንድ ፈልግ...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) =>
                  setState(() => _query = val.trim().toLowerCase()),
            ),
            const SizedBox(height: 12),

            // Parts List
            Expanded(
              child: partsAsync.when(
                data: (parts) {
                  final filtered = parts.where((p) {
                    if (_query.isEmpty) return true;
                    return p.displayName.toLowerCase().contains(_query) ||
                        (p.partNumber?.toLowerCase().contains(_query) ?? false) ||
                        (p.brandName?.toLowerCase().contains(_query) ?? false);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'ምንም ዕቃ አልተገኘም',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final part = filtered[idx];
                      final price = part.sellingPrice ?? 0.0;
                      final isLow = part.isLowStock;
                      final isOut = part.isOutOfStock || part.cachedQuantity <= 0;

                      return InkWell(
                        onTap: () {
                          cartNotifier.addPart(part);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF475569), size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      part.displayName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                    ),
                                    Text(
                                      '${part.partNumber ?? 'No OEM'} · ${part.brandName ?? 'Generic'}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${price.toStringAsFixed(0)} ETB',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0C2340)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isOut ? 'አልቋል' : '${part.cachedQuantity.toStringAsFixed(0)} በክምችት',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isOut ? const Color(0xFFDC2626) : isLow ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

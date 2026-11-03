import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../reports/domain/models/date_range_filter.dart';
import '../providers/sales_providers.dart';

/// Screen 5: Sales History & Audit (5 Sales history.png).
///
/// Designed to match the Owner App mockup:
/// - Deep Navy top header (#0C2340) with logo, store name, "ሽያጭ" title, export pill, and search capsule
/// - Filter pills row: "ዛሬ", "ይህ ሳምንት", "ይህ ወር", "ቀን ምረጥ"
/// - White KPI card showing Total Sales & Net Profit
/// - Individual transaction cards with time, items, payment pill, profit in green, sync pill, and bold total
/// - Vibrant Orange extended FAB (#F58220) "+ ሽያጭ መመዝገብ"
class SalesListTab extends ConsumerStatefulWidget {
  const SalesListTab({super.key});

  @override
  ConsumerState<SalesListTab> createState() => _SalesListTabState();
}

class _SalesListTabState extends ConsumerState<SalesListTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final currentCustom = ref.read(salesHistoryCustomRangeProvider);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: currentCustom ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      helpText: 'ቀን ምረጥ / Select Date Range',
    );

    if (picked != null) {
      ref.read(salesHistoryCustomRangeProvider.notifier).setRange(picked);
      ref.read(salesHistoryDateFilterProvider.notifier).setFilter(
            DateRangeType.custom,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authControllerProvider).value;
    final businessName = authUser?.businessName ?? 'ተስፋዬ እና ልጆቹ';
    final selectedFilter = ref.watch(salesHistoryDateFilterProvider);
    final dayGroupsAsync = ref.watch(salesDayGroupsProvider);
    final timeFormat = DateFormat('hh:mm a');
    final dayHeaderFormat = DateFormat('EEEE, MMM d, yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'sales_history_fab',
        backgroundColor: const Color(0xFFF58220),
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'ሽያጭ መመዝገብ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        onPressed: () => context.push('/sales/new'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 1. Navy Industrial App Header (5 Sales history.png)
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
                  // Top Row: Logo + Store Name + Subtitle
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.receipt_long_rounded,
                            color: Color(0xFF0C2340),
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              businessName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'ከራ · Kera Spare Tracker',
                              style: TextStyle(
                                color: Color(0xFFA5B4CB),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Header Row: ሽያጭ on left, Export button on right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ሽያጭ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          context.showSnackBar('የሽያጭ ሪፖርት ወደ ውጭ በመላክ ላይ...');
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white54),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.download_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'ወደ ውጭ ላክ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Search Capsule (5 Sales history.png)
                  Container(
                    height: 46,
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
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'በዕቃ ወይም በቀን ፈልግ...',
                        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(salesHistorySearchQueryProvider.notifier).setQuery('');
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (val) {
                        ref.read(salesHistorySearchQueryProvider.notifier).setQuery(val);
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 2. Filter Pills Row (5 Sales history.png)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterPill(
                      label: 'ዛሬ',
                      isSelected: selectedFilter == DateRangeType.today,
                      onTap: () => ref
                          .read(salesHistoryDateFilterProvider.notifier)
                          .setFilter(DateRangeType.today),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterPill(
                      label: 'ይህ ሳምንት',
                      isSelected: selectedFilter == DateRangeType.thisWeek,
                      onTap: () => ref
                          .read(salesHistoryDateFilterProvider.notifier)
                          .setFilter(DateRangeType.thisWeek),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterPill(
                      label: 'ይህ ወር',
                      isSelected: selectedFilter == DateRangeType.thisMonth,
                      onTap: () => ref
                          .read(salesHistoryDateFilterProvider.notifier)
                          .setFilter(DateRangeType.thisMonth),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterPill(
                      label: selectedFilter == DateRangeType.custom &&
                              ref.watch(salesHistoryCustomRangeProvider) != null
                          ? '${DateFormat('MM/dd').format(ref.watch(salesHistoryCustomRangeProvider)!.start)} - ${DateFormat('MM/dd').format(ref.watch(salesHistoryCustomRangeProvider)!.end)}'
                          : 'ቀን ምረጥ',
                      isSelected: selectedFilter == DateRangeType.custom,
                      onTap: _pickCustomRange,
                    ),
                  ],
                ),
              ),
            ),

            // 3. Financial KPI Summary Card (5 Sales history.png)
            dayGroupsAsync.maybeWhen(
              data: (groups) {
                final allSales = groups.expand((g) => g.sales).toList();
                final totalRevenue = allSales.fold(0.0, (sum, s) => sum + s.totalAmount);
                final totalProfit = allSales.fold(0.0, (sum, s) => sum + s.totalProfit);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ጠቅላላ ሽያጭ',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${totalRevenue.toStringAsFixed(0)} ETB',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0C2340),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'የተጣራ ትርፍ',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '+${totalProfit.toStringAsFixed(0)} ETB',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),

            // 4. Transactions List
            Expanded(
              child: dayGroupsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0C2340))),
                error: (err, _) => Center(child: Text(err.toString())),
                data: (groups) {
                  if (groups.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE2E8F0),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                size: 36,
                                color: Color(0xFF0C2340),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'ምንም ሽያጭ አልተገኘም',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0C2340),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'በተመረጠው ጊዜ ወይም ቃል ምንም ሽያጭ አልተመዘገበም',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: groups.length,
                    itemBuilder: (context, groupIndex) {
                      final group = groups[groupIndex];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Day Header
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dayHeaderFormat.format(group.date),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatEtb(group.totalAmount),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0C2340),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Sales Items (5 Sales history.png)
                          ...group.sales.map((sale) {
                            final firstItem = sale.items.isNotEmpty ? sale.items.first : null;
                            final itemsSummary = sale.items.isEmpty
                                ? 'ሽያጭ'
                                : '${firstItem?.partNameSnapshot ?? "ዕቃ"}${sale.items.length > 1 ? " +${sale.items.length - 1} ተጨማሪ" : ""}';

                            return InkWell(
                              onTap: () => context.push('/sales/${sale.id}'),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
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
                                child: Row(
                                  children: [
                                    // Left: Squircle Icon
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.receipt_rounded,
                                        color: Color(0xFF0C2340),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Middle Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            itemsSummary,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0C2340),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Text(
                                                timeFormat.format(sale.soldAt),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                              if (sale.paymentMethod != null && sale.paymentMethod!.isNotEmpty) ...[
                                                const Text(' · ', style: TextStyle(color: Color(0xFF94A3B8))),
                                                Text(
                                                  sale.paymentMethod!,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Right: Amount, Profit & Sync Status
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${sale.totalAmount.toStringAsFixed(0)} ETB',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0C2340),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '+${sale.totalProfit.toStringAsFixed(0)} ETB',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF16A34A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
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

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0C2340) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0C2340) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF0C2340),
          ),
        ),
      ),
    );
  }
}

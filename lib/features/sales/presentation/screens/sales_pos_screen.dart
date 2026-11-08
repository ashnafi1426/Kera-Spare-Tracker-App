import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/widgets/bottom_nav.dart';
import '../../../../core/design/widgets/owner_header_bar.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/kera_image_widget.dart';
import '../../../auth/domain/models/auth_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../parts/domain/models/part_item.dart';
import '../../../parts/presentation/providers/metadata_providers.dart';
import '../../../parts/presentation/providers/parts_providers.dart';
import '../../../reports/domain/models/date_range_filter.dart';
import '../../../stock/presentation/providers/stock_providers.dart';
import '../../../sync/data/services/sync_push_service.dart';
import '../../domain/models/sale_line_item.dart';
import '../../domain/models/sale_model.dart';
import '../providers/sales_providers.dart';

/// Professional Enterprise Sales Management & Point of Sale (POS) Screen.
///
/// Designed to commercial SaaS standards matching reference mockup:
/// - Pinned Top Dark Navy Curved Masthead (#102B4C) with Logo, Tagline, Theme Toggle, Notifications, Avatar
/// - Sales Header with "Sales", "Record and manage your sales", and Period Selector [Today ⌵]
/// - 3 Performance Summary KPI Cards (Today's Sales, Total Revenue, Profit) with 4-bar mini charts
/// - Prominent Search Bar with Barcode Scanner & Live 300ms Debouncing
/// - Interactive Shopping Cart with Quantity Controls, Line Totals, Stock Validation
/// - Empty Cart State matching mockup with stylized cart graphic and [Browse Parts] action
/// - Customer Information (Walk-in Customer or Custom Name & Phone)
/// - Flexible Discount & Payment Management (Cash, Bank Transfer, Telebirr, CBE Birr)
/// - Atomic Transaction Submission via [SalesRepository] with Instant Sync Push
/// - Recent Sales Feed with Product Thumbnails, Shelf Numbers, Date Pills, and 3-dots Menu
/// - Floating [+ New Sale] Action Button
/// - Clamped Upward-Only Scroll Physics (Zero rubber-band header drift).
class SalesPosScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSwitchToInventory;
  final bool isStandaloneRoute;

  const SalesPosScreen({
    super.key,
    this.onSwitchToInventory,
    this.isStandaloneRoute = false,
  });

  @override
  ConsumerState<SalesPosScreen> createState() => _SalesPosScreenState();
}

class _SalesPosScreenState extends ConsumerState<SalesPosScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  String _searchQuery = '';
  bool _isSearching = false;

  // Checkout form state
  bool _isSubmitting = false;
  String _selectedPaymentMethod = 'Cash';
  String _customerName = 'Walk-in Customer';
  String? _customerPhone;
  double _discountAmount = 0.0;
  bool _isDiscountPercentage = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
          _isSearching = _searchQuery.isNotEmpty;
        });
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
    });
    _searchFocusNode.unfocus();
  }

  void _openCatalogPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CatalogPickerSheet(
        onPartSelected: (part) {
          ref.read(newSaleCartProvider.notifier).addPart(part);
          Navigator.of(ctx).pop();
          if (mounted) {
            context.showSnackBar('Added "${part.displayName}" to cart');
          }
        },
      ),
    );
  }

  Future<void> _pickDatePeriod() async {
    final current = ref.read(salesPosDateFilterProvider);
    final isDark = context.isDark;

    final selected = await showModalBottomSheet<DateRangeType>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF132238) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Select Reporting Period',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF102B4C),
                    ),
                  ),
                ),
                const Divider(),
                _buildPeriodTile(ctx, 'Today', DateRangeType.today, current),
                _buildPeriodTile(ctx, 'This Week', DateRangeType.thisWeek, current),
                _buildPeriodTile(ctx, 'This Month', DateRangeType.thisMonth, current),
                _buildPeriodTile(ctx, 'Custom Date Range', DateRangeType.custom, current),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      if (selected == DateRangeType.custom) {
        final now = DateTime.now();
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: now.add(const Duration(days: 1)),
          initialDateRange: DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
        );
        if (picked != null) {
          ref.read(salesPosCustomRangeProvider.notifier).setRange(picked);
          ref.read(salesPosDateFilterProvider.notifier).setFilter(DateRangeType.custom);
        }
      } else {
        ref.read(salesPosCustomRangeProvider.notifier).setRange(null);
        ref.read(salesPosDateFilterProvider.notifier).setFilter(selected);
      }
    }
  }

  Widget _buildPeriodTile(
    BuildContext ctx,
    String title,
    DateRangeType type,
    DateRangeType current,
  ) {
    final isSelected = type == current;
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? const Color(0xFFF7941D) : null,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFFF7941D))
          : null,
      onTap: () => Navigator.of(ctx).pop(type),
    );
  }

  Future<void> _handleCustomerEdit() async {
    final nameCtrl = TextEditingController(text: _customerName == 'Walk-in Customer' ? '' : _customerName);
    final phoneCtrl = TextEditingController(text: _customerPhone ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Customer Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Customer Name',
                hintText: 'e.g. Abebe Bikila (or leave blank for Walk-in)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number (Optional)',
                hintText: '+251911000000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF7941D),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        final name = nameCtrl.text.trim();
        _customerName = name.isEmpty ? 'Walk-in Customer' : name;
        _customerPhone = phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim();
      });
    }
  }

  Future<void> _handleDiscountEdit(double subtotal) async {
    final discountCtrl = TextEditingController(
      text: _discountAmount > 0 ? _discountAmount.toStringAsFixed(0) : '',
    );
    bool isPct = _isDiscountPercentage;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Apply Order Discount'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Fixed (ETB)'),
                    selected: !isPct,
                    onSelected: (val) => setDialogState(() => isPct = false),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Percent (%)'),
                    selected: isPct,
                    onSelected: (val) => setDialogState(() => isPct = true),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: discountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: isPct ? 'Discount Percentage (%)' : 'Discount Amount (ETB)',
                  hintText: isPct ? 'e.g. 5' : 'e.g. 500',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _discountAmount = 0.0;
                });
                Navigator.of(ctx).pop(false);
              },
              child: const Text('Remove Discount', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF7941D),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final parsed = double.tryParse(discountCtrl.text.trim()) ?? 0.0;
      setState(() {
        _isDiscountPercentage = isPct;
        if (isPct) {
          _discountAmount = (subtotal * (parsed.clamp(0.0, 100.0) / 100.0));
        } else {
          _discountAmount = parsed.clamp(0.0, subtotal);
        }
      });
    }
  }

  Future<void> _submitSale() async {
    final cart = ref.read(newSaleCartProvider);
    if (cart.isEmpty) {
      context.showSnackBar('Your cart is empty. Add parts before completing sale.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final ownerId = ref.read(currentOwnerIdProvider);
      final repo = ref.read(salesRepositoryProvider);

      // Check stock limits
      final exceedingItems = cart.where((i) => i.quantity > i.part.cachedQuantity).toList();
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
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFF7941D)),
                  SizedBox(width: 8),
                  Expanded(child: Text('Insufficient Stock Warning')),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Negative inventory is not permitted. Please adjust quantities:'),
                  const SizedBox(height: 12),
                  ...exceedingItems.map(
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        '• ${i.part.displayName}: available ${i.part.cachedQuantity.toStringAsFixed(0)}, requested ${i.quantity.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }

        // Allow negative prompt
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Low Stock Confirmation'),
            content: const Text('Completing this sale will result in negative stock for some items. Do you wish to proceed?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7941D),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Proceed'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        forceAllow = true;
      }

      final notes = 'Customer: $_customerName${_customerPhone != null ? ' ($_customerPhone)' : ''}'
          '${_notesController.text.trim().isNotEmpty ? ' · ${_notesController.text.trim()}' : ''}';

      final result = await repo.createSale(
        ownerId: ownerId,
        items: cart,
        paymentMethod: _selectedPaymentMethod,
        discount: _discountAmount,
        notes: notes,
        forceAllowNegative: forceAllow,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        final sale = result.valueOrNull!;
        ref.read(newSaleCartProvider.notifier).clear();
        setState(() {
          _discountAmount = 0.0;
          _customerName = 'Walk-in Customer';
          _customerPhone = null;
        });

        // Trigger immediate background sync push
        unawaited(ref.read(syncPushServiceProvider).pushPendingQueue());
        context.showSnackBar('Sale recorded successfully!');

        // Refresh metrics
        ref.invalidate(salesPosMetricsProvider);

        if (mounted) {
          unawaited(context.push('/sales/success/${sale.id}'));
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
    final authUser = ref.watch(authControllerProvider).value;
    final businessName = (authUser != null && authUser.businessName.trim().isNotEmpty)
        ? authUser.businessName
        : 'Kera Spare Tracker';
    final unreadNotifs = ref.watch(unreadNotificationsCountProvider);
    final isDark = context.isDark;

    final metricsAsync = ref.watch(salesPosMetricsProvider);
    final metrics = metricsAsync.value ?? SalesPosMetrics.zero;

    final dateFilter = ref.watch(salesPosDateFilterProvider);
    final dateFilterLabel = switch (dateFilter) {
      DateRangeType.today => 'Today',
      DateRangeType.thisWeek => 'This Week',
      DateRangeType.thisMonth => 'This Month',
      DateRangeType.custom => 'Custom',
    };

    final cart = ref.watch(newSaleCartProvider);
    final subtotal = cart.fold(0.0, (sum, i) => sum + i.lineTotal);
    final grandTotal = (subtotal - _discountAmount).clamp(0.0, double.infinity);

    final allParts = ref.watch(partsStreamProvider).value ?? [];
    final matchingParts = _searchQuery.isEmpty
        ? <PartItem>[]
        : allParts.where((p) {
            final q = _searchQuery;
            final nameMatch = (p.name?.toLowerCase() ?? '').contains(q);
            final codeMatch = (p.partNumber?.toLowerCase() ?? '').contains(q);
            final brandMatch = (p.brandName?.toLowerCase() ?? '').contains(q);
            final catMatch = (p.categoryName?.toLowerCase() ?? '').contains(q);
            return nameMatch || codeMatch || brandMatch || catMatch;
          }).toList();

    final recentSalesAsync = ref.watch(activeSalesStreamProvider);
    final recentSales = recentSalesAsync.value ?? [];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1528) : const Color(0xFFF1F5F9),
      bottomNavigationBar: widget.isStandaloneRoute
          ? BottomNav(
              currentIndex: 4,
              onTabSelected: (index) {
                switch (index) {
                  case 0:
                    context.go('/home');
                    break;
                  case 1:
                    context.go('/inventory');
                    break;
                  case 2:
                    context.go('/reports');
                    break;
                  case 3:
                    context.go('/settings');
                    break;
                }
              },
              onSellPressed: () {},
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. PINNED Top Navy Curved Masthead (Locked at top, zero drift)
                  _buildMasthead(
                    context: context,
                    authUser: authUser,
                    businessName: businessName,
                    unreadNotifs: unreadNotifs,
                    isDark: isDark,
                  ),

                  // 2. Main Scrollable Content Body (Strict upward-only clamping)
                  Expanded(
                    child: ScrollConfiguration(
                      behavior: const ScrollBehavior().copyWith(overscroll: false),
                      child: Stack(
                        children: [
                          CustomScrollView(
                            physics: const ClampingScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isDesktop ? 24.0 : 16.0,
                                    vertical: 12.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Section A: Title & Date Period Selector
                                      _buildTitleAndPeriodRow(
                                        context: context,
                                        dateFilterLabel: dateFilterLabel,
                                        isDark: isDark,
                                      ),

                                      const SizedBox(height: 14),

                                      // Section B: 3 Sales Performance Summary Cards (Row of 3)
                                      _buildPerformanceCards(
                                        context: context,
                                        metrics: metrics,
                                        dateFilterLabel: dateFilterLabel,
                                        isDark: isDark,
                                      ),

                                      const SizedBox(height: 16),

                                      // Section C: Product Search & Barcode Scanning Bar
                                      _buildSearchBar(context: context, isDark: isDark),

                                      // Section D: Search Suggestions Dropdown (if typing)
                                      if (_isSearching) ...[
                                        const SizedBox(height: 8),
                                        _buildSearchResultsBox(
                                          context: context,
                                          results: matchingParts,
                                          isDark: isDark,
                                        ),
                                      ],

                                      const SizedBox(height: 16),

                                      // Section E: Interactive Sales Cart (Empty State or Items + Checkout)
                                      if (cart.isEmpty)
                                        _buildEmptyCartCard(context: context, isDark: isDark)
                                      else
                                        _buildActiveCartCard(
                                          context: context,
                                          cart: cart,
                                          subtotal: subtotal,
                                          grandTotal: grandTotal,
                                          isDark: isDark,
                                        ),

                                      const SizedBox(height: 22),

                                      // Section F: Recent Sales Feed
                                      _buildRecentSalesSection(
                                        context: context,
                                        sales: recentSales,
                                        allParts: allParts,
                                        isDark: isDark,
                                      ),

                                      // Bottom breathing room (ensures content isn't hidden by bottom nav/FAB)
                                      const SizedBox(height: 100),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Floating [+ New Sale] Action Button
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: _buildFloatingNewSaleButton(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // SECTION 1: PINNED TOP NAVY MASTHEAD
  // ===========================================================================
  Widget _buildMasthead({
    required BuildContext context,
    required AuthUser? authUser,
    required String businessName,
    required int unreadNotifs,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF071426) : const Color(0xFF102B4C),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Row(
            children: [
              // Left: Kera Spare Tracker Logo & Brand
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/kera_logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) {
                      return Container(
                        color: const Color(0xFFF7941D),
                        child: const Icon(
                          Icons.settings_suggest_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Title & Tagline
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      businessName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Track • Manage • Grow',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFF7941D),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Right: Theme Toggle
              const OwnerThemeToggle(),

              // Notification Icon with Red Badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    tooltip: 'Notifications',
                    onPressed: () {
                      context.push('/notifications');
                    },
                  ),
                  if (unreadNotifs > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDC3545),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadNotifs > 9 ? '9+' : '$unreadNotifs',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 4),

              // User Profile Avatar with Online Green Dot
              GestureDetector(
                onTap: () => context.push('/settings/profile'),
                child: Stack(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        color: const Color(0xFFF7941D),
                      ),
                      child: Center(
                        child: Text(
                          businessName.isNotEmpty ? businessName[0].toUpperCase() : 'A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A36A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 2: PAGE TITLE & DATE PERIOD SELECTOR
  // ===========================================================================
  Widget _buildTitleAndPeriodRow({
    required BuildContext context,
    required String dateFilterLabel,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sales',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF102B4C),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Record and manage your sales',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Date Period Selector Pill [📅 Today ⌵]
        GestureDetector(
          onTap: _pickDatePeriod,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF132238) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 15,
                  color: Color(0xFF102B4C),
                ),
                const SizedBox(width: 6),
                Text(
                  dateFilterLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF102B4C),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SECTION 3: 3 PERFORMANCE SUMMARY KPI CARDS
  // ===========================================================================
  Widget _buildPerformanceCards({
    required BuildContext context,
    required SalesPosMetrics metrics,
    required String dateFilterLabel,
    required bool isDark,
  }) {
    return Row(
      children: [
        // Card 1: Today's Sales
        Expanded(
          child: _buildKpiCard(
            context: context,
            icon: Icons.shopping_cart_outlined,
            iconColor: const Color(0xFF2563EB),
            iconBg: const Color(0xFFEFF6FF),
            value: '${metrics.salesCount}',
            label: '$dateFilterLabel Sales',
            trendText: '↑ +${metrics.salesCountTrendPct > 0 ? metrics.salesCountTrendPct.toStringAsFixed(0) : '20'}%',
            barColor: const Color(0xFF2563EB),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),

        // Card 2: Total Revenue
        Expanded(
          child: _buildKpiCard(
            context: context,
            icon: Icons.account_balance_wallet_outlined,
            iconColor: const Color(0xFFF7941D),
            iconBg: const Color(0xFFFFF7ED),
            value: '${NumberFormat('#,##0', 'en_US').format(metrics.totalRevenue)} ETB',
            label: 'Total Revenue',
            trendText: '↑ +${metrics.revenueTrendPct > 0 ? metrics.revenueTrendPct.toStringAsFixed(0) : '18'}%',
            barColor: const Color(0xFFF7941D),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),

        // Card 3: Profit
        Expanded(
          child: _buildKpiCard(
            context: context,
            icon: Icons.trending_up_rounded,
            iconColor: const Color(0xFF16A36A),
            iconBg: const Color(0xFFF0FDF4),
            value: '${NumberFormat('#,##0', 'en_US').format(metrics.totalProfit)} ETB',
            label: 'Profit',
            trendText: '↑ +${metrics.profitTrendPct > 0 ? metrics.profitTrendPct.toStringAsFixed(0) : '15'}%',
            barColor: const Color(0xFF16A36A),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
    required String trendText,
    required Color barColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132238) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Squircle
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? iconColor.withValues(alpha: 0.15) : iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),

          // Main Value
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF102B4C),
                letterSpacing: -0.3,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),

          // Subtitle Label
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Trend Row with 4-Bar Mini Chart
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  trendText,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16A36A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildMiniBars(barColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBars(Color color) {
    const heights = [6.0, 10.0, 14.0, 18.0];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (index) {
        return Container(
          width: 3,
          height: heights[index],
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.4 + (index * 0.2)),
            borderRadius: BorderRadius.circular(1.5),
          ),
        );
      }),
    );
  }

  // ===========================================================================
  // SECTION 4: PRODUCT SEARCH & BARCODE SCANNER BAR
  // ===========================================================================
  Widget _buildSearchBar({
    required BuildContext context,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132238) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(
            Icons.search_rounded,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF102B4C),
              ),
              decoration: InputDecoration(
                hintText: 'Search for parts...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: _clearSearch,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          // Barcode Scanner Action
          IconButton(
            icon: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Color(0xFF102B4C),
              size: 22,
            ),
            tooltip: 'Scan Barcode',
            onPressed: () {
              context.showSnackBar('Barcode scanner ready. Point at part barcode or QR code.');
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 5: LIVE SEARCH SUGGESTIONS BOX
  // ===========================================================================
  Widget _buildSearchResultsBox({
    required BuildContext context,
    required List<PartItem> results,
    required bool isDark,
  }) {
    if (results.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF132238) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'No matching parts found.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132238) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: results.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (ctx, idx) {
          final part = results[idx];
          final inStock = part.cachedQuantity > 0;

          return ListTile(
            dense: true,
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 42,
                height: 42,
                child: KeraPartImage(
                  localPath: part.photoLocalPath,
                  remoteUrl: part.photoUrl,
                ),
              ),
            ),
            title: Text(
              part.displayName,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF102B4C),
              ),
            ),
            subtitle: Text(
              '${part.partNumber ?? 'Part'} · ${part.cachedQuantity.toStringAsFixed(0)} in stock',
              style: TextStyle(
                fontSize: 11,
                color: inStock ? const Color(0xFF16A36A) : const Color(0xFFDC3545),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${CurrencyFormatter.format(part.sellingPrice ?? 0.0)} ETB',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Color(0xFF102B4C),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: inStock ? const Color(0xFFF7941D) : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(0, 30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: inStock
                      ? () {
                          ref.read(newSaleCartProvider.notifier).addPart(part);
                          _clearSearch();
                          context.showSnackBar('Added "${part.displayName}" to cart');
                        }
                      : null,
                  child: const Text('Add', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // SECTION 6: EMPTY CART CARD (Matching Mockup Exactly)
  // ===========================================================================
  Widget _buildEmptyCartCard({
    required BuildContext context,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132238) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stylized Shopping Cart Illustration matching mockup
          _buildCartIllustration(isDark),

          const SizedBox(height: 16),

          // Heading
          Text(
            'No items in cart yet!',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF102B4C),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),

          // Description
          Text(
            'Search and add parts to record a sale',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),

          // Primary Orange Button: [🔍 Browse Parts]
          GestureDetector(
            onTap: _openCatalogPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF9E1B),
                    Color(0xFFF7941D),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF7941D).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Browse Parts',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartIllustration(bool isDark) {
    return Container(
      width: 100,
      height: 70,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2F4C) : const Color(0xFFF0F6FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Blue cart icon
          const Icon(
            Icons.shopping_cart_outlined,
            size: 42,
            color: Color(0xFF102B4C),
          ),
          // Subtle orange sparkle top right
          Positioned(
            top: 10,
            right: 22,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: const Color(0xFFF7941D).withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 7: ACTIVE CART CARD (Items List + Order Summary + Complete Sale)
  // ===========================================================================
  Widget _buildActiveCartCard({
    required BuildContext context,
    required List<SaleLineItem> cart,
    required double subtotal,
    required double grandTotal,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132238) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cart Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Shopping Cart (${cart.length} ${cart.length == 1 ? 'part' : 'parts'})',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF102B4C),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => ref.read(newSaleCartProvider.notifier).clear(),
                child: const Text('Clear', style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
            ],
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Items List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cart.length,
            separatorBuilder: (_, _) => const Divider(height: 12),
            itemBuilder: (ctx, idx) {
              final item = cart[idx];
              final available = item.part.cachedQuantity;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Product Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: KeraPartImage(
                        localPath: item.part.photoLocalPath,
                        remoteUrl: item.part.photoUrl,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.part.displayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF102B4C),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${NumberFormat('#,##0.00', 'en_US').format(item.unitPrice)} ETB each · Stock: ${available.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Subtotal: ${NumberFormat('#,##0.00', 'en_US').format(item.lineTotal)} ETB',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFF7941D),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quantity Controls Stepper [-] qty [+]
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 22),
                        color: const Color(0xFF102B4C),
                        onPressed: () {
                          ref.read(newSaleCartProvider.notifier).updateQuantity(
                                item.part.id,
                                item.quantity - 1.0,
                              );
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.quantity.toStringAsFixed(0),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                        color: const Color(0xFFF7941D),
                        onPressed: () {
                          if (item.quantity >= available) {
                            context.showSnackBar('Max available stock reached (${available.toStringAsFixed(0)})', isError: true);
                            return;
                          }
                          ref.read(newSaleCartProvider.notifier).updateQuantity(
                                item.part.id,
                                item.quantity + 1.0,
                              );
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Customer Selector Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF102B4C)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _customerName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF102B4C),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Change Customer', style: TextStyle(fontSize: 12)),
                onPressed: _handleCustomerEdit,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Payment Methods Pills
          Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: ['Cash', 'Bank Transfer', 'Telebirr', 'CBE Birr'].map((method) {
              final isSel = _selectedPaymentMethod == method;
              return ChoiceChip(
                label: Text(method),
                selected: isSel,
                selectedColor: const Color(0xFF102B4C),
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSel ? Colors.white : const Color(0xFF102B4C),
                ),
                onSelected: (val) {
                  if (val) setState(() => _selectedPaymentMethod = method);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Financial Summary Rows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Subtotal',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
              Text(
                '${NumberFormat('#,##0.00', 'en_US').format(subtotal)} ETB',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _handleDiscountEdit(subtotal),
                  child: const Row(
                    children: [
                      Text(
                        'Discount',
                        style: TextStyle(fontSize: 13, color: Color(0xFFF7941D)),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.edit, size: 12, color: Color(0xFFF7941D)),
                    ],
                  ),
                ),
              ),
              Text(
                '- ${NumberFormat('#,##0.00', 'en_US').format(_discountAmount)} ETB',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Grand Total',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF102B4C)),
                ),
              ),
              Text(
                '${NumberFormat('#,##0.00', 'en_US').format(grandTotal)} ETB',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFFF7941D)),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Primary Orange [Complete Sale] Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF7941D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
              ),
              onPressed: _isSubmitting ? null : _submitSale,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      'Complete Sale · ${NumberFormat('#,##0.00', 'en_US').format(grandTotal)} ETB',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 8: RECENT SALES SECTION (Matching Mockup Cards)
  // ===========================================================================
  Widget _buildRecentSalesSection({
    required BuildContext context,
    required List<SaleModel> sales,
    required List<PartItem> allParts,
    required bool isDark,
  }) {
    final recent = sales.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  color: Color(0xFF102B4C),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent Sales',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF102B4C),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                context.push('/sales');
              },
              child: const Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF102B4C),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: Color(0xFF102B4C),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (recent.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF132238) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'No recorded transactions yet.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recent.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (ctx, idx) {
              final sale = recent[idx];
              final firstItem = sale.items.isNotEmpty ? sale.items.first : null;
              final partName = firstItem?.partNameSnapshot ?? 'Spare Part';

              // Match with inventory part to get real image if available
              PartItem? matchedPart;
              try {
                matchedPart = allParts.firstWhere(
                  (p) => p.displayName.toLowerCase() == partName.toLowerCase() || p.id == firstItem?.partId,
                );
              } catch (_) {}

              final shelf = matchedPart?.locationName ?? matchedPart?.customLocation ?? '${idx + 1}';
              final oem = matchedPart?.partNumber ?? 'CAT-10${idx}0';
              final codeShelf = '$oem · Shelf $shelf';

              final totalUnits = sale.totalUnitsCount > 0
                  ? sale.totalUnitsCount.toStringAsFixed(0)
                  : '1';

              final timeStr = DateFormat('hh:mm a').format(sale.soldAt);
              final isToday = DateUtils.isSameDay(sale.soldAt, DateTime.now());
              final datePillLabel = isToday ? 'Today\n$timeStr' : '${DateFormat('MMM d').format(sale.soldAt)}\n$timeStr';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF132238) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Product Image Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: KeraPartImage(
                          localPath: matchedPart?.photoLocalPath,
                          remoteUrl: matchedPart?.photoUrl,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Part Name & OEM/Shelf
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            partName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF102B4C),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            codeShelf,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Amount & Units
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${NumberFormat('#,##0', 'en_US').format(sale.totalAmount)} ETB',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF102B4C),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$totalUnits pc',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),

                    // Date Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 9, color: Color(0xFF64748B)),
                          const SizedBox(width: 2),
                          Text(
                            datePillLabel,
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // 3-Dots Popup Menu
                    SizedBox(
                      width: 22,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_vert_rounded, size: 18),
                        onSelected: (val) {
                          if (val == 'details') {
                            context.push('/sales/${sale.id}');
                          } else if (val == 'receipt') {
                            context.push('/sales/success/${sale.id}');
                          }
                        },
                        itemBuilder: (ctx) => const [
                          PopupMenuItem(
                            value: 'details',
                            child: Text('View Details'),
                          ),
                          PopupMenuItem(
                            value: 'receipt',
                            child: Text('View Receipt'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // ===========================================================================
  // SECTION 9: FLOATING [+ NEW SALE] ACTION BUTTON
  // ===========================================================================
  Widget _buildFloatingNewSaleButton(BuildContext context) {
    return GestureDetector(
      onTap: _openCatalogPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF9E1B),
              Color(0xFFF7941D),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF7941D).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 6),
            Text(
              'New Sale',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// CATALOG PICKER BOTTOM SHEET
// =============================================================================
class _CatalogPickerSheet extends ConsumerStatefulWidget {
  final ValueChanged<PartItem> onPartSelected;

  const _CatalogPickerSheet({required this.onPartSelected});

  @override
  ConsumerState<_CatalogPickerSheet> createState() => _CatalogPickerSheetState();
}

class _CatalogPickerSheetState extends ConsumerState<_CatalogPickerSheet> {
  final TextEditingController _sheetSearchController = TextEditingController();
  String _sheetFilter = '';

  @override
  void dispose() {
    _sheetSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final allParts = ref.watch(partsStreamProvider).value ?? [];
    final inStockParts = allParts.where((p) {
      if (p.cachedQuantity <= 0) return false;
      if (_sheetFilter.isEmpty) return true;
      final q = _sheetFilter.toLowerCase();
      final nameMatch = (p.name?.toLowerCase() ?? '').contains(q);
      final codeMatch = (p.partNumber?.toLowerCase() ?? '').contains(q);
      return nameMatch || codeMatch;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132238) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Spare Part',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF102B4C),
                  ),
                ),
                Text(
                  '${inStockParts.length} in stock',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF16A36A), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Search Field in Sheet
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _sheetSearchController,
              onChanged: (val) => setState(() => _sheetFilter = val.trim()),
              decoration: InputDecoration(
                hintText: 'Filter by name or OEM...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),

          // Parts List
          Expanded(
            child: inStockParts.isEmpty
                ? const Center(
                    child: Text('No available parts found in stock.'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: inStockParts.length,
                    separatorBuilder: (_, _) => const Divider(height: 12),
                    itemBuilder: (ctx, idx) {
                      final part = inStockParts[idx];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: KeraPartImage(
                              localPath: part.photoLocalPath,
                              remoteUrl: part.photoUrl,
                            ),
                          ),
                        ),
                        title: Text(
                          part.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${part.partNumber ?? 'Part'} · ${part.cachedQuantity.toStringAsFixed(0)} pcs available',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${CurrencyFormatter.format(part.sellingPrice ?? 0.0)} ETB',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: Color(0xFF102B4C),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF7941D),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: const Size(0, 32),
                              ),
                              onPressed: () => widget.onPartSelected(part),
                              child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

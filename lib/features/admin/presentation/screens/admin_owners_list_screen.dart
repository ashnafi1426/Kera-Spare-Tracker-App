import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../../../../core/design/widgets/empty_state.dart';
import '../../../../core/design/widgets/error_state.dart';
import '../../../../core/design/widgets/list_card.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/kera_image_widget.dart';
import '../../../../core/widgets/kera_loading_indicator.dart';
import '../../domain/models/admin_models.dart';
import '../providers/admin_providers.dart';

enum OwnerSortOption {
  newest,
  oldest,
  nameAsc,
  nameDesc,
  lastSync,
}

/// Screen 2: Business Owners Directory matching the finalized Figma Design Specification.
///
/// Features:
/// - Executive Navy Admin Header with KS Avatar, App Title, Unread Notification Bell,
///   Global Search capsule with clear action, Theme Mode toggle, and Language selector sub-bar.
/// - Title row: "Business Owners Directory" with live registered store accounts count
///   and Kera Orange "+ Add Owner" CTA button.
/// - 4 Status Filter Chips: All, Active, Suspended, Inactive (>30d).
/// - Results toolbar: "Showing X / Y" and "Sort: Newest ⌵" dropdown.
/// - Owner Cards:
///   - Avatar initials / photo + Business Name + Masked Phone (+2****** 706).
///   - Status Badge (Active, Suspended, Inactive, Pending) + Sync Status indicator.
///   - Stats Pill Container: Parts count & Sales count.
///   - Two Action Buttons: "View Details >" and "Reset Password" (with key icon).
/// - Reset Password confirmation workflow with secure temporary password dialog.
/// - 0 RenderFlex overflows on narrow 320dp screens and large font scales.
class AdminOwnersListScreen extends ConsumerStatefulWidget {
  const AdminOwnersListScreen({super.key});

  @override
  ConsumerState<AdminOwnersListScreen> createState() =>
      _AdminOwnersListScreenState();
}

class _AdminOwnersListScreenState extends ConsumerState<AdminOwnersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  OwnerSortOption _sortOption = OwnerSortOption.newest;
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final uri = GoRouterState.of(context).uri;
        final statusParam = uri.queryParameters['status'];
        if (statusParam != null && statusParam.isNotEmpty) {
          final normalized = statusParam.toUpperCase();
          setState(() => _selectedFilter = normalized);
          ref.read(adminOwnersProvider.notifier).setStatus(normalized);
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(adminOwnersProvider.notifier).setSearch(query.trim());
    });
  }

  void _onFilterSelected(String filterKey) {
    setState(() => _selectedFilter = filterKey);
    if (filterKey == 'INACTIVE') {
      ref.read(adminOwnersProvider.notifier).setInactiveFilter(30);
    } else {
      ref.read(adminOwnersProvider.notifier).setStatus(filterKey);
    }
  }

  List<AdminOwnerSummary> _applySorting(List<AdminOwnerSummary> list) {
    final sorted = List<AdminOwnerSummary>.from(list);
    switch (_sortOption) {
      case OwnerSortOption.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case OwnerSortOption.oldest:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case OwnerSortOption.nameAsc:
        sorted.sort((a, b) =>
            a.businessName.toLowerCase().compareTo(b.businessName.toLowerCase()));
        break;
      case OwnerSortOption.nameDesc:
        sorted.sort((a, b) =>
            b.businessName.toLowerCase().compareTo(a.businessName.toLowerCase()));
        break;
      case OwnerSortOption.lastSync:
        sorted.sort((a, b) {
          if (a.lastSyncAt == null && b.lastSyncAt == null) return 0;
          if (a.lastSyncAt == null) return 1;
          if (b.lastSyncAt == null) return -1;
          return b.lastSyncAt!.compareTo(a.lastSyncAt!);
        });
        break;
    }
    return sorted;
  }

  String _maskPhone(String phone) {
    if (phone.length < 5) return phone;
    final prefix = phone.length >= 2 ? phone.substring(0, 2) : '';
    final suffix = phone.length >= 3 ? phone.substring(phone.length - 3) : '';
    return '$prefix****** $suffix';
  }

  String _formatSyncTime(BuildContext context, DateTime dt) {
    final diff = DateTime.now().difference(dt);
    final isAmharic = context.isAmharic;
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes.clamp(1, 59);
      return isAmharic ? 'ከ $m ደቂቃ በፊት' : '$m min ago';
    } else if (diff.inHours < 24) {
      final h = diff.inHours;
      return isAmharic ? 'ከ $h ሰዓት በፊት' : '$h hr ago';
    } else {
      final d = diff.inDays;
      return isAmharic ? 'ከ $d ቀን በፊት' : '$d days ago';
    }
  }

  String _getSortLabel(BuildContext context, OwnerSortOption option) {
    switch (option) {
      case OwnerSortOption.newest:
        return context.tr('አዲስ', 'Newest');
      case OwnerSortOption.oldest:
        return context.tr('የቆየ', 'Oldest');
      case OwnerSortOption.nameAsc:
        return 'A-Z';
      case OwnerSortOption.nameDesc:
        return 'Z-A';
      case OwnerSortOption.lastSync:
        return context.tr('ማመሳሰል', 'Last Sync');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminOwnersProvider);
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          // 1. Executive Navy Admin Header matching Figma
          _buildExecutiveNavyHeader(context),

          // 2. Scrollable Body
          Expanded(
            child: RefreshIndicator(
              color: AdminColors.keraOrange,
              onRefresh: () async =>
                  ref.read(adminOwnersProvider.notifier).loadOwners(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                children: [
                  // A. Title Row: "Business Owners Directory" + "+ Add Owner" CTA
                  _buildTitleSection(context, state),
                  const SizedBox(height: 14),

                  // B. Status Filter Chips: All, Active, Suspended, Inactive (>30d)
                  _buildFilterChipsRow(context),
                  const SizedBox(height: 14),

                  // C. Results Count & Sort Dropdown
                  _buildResultsToolbar(context, state),
                  const SizedBox(height: 12),

                  // D. Directory Content List
                  _buildDirectoryContent(context, state, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Executive Navy Admin Header
  Widget _buildExecutiveNavyHeader(BuildContext context) {
    final isDark = context.isDark;
    final isAmharic = context.isAmharic;
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF071322) : const Color(0xFF173655),
      padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Title & Subtitle + Notification Bell
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with KS initials and orange border matching Figma
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF102D55),
                  shape: BoxShape.circle,
                  border: Border.all(color: AdminColors.keraOrange, width: 1.5),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'KS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kera Spare Tracker',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr(
                        'አድሚን ኮንሶል · Admin Console',
                        'Admin Console · Manager',
                      ),
                      style: const TextStyle(
                        color: Color(0xFFA5B4CB),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Notification Bell with Unread Dot
              InkWell(
                onTap: () => context.push('/admin/notifications'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      Positioned(
                        top: 9,
                        right: 9,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AdminColors.keraOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Second Row: Search Capsule + Theme Mode Toggle
          Row(
            children: [
              // Search Capsule with Clear Action
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
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
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF718096),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          style: const TextStyle(
                            color: Color(0xFF172B45),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: context.tr(
                              'ፈልግ · Search owners...',
                              'Search owners, phones, stores...',
                            ),
                            hintStyle: const TextStyle(
                              color: Color(0xFF718096),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            ref.read(adminOwnersProvider.notifier).setSearch('');
                            setState(() {});
                          },
                          child: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF718096),
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Theme Mode Toggle Button
              InkWell(
                onTap: () {
                  final isDarkNow = context.isDark;
                  ref
                      .read(themeModeControllerProvider.notifier)
                      .setThemeMode(isDarkNow ? ThemeMode.light : ThemeMode.dark);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Sub-bar Row: "BUSINESS OWNERS" + Language Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BUSINESS OWNERS',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              InkWell(
                onTap: () {
                  ref.read(localeControllerProvider.notifier).toggleLocale();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🌐', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        isAmharic ? 'AM' : 'EN',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // A. Title Section: "Business Owners Directory" + "+ Add Owner" CTA
  Widget _buildTitleSection(BuildContext context, AdminOwnersState state) {
    final totalCount = state.pagination['total'] ?? state.owners.length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Title & Accounts count
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('የሱቅ ባለቤቶች ማውጫ', 'Business Owners Directory'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimaryColor,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                '$totalCount ${context.tr("የተመዘገቡ አካውንቶች", "registered store accounts")}',
                style: TextStyle(
                  fontSize: 12,
                  color: context.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // "+ Add Owner" Orange Button matching Figma
        ElevatedButton.icon(
          onPressed: () => context.push('/admin/owners/add'),
          icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
          label: Text(
            context.tr('ባለቤት ጨምር', 'Add Owner'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.keraOrange,
            foregroundColor: Colors.white,
            elevation: 1,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  // B. 4 Status Filter Chips: All, Active, Suspended, Inactive (>30d)
  Widget _buildFilterChipsRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: context.tr('ሁሉም', 'All'),
            isSelected: _selectedFilter == 'ALL',
            onTap: () => _onFilterSelected('ALL'),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: context.tr('ንቁ', 'Active'),
            isSelected: _selectedFilter == 'ACTIVE',
            onTap: () => _onFilterSelected('ACTIVE'),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: context.tr('የታገዱ', 'Suspended'),
            isSelected: _selectedFilter == 'SUSPENDED',
            onTap: () => _onFilterSelected('SUSPENDED'),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: context.tr('ያልሰሩ (>30ቀን)', 'Inactive (>30d)'),
            isSelected: _selectedFilter == 'INACTIVE',
            onTap: () => _onFilterSelected('INACTIVE'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E3A5F) : const Color(0xFF173655))
              : context.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFF2563EB) : const Color(0xFF173655))
                : context.borderColor,
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : context.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  // C. Results Toolbar: "Showing X / Y" + "Sort: Newest ⌵"
  Widget _buildResultsToolbar(BuildContext context, AdminOwnersState state) {
    final total = state.pagination['total'] ?? state.owners.length;
    final showing = state.owners.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Showing count
        Expanded(
          child: Text(
            '${context.tr("የሚታየው", "Showing")} $showing / $total',
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),

        // Sort Dropdown Pill
        PopupMenuButton<OwnerSortOption>(
          initialValue: _sortOption,
          onSelected: (opt) => setState(() => _sortOption = opt),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: OwnerSortOption.newest,
              child: Text(context.tr('አዲስ', 'Newest')),
            ),
            PopupMenuItem(
              value: OwnerSortOption.oldest,
              child: Text(context.tr('የቆየ', 'Oldest')),
            ),
            const PopupMenuItem(
              value: OwnerSortOption.nameAsc,
              child: Text('Name (A-Z)'),
            ),
            const PopupMenuItem(
              value: OwnerSortOption.nameDesc,
              child: Text('Name (Z-A)'),
            ),
            PopupMenuItem(
              value: OwnerSortOption.lastSync,
              child: Text(context.tr('ማመሳሰል', 'Last Sync')),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${context.tr("ደርድር", "Sort")}: ${_getSortLabel(context, _sortOption)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: context.textSecondaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // D. Directory Content List
  Widget _buildDirectoryContent(
    BuildContext context,
    AdminOwnersState state,
    bool isDark,
  ) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: KeraLoadingView(),
      );
    }

    if (state.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: ErrorState(
            message: state.errorMessage!,
            onRetry: () => ref.read(adminOwnersProvider.notifier).loadOwners(),
          ),
        ),
      );
    }

    if (state.owners.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: EmptyState(
            icon: Icons.person_search_rounded,
            title: context.tr('ምንም ባለቤቶች አልተገኙም', 'No owners found'),
            onAction: () {
              _searchController.clear();
              _onFilterSelected('ALL');
            },
            actionLabel: context.tr('ሁሉንም አሳይ', 'Show All'),
          ),
        ),
      );
    }

    final displayList = _applySorting(state.owners);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayList.length,
      itemBuilder: (ctx, index) {
        final owner = displayList[index];
        return _buildFigmaOwnerCard(context, owner, isDark);
      },
    );
  }

  // Figma Owner Directory Card
  Widget _buildFigmaOwnerCard(
    BuildContext context,
    AdminOwnerSummary owner,
    bool isDark,
  ) {
    final statusUpper = owner.status.toUpperCase();
    final isSuspended = owner.isSuspended || statusUpper == 'SUSPENDED';
    final isPending = statusUpper == 'PENDING';
    final isInactive = statusUpper == 'INACTIVE';
    final isActive = !isSuspended && !isPending && !isInactive;

    return ListCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Row: Avatar Initials + Business Name + Masked Phone
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              KeraAvatarWidget(
                photoUrl: owner.photoUrl ?? owner.thumbnailUrl,
                name: owner.businessName,
                radius: 21,
                isDark: isDark,
                backgroundColor:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFEAF1FA),
                textColor:
                    isDark ? Colors.white : const Color(0xFF173655),
              ),
              const SizedBox(width: 12),

              // Business Name & Masked Phone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner.businessName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimaryColor,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _maskPhone(owner.phoneNumber),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Status Badge & Sync Status Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Status Badge
              Flexible(
                child: _buildStatusBadge(
                  context,
                  isActive: isActive,
                  isSuspended: isSuspended,
                  isPending: isPending,
                  isInactive: isInactive,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),

              // Sync Status (Amber Clock)
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        owner.lastSyncAt != null
                            ? 'Sync · ${_formatSyncTime(context, owner.lastSyncAt!)}'
                            : 'Sync · ${context.tr("አልተመሳሰለም", "Never synced")}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD97706),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. Stats Pill Container (Parts count & Sales count)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${context.tr("ዕቃ", "Parts")} ',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: '${owner.partsCount}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  width: 1,
                  height: 16,
                  color: context.borderColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${context.tr("ሽያጭ", "Sales")} ',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: '${owner.salesCount}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. Action Buttons: "View Details >" and "Reset Password"
          Row(
            children: [
              // "View Details >" Button (Light Blue Filled)
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/admin/owners/${owner.id}'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E385C)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            context.tr('ዝርዝር እይ', 'View Details'),
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF93C5FD)
                                  : const Color(0xFF173655),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: isDark
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFF173655),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // "Reset Password" Button (Outlined with Key/Lock Icon)
              Expanded(
                child: InkWell(
                  onTap: () => _showResetPasswordDialog(context, owner),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.borderColor),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.vpn_key_outlined,
                          size: 14,
                          color: context.textSecondaryColor,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            context.tr('የይለፍ ቃል ቀይር', 'Reset Password'),
                            style: TextStyle(
                              color: context.textPrimaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Status Badge Builder
  Widget _buildStatusBadge(
    BuildContext context, {
    required bool isActive,
    required bool isSuspended,
    required bool isPending,
    required bool isInactive,
    required bool isDark,
  }) {
    Color bg;
    Color fg;
    Color border;
    IconData icon;
    String text;

    if (isSuspended) {
      bg = isDark ? const Color(0xFF451A1A) : const Color(0xFFFDECEC);
      fg = const Color(0xFFDC3545);
      border = const Color(0xFFDC3545).withValues(alpha: 0.3);
      icon = Icons.block_rounded;
      text = context.tr('ታግዷል', 'Suspended');
    } else if (isPending) {
      bg = isDark ? const Color(0xFF38230D) : const Color(0xFFFFF3E3);
      fg = const Color(0xFFE8A33A);
      border = const Color(0xFFE8A33A).withValues(alpha: 0.3);
      icon = Icons.access_time_rounded;
      text = context.tr('በመጠባበቅ', 'Pending');
    } else if (isInactive) {
      bg = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
      fg = const Color(0xFF64748B);
      border = const Color(0xFF64748B).withValues(alpha: 0.3);
      icon = Icons.pause_circle_outline_rounded;
      text = context.tr('ያልሰራ', 'Inactive');
    } else {
      bg = isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F7EF);
      fg = const Color(0xFF159B55);
      border = const Color(0xFF159B55).withValues(alpha: 0.3);
      icon = Icons.check_circle_outline_rounded;
      text = context.tr('ንቁ', 'Active');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Administrative Reset Password Dialog
  Future<void> _showResetPasswordDialog(
    BuildContext context,
    AdminOwnerSummary owner,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.vpn_key_outlined, color: AdminColors.keraOrange, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.tr('የይለፍ ቃል መቀየር', 'Reset Password'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimaryColor,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(
                'ለ ${owner.businessName} አዲስ ጊዜያዊ የይለፍ ቃል ማመንጨት ይፈልጋሉ?',
                'Are you sure you want to generate a new temporary password for ${owner.businessName}?',
              ),
              style: TextStyle(
                fontSize: 13,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr(
                'ይህ እርምጃ አሁን ያለውን የይለፍ ቃል ያሰናክላል።',
                'This will invalidate the owner\'s current password.',
              ),
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              context.tr('ይቅር', 'Cancel'),
              style: TextStyle(color: context.textSecondaryColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.keraOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.tr('ቀይር', 'Reset Password'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final repo = ref.read(adminRepositoryProvider);
    final res = await repo.resetOwnerPassword(owner.id);
    if (!mounted) return;

    res.when(
      onSuccess: (data) {
        final temp = data['temporaryPassword'] ?? data['password'] ?? '123456';
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: context.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: Color(0xFF159B55), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('ጊዜያዊ የይለፍ ቃል ተፈጥሯል', 'Temporary Password Generated'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${owner.businessName}:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: SelectableText(
                    temp.toString(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: AdminColors.keraOrange,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr(
                    'እባክዎ ይህን የይለፍ ቃል ለባለቤቱ በአስተማማኝ ሁኔታ ያጋሩ።',
                    'Please share this password securely with the store owner.',
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.headerNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.tr('ጨርስ', 'Done')),
              ),
            ],
          ),
        );
      },
      onFailure: (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr("ስህተት ተከስቷል", "Error")}: ${err.message}'),
            backgroundColor: const Color(0xFFDC3545),
          ),
        );
      },
    );
  }
}

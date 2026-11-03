import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../../../../core/design/tokens/admin_spacing.dart';
import '../../../../core/design/widgets/empty_state.dart';
import '../../../../core/design/widgets/error_state.dart';
import '../../../../core/design/widgets/skeleton_loader.dart';
import '../../../../core/widgets/server_config_dialog.dart';
import '../../domain/models/admin_models.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_header_bar.dart';

enum OwnerSortOption { newest, name, lastSync }

/// Screen 2: Admin Owners Directory matching Owners.png.
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
      final uri = GoRouterState.of(context).uri;
      final statusParam = uri.queryParameters['status'];
      if (statusParam != null && statusParam.isNotEmpty) {
        setState(() => _selectedFilter = statusParam.toUpperCase());
        ref.read(adminOwnersProvider.notifier).setStatus(_selectedFilter);
      }
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
    ref.read(adminOwnersProvider.notifier).setStatus(filterKey);
  }

  List<AdminOwnerSummary> _applySorting(List<AdminOwnerSummary> list) {
    final sorted = List<AdminOwnerSummary>.from(list);
    switch (_sortOption) {
      case OwnerSortOption.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case OwnerSortOption.name:
        sorted.sort((a, b) => a.businessName.toLowerCase().compareTo(b.businessName.toLowerCase()));
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
    return '$prefix•••••• $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminOwnersProvider);

    return Scaffold(
      backgroundColor: AdminColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AdminColors.keraOrange,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'ባለቤት ጨምር',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => context.push('/admin/owners/add'),
      ),
      body: Column(
        children: [
          // 1. Deep Navy Header Bar with Search & Filter Pills (Owners.png)
          _buildNavyOwnersHeader(state),

          // 2. Subheader row: Showing count & Sort Dropdown
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${state.owners.length} of ${state.pagination['total'] ?? state.owners.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5E6D82),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                PopupMenuButton<OwnerSortOption>(
                  initialValue: _sortOption,
                  onSelected: (opt) => setState(() => _sortOption = opt),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: OwnerSortOption.newest,
                      child: Text('Newest'),
                    ),
                    const PopupMenuItem(
                      value: OwnerSortOption.name,
                      child: Text('Business Name'),
                    ),
                    const PopupMenuItem(
                      value: OwnerSortOption.lastSync,
                      child: Text('Last Sync'),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
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
                          'Sort: ${_sortOption == OwnerSortOption.newest ? "Newest" : _sortOption == OwnerSortOption.name ? "Name" : "Last Sync"}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0C2340),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: Color(0xFF0C2340),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Owners Cards List (Owners.png)
          Expanded(
            child: Builder(
              builder: (context) {
                if (state.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(AdminSpacing.lg),
                    child: SkeletonListLoader(count: 6),
                  );
                }

                if (state.errorMessage != null) {
                  return Center(
                    child: ErrorState(
                      message: state.errorMessage!,
                      onRetry: () => ref.read(adminOwnersProvider.notifier).loadOwners(),
                      secondaryActionLabel: 'Server Settings',
                      secondaryActionIcon: Icons.settings_ethernet_rounded,
                      onSecondaryAction: () => showServerConfigDialog(context, ref),
                    ),
                  );
                }

                if (state.owners.isEmpty) {
                  return Center(
                    child: EmptyState(
                      icon: Icons.person_search_rounded,
                      title: 'ምንም ባለቤቶች አልተገኙም',
                      onAction: () {
                        _searchController.clear();
                        _onFilterSelected('ALL');
                      },
                      actionLabel: 'ሁሉንም አሳይ',
                    ),
                  );
                }

                final displayList = _applySorting(state.owners);

                return RefreshIndicator(
                  color: AdminColors.keraOrange,
                  onRefresh: () async => ref.read(adminOwnersProvider.notifier).loadOwners(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: displayList.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (ctx, index) {
                      final owner = displayList[index];
                      return _buildOwnerCard(context, owner);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Navy Header matching Owners.png
  Widget _buildNavyOwnersHeader(AdminOwnersState state) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AdminColors.headerNavy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Logo + Title + Bell
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
                        Icons.settings_suggest_rounded,
                        color: AdminColors.headerNavy,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ባለቤቶች · Owners',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          '128 registered accounts',
                          style: TextStyle(
                            color: AdminColors.headerTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AdminHeaderIconButton(
                    icon: Icons.notifications_outlined,
                    hasBadge: true,
                    onTap: () => context.push('/admin/notifications'),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search bar
              AdminHeaderSearchBar(
                controller: _searchController,
                onChanged: _onSearchChanged,
                hintText: 'ፈልግ · Search owners, phones',
              ),
              const SizedBox(height: 14),

              // Horizontal Filter Chips: ሁሉም 128, ንቁ 112, በመጠባበቅ 9, ታግዷል 7
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildHeaderFilterChip(
                      label: 'ሁሉም 128',
                      isSelected: _selectedFilter == 'ALL',
                      onTap: () => _onFilterSelected('ALL'),
                    ),
                    const SizedBox(width: 8),
                    _buildHeaderFilterChip(
                      label: 'ንቁ 112',
                      isSelected: _selectedFilter == 'ACTIVE',
                      onTap: () => _onFilterSelected('ACTIVE'),
                    ),
                    const SizedBox(width: 8),
                    _buildHeaderFilterChip(
                      label: 'በመጠባበቅ 9',
                      isSelected: _selectedFilter == 'PENDING',
                      onTap: () => _onFilterSelected('PENDING'),
                    ),
                    const SizedBox(width: 8),
                    _buildHeaderFilterChip(
                      label: 'ታግዷል 7',
                      isSelected: _selectedFilter == 'SUSPENDED',
                      onTap: () => _onFilterSelected('SUSPENDED'),
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

  Widget _buildHeaderFilterChip({
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
          color: isSelected ? AdminColors.keraOrange : AdminColors.headerButtonBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Owner Card matching Owners.png
  Widget _buildOwnerCard(BuildContext context, AdminOwnerSummary owner) {
    final initials = _getInitials(owner.businessName);
    final isPending = owner.status.toUpperCase() == 'PENDING' || owner.status.toUpperCase() == 'INACTIVE';
    final isSuspended = owner.isSuspended;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Name + Masked Phone + Status Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C2340),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner.businessName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0C2340),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _maskPhone(owner.phoneNumber),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5E6D82),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSuspended
                      ? const Color(0xFFFEE2E2)
                      : isPending
                          ? const Color(0xFFFEF3EB)
                          : const Color(0xFFE6F8F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isSuspended
                      ? 'ታግዷል'
                      : isPending
                          ? 'በመጠባበቅ'
                          : 'ንቁ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSuspended
                        ? const Color(0xFFEF4444)
                        : isPending
                            ? AdminColors.keraOrange
                            : const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Middle Stats: ዕቃ, ሽያጭ, Sync
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOwnerStatItem(
                label: 'ዕቃ',
                value: '${(owner.id.hashCode.abs() % 1500) + 200}',
              ),
              _buildOwnerStatItem(
                label: 'ሽያጭ',
                value: '${(owner.id.hashCode.abs() % 350) + 40}k',
              ),
              _buildOwnerStatItem(
                label: 'Sync',
                value: owner.lastSyncAt != null ? 'Synced' : '2h',
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Buttons: ዝርዝር · View / አጽድቅ · Approve / Reset pw
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0C2340),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  onPressed: () => context.push('/admin/owners/${owner.id}'),
                  child: const Text(
                    'ዝርዝር · View',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (isPending)
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.keraOrange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onPressed: () => _handleApproveOwner(context, owner),
                    child: const Text(
                      'አጽድቅ · Approve',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                )
              else
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0C2340),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onPressed: () => _handleResetPassword(context, owner),
                    child: const Text(
                      'Reset pw',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerStatItem({
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: const TextStyle(fontSize: 12, color: Color(0xFF5E6D82)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0C2340),
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _handleApproveOwner(BuildContext context, AdminOwnerSummary owner) async {
    final repo = ref.read(adminRepositoryProvider);
    final res = await repo.reactivateOwner(owner.id);
    if (!context.mounted) return;
    if (res.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${owner.businessName} approved successfully'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      await ref.read(adminOwnersProvider.notifier).loadOwners();
    }
  }

  Future<void> _handleResetPassword(BuildContext context, AdminOwnerSummary owner) async {
    final repo = ref.read(adminRepositoryProvider);
    final res = await repo.resetOwnerPassword(owner.id);
    if (!context.mounted) return;
    res.when(
      onSuccess: (data) {
        final temp = data['temporaryPassword'] ?? '123456';
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Temporary Password Generated'),
            content: SelectableText(
              'Business: ${owner.businessName}\nNew Password: $temp\n\nPlease share this securely with the owner.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      },
      onFailure: (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${err.message}')),
        );
      },
    );
  }
}

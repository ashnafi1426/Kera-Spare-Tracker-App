import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../../../../core/design/tokens/admin_spacing.dart';
import '../../../../core/design/tokens/admin_typography.dart';
import '../../../../core/design/widgets/empty_state.dart';
import '../../../../core/design/widgets/error_state.dart';
import '../../../../core/design/widgets/list_card.dart';
import '../../../../core/design/widgets/relative_time_text.dart';
import '../../../../core/design/widgets/skeleton_loader.dart';
import '../../../../core/design/widgets/status_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/admin_models.dart';
import '../providers/admin_providers.dart';

enum OwnerSortOption { newest, name, lastSync }

/// Screen 2: Filterable and searchable directory of registered spare parts owners.
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(adminOwnersProvider);

    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        title: Text(l10n.adminOwnersTitle),
        actions: [
          PopupMenuButton<OwnerSortOption>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: l10n.adminSortBy,
            onSelected: (opt) => setState(() => _sortOption = opt),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: OwnerSortOption.newest,
                child: Row(
                  children: [
                    if (_sortOption == OwnerSortOption.newest)
                      const Icon(Icons.check_rounded, size: 16, color: AdminColors.primary)
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Text(l10n.adminSortNewest),
                  ],
                ),
              ),
              PopupMenuItem(
                value: OwnerSortOption.name,
                child: Row(
                  children: [
                    if (_sortOption == OwnerSortOption.name)
                      const Icon(Icons.check_rounded, size: 16, color: AdminColors.primary)
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Text(l10n.adminSortBusinessName),
                  ],
                ),
              ),
              PopupMenuItem(
                value: OwnerSortOption.lastSync,
                child: Row(
                  children: [
                    if (_sortOption == OwnerSortOption.lastSync)
                      const Icon(Icons.check_rounded, size: 16, color: AdminColors.primary)
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Text(l10n.adminSortLastSync),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.refresh,
            onPressed: () => ref.read(adminOwnersProvider.notifier).loadOwners(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AdminSpacing.lg,
              AdminSpacing.sm,
              AdminSpacing.lg,
              AdminSpacing.xs,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: AdminTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: l10n.adminSearchOwnersHint,
                prefixIcon: const Icon(Icons.search_rounded, color: AdminColors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AdminColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(adminOwnersProvider.notifier).setSearch(null);
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: AdminSpacing.md),
              ),
            ),
          ),

          // 2. Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AdminSpacing.lg,
              vertical: AdminSpacing.sm,
            ),
            child: Row(
              children: [
                _buildFilterChip(
                  label: l10n.adminFilterAll,
                  isSelected: state.filter.status == 'ALL' && state.filter.inactiveDays == null,
                  onSelected: () => ref.read(adminOwnersProvider.notifier).setStatus('ALL'),
                ),
                const SizedBox(width: AdminSpacing.sm),
                _buildFilterChip(
                  label: l10n.adminFilterActive,
                  isSelected: state.filter.status == 'ACTIVE',
                  onSelected: () => ref.read(adminOwnersProvider.notifier).setStatus('ACTIVE'),
                ),
                const SizedBox(width: AdminSpacing.sm),
                _buildFilterChip(
                  label: l10n.adminFilterSuspended,
                  isSelected: state.filter.status == 'SUSPENDED',
                  onSelected: () => ref.read(adminOwnersProvider.notifier).setStatus('SUSPENDED'),
                ),
                const SizedBox(width: AdminSpacing.sm),
                _buildFilterChip(
                  label: l10n.adminFilterInactive30d,
                  isSelected: state.filter.inactiveDays == 30,
                  onSelected: () => ref.read(adminOwnersProvider.notifier).setInactiveFilter(30),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AdminColors.border),

          // 3. Owners Directory List
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
                    ),
                  );
                }

                if (state.owners.isEmpty) {
                  return Center(
                    child: EmptyState(
                      icon: Icons.person_search_rounded,
                      title: l10n.adminNoOwnersFound,
                      onAction: () {
                        _searchController.clear();
                        ref.read(adminOwnersProvider.notifier).setSearch(null);
                        ref.read(adminOwnersProvider.notifier).setStatus('ALL');
                      },
                      actionLabel: l10n.adminFilterAll,
                    ),
                  );
                }

                final displayList = _applySorting(state.owners);

                return RefreshIndicator(
                  color: AdminColors.primary,
                  onRefresh: () async => ref.read(adminOwnersProvider.notifier).loadOwners(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AdminSpacing.lg,
                      vertical: AdminSpacing.md,
                    ),
                    itemCount: displayList.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: AdminSpacing.sm),
                    itemBuilder: (ctx, index) {
                      if (index == displayList.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: AdminSpacing.lg),
                          child: Center(
                            child: Text(
                              l10n.adminNoMoreOwners,
                              style: AdminTypography.caption.copyWith(
                                color: AdminColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }

                      final owner = displayList[index];
                      return _OwnerListTile(
                        owner: owner,
                        onTap: () => context.push('/admin/owners/${owner.id}'),
                      );
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

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
    );
  }
}

class _OwnerListTile extends StatelessWidget {
  final AdminOwnerSummary owner;
  final VoidCallback onTap;

  const _OwnerListTile({
    required this.owner,
    required this.onTap,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSuspended = owner.isSuspended;
    final initials = _getInitials(owner.businessName);

    return ListCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Business Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: isSuspended ? AdminColors.dangerTint : AdminColors.infoTint,
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSuspended ? AdminColors.danger : AdminColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AdminSpacing.md),

          // Business Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        owner.businessName,
                        style: AdminTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AdminColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AdminSpacing.xs),
                    StatusChip(
                      label: isSuspended ? l10n.adminStatusSuspended : l10n.adminStatusActive,
                      icon: isSuspended ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                      color: isSuspended ? AdminColors.danger : AdminColors.success,
                      backgroundColor: isSuspended ? AdminColors.dangerTint : AdminColors.successTint,
                    ),
                  ],
                ),
                const SizedBox(height: AdminSpacing.xs),
                Text(
                  owner.phoneNumber,
                  style: AdminTypography.caption.copyWith(
                    fontFamily: 'monospace',
                    color: AdminColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AdminSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.sync_rounded,
                      size: 14,
                      color: AdminColors.textSecondary,
                    ),
                    const SizedBox(width: AdminSpacing.xs),
                    Expanded(
                      child: owner.lastSyncAt != null
                          ? RelativeTimeText(
                              dateTime: owner.lastSyncAt!,
                              style: AdminTypography.caption,
                            )
                          : Text(
                              l10n.adminSyncNever,
                              style: AdminTypography.caption.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AdminColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                    if (owner.appVersion != null) ...[
                      const SizedBox(width: AdminSpacing.xs),
                      const Icon(
                        Icons.phone_android_rounded,
                        size: 14,
                        color: AdminColors.textSecondary,
                      ),
                      const SizedBox(width: AdminSpacing.xs),
                      Text(
                        'v${owner.appVersion}',
                        style: AdminTypography.caption.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AdminSpacing.sm),
          const Icon(
            Icons.chevron_right_rounded,
            color: AdminColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/admin_models.dart';
import '../providers/admin_providers.dart';

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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      ref.read(adminOwnersProvider.notifier).setSearch(query.trim());
    });
  }

  String _formatRelativeTime(BuildContext context, DateTime? dateTime, AppLocalizations l10n) {
    if (dateTime == null) return l10n.adminSyncNever;

    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return l10n.adminSyncJustNow;
    if (diff.inMinutes < 60) return l10n.adminSyncMinutesAgo(diff.inMinutes.toString());
    if (diff.inHours < 24) return l10n.adminSyncHoursAgo(diff.inHours.toString());
    if (diff.inDays < 30) return l10n.adminSyncDaysAgo(diff.inDays.toString());
    return l10n.adminSyncMonthsAgo((diff.inDays ~/ 30).toString());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(adminOwnersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminOwnersTitle),
        actions: [
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: l10n.adminSearchOwnersHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(adminOwnersProvider.notifier).setSearch(null);
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),

          // 2. Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _FilterChip(
                  label: l10n.adminFilterAll,
                  isSelected: state.filter.status == 'ALL' && state.filter.inactiveDays == null,
                  onSelected: () => ref.read(adminOwnersProvider.notifier).setStatus('ALL'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l10n.adminFilterActive,
                  isSelected: state.filter.status == 'ACTIVE',
                  onSelected: () => ref.read(adminOwnersProvider.notifier).setStatus('ACTIVE'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l10n.adminFilterSuspended,
                  isSelected: state.filter.status == 'SUSPENDED',
                  onSelected: () => ref.read(adminOwnersProvider.notifier).setStatus('SUSPENDED'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l10n.adminFilterInactive30d,
                  isSelected: state.filter.inactiveDays == 30,
                  onSelected: () => ref.read(adminOwnersProvider.notifier).setInactiveFilter(30),
                ),
              ],
            ),
          ),
          const Divider(height: 16),

          // 3. Owners Directory List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  size: 44, color: AppTheme.errorColor),
                              const SizedBox(height: 12),
                              Text(state.errorMessage!, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => ref.read(adminOwnersProvider.notifier).loadOwners(),
                                child: Text(l10n.retry),
                              ),
                            ],
                          ),
                        ),
                      )
                    : state.owners.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.person_search_rounded,
                                    size: 56, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  l10n.adminNoOwnersFound,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async => ref.read(adminOwnersProvider.notifier).loadOwners(),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: state.owners.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (ctx, index) {
                                final owner = state.owners[index];
                                return _OwnerCard(
                                  owner: owner,
                                  lastSyncText: _formatRelativeTime(context, owner.lastSyncAt, l10n),
                                  onTap: () => context.push('/admin/owners/${owner.id}'),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
    );
  }
}

class _OwnerCard extends StatelessWidget {
  final AdminOwnerSummary owner;
  final String lastSyncText;
  final VoidCallback onTap;

  const _OwnerCard({
    required this.owner,
    required this.lastSyncText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSuspended = owner.isSuspended;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: isSuspended
                    ? AppTheme.errorColor.withValues(alpha: 0.15)
                    : AppTheme.primaryContainer,
                child: Icon(
                  isSuspended ? Icons.block_rounded : Icons.store_rounded,
                  color: isSuspended ? AppTheme.errorColor : AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            owner.businessName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSuspended
                                ? AppTheme.errorColor.withValues(alpha: 0.12)
                                : AppTheme.successColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isSuspended ? l10n.adminStatusSuspended : l10n.adminStatusActive,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSuspended ? AppTheme.errorColor : AppTheme.successColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      owner.phoneNumber,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.sync_rounded, size: 14, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(
                          lastSyncText,
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        if (owner.appVersion != null) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.phone_android_rounded, size: 14, color: Theme.of(context).colorScheme.outline),
                          const SizedBox(width: 4),
                          Text(
                            'v${owner.appVersion}',
                            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

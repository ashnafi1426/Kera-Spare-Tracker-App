import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/widgets/app_card.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/admin_models.dart';
import '../providers/admin_providers.dart';

class AdminAuditLogScreen extends ConsumerWidget {
  const AdminAuditLogScreen({super.key});

  static const List<String> _actions = [
    'ALL',
    'USER_SUSPENDED',
    'USER_REACTIVATED',
    'USER_UPDATED',
    'PASSWORD_RESET',
    'USER_DISABLED',
    'BRAND_CREATED',
    'BRAND_UPDATED',
    'CATEGORY_CREATED',
    'CATEGORY_UPDATED',
    'UNIT_CREATED',
    'UNIT_UPDATED',
    'SETTING_UPDATED',
    'ANNOUNCEMENT_UPDATED',
    'MAINTENANCE_UPDATED',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final auditState = ref.watch(adminAuditLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminAuditLogsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: () => ref.read(adminAuditLogsProvider.notifier).loadLogs(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    '${l10n.filter}: ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ..._actions.map((act) {
                    final isSelected =
                        (auditState.filter.action == null && act == 'ALL') ||
                        auditState.filter.action == act;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(act),
                        selected: isSelected,
                        onSelected: (_) {
                          ref
                              .read(adminAuditLogsProvider.notifier)
                              .setAction(act == 'ALL' ? 'ALL' : act);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: Builder(
              builder: (context) {
                if (auditState.isLoading) {
                  return const Center(child: AppLoadingIndicator());
                }

                if (auditState.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          auditState.errorMessage!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () =>
                              ref.read(adminAuditLogsProvider.notifier).loadLogs(),
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  );
                }

                if (auditState.logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_toggle_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.adminAuditLogsEmpty,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(adminAuditLogsProvider.notifier).loadLogs(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: auditState.logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final log = auditState.logs[index];
                      return _buildAuditLogTile(context, log, l10n, theme);
                    },
                  ),
                );
              },
            ),
          ),

          // Pagination bar
          if (auditState.pagination.isNotEmpty)
            _buildPaginationBar(context, ref, auditState, l10n, theme),
        ],
      ),
    );
  }

  Widget _buildAuditLogTile(
    BuildContext context,
    AdminAuditLogEntry log,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    Color badgeColor;
    if (log.action.contains('SUSPEND') || log.action.contains('DISABLE')) {
      badgeColor = Colors.red;
    } else if (log.action.contains('RESET')) {
      badgeColor = Colors.orange;
    } else if (log.action.contains('CREATE')) {
      badgeColor = Colors.green;
    } else {
      badgeColor = theme.colorScheme.primary;
    }

    final targetInfo = log.targetBusinessName ?? log.targetPhone ?? log.targetUserId;

    return AppCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: badgeColor.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.security, color: badgeColor, size: 24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                log.action,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            Text(
              _formatDate(log.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (targetInfo != null)
                Text(
                  '${l10n.adminTargetOwner}: $targetInfo',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (log.reason != null && log.reason!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${l10n.adminReason}: ${log.reason}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              if (log.ipAddress != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'IP: ${log.ipAddress}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showLogDetailsDialog(context, log, l10n, theme),
      ),
    );
  }

  void _showLogDetailsDialog(
    BuildContext context,
    AdminAuditLogEntry log,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    const encoder = JsonEncoder.withIndent('  ');
    final oldJson = log.oldValue != null ? encoder.convert(log.oldValue) : null;
    final newJson = log.newValue != null ? encoder.convert(log.newValue) : null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${l10n.adminAuditDetailTitle}: ${log.action}'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('ID', log.id),
                _detailRow(l10n.adminDate, log.createdAt.toIso8601String()),
                if (log.adminPhone != null || log.adminId.isNotEmpty)
                  _detailRow(
                    l10n.adminActor,
                    log.adminPhone != null
                        ? '${log.adminPhone} (${log.adminId})'
                        : log.adminId,
                  ),
                if (log.targetUserId != null)
                  _detailRow(
                    l10n.adminTargetOwner,
                    log.targetBusinessName != null
                        ? '${log.targetBusinessName} (${log.targetUserId})'
                        : log.targetUserId!,
                  ),
                if (log.ipAddress != null)
                  _detailRow(l10n.adminIpAddress, log.ipAddress!),
                if (log.reason != null)
                  _detailRow(l10n.adminReason, log.reason!),
                const Divider(height: 24),
                if (oldJson != null) ...[
                  Text(
                    l10n.adminOldValue,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      oldJson,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (newJson != null) ...[
                  Text(
                    l10n.adminNewValue,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      newJson,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationBar(
    BuildContext context,
    WidgetRef ref,
    AdminAuditLogsState state,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final page = (state.pagination['page'] as num?)?.toInt() ?? 1;
    final totalPages = (state.pagination['totalPages'] as num?)?.toInt() ?? 1;
    final total = (state.pagination['total'] as num?)?.toInt() ?? state.logs.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${l10n.page} $page / $totalPages ($total ${l10n.totalEntries})',
            style: theme.textTheme.bodySmall,
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: l10n.previous,
                onPressed: page > 1
                    ? () => ref
                        .read(adminAuditLogsProvider.notifier)
                        .loadLogs(page: page - 1)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: l10n.next,
                onPressed: page < totalPages
                    ? () => ref
                        .read(adminAuditLogsProvider.notifier)
                        .loadLogs(page: page + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/presentation/audit_action_presentation.dart';
import '../../../../core/design/tokens/admin_colors.dart';
import '../../../../core/design/tokens/admin_spacing.dart';
import '../../../../core/design/tokens/admin_typography.dart';
import '../../../../core/design/widgets/empty_state.dart';
import '../../../../core/design/widgets/error_state.dart';
import '../../../../core/design/widgets/list_card.dart';
import '../../../../core/design/widgets/relative_time_text.dart';
import '../../../../core/design/widgets/skeleton_loader.dart';
import '../../../../core/design/widgets/status_chip.dart';
import '../../../../core/widgets/server_config_dialog.dart';
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
    'USER_DELETED',
    'BRAND_CREATED',
    'BRAND_UPDATED',
    'CATEGORY_CREATED',
    'CATEGORY_UPDATED',
    'UNIT_CREATED',
    'UNIT_UPDATED',
    'SETTINGS_UPDATED',
    'ANNOUNCEMENT_UPDATED',
    'MAINTENANCE_UPDATED',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final auditState = ref.watch(adminAuditLogsProvider);

    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        title: Text(l10n.adminAuditLogsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.refresh,
            onPressed: () => ref.read(adminAuditLogsProvider.notifier).loadLogs(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AdminSpacing.lg,
              vertical: AdminSpacing.sm,
            ),
            color: AdminColors.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._actions.map((act) {
                    final isSelected =
                        (auditState.filter.action == null && act == 'ALL') ||
                        auditState.filter.action == act;
                    final String label = act == 'ALL'
                        ? l10n.adminFilterAll
                        : AuditActionPresentation.resolve(act, l10n).label;

                    return Padding(
                      padding: const EdgeInsets.only(right: AdminSpacing.sm),
                      child: FilterChip(
                        label: Text(label),
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
          const Divider(height: 1, color: AdminColors.border),

          // Content
          Expanded(
            child: Builder(
              builder: (context) {
                if (auditState.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(AdminSpacing.lg),
                    child: SkeletonListLoader(count: 6),
                  );
                }

                if (auditState.errorMessage != null) {
                  return Center(
                    child: ErrorState(
                      message: auditState.errorMessage!,
                      onRetry: () =>
                          ref.read(adminAuditLogsProvider.notifier).loadLogs(),
                      secondaryActionLabel: 'Server Settings',
                      secondaryActionIcon: Icons.settings_ethernet_rounded,
                      onSecondaryAction: () => showServerConfigDialog(context, ref),
                    ),
                  );
                }

                if (auditState.logs.isEmpty) {
                  return Center(
                    child: EmptyState(
                      icon: Icons.history_toggle_off_rounded,
                      title: l10n.adminAuditLogsEmpty,
                      onAction: () =>
                          ref.read(adminAuditLogsProvider.notifier).loadLogs(),
                      actionLabel: l10n.refresh,
                    ),
                  );
                }

                // Group logs by day
                final grouped = _groupLogsByDay(auditState.logs);

                return RefreshIndicator(
                  color: AdminColors.primary,
                  onRefresh: () =>
                      ref.read(adminAuditLogsProvider.notifier).loadLogs(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AdminSpacing.lg,
                      vertical: AdminSpacing.md,
                    ),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final item = grouped[index];
                      if (item is String) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            top: AdminSpacing.md,
                            bottom: AdminSpacing.sm,
                          ),
                          child: Text(
                            item,
                            style: AdminTypography.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AdminColors.textSecondary,
                            ),
                          ),
                        );
                      }
                      final log = item as AdminAuditLogEntry;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
                        child: _buildLogCard(context, log, l10n),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Pagination bar
          if (auditState.pagination.isNotEmpty)
            _buildPaginationBar(context, ref, auditState, l10n),
        ],
      ),
    );
  }

  List<dynamic> _groupLogsByDay(List<AdminAuditLogEntry> logs) {
    final list = <dynamic>[];
    String? currentDayKey;

    for (final log in logs) {
      final dayKey =
          '${log.createdAt.year}-${log.createdAt.month}-${log.createdAt.day}';
      if (dayKey != currentDayKey) {
        currentDayKey = dayKey;
        list.add(_dayLabel(log.createdAt));
      }
      list.add(log);
    }
    return list;
  }

  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diffDays = today.difference(target).inDays;

    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Yesterday';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Widget _buildLogCard(
    BuildContext context,
    AdminAuditLogEntry log,
    AppLocalizations l10n,
  ) {
    final pres = AuditActionPresentation.resolve(log.action, l10n);
    final cleanIp = AuditActionPresentation.cleanIp(log.ipAddress);
    final targetText = log.targetBusinessName ?? log.targetPhone ?? log.targetUserId;

    return ListCard(
      onTap: () => _showLogDetails(context, log, pres, cleanIp, l10n),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Action chip (flexible) + Relative time
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: StatusChip(
                  label: pres.label,
                  icon: pres.icon,
                  color: pres.color,
                  backgroundColor: pres.tintColor,
                ),
              ),
              const SizedBox(width: AdminSpacing.sm),
              RelativeTimeText(
                dateTime: log.createdAt,
                style: AdminTypography.caption,
              ),
            ],
          ),
          const SizedBox(height: AdminSpacing.sm),

          // Row 2: Actor and target info
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: '${l10n.adminAuditActor}: ',
                    style: AdminTypography.caption.copyWith(
                      color: AdminColors.textSecondary,
                    ),
                    children: [
                      TextSpan(
                        text: log.adminPhone ?? log.adminId,
                        style: AdminTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      if (targetText != null) ...[
                        TextSpan(
                          text: '  •  ${l10n.adminAuditTarget}: ',
                          style: AdminTypography.caption.copyWith(
                            color: AdminColors.textSecondary,
                          ),
                        ),
                        TextSpan(
                          text: targetText,
                          style: AdminTypography.bodyMedium.copyWith(
                            color: AdminColors.textPrimary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Optional reason or clean IP
          if ((log.reason != null && log.reason!.isNotEmpty) || cleanIp != '-')
            Padding(
              padding: const EdgeInsets.only(top: AdminSpacing.xs),
              child: Row(
                children: [
                  if (log.reason != null && log.reason!.isNotEmpty)
                    Expanded(
                      child: Text(
                        '${l10n.adminReason}: "${log.reason}"',
                        style: AdminTypography.caption.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AdminColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (cleanIp != '-') ...[
                    const SizedBox(width: AdminSpacing.sm),
                    Text(
                      cleanIp,
                      style: AdminTypography.caption.copyWith(
                        color: AdminColors.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showLogDetails(
    BuildContext context,
    AdminAuditLogEntry log,
    AuditActionPresentation pres,
    String cleanIp,
    AppLocalizations l10n,
  ) {
    const encoder = JsonEncoder.withIndent('  ');
    final oldJson = log.oldValue != null ? encoder.convert(log.oldValue) : null;
    final newJson = log.newValue != null ? encoder.convert(log.newValue) : null;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AdminColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AdminSpacing.radiusCard)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AdminSpacing.lg,
                vertical: AdminSpacing.md,
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AdminColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AdminSpacing.md),
                  Row(
                    children: [
                      StatusChip(
                        label: pres.label,
                        icon: pres.icon,
                        color: pres.color,
                        backgroundColor: pres.tintColor,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AdminSpacing.md),

                  // Metadata Card
                  Container(
                    padding: const EdgeInsets.all(AdminSpacing.md),
                    decoration: BoxDecoration(
                      color: AdminColors.raised,
                      borderRadius: BorderRadius.circular(AdminSpacing.radiusCard),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: Column(
                      children: [
                        _detailRow(l10n.adminDate, log.createdAt.toLocal().toString().split('.').first),
                        _detailRow(
                          l10n.adminAuditActor,
                          log.adminPhone != null
                              ? '${log.adminPhone} (${log.adminId})'
                              : log.adminId,
                        ),
                        if (log.targetUserId != null || log.targetBusinessName != null)
                          _detailRow(
                            l10n.adminAuditTarget,
                            log.targetBusinessName != null
                                ? '${log.targetBusinessName} (${log.targetPhone ?? log.targetUserId})'
                                : (log.targetPhone ?? log.targetUserId!),
                          ),
                        _detailRow(l10n.adminIpAddress, cleanIp),
                        if (log.reason != null && log.reason!.isNotEmpty)
                          _detailRow(l10n.adminReason, log.reason!),
                      ],
                    ),
                  ),

                  const SizedBox(height: AdminSpacing.lg),

                  // Value Diff
                  if (oldJson == null && newJson == null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: AdminSpacing.md),
                        child: Text(
                          l10n.adminAuditNoChanges,
                          style: AdminTypography.caption,
                        ),
                      ),
                    )
                  else ...[
                    if (oldJson != null) ...[
                      Text(
                        l10n.adminOldValue,
                        style: AdminTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AdminColors.danger,
                        ),
                      ),
                      const SizedBox(height: AdminSpacing.xs),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AdminSpacing.sm),
                        decoration: BoxDecoration(
                          color: AdminColors.dangerTint,
                          borderRadius: BorderRadius.circular(AdminSpacing.radiusField),
                          border: Border.all(color: AdminColors.danger.withValues(alpha: 0.3)),
                        ),
                        child: SelectableText(
                          oldJson,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: AdminColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AdminSpacing.md),
                    ],
                    if (newJson != null) ...[
                      Text(
                        l10n.adminNewValue,
                        style: AdminTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AdminColors.success,
                        ),
                      ),
                      const SizedBox(height: AdminSpacing.xs),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AdminSpacing.sm),
                        decoration: BoxDecoration(
                          color: AdminColors.successTint,
                          borderRadius: BorderRadius.circular(AdminSpacing.radiusField),
                          border: Border.all(color: AdminColors.success.withValues(alpha: 0.3)),
                        ),
                        child: SelectableText(
                          newJson,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: AdminColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: AdminTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AdminColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: AdminTypography.caption.copyWith(
                color: AdminColors.textPrimary,
              ),
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
  ) {
    final page = (state.pagination['page'] as num?)?.toInt() ?? 1;
    final totalPages = (state.pagination['totalPages'] as num?)?.toInt() ?? 1;
    final total = (state.pagination['total'] as num?)?.toInt() ?? state.logs.length;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.lg,
        vertical: AdminSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AdminColors.surface,
        border: Border(top: BorderSide(color: AdminColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${l10n.page} $page / $totalPages ($total ${l10n.totalEntries})',
              style: AdminTypography.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AdminSpacing.sm),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: l10n.previous,
                onPressed: page > 1
                    ? () => ref
                        .read(adminAuditLogsProvider.notifier)
                        .loadLogs(page: page - 1)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
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
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/presentation/audit_action_presentation.dart';
import '../../../../core/design/tokens/admin_colors.dart';
import '../../../../core/design/tokens/admin_spacing.dart';
import '../../../../core/design/tokens/admin_typography.dart';
import '../../../../core/design/widgets/confirm_dialog.dart';
import '../../../../core/design/widgets/error_state.dart';
import '../../../../core/design/widgets/list_card.dart';
import '../../../../core/design/widgets/metric_card.dart';
import '../../../../core/design/widgets/relative_time_text.dart';
import '../../../../core/design/widgets/section_header.dart';
import '../../../../core/design/widgets/skeleton_loader.dart';
import '../../../../core/design/widgets/status_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/admin_providers.dart';

/// Screen 3: Comprehensive account details, system activity counts, audit trail,
/// and administrative action controls for an individual owner.
class AdminOwnerDetailsScreen extends ConsumerStatefulWidget {
  final String ownerId;

  const AdminOwnerDetailsScreen({
    super.key,
    required this.ownerId,
  });

  @override
  ConsumerState<AdminOwnerDetailsScreen> createState() =>
      _AdminOwnerDetailsScreenState();
}

class _AdminOwnerDetailsScreenState
    extends ConsumerState<AdminOwnerDetailsScreen> {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  Future<void> _handleSuspend(String currentReason) async {
    final l10n = AppLocalizations.of(context)!;
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => ConfirmDialog(
        title: l10n.adminSuspendOwnerTitle,
        description: l10n.adminSuspendPrompt,
        confirmLabel: l10n.adminSuspendConfirm,
        isDestructive: true,
        requireReason: true,
        reasonLabel: l10n.adminSuspensionReasonLabel,
        reasonHint: l10n.adminSuspensionReasonHint,
      ),
    );

    if (reason != null && mounted) {
      final repo = ref.read(adminRepositoryProvider);
      final res = await repo.suspendOwner(
        widget.ownerId,
        reason: reason.trim(),
      );

      if (!mounted) return;
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminOwnerSuspendedSuccess),
            backgroundColor: AdminColors.success,
          ),
        );
        ref.invalidate(adminOwnerDetailsProvider(widget.ownerId));
        await ref.read(adminOwnersProvider.notifier).loadOwners();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.failureOrNull?.message ?? l10n.authServerError),
            backgroundColor: AdminColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _handleReactivate() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmDialog(
        title: l10n.adminReactivateOwnerTitle,
        description: l10n.adminReactivatePrompt,
        confirmLabel: l10n.adminReactivateConfirm,
        isDestructive: false,
        requireReason: false,
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(adminRepositoryProvider);
      final res = await repo.reactivateOwner(widget.ownerId);

      if (!mounted) return;
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminOwnerReactivatedSuccess),
            backgroundColor: AdminColors.success,
          ),
        );
        ref.invalidate(adminOwnerDetailsProvider(widget.ownerId));
        await ref.read(adminOwnersProvider.notifier).loadOwners();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.failureOrNull?.message ?? l10n.authServerError),
            backgroundColor: AdminColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _handleResetPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmDialog(
        title: l10n.adminResetPasswordTitle,
        description: l10n.adminResetPasswordPrompt,
        confirmLabel: l10n.adminResetPasswordConfirm,
        isDestructive: false,
        requireReason: false,
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(adminRepositoryProvider);
      final res = await repo.resetOwnerPassword(widget.ownerId);

      if (!mounted) return;
      if (res.isSuccess) {
        final data = res.valueOrNull!;
        final tempPassword = data['temporaryPassword']?.toString() ?? '';

        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AdminColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AdminSpacing.radiusCard),
            ),
            title: Text(l10n.adminTempPasswordTitle, style: AdminTypography.h3),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.adminTempPasswordWarning, style: AdminTypography.caption),
                const SizedBox(height: AdminSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AdminColors.raised,
                    borderRadius: BorderRadius.circular(AdminSpacing.radiusField),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SelectableText(
                        tempPassword,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontFamily: 'monospace',
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: AdminColors.primary),
                        tooltip: l10n.copy,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: tempPassword));
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(l10n.copiedToClipboard),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.dismiss),
              ),
            ],
          ),
        );
        ref.invalidate(adminOwnerDetailsProvider(widget.ownerId));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.failureOrNull?.message ?? l10n.authServerError),
            backgroundColor: AdminColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _handleEditDetails(String currentName, String currentPhone) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone);
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminSpacing.radiusCard),
        ),
        title: Text(l10n.adminEditOwnerTitle, style: AdminTypography.h3),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.businessName),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? l10n.required : null,
              ),
              const SizedBox(height: AdminSpacing.md),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(labelText: l10n.phoneNumber),
                keyboardType: TextInputType.phone,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? l10n.required : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(adminRepositoryProvider);
      final res = await repo.updateOwner(
        widget.ownerId,
        businessName: nameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
      );

      if (!mounted) return;
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminOwnerUpdatedSuccess),
            backgroundColor: AdminColors.success,
          ),
        );
        ref.invalidate(adminOwnerDetailsProvider(widget.ownerId));
        await ref.read(adminOwnersProvider.notifier).loadOwners();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.failureOrNull?.message ?? l10n.authServerError),
            backgroundColor: AdminColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _handleDisable(String expectedPhone) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminSpacing.radiusCard),
        ),
        title: Text(l10n.adminDisableAccountTitle, style: AdminTypography.h3),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.adminDisableWarningPrompt(expectedPhone),
                style: AdminTypography.bodyMedium,
              ),
              const SizedBox(height: AdminSpacing.md),
              TextFormField(
                controller: confirmController,
                decoration: InputDecoration(
                  labelText: l10n.adminConfirmPhoneLabel,
                  hintText: expectedPhone,
                ),
                validator: (val) {
                  if (val != expectedPhone) {
                    return l10n.adminPhoneConfirmationMismatch;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: Text(l10n.adminDisableConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(adminRepositoryProvider);
      final res = await repo.disableOwner(
        widget.ownerId,
        phoneConfirmation: confirmController.text.trim(),
      );

      if (!mounted) return;
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminAccountDisabledSuccess),
            backgroundColor: AdminColors.success,
          ),
        );
        await ref.read(adminOwnersProvider.notifier).loadOwners();
        if (mounted) {
          context.pop();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.failureOrNull?.message ?? l10n.authServerError),
            backgroundColor: AdminColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final detailsAsync = ref.watch(adminOwnerDetailsProvider(widget.ownerId));

    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        title: Text(l10n.adminOwnerDetailsTitle),
      ),
      body: detailsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AdminSpacing.lg),
          child: SkeletonListLoader(count: 4),
        ),
        error: (err, _) => Center(
          child: ErrorState(
            message: err.toString(),
            onRetry: () => ref.refresh(adminOwnerDetailsProvider(widget.ownerId)),
          ),
        ),
        data: (details) {
          final owner = details.owner;
          final isSuspended = owner.isSuspended;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AdminSpacing.lg,
              vertical: AdminSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header & Status Card
                ListCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              owner.businessName,
                              style: AdminTypography.h2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          StatusChip(
                            label: isSuspended
                                ? l10n.adminStatusSuspended
                                : l10n.adminStatusActive,
                            icon: isSuspended
                                ? Icons.block_rounded
                                : Icons.check_circle_outline_rounded,
                            color: isSuspended ? AdminColors.danger : AdminColors.success,
                            backgroundColor: isSuspended
                                ? AdminColors.dangerTint
                                : AdminColors.successTint,
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
                      if (owner.suspendedReason != null &&
                          owner.suspendedReason!.isNotEmpty) ...[
                        const SizedBox(height: AdminSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(AdminSpacing.sm),
                          decoration: BoxDecoration(
                            color: AdminColors.dangerTint,
                            borderRadius: BorderRadius.circular(AdminSpacing.radiusField),
                            border: Border.all(color: AdminColors.danger.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: AdminColors.danger,
                              ),
                              const SizedBox(width: AdminSpacing.sm),
                              Expanded(
                                child: Text(
                                  '${l10n.adminSuspensionReasonLabel}: ${owner.suspendedReason}',
                                  style: AdminTypography.caption.copyWith(
                                    color: AdminColors.danger,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AdminSpacing.md),
                      const Divider(height: 1, color: AdminColors.border),
                      const SizedBox(height: AdminSpacing.md),
                      _detailRow(l10n.adminRegisteredDate, _dateFormat.format(owner.createdAt)),
                      _detailRow(
                        l10n.adminLastSync,
                        owner.lastSyncAt != null
                            ? _dateFormat.format(owner.lastSyncAt!)
                            : l10n.adminSyncNever,
                      ),
                      _detailRow(l10n.adminAppVersion, owner.appVersion ?? 'N/A'),
                      _detailRow(l10n.adminFailedSyncCount, owner.failedSyncCount.toString()),
                    ],
                  ),
                ),
                const SizedBox(height: AdminSpacing.xl),

                // 2. Activity Statistics (COUNTS ONLY)
                SectionHeader(title: l10n.adminTenantCountsOnly),
                const SizedBox(height: AdminSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        label: l10n.adminTotalPartsCount,
                        value: details.totalParts.toString(),
                        icon: Icons.precision_manufacturing_rounded,
                        accentColor: const Color(0xFF818CF8),
                      ),
                    ),
                    const SizedBox(width: AdminSpacing.md),
                    Expanded(
                      child: MetricCard(
                        label: l10n.adminTotalSalesCount,
                        value: details.totalSales.toString(),
                        icon: Icons.point_of_sale_rounded,
                        accentColor: const Color(0xFF38BDF8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AdminSpacing.xl),

                // 3. Administrative Actions Section
                SectionHeader(title: l10n.adminActionsHeader),
                const SizedBox(height: AdminSpacing.sm),
                Wrap(
                  spacing: AdminSpacing.sm,
                  runSpacing: AdminSpacing.sm,
                  children: [
                    if (!isSuspended)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.danger,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _handleSuspend(owner.suspendedReason ?? ''),
                        icon: const Icon(Icons.block_rounded, size: 18),
                        label: Text(l10n.adminSuspend),
                      )
                    else
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.success,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _handleReactivate,
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                        label: Text(l10n.adminReactivate),
                      ),
                    OutlinedButton.icon(
                      onPressed: _handleResetPassword,
                      icon: const Icon(Icons.lock_reset_rounded, size: 18),
                      label: Text(l10n.adminResetPassword),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _handleEditDetails(owner.businessName, owner.phoneNumber),
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: Text(l10n.editProfile),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminColors.danger,
                        side: const BorderSide(color: AdminColors.danger),
                      ),
                      onPressed: () => _handleDisable(owner.phoneNumber),
                      icon: const Icon(Icons.delete_forever_rounded, size: 18),
                      label: Text(l10n.adminDisableAccount),
                    ),
                  ],
                ),
                const SizedBox(height: AdminSpacing.xl),

                // 4. Audit History for this Owner
                SectionHeader(title: l10n.adminAuditHistoryForUser),
                const SizedBox(height: AdminSpacing.sm),
                if (details.auditLogs.isEmpty)
                  ListCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AdminSpacing.md),
                      child: Center(
                        child: Text(
                          l10n.adminNoAuditLogs,
                          style: AdminTypography.caption,
                        ),
                      ),
                    ),
                  )
                else
                  ListCard(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: details.auditLogs.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, color: AdminColors.border),
                      itemBuilder: (ctx, i) {
                        final log = details.auditLogs[i];
                        final pres = AuditActionPresentation.resolve(log.action, l10n);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: AdminSpacing.sm),
                          child: Row(
                            children: [
                              StatusChip(
                                label: pres.label,
                                icon: pres.icon,
                                color: pres.color,
                                backgroundColor: pres.tintColor,
                              ),
                              const SizedBox(width: AdminSpacing.sm),
                              Expanded(
                                child: Text(
                                  log.reason ?? '',
                                  style: AdminTypography.caption.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              RelativeTimeText(
                                dateTime: log.createdAt,
                                style: AdminTypography.caption,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: AdminSpacing.xxl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AdminSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AdminTypography.caption.copyWith(
              color: AdminColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AdminTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

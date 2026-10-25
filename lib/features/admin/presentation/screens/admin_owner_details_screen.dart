import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
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
    final reasonController = TextEditingController(text: currentReason);
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminSuspendOwnerTitle),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.adminSuspendPrompt),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.adminSuspensionReasonLabel,
                  hintText: l10n.adminSuspensionReasonHint,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.adminReasonRequired;
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
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: Text(l10n.adminSuspendConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(adminRepositoryProvider);
      final res = await repo.suspendOwner(
        widget.ownerId,
        reason: reasonController.text.trim(),
      );

      if (!mounted) return;
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminOwnerSuspendedSuccess),
            backgroundColor: AppTheme.successColor,
          ),
        );
        ref.invalidate(adminOwnerDetailsProvider(widget.ownerId));
        await ref.read(adminOwnersProvider.notifier).loadOwners();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.failureOrNull?.message ?? l10n.authServerError),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _handleReactivate() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminReactivateOwnerTitle),
        content: Text(l10n.adminReactivatePrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.adminReactivateConfirm),
          ),
        ],
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
            backgroundColor: AppTheme.successColor,
          ),
        );
        ref.invalidate(adminOwnerDetailsProvider(widget.ownerId));
        await ref.read(adminOwnersProvider.notifier).loadOwners();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.failureOrNull?.message ?? l10n.authServerError),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _handleResetPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminResetPasswordTitle),
        content: Text(l10n.adminResetPasswordPrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.adminResetPasswordConfirm),
          ),
        ],
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
            title: Text(l10n.adminTempPasswordTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.adminTempPasswordWarning),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(ctx).colorScheme.outline),
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
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded),
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
            backgroundColor: AppTheme.errorColor,
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
        title: Text(l10n.adminEditOwnerTitle),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.businessName),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return l10n.required;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(labelText: l10n.phoneNumber),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return l10n.required;
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
            backgroundColor: AppTheme.successColor,
          ),
        );
        ref.invalidate(adminOwnerDetailsProvider(widget.ownerId));
        await ref.read(adminOwnersProvider.notifier).loadOwners();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.failureOrNull?.message ?? l10n.authServerError),
            backgroundColor: AppTheme.errorColor,
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
        title: Text(l10n.adminDisableAccountTitle),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.adminDisableWarningPrompt(expectedPhone),
                style: const TextStyle(height: 1.4),
              ),
              const SizedBox(height: 16),
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
              backgroundColor: AppTheme.errorColor,
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
            backgroundColor: AppTheme.successColor,
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
            backgroundColor: AppTheme.errorColor,
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
      appBar: AppBar(
        title: Text(l10n.adminOwnerDetailsTitle),
      ),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.errorColor),
              const SizedBox(height: 12),
              Text(err.toString()),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(adminOwnerDetailsProvider(widget.ownerId)),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (details) {
          final owner = details.owner;
          final isSuspended = owner.isSuspended;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header & Status Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSuspended
                                    ? AppTheme.errorColor.withValues(alpha: 0.12)
                                    : AppTheme.successColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isSuspended ? l10n.adminStatusSuspended : l10n.adminStatusActive,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSuspended ? AppTheme.errorColor : AppTheme.successColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          owner.phoneNumber,
                          style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (owner.suspendedReason != null && owner.suspendedReason!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded,
                                    size: 18, color: AppTheme.errorColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${l10n.adminSuspensionReasonLabel}: ${owner.suspendedReason}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Divider(height: 24),
                        _DetailRow(label: l10n.adminRegisteredDate, value: _dateFormat.format(owner.createdAt)),
                        _DetailRow(
                          label: l10n.adminLastSync,
                          value: owner.lastSyncAt != null ? _dateFormat.format(owner.lastSyncAt!) : l10n.adminSyncNever,
                        ),
                        _DetailRow(label: l10n.adminAppVersion, value: owner.appVersion ?? 'N/A'),
                        _DetailRow(label: l10n.adminFailedSyncCount, value: owner.failedSyncCount.toString()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Activity Statistics (COUNTS ONLY, strictly no row contents)
                Text(
                  l10n.adminTenantCountsOnly,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.adminTotalPartsCount, style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 4),
                              Text(
                                details.totalParts.toString(),
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.adminTotalSalesCount, style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 4),
                              Text(
                                details.totalSales.toString(),
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. Administrative Actions Section
                Text(
                  l10n.adminActionsHeader,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (!isSuspended)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _handleSuspend(owner.suspendedReason ?? ''),
                        icon: const Icon(Icons.block_rounded, size: 18),
                        label: Text(l10n.adminSuspend),
                      )
                    else
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
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
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                      ),
                      onPressed: () => _handleDisable(owner.phoneNumber),
                      icon: const Icon(Icons.delete_forever_rounded, size: 18),
                      label: Text(l10n.adminDisableAccount),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // 4. Audit History for this Owner
                Text(
                  l10n.adminAuditHistoryForUser,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (details.auditLogs.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(l10n.adminNoAuditLogs),
                    ),
                  )
                else
                  Card(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: details.auditLogs.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final log = details.auditLogs[i];
                        return ListTile(
                          title: Text(
                            log.action,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          subtitle: Text(
                            log.reason ?? _dateFormat.format(log.createdAt),
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            _dateFormat.format(log.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/language_selector_widget.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../parts/presentation/providers/inventory_providers.dart';
import '../../../stock/presentation/providers/stock_providers.dart';
import '../../data/services/export_backup_service.dart';

/// Comprehensive Settings and Preferences screen for Kera Spare Tracker.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final colorScheme = context.colorScheme;
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    final currentThemeMode = ref.watch(themeModeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navSettings),
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            children: [
              // 1. Account Details Card
              if (user != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: colorScheme.primaryContainer,
                              child: Icon(
                                Icons.store_rounded,
                                size: 30,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.businessName,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.phoneNumber,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: l10n.editProfile,
                              onPressed: () => _showEditBusinessNameDialog(
                                context,
                                user.businessName,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: colorScheme.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              icon: const Icon(Icons.lock_reset_rounded, size: 20),
                              label: Text(
                                l10n.changePassword,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              onPressed: () => _showChangePasswordDialog(context),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user.role.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 2. Preferences: Language & Theme
              Card(
                child: Column(
                  children: [
                    const LanguageSettingTile(),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.palette_outlined,
                        color: colorScheme.primary,
                      ),
                      title: Text(
                        l10n.themeMode,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(switch (currentThemeMode) {
                        ThemeMode.light => l10n.themeLight,
                        ThemeMode.dark => l10n.themeDark,
                        ThemeMode.system => l10n.themeSystem,
                      }),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showThemeModeDialog(context, currentThemeMode),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.monetization_on_outlined,
                        color: Colors.green.shade700,
                      ),
                      title: Text(
                        l10n.currencyLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(l10n.currencyDesc),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.side(color: Colors.green.shade200),
                        ),
                        child: Text(
                          'ETB',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Inventory & Policies Section
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(
                        Icons.exposure_neg_1_rounded,
                        color: colorScheme.primary,
                      ),
                      title: Text(
                        l10n.allowNegativeStock,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(l10n.allowNegativeStockDesc),
                      value: ref.watch(allowNegativeStockNotifierProvider).value ??
                          false,
                      onChanged: (val) => ref
                          .read(allowNegativeStockNotifierProvider.notifier)
                          .toggle(val),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade800,
                      ),
                      title: Text(
                        l10n.lowStockListTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(l10n.lowStockListDesc),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ref.watch(lowStockPartsStreamProvider).when(
                                data: (items) => items.isNotEmpty
                                    ? Badge(
                                        label: Text('${items.length}'),
                                        backgroundColor: Colors.orange.shade800,
                                      )
                                    : const SizedBox.shrink(),
                                loading: () => const SizedBox.shrink(),
                                error: (_, _) => const SizedBox.shrink(),
                              ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                      onTap: () => context.push('/stock/low-stock'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.directions_car_rounded,
                        color: colorScheme.primary,
                      ),
                      title: Text(
                        l10n.brandsTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(l10n.manageBrandsDesc),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/settings/brands'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.folder_open_rounded,
                        color: colorScheme.secondary,
                      ),
                      title: Text(
                        l10n.categoriesTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(l10n.manageCategoriesDesc),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/settings/categories'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.shelves,
                        color: colorScheme.tertiary,
                      ),
                      title: Text(
                        l10n.locationsTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(l10n.manageLocationsDesc),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/settings/locations'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4. Data Management & Export Section
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.table_chart_outlined,
                        color: colorScheme.primary,
                      ),
                      title: Text(
                        l10n.exportInventoryCsv,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(l10n.exportInventoryDesc),
                      trailing: const Icon(Icons.share_rounded),
                      onTap: user == null
                          ? null
                          : () => _handleExportInventory(context, user.ownerId),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.receipt_long_outlined,
                        color: colorScheme.secondary,
                      ),
                      title: Text(
                        l10n.exportSalesCsv,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(l10n.exportSalesDesc),
                      trailing: const Icon(Icons.share_rounded),
                      onTap: user == null
                          ? null
                          : () => _handleExportSales(context, user.ownerId),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.backup_outlined,
                        color: Colors.blue.shade700,
                      ),
                      title: Text(
                        l10n.backupDatabase,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(l10n.backupDatabaseDesc),
                      trailing: const Icon(Icons.download_rounded),
                      onTap: () => _handleBackupDatabase(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.settings_backup_restore_rounded,
                        color: Colors.deepOrange.shade700,
                      ),
                      title: Text(
                        l10n.restoreDatabase,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(l10n.restoreDatabaseDesc),
                      trailing: const Icon(Icons.upload_file_rounded),
                      onTap: () => _confirmRestoreDatabase(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 5. Benchmark & Demo Tools
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.speed_rounded, color: colorScheme.primary),
                      title: Text(
                        l10n.seedParts,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(l10n.seedPartsDesc),
                      onTap: () async {
                        context.showSnackBar(l10n.seedingInProgress);
                        final success = await ref
                            .read(inventoryListProvider.notifier)
                            .seedTestParts(count: 2000);
                        if (context.mounted) {
                          if (success) {
                            context.showSnackBar(l10n.seedSuccess);
                          } else {
                            context.showSnackBar('Failed to seed parts',
                                isError: true);
                          }
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.delete_sweep_rounded,
                        color: colorScheme.error,
                      ),
                      title: Text(
                        l10n.clearTestParts,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.error,
                        ),
                      ),
                      subtitle: Text(l10n.clearTestPartsConfirm),
                      onTap: () => _confirmClearParts(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 6. About App & Version Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: colorScheme.primary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            l10n.aboutTitle,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.aboutDesc,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.appVersion('1.0.0 (Build 1)'),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 7. Logout Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error, width: 1.5),
                  minimumSize: const Size(
                    double.infinity,
                    AppConstants.standardButtonHeight,
                  ),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: Text(
                  l10n.logout,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () => _confirmLogout(context),
              ),
              const SizedBox(height: 32),
            ],
          ),

          // Loading overlay during export/backup
          if (_isExporting)
            Container(
              color: Colors.black38,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Processing... Please wait'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- Handlers & Dialogs ---

  Future<void> _handleExportInventory(
    BuildContext context,
    String ownerId,
  ) async {
    setState(() => _isExporting = true);
    try {
      final file = await ref
          .read(exportBackupServiceProvider)
          .exportInventoryCsv(ownerId: ownerId);
      if (context.mounted) {
        final name = file.path.split(RegExp(r'[/\\]')).last;
        context.showSnackBar(context.l10n.exportSuccess(name));
      }
    } catch (e) {
      if (context.mounted) {
        context.showSnackBar(
          context.l10n.exportError(e.toString()),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleExportSales(
    BuildContext context,
    String ownerId,
  ) async {
    setState(() => _isExporting = true);
    try {
      final file = await ref
          .read(exportBackupServiceProvider)
          .exportSalesCsv(ownerId: ownerId);
      if (context.mounted) {
        final name = file.path.split(RegExp(r'[/\\]')).last;
        context.showSnackBar(context.l10n.exportSuccess(name));
      }
    } catch (e) {
      if (context.mounted) {
        context.showSnackBar(
          context.l10n.exportError(e.toString()),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleBackupDatabase(BuildContext context) async {
    setState(() => _isExporting = true);
    try {
      final file =
          await ref.read(exportBackupServiceProvider).backupDatabase();
      if (context.mounted) {
        final name = file.path.split(RegExp(r'[/\\]')).last;
        context.showSnackBar(context.l10n.exportSuccess(name));
      }
    } catch (e) {
      if (context.mounted) {
        context.showSnackBar(
          context.l10n.exportError(e.toString()),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _confirmRestoreDatabase(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.restoreConfirmTitle),
        content: Text(l10n.restoreConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.error,
              foregroundColor: context.colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.restoreDatabase),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      setState(() => _isExporting = true);
      try {
        final restored =
            await ref.read(exportBackupServiceProvider).restoreDatabase();
        if (context.mounted) {
          if (restored) {
            context.showSnackBar(context.l10n.restoreSuccess);
          }
        }
      } catch (e) {
        if (context.mounted) {
          context.showSnackBar(context.l10n.restoreError, isError: true);
        }
      } finally {
        if (mounted) setState(() => _isExporting = false);
      }
    }
  }

  void _showThemeModeDialog(BuildContext context, ThemeMode currentMode) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.themeMode),
        children: [
          RadioListTile<ThemeMode>(
            title: Text(l10n.themeSystem),
            value: ThemeMode.system,
            groupValue: currentMode,
            onChanged: (val) {
              if (val != null) {
                ref.read(themeModeControllerProvider.notifier).setThemeMode(val);
                Navigator.pop(ctx);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: Text(l10n.themeLight),
            value: ThemeMode.light,
            groupValue: currentMode,
            onChanged: (val) {
              if (val != null) {
                ref.read(themeModeControllerProvider.notifier).setThemeMode(val);
                Navigator.pop(ctx);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: Text(l10n.themeDark),
            value: ThemeMode.dark,
            groupValue: currentMode,
            onChanged: (val) {
              if (val != null) {
                ref.read(themeModeControllerProvider.notifier).setThemeMode(val);
                Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditBusinessNameDialog(
    BuildContext context,
    String currentName,
  ) {
    final l10n = context.l10n;
    final controller = TextEditingController(text: currentName);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.editProfile),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.businessName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                final result = await ref
                    .read(authControllerProvider.notifier)
                    .updateBusinessName(newName);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (result.isSuccess) {
                    context.showSnackBar('Profile updated');
                  }
                }
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final l10n = context.l10n;
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscure = true;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.changePassword),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentController,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: l10n.currentPassword,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newController,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: l10n.newPassword,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: l10n.confirmNewPassword,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: !obscure,
                      onChanged: (val) {
                        setDialogState(() => obscure = !(val ?? false));
                      },
                    ),
                    const Text('Show passwords'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final curr = currentController.text.trim();
                final newPass = newController.text.trim();
                final confirm = confirmController.text.trim();

                if (newPass.length < 6) {
                  context.showSnackBar(l10n.passwordTooShort, isError: true);
                  return;
                }
                if (newPass != confirm) {
                  context.showSnackBar(l10n.passwordMismatch, isError: true);
                  return;
                }

                final result = await ref
                    .read(authControllerProvider.notifier)
                    .changePassword(
                      currentPassword: curr,
                      newPassword: newPass,
                    );

                if (ctx.mounted) {
                  if (result.isSuccess) {
                    Navigator.pop(ctx);
                    context.showSnackBar(l10n.passwordChangedSuccess);
                  } else {
                    context.showSnackBar(
                      l10n.invalidCurrentPassword,
                      isError: true,
                    );
                  }
                }
              },
              child: Text(l10n.changePassword),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearParts(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearTestParts),
        content: Text(l10n.clearTestPartsConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.error,
              foregroundColor: context.colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success =
          await ref.read(inventoryListProvider.notifier).clearTestParts();
      if (context.mounted) {
        if (success) {
          context.showSnackBar(l10n.clearTestPartsSuccess);
        } else {
          context.showSnackBar('Failed to clear test parts', isError: true);
        }
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.error,
              foregroundColor: context.colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}

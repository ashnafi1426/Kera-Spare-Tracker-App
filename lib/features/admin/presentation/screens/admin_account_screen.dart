import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../../../../core/design/tokens/admin_spacing.dart';
import '../../../../core/design/tokens/admin_typography.dart';
import '../../../../core/design/widgets/confirm_dialog.dart';
import '../../../../core/design/widgets/list_card.dart';
import '../../../../core/design/widgets/status_chip.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../security/presentation/widgets/app_lock_settings_card.dart';

class AdminAccountScreen extends ConsumerStatefulWidget {
  const AdminAccountScreen({super.key});

  @override
  ConsumerState<AdminAccountScreen> createState() => _AdminAccountScreenState();
}

class _AdminAccountScreenState extends ConsumerState<AdminAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isChangingPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isChangingPassword = true);
    final l10n = AppLocalizations.of(context)!;

    final res = await ref.read(authControllerProvider.notifier).changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );

    if (!mounted) return;
    setState(() => _isChangingPassword = false);

    res.when(
      onSuccess: (_) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminPasswordChangedSuccess),
            backgroundColor: AdminColors.success,
          ),
        );
      },
      onFailure: (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err.message),
            backgroundColor: AdminColors.danger,
          ),
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmDialog(
        title: l10n.logout,
        description: l10n.logoutConfirmation,
        confirmLabel: l10n.logout,
        isDestructive: true,
        requireReason: false,
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authControllerProvider.notifier).logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    final currentLocale = ref.watch(localeControllerProvider);

    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        title: Text(l10n.adminAccountTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.lg,
          vertical: AdminSpacing.md,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Card
                ListCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AdminSpacing.md),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 36,
                          backgroundColor: AdminColors.infoTint,
                          child: Icon(
                            Icons.admin_panel_settings_rounded,
                            size: 40,
                            color: AdminColors.primary,
                          ),
                        ),
                        const SizedBox(height: AdminSpacing.md),
                        Text(
                          user?.businessName ?? 'System Administrator',
                          style: AdminTypography.h2,
                        ),
                        const SizedBox(height: AdminSpacing.xs),
                        Text(
                          user?.phoneNumber ?? '',
                          style: AdminTypography.caption.copyWith(
                            fontFamily: 'monospace',
                            color: AdminColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AdminSpacing.sm),
                        StatusChip(
                          label: user?.role.toUpperCase() ?? 'ADMIN',
                          icon: Icons.verified_user_rounded,
                          color: AdminColors.primary,
                          backgroundColor: AdminColors.infoTint,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AdminSpacing.lg),

                // Language Preferences Card
                ListCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.language,
                        style: AdminTypography.h3,
                      ),
                      const SizedBox(height: AdminSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'am',
                              label: Text('አማርኛ (Amharic)'),
                            ),
                            ButtonSegment(
                              value: 'en',
                              label: Text('English'),
                            ),
                          ],
                          selected: {currentLocale.languageCode},
                          onSelectionChanged: (selection) {
                            ref
                                .read(localeControllerProvider.notifier)
                                .setLocale(Locale(selection.first));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AdminSpacing.lg),

                // App Lock Security Card
                const AppLockSettingsCard(),
                const SizedBox(height: AdminSpacing.lg),

                // Change Password Card
                ListCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.lock_reset_rounded,
                              color: AdminColors.primary,
                            ),
                            const SizedBox(width: AdminSpacing.sm),
                            Text(
                              l10n.changePassword,
                              style: AdminTypography.h3,
                            ),
                          ],
                        ),
                        const SizedBox(height: AdminSpacing.md),
                        const Divider(height: 1, color: AdminColors.border),
                        const SizedBox(height: AdminSpacing.md),
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: _obscureCurrent,
                          style: AdminTypography.bodyMedium,
                          decoration: InputDecoration(
                            labelText: l10n.currentPassword,
                            suffixIcon: IconButton(
                              icon: Icon(_obscureCurrent
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded),
                              onPressed: () => setState(
                                  () => _obscureCurrent = !_obscureCurrent),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return l10n.passwordRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AdminSpacing.sm),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscureNew,
                          style: AdminTypography.bodyMedium,
                          decoration: InputDecoration(
                            labelText: l10n.newPassword,
                            suffixIcon: IconButton(
                              icon: Icon(_obscureNew
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded),
                              onPressed: () =>
                                  setState(() => _obscureNew = !_obscureNew),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.length < 8) {
                              return l10n.passwordTooShort;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AdminSpacing.sm),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          style: AdminTypography.bodyMedium,
                          decoration: InputDecoration(
                            labelText: l10n.confirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirm
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          validator: (val) {
                            if (val != _newPasswordController.text) {
                              return l10n.passwordsDoNotMatch;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AdminSpacing.md),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AdminColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AdminSpacing.radiusButton),
                              ),
                            ),
                            icon: _isChangingPassword
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_rounded, size: 18),
                            label: Text(l10n.save),
                            onPressed: _isChangingPassword
                                ? null
                                : _submitChangePassword,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AdminSpacing.xl),

                // Logout Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminColors.danger,
                    side: const BorderSide(color: AdminColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: AdminSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AdminSpacing.radiusButton),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(
                    l10n.logout,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _handleLogout,
                ),
                const SizedBox(height: AdminSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

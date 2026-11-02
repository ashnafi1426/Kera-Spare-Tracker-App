import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/design/widgets/kera_button.dart';
import '../../../../core/design/widgets/kera_card.dart';
import '../../../../core/errors/failure.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/auth_controller.dart';

/// Stitch Design: Screen 5 — Forgot / Change Password / የይለፍ ቃል መቀየሪያ
/// Screen allowing or forcing users to change their account password.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  final bool isForced;

  const ChangePasswordScreen({
    super.key,
    this.isForced = false,
  });

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final l10n = AppLocalizations.of(context)!;
    final result = await ref.read(authControllerProvider.notifier).changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );

    if (!mounted) return;

    if (result.isSuccess) {
      // Re-fetch current user profile to update mustChangePassword state in AuthController
      final userResult = await ref.read(authRepositoryProvider).currentUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.passwordChangedSuccess),
            backgroundColor: KeraColors.success,
          ),
        );
        final user = userResult.valueOrNull ?? ref.read(authControllerProvider).value;
        final targetRoute = (user?.isAdmin ?? false) ? '/admin' : '/home';
        if (widget.isForced || user?.mustChangePassword == false) {
          context.go(targetRoute);
        } else {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(targetRoute);
          }
        }
      }
    } else {
      final err = result.failureOrNull;
      String msg = err?.message ?? l10n.authServerError;
      if (err is AuthFailure && err.code == 'INVALID_CREDENTIALS') {
        msg = l10n.invalidCurrentPassword;
      }
      setState(() {
        _errorMessage = msg;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isForced,
      child: Scaffold(
        backgroundColor: KeraColors.surfaceCanvas,
        body: Column(
          children: [
            // Top Bar
            _buildTopBanner(context),

            // Main Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: KeraSpacing.lg,
                  vertical: KeraSpacing.md,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Page Title & Microcontext
                        _buildTitleHeader(context),
                        const SizedBox(height: KeraSpacing.md),

                        // Forced Password Alert or Step Indicator
                        if (widget.isForced) ...[
                          _buildForcedPasswordAlert(context),
                          const SizedBox(height: KeraSpacing.md),
                        ],

                        // Error Banner
                        if (_errorMessage != null) ...[
                          _buildErrorBanner(context),
                          const SizedBox(height: KeraSpacing.md),
                        ],

                        // Main Form Card
                        _buildFormCard(context),
                        const SizedBox(height: KeraSpacing.md),

                        // Quick Assistance Bento Help Item
                        _buildAssistanceCard(context),
                        const SizedBox(height: KeraSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner(BuildContext context) {
    return Container(
      color: KeraColors.primaryNavy,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: KeraSpacing.sm),
          child: Row(
            children: [
              if (!widget.isForced)
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/login');
                    }
                  },
                  tooltip: 'ተመለስ / Back',
                )
              else
                const SizedBox(width: KeraSpacing.md),
              const Icon(
                Icons.storefront_rounded,
                color: KeraColors.actionBlueTint,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'ኬራ ስፔር / Kera Spare',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              // Network Sync State
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(KeraRadii.full),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: KeraColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'የተገናኘ / Synced',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: KeraSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: KeraColors.actionBlueTint,
            borderRadius: BorderRadius.circular(KeraRadii.xs),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_reset_rounded, size: 15, color: KeraColors.actionBlue),
              const SizedBox(width: 4),
              Text(
                'የመለያ ደህንነት ማስተካከያ',
                style: KeraTypography.labelSmall(color: KeraColors.actionBlue).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.changePassword,
          style: KeraTypography.headlineSmall(color: KeraColors.textPrimary).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          'Reset credentials for Addis Ababa Retail Terminal',
          style: KeraTypography.bodySmall(color: KeraColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildForcedPasswordAlert(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(KeraSpacing.md),
      decoration: BoxDecoration(
        color: KeraColors.actionBlueTint.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(KeraRadii.lg),
        border: Border.all(color: KeraColors.actionBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.security_rounded,
            color: KeraColors.actionBlue,
            size: 26,
          ),
          const SizedBox(width: KeraSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.mustChangePasswordTitle,
                  style: KeraTypography.labelLarge(color: KeraColors.actionBlue).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.mustChangePasswordPrompt,
                  style: KeraTypography.bodySmall(color: KeraColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KeraSpacing.md),
      decoration: BoxDecoration(
        color: KeraColors.errorLight,
        borderRadius: BorderRadius.circular(KeraRadii.lg),
        border: Border.all(color: KeraColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: KeraColors.error, size: 20),
          const SizedBox(width: KeraSpacing.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: KeraTypography.bodySmall(color: KeraColors.error).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return KeraCard(
      padding: const EdgeInsets.all(KeraSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.key_rounded, size: 18, color: KeraColors.actionBlue),
                const SizedBox(width: 6),
                Text(
                  'አዲስ የይለፍ ቃል ማዘጋጃ',
                  style: KeraTypography.labelLarge(color: KeraColors.textPrimary).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: KeraColors.borderOpaque),

            // Current Password Input
            Text(
              l10n.currentPassword,
              style: KeraTypography.labelLarge(color: KeraColors.textPrimary).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrent,
              decoration: InputDecoration(
                hintText: l10n.currentPassword,
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: KeraColors.textSecondary),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrent
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: KeraColors.textSecondary,
                  ),
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.currentPassword;
                }
                return null;
              },
            ),
            const SizedBox(height: KeraSpacing.md),

            // New Password Input
            Text(
              '${l10n.newPassword} (New Password)',
              style: KeraTypography.labelLarge(color: KeraColors.textPrimary).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                hintText: 'ቢያንስ 8 ፊደላትና ቁጥሮች...',
                prefixIcon: const Icon(Icons.lock_rounded, color: KeraColors.textSecondary),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: KeraColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().length < 6) {
                  return l10n.passwordTooShort;
                }
                return null;
              },
            ),
            const SizedBox(height: 6),
            // Password Quality bar
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: KeraColors.success,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: KeraColors.success,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: KeraColors.success,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: KeraColors.borderOpaque,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: KeraSpacing.md),

            // Confirm New Password Input
            Text(
              '${l10n.confirmNewPassword} (Confirm Password)',
              style: KeraTypography.labelLarge(color: KeraColors.textPrimary).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                hintText: 'የይለፍ ቃሉን ደግመው ያስገቡ...',
                prefixIcon: const Icon(Icons.lock_clock_outlined, color: KeraColors.textSecondary),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: KeraColors.textSecondary,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (value) {
                if (value != _newPasswordController.text) {
                  return l10n.passwordMismatch;
                }
                return null;
              },
            ),
            const SizedBox(height: KeraSpacing.sm),

            // Industrial Validation Pill Checklist (Stitch Screen 5)
            Container(
              padding: const EdgeInsets.all(KeraSpacing.sm),
              decoration: BoxDecoration(
                color: KeraColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(KeraRadii.md),
              ),
              child: const Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _ValidationPill(label: '8+ ፊደላት'),
                  _ValidationPill(label: 'ቁጥር ተካቷል'),
                  _ValidationPill(label: 'ልዩ ምልክት (@#\$)'),
                ],
              ),
            ),
            const SizedBox(height: KeraSpacing.lg),

            // Submit Button
            KeraButton.primary(
              label: '${l10n.changePassword} (Reset Password)',
              icon: Icons.published_with_changes_rounded,
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssistanceCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KeraSpacing.md),
      decoration: BoxDecoration(
        color: KeraColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(KeraRadii.lg),
        border: Border.all(color: KeraColors.borderOpaque),
      ),
      child: Row(
        children: [
          const Icon(Icons.support_agent_rounded, color: KeraColors.textSecondary, size: 24),
          const SizedBox(width: KeraSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'እርዳታ ይፈልጋሉ? / Help Desk',
                  style: KeraTypography.labelMedium(color: KeraColors.textPrimary).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'የሱቅ አስተዳዳሪ (Store Admin) ያነጋግሩ',
                  style: KeraTypography.bodySmall(color: KeraColors.textSecondary).copyWith(
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KeraRadii.sm),
              ),
              side: const BorderSide(color: KeraColors.borderOpaque),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ድጋፍ መስመር: 822 (ይደውሉ)'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              '822 ይደውሉ',
              style: KeraTypography.labelSmall(color: KeraColors.actionBlue).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationPill extends StatelessWidget {
  final String label;

  const _ValidationPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: KeraColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(KeraRadii.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 12, color: KeraColors.success),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: KeraColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

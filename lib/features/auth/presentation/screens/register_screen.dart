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
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/language_selector_widget.dart';
import '../controllers/auth_controller.dart';

/// Stitch Design: Screen 4 — Business Registration / የንግድ ምዝገባ
/// Allows new spare parts business owners in Kera to register their store.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _agreedToTerms = true;
  bool _isLoading = false;
  bool _isOfflineError = false;
  String? _errorMessage;

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() {
      _errorMessage = null;
      _isOfflineError = false;
    });
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('እባክዎን በመመሪያ እና ደንብ ይስማሙ (Please accept terms)'),
          backgroundColor: KeraColors.warning,
        ),
      );
      return;
    }

    final l10n = context.l10n;
    setState(() => _isLoading = true);

    final result = await ref.read(authControllerProvider.notifier).register(
          phoneNumber: _phoneController.text.trim(),
          businessName: _businessNameController.text.trim(),
          password: _passwordController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.when(
      onSuccess: (_) {
        context.go('/home');
      },
      onFailure: (failure) {
        if (failure is OfflineInternetRequiredFailure) {
          setState(() {
            _isOfflineError = true;
            _errorMessage = l10n.authOfflineInternetRequired;
          });
          return;
        }

        if (failure.code == 'NO_INTERNET') {
          setState(() {
            _isOfflineError = true;
            _errorMessage = l10n.authNoInternet;
          });
          return;
        }

        if (failure.code == 'SERVER_UNREACHABLE' ||
            failure is NetworkFailure) {
          setState(() {
            _isOfflineError = true;
            _errorMessage = failure.message;
          });
          return;
        }

        String msg;
        switch (failure.code) {
          case 'PHONE_TAKEN':
            msg = l10n.authPhoneTaken;
            break;
          case 'ACCOUNT_SUSPENDED':
            msg = l10n.authAccountSuspended;
            break;
          case 'SERVER_ERROR':
            msg = l10n.authServerError;
            break;
          default:
            msg = failure.message;
        }
        setState(() => _errorMessage = msg);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KeraColors.surfaceCanvas,
      body: Column(
        children: [
          // Top Bar (Stitch Screen 4 Header)
          _buildTopBanner(context),

          // Main Scrollable Canvas
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
                      // Step Progress Header (Step 1 of 2)
                      _buildStepProgress(context),
                      const SizedBox(height: KeraSpacing.md),

                      // Title & Orientation Banner
                      _buildTitleHeader(context),
                      const SizedBox(height: KeraSpacing.md),

                      // Error Banner (if any)
                      if (_errorMessage != null) ...[
                        _buildErrorBanner(context),
                        const SizedBox(height: KeraSpacing.md),
                      ],

                      // Registration Form Container
                      _buildRegistrationForm(context),
                      const SizedBox(height: KeraSpacing.lg),

                      // Footer with Login Link & Offline Guarantee
                      _buildFooter(context),
                      const SizedBox(height: KeraSpacing.md),
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
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/login');
                  }
                },
                tooltip: 'ወደ ኋላ ተመለስ / Back',
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'ኬራ ስፔር / Kera Spare',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const LanguageSegmentedSwitch(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepProgress(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ደረጃ 1 ከ 2 (Step 1 of 2)',
              style: KeraTypography.labelLarge(color: KeraColors.actionBlue).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'የንግድ መረጃ',
              style: KeraTypography.bodySmall(color: KeraColors.textSecondary).copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  color: KeraColors.actionBlue,
                  borderRadius: BorderRadius.circular(KeraRadii.full),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  color: KeraColors.borderOpaque,
                  borderRadius: BorderRadius.circular(KeraRadii.full),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTitleHeader(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: KeraColors.actionBlueTint,
            borderRadius: BorderRadius.circular(KeraRadii.md),
          ),
          child: const Icon(
            Icons.app_registration_rounded,
            color: KeraColors.actionBlue,
            size: 24,
          ),
        ),
        const SizedBox(width: KeraSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.registerTitle,
                style: KeraTypography.headlineSmall(color: KeraColors.textPrimary).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                l10n.registerSubtitle,
                style: KeraTypography.bodySmall(color: KeraColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(KeraSpacing.md),
      decoration: BoxDecoration(
        color: KeraColors.errorLight,
        borderRadius: BorderRadius.circular(KeraRadii.lg),
        border: Border.all(color: KeraColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: KeraColors.error, size: 22),
          const SizedBox(width: KeraSpacing.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: KeraTypography.labelLarge(color: KeraColors.error).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_isOfflineError) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                foregroundColor: KeraColors.error,
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(l10n.retry),
              onPressed: _handleRegister,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRegistrationForm(BuildContext context) {
    final l10n = context.l10n;

    return KeraCard(
      padding: const EdgeInsets.all(KeraSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Field 1: Business / Shop Name
            Text(
              l10n.businessName,
              style: KeraTypography.labelLarge(color: KeraColors.textPrimary).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _businessNameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: l10n.businessNameHint,
                prefixIcon: const Icon(Icons.storefront_outlined, color: KeraColors.textSecondary),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return l10n.businessNameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 13, color: KeraColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'የንግድ ፍቃድ ላይ ያለውን ስም ያስገቡ',
                  style: KeraTypography.bodySmall(color: KeraColors.textSecondary).copyWith(
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: KeraSpacing.md),

            // Field 2: Phone Number
            Text(
              l10n.phoneNumber,
              style: KeraTypography.labelLarge(color: KeraColors.textPrimary).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: KeraTypography.bodyLarge(color: KeraColors.textPrimary).copyWith(fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: l10n.phoneNumberHint,
                prefixIcon: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: const BoxDecoration(
                    color: KeraColors.surfaceSubtle,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(KeraRadii.md),
                    ),
                    border: Border(
                      right: BorderSide(color: KeraColors.borderOpaque),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+251',
                        style: KeraTypography.labelLarge(color: KeraColors.textPrimary).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ET',
                        style: KeraTypography.bodySmall(color: KeraColors.textSecondary).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return l10n.phoneRequired;
                }
                return Validators.validateEthiopianPhone(val) != null
                    ? l10n.phoneInvalid
                    : null;
              },
            ),
            const SizedBox(height: 4),
            Text(
              'የኤስኤምኤስ (SMS) ማረጋገጫ ኮድ ይላካል',
              style: KeraTypography.bodySmall(color: KeraColors.textSecondary).copyWith(
                fontSize: 11,
              ),
            ),
            const SizedBox(height: KeraSpacing.md),

            // Field 3: Password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.password,
                  style: KeraTypography.labelLarge(color: KeraColors.textPrimary).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'ጠንካራ / Strong',
                  style: KeraTypography.bodySmall(color: KeraColors.success).copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: l10n.passwordHint,
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: KeraColors.textSecondary),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: KeraColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return l10n.passwordRequired;
                }
                if (val.length < 6) {
                  return l10n.passwordTooShort;
                }
                return null;
              },
            ),
            const SizedBox(height: 6),
            // Password strength bar indicator
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: KeraColors.success,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: KeraColors.success,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: KeraColors.success,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: KeraSpacing.md),

            // Field 4: Confirm Password
            Text(
              l10n.confirmPassword,
              style: KeraTypography.labelLarge(color: KeraColors.textPrimary).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: l10n.confirmPassword,
                prefixIcon: const Icon(Icons.verified_user_outlined, color: KeraColors.textSecondary),
              ),
              validator: (val) {
                if (val != _passwordController.text) {
                  return l10n.passwordsDoNotMatch;
                }
                return null;
              },
            ),
            const SizedBox(height: KeraSpacing.md),

            // Terms & Conditions Checkbox
            InkWell(
              onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
              borderRadius: BorderRadius.circular(KeraRadii.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreedToTerms,
                        activeColor: KeraColors.actionBlue,
                        onChanged: (val) =>
                            setState(() => _agreedToTerms = val ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          text: 'በኬራ መለዋወጫ ',
                          style: KeraTypography.bodySmall(color: KeraColors.textPrimary),
                          children: [
                            TextSpan(
                              text: 'መመሪያ እና ደንብ',
                              style: KeraTypography.bodySmall(color: KeraColors.actionBlue).copyWith(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const TextSpan(
                              text: ' ተስማምቻለሁ (I agree to Terms & Conditions)',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: KeraSpacing.lg),

            // Submit Button
            KeraButton.primary(
              label: l10n.register,
              icon: Icons.arrow_forward_rounded,
              isLoading: _isLoading,
              onPressed: _handleRegister,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () => context.go('/login'),
              borderRadius: BorderRadius.circular(KeraRadii.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.alreadyHaveAccount,
                      style: KeraTypography.labelLarge(color: KeraColors.actionBlue).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.login_rounded, size: 16, color: KeraColors.actionBlue),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: KeraSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.offline_bolt_rounded, size: 16, color: KeraColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              'የኢንተርኔት መቆራረጥ ቢያጋጥም መረጃዎ በስልክዎ ይቀመጣል',
              style: KeraTypography.bodySmall(color: KeraColors.textSecondary).copyWith(
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/design/tokens/admin_colors.dart';
import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/design/widgets/kera_card.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/app_lock_service.dart';
import '../../../../core/services/session_store.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/kera_logo_widget.dart';
import '../../../../core/widgets/language_selector_widget.dart';
import '../../../../data/local/database_provider.dart';
import '../../data/repositories/api_auth_repository.dart';
import '../controllers/auth_controller.dart';

/// Stitch Design: Screen 3 — Login Screen / መግቢያ
/// Allowing existing spare parts owners and operators to log in with phone and password.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  bool _isOfflineError = false;
  String? _errorMessage;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin({bool forceDiscardUnsynced = false}) async {
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      final remaining = _lockoutUntil!.difference(DateTime.now()).inSeconds;
      setState(() {
        _errorMessage = context.tr(
          'ተከታታይ የተሳሳተ ሙከራዎች ምክንያት ለ $remaining ሰከንድ ታግዷል',
          'Too many failed attempts. Try again in ${remaining}s',
        );
      });
      return;
    }
    setState(() {
      _errorMessage = null;
      _isOfflineError = false;
    });
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;
    setState(() => _isLoading = true);

    final result = await ref.read(authControllerProvider.notifier).login(
          phoneNumber: _phoneController.text.trim(),
          password: _passwordController.text.trim(),
          forceDiscardUnsynced: forceDiscardUnsynced,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    await result.when(
      onSuccess: (user) async {
        _failedAttempts = 0;
        _lockoutUntil = null;
        final lockService = ref.read(appLockServiceProvider);
        if (lockService.state.isEnabled) {
          lockService.lockApp();
        }
        if (user.mustChangePassword) {
          context.go('/change-password');
        } else if (user.isAdmin) {
          context.go('/admin');
        } else {
          // Rule 6: Check if first login on phone has 0 parts; if so pull catalog
          final db = ref.read(appDatabaseProvider);
          final firstPart =
              await (db.select(db.spareParts)..limit(1)).getSingleOrNull();

          if (!mounted) return;
          if (firstPart == null) {
            context.go('/initial-sync');
          } else {
            context.go('/home');
          }
        }
      },
      onFailure: (failure) async {
        if (failure is DifferentOwnerConflictFailure) {
          // Rule 4: Different account conflict dialog
          final discardAndProceed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.authDifferentOwnerConflictTitle),
              content: Text(
                '${l10n.authDifferentOwnerConflictMessage}\n(${failure.previousOwnerName})',
              ),
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
                  child: Text(l10n.authDiscardUnsyncedAndLogin),
                ),
              ],
            ),
          );

          if (discardAndProceed == true && mounted) {
            await _handleLogin(forceDiscardUnsynced: true);
          }
          return;
        }

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
            failure.code == 'INTERNAL_SERVER_ERROR' ||
            failure.code == 'DATABASE_UNAVAILABLE' ||
            failure is NetworkFailure) {
          setState(() {
            _isOfflineError = true;
            _errorMessage = failure.code == 'DATABASE_UNAVAILABLE'
                ? '${l10n.authServerError} (Database offline)'
                : (failure.code == 'INTERNAL_SERVER_ERROR'
                    ? l10n.authServerError
                    : failure.message);
          });
          return;
        }

        _failedAttempts++;
        if (_failedAttempts >= 5) {
          _lockoutUntil = DateTime.now().add(const Duration(seconds: 60));
          setState(() {
            _errorMessage = context.tr(
              'ተከታታይ 5 የተሳሳቱ ሙከራዎች! እባክዎ ለ 60 ሰከንዶች ይጠብቁ።',
              '5 consecutive failed login attempts! Temporary lockout for 60 seconds.',
            );
          });
          return;
        }

        String msg;
        switch (failure.code) {
          case 'INVALID_CREDENTIALS':
            msg = l10n.authWrongPassword;
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
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          // Top System Anchor Banner (Stitch Screen 3 Header)
          _buildTopBanner(context),

          // Main Scrollable Canvas Content
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
                      // Screen Intent Title Cluster
                      _buildHeaderCluster(context),
                      const SizedBox(height: KeraSpacing.md),

                      // Error Banner (if any)
                      if (_errorMessage != null) ...[
                        _buildErrorBanner(context),
                        const SizedBox(height: KeraSpacing.md),
                      ],

                      // Main Form Container Card
                      _buildFormCard(context),
                      const SizedBox(height: KeraSpacing.md),

                      // Biometric Quick Login Component (Stitch feature)
                      _buildBiometricCard(context),
                      const SizedBox(height: KeraSpacing.lg),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Registration Hub Footer
          _buildFooter(context),
        ],
      ),
    );
  }

  /// Top bar with brand and language switch
  Widget _buildTopBanner(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      color: isDark ? const Color(0xFF071322) : KeraColors.primaryNavy,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: KeraSpacing.md),
          child: Row(
            children: [
              const KeraLogoWidget(size: 28, borderRadius: 6),
              const SizedBox(width: 8),
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
              IconButton(
                icon: const Icon(
                  Icons.settings_ethernet_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Server Connection Settings',
                onPressed: () => _showServerConfigDialog(context),
              ),
              const SizedBox(width: 8),
              const LanguageSegmentedSwitch(),
            ],
          ),
        ),
      ),
    );
  }

  /// Screen Intent Title Cluster
  Widget _buildHeaderCluster(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        const Center(
          child: KeraLogoWidget(size: 64, borderRadius: 16),
        ),
        const SizedBox(height: 14),
        Text(
          context.tr('እንኳን ደህና መጡ', 'Welcome to Kera Spare'),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: context.textPrimaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          context.tr(
            'የስልክ ቁጥርዎን እና የይለፍ ቃልዎን በማስገባት ይግቡ',
            'Sign in with your phone and password to continue',
          ),
          style: TextStyle(
            fontSize: 13,
            color: context.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Inline Dynamic Error Alert Box
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: KeraColors.error,
            size: 22,
          ),
          const SizedBox(width: KeraSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _errorMessage ?? 'Authentication Error',
                  style: KeraTypography.labelLarge(color: KeraColors.error).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isOfflineError) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          foregroundColor: KeraColors.error,
                        ),
                        icon: const Icon(Icons.settings_ethernet_rounded, size: 16),
                        label: const Text('Server Settings'),
                        onPressed: () => _showServerConfigDialog(context),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          foregroundColor: KeraColors.error,
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(l10n.retry),
                        onPressed: _handleLogin,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Main Form Card with phone input, password, and submission
  Widget _buildFormCard(BuildContext context) {
    final l10n = context.l10n;

    return KeraCard(
      padding: const EdgeInsets.all(KeraSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Phone Number Label
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.phoneNumber,
                  style: KeraTypography.labelLarge(color: KeraColors.textPrimary).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '/ Phone Number',
                  style: KeraTypography.bodySmall(color: KeraColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Phone Input with Country Code (+251)
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: KeraTypography.bodyLarge(color: KeraColors.textPrimary).copyWith(
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
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
                      const Text('🇪🇹', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        '+251',
                        style: KeraTypography.labelLarge(color: KeraColors.textPrimary).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _phoneController,
                  builder: (context, value, _) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.cancel_rounded, size: 18),
                      color: KeraColors.textSecondary,
                      onPressed: () => _phoneController.clear(),
                    );
                  },
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
              'የኢትዮጵያ ስልክ ቁጥር ቅርጸት (09 ወይም 07)',
              style: KeraTypography.bodySmall(color: KeraColors.textSecondary).copyWith(
                fontSize: 11,
              ),
            ),
            const SizedBox(height: KeraSpacing.md),

            // Password Label
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.password,
                  style: KeraTypography.labelLarge(color: KeraColors.textPrimary).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'ሚስጥራዊ ቁጥር',
                  style: KeraTypography.bodySmall(color: KeraColors.textSecondary).copyWith(
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Password Input
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: KeraTypography.bodyLarge(color: KeraColors.textPrimary).copyWith(
                fontFamily: _obscurePassword ? null : 'monospace',
              ),
              decoration: InputDecoration(
                hintText: l10n.passwordHint,
                prefixIcon: const Icon(
                  Icons.key_rounded,
                  color: KeraColors.textSecondary,
                ),
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
            const SizedBox(height: KeraSpacing.xs),

            // Aux Row: Remember Me & Forgot Password
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 4,
              children: [
                InkWell(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  borderRadius: BorderRadius.circular(KeraRadii.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: KeraColors.actionBlue,
                            onChanged: (val) =>
                                setState(() => _rememberMe = val ?? false),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'አስታውሰኝ (Remember)',
                          style: KeraTypography.bodySmall(color: KeraColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AdminColors.keraOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  child: Text(
                    context.tr('የይለፍ ቃል ረሱ?', 'Forgot password?'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: KeraSpacing.md),

            // Large Orange Login Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.keraOrange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AdminColors.keraOrange.withValues(alpha: 0.5),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(KeraRadii.md),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            context.tr('ይግቡ', 'Login'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Offline Login Hint
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.offline_bolt_outlined, size: 16, color: AdminColors.keraOrange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr(
                        'ከመጀመሪያው ምዝገባ በኋላ ያለ ኢንተርኔት መግባት ይችላሉ።',
                        'You can log in offline after the first sign-in.',
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Admin Shortcut (Debug Mode)
            if (kDebugMode) ...[
              const SizedBox(height: KeraSpacing.sm),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _phoneController.text = '0900000000';
                            _passwordController.text = 'AdminPassword123!';
                            _errorMessage = null;
                          });
                        },
                  icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                  label: const Text('Fill Admin Credentials'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(KeraRadii.md),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Biometric Quick Login Card (matches Stitch retail experience)
  Widget _buildBiometricCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KeraSpacing.md),
      decoration: BoxDecoration(
        color: KeraColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(KeraRadii.xl),
        border: Border.all(color: KeraColors.borderOpaque),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(KeraRadii.md),
              border: Border.all(color: KeraColors.borderOpaque),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.fingerprint_rounded,
              color: KeraColors.actionBlue,
              size: 26,
            ),
          ),
          const SizedBox(width: KeraSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'የጣት አሻራ ፈጣን መግቢያ',
                  style: KeraTypography.labelLarge(color: KeraColors.textPrimary).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Biometric one-tap staff authentication',
                  style: KeraTypography.bodySmall(color: KeraColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KeraRadii.md),
              ),
              side: const BorderSide(color: KeraColors.borderOpaque),
            ),
            icon: const Icon(Icons.touch_app_rounded, size: 16, color: KeraColors.actionBlue),
            label: Text(
              'አንብብ',
              style: KeraTypography.labelMedium(color: KeraColors.actionBlue).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('የጣት አሻራ በመደብሩ ላይ ሲዘጋጅ በቀጥታ ይሰራል።'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Bottom Footer matching Stitch Screen 3
  Widget _buildFooter(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: KeraSpacing.lg,
        vertical: KeraSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(
          top: BorderSide(color: context.borderColor),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'አዲስ የንግድ መደብር ነዎት? ',
                style: KeraTypography.bodySmall(color: KeraColors.textSecondary),
              ),
              InkWell(
                onTap: () => context.go('/register'),
                borderRadius: BorderRadius.circular(KeraRadii.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.dontHaveAccount,
                        style: KeraTypography.labelMedium(color: KeraColors.actionBlue).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.open_in_new_rounded,
                        size: 14,
                        color: KeraColors.actionBlue,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.blueGrey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Kera Spare OS v2.4.1 • Addis Ababa Retail Grid',
                  style: KeraTypography.bodySmall(color: KeraColors.textSecondary).copyWith(
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Server Configuration Dialog (Preserved verbatim for local development & Wi-Fi support)
  Future<void> _showServerConfigDialog(BuildContext context) async {
    final serverController =
        TextEditingController(text: AppConstants.apiBaseUrl);
    String? statusMessage;
    bool isTesting = false;
    bool? testSuccess;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.dns_rounded,
                    color: Theme.of(ctx).colorScheme.primary),
                const SizedBox(width: 8),
                const Expanded(child: Text('Server Settings')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configure API Base URL to connect over Wi-Fi, hotspot, or USB tether:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: serverController,
                    decoration: InputDecoration(
                      labelText: 'API Base URL',
                      hintText: 'http://192.168.137.146:7000/api/v1',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () =>
                            setDialogState(() => serverController.clear()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Quick Presets:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        label: const Text('Wi-Fi (.90)'),
                        onPressed: () {
                          setDialogState(() {
                            serverController.text =
                                'http://192.168.137.90:7000/api/v1';
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('USB (127.0.0.1)'),
                        onPressed: () {
                          setDialogState(() {
                            serverController.text =
                                'http://127.0.0.1:7000/api/v1';
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('Wi-Fi (.146)'),
                        onPressed: () {
                          setDialogState(() {
                            serverController.text =
                                'http://192.168.137.146:7000/api/v1';
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('Emulator (10.0.2.2)'),
                        onPressed: () {
                          setDialogState(() {
                            serverController.text =
                                'http://10.0.2.2:7000/api/v1';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: isTesting
                        ? null
                        : () async {
                            setDialogState(() {
                              isTesting = true;
                              statusMessage = null;
                              testSuccess = null;
                            });
                            try {
                              final url = serverController.text.trim();
                              final testDio = Dio(
                                BaseOptions(
                                  baseUrl: url,
                                  connectTimeout: const Duration(seconds: 3),
                                  receiveTimeout: const Duration(seconds: 3),
                                ),
                              );
                              final res = await testDio.get('/health');
                              if (res.statusCode == 200) {
                                setDialogState(() {
                                  isTesting = false;
                                  testSuccess = true;
                                  statusMessage =
                                      'Connected! Backend is reachable.';
                                });
                              } else {
                                setDialogState(() {
                                  isTesting = false;
                                  testSuccess = false;
                                  statusMessage =
                                      'Server response: ${res.statusCode}';
                                });
                              }
                            } catch (_) {
                              setDialogState(() {
                                isTesting = false;
                                testSuccess = false;
                                statusMessage =
                                    'Connection failed. Check IP & port.';
                              });
                            }
                          },
                    icon: isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.bolt_rounded, size: 18),
                    label: const Text('Test Connection'),
                  ),
                  if (statusMessage != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          testSuccess == true
                              ? Icons.check_circle_rounded
                              : Icons.error_rounded,
                          size: 16,
                          color:
                              testSuccess == true ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            statusMessage!,
                            style: TextStyle(
                              fontSize: 12,
                              color: testSuccess == true
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final target = serverController.text.trim();
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(ctx);
                  if (target.isNotEmpty) {
                    AppConstants.setApiBaseUrl(target);
                    final sessionStore = ref.read(sessionStoreProvider);
                    await sessionStore.saveApiBaseUrl(target);
                    final authRepo = ref.read(authRepositoryProvider);
                    if (authRepo is ApiAuthRepository) {
                      authRepo.dio.options.baseUrl = target;
                    }
                  }
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text('Server URL set to: $target')),
                  );
                },
                child: const Text('Save & Apply'),
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/network_monitor.dart';
import '../../../../core/services/app_lock_service.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../data/local/database_provider.dart';
import '../../data/repositories/api_auth_repository.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_colors.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/phone_number_input.dart';

/// Redesigned Login Screen strictly matching approved Figma design (media_1794818532478_9cad40e8.png):
/// - Unified AuthHeader with Logo plate, KERA SPARE title, Language toggle & Support
/// - Brand Introduction with orange kicker, Amharic & English welcome headings
/// - Form Card with +251 Phone Input, Password with visibility eye toggle, Remember me, Forgot PIN
/// - Deep Navy primary Log in CTA button
/// - Native Touch ID / Biometric authentication button
/// - Footer linking to Merchant Registration and live Security & Online/Offline status
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = true;
  bool _isLoading = false;
  String? _errorMessage;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _warmUpBackend();
    });
  }

  void _warmUpBackend() {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      if (authRepo is ApiAuthRepository) {
        authRepo.warmUp();
      }
    } catch (_) {}
  }

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
    });

    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;
    setState(() => _isLoading = true);

    String phone = _phoneController.text.trim();
    if (phone.startsWith('0')) {
      phone = phone.substring(1);
    }

    final result = await ref.read(authControllerProvider.notifier).login(
          phoneNumber: phone,
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
          final discardAndProceed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: context.isDark ? AuthColors.darkSurface : Colors.white,
              title: Text(
                l10n.authDifferentOwnerConflictTitle,
                style: TextStyle(
                  color: context.isDark ? Colors.white : AuthColors.primaryNavy,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                '${l10n.authDifferentOwnerConflictMessage}\n(${failure.previousOwnerName})',
                style: TextStyle(
                  color: context.isDark ? const Color(0xFFCBD5E1) : AuthColors.secondaryText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    l10n.cancel,
                    style: const TextStyle(color: AuthColors.secondaryText),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuthColors.accentOrange,
                    foregroundColor: Colors.white,
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
            _errorMessage = l10n.authOfflineInternetRequired;
          });
          return;
        }

        if (failure.code == 'NO_INTERNET') {
          setState(() {
            _errorMessage = l10n.authNoInternet;
          });
          return;
        }

        if (failure.code == 'SERVER_UNREACHABLE' || failure is NetworkFailure) {
          setState(() {
            _errorMessage = failure.message;
          });
          return;
        }

        _failedAttempts++;
        if (_failedAttempts >= 5) {
          _lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
        }

        String msg;
        switch (failure.code) {
          case 'WRONG_CREDENTIALS':
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

  Future<void> _handleBiometricLogin() async {
    final lockService = ref.read(appLockServiceProvider);
    final authenticated = await lockService.authenticateWithBiometrics(
      context.tr(
        'በጣት አሻራ ወይም በፊት ለይቶ ማወቅ ይግቡ',
        'Authenticate with Touch ID / Face ID to log in',
      ),
    );

    if (authenticated && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final backgroundColor = AuthColors.bgOf(isDark);
    final cardBg = AuthColors.surfaceOf(isDark);
    final borderColor = AuthColors.borderOf(isDark);
    final textPrimary = AuthColors.textPrimaryOf(isDark);
    final textSecondary = AuthColors.textSecondaryOf(isDark);

    final isOnline = ref.watch(isOnlineProvider).value ?? true;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Row (Back, Logo, Title, Language, Support)
            AuthHeader(
              subtitle: 'Login',
              onBackPressed: () {
                if (Navigator.of(context).canPop()) {
                  context.pop();
                }
              },
            ),

            // 2. Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),

                        // 2.1 Brand Introduction Section
                        _buildBrandIntroduction(context, isDark, textPrimary, textSecondary),
                        const SizedBox(height: 24),

                        // 2.2 Error Message Banner
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AuthColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AuthColors.error.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AuthColors.error, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: AuthColors.error,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // 2.3 Form Card
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: borderColor),
                            boxShadow: const [
                              BoxShadow(
                                color: AuthColors.cardShadow,
                                blurRadius: 16,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Phone Number Input
                                PhoneNumberInput(
                                  controller: _phoneController,
                                  isRequired: false,
                                ),
                                const SizedBox(height: 18),

                                // Password Input
                                AuthTextField(
                                  label: 'Password',
                                  amharicLabel: 'የይለፍ ቃል',
                                  hintText: 'Enter your password',
                                  controller: _passwordController,
                                  prefixIcon: Icons.lock_outline_rounded,
                                  isPassword: true,
                                  isRequired: false,
                                  validator: (val) {
                                    if (val == null || val.isEmpty) {
                                      return context.tr(
                                        'የይለፍ ቃልዎን ያስገቡ',
                                        'Please enter your password',
                                      );
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                // Remember Me & Forgot PIN Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => setState(() => _rememberMe = !_rememberMe),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 19,
                                              height: 19,
                                              decoration: BoxDecoration(
                                                color: _rememberMe ? AuthColors.primaryNavy : Colors.transparent,
                                                borderRadius: BorderRadius.circular(5),
                                                border: Border.all(
                                                  color: _rememberMe ? AuthColors.primaryNavy : borderColor,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: _rememberMe
                                                  ? const Icon(
                                                      Icons.check_rounded,
                                                      size: 14,
                                                      color: Colors.white,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                'Remember me',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: textPrimary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () => context.push('/forgot-password'),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      child: const Text(
                                        'Forgot PIN?',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AuthColors.primaryNavy,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Primary Log In CTA Button
                                AuthPrimaryButton(
                                  label: 'Log in',
                                  isLoading: _isLoading,
                                  onPressed: () => _handleLogin(),
                                ),
                                const SizedBox(height: 12),

                                // Secondary Biometric Login Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: OutlinedButton(
                                    onPressed: _handleBiometricLogin,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: textPrimary,
                                      side: BorderSide(color: borderColor, width: 1.0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.fingerprint_rounded,
                                            size: 20,
                                            color: textPrimary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Log in with Touch ID',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // 2.4 Footer: Create a merchant account
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'New to Kera Spare?',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => context.push('/register'),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Create a merchant account',
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? const Color(0xFF60A5FA) : AuthColors.primaryNavy,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 16,
                                          color: isDark ? const Color(0xFF60A5FA) : AuthColors.primaryNavy,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 2.5 Security & Connectivity Status
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 16,
                                color: textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Secure & private',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '·',
                                  style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                width: 7.5,
                                height: 7.5,
                                decoration: BoxDecoration(
                                  color: isOnline ? AuthColors.success : AuthColors.accentOrange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isOnline ? 'Online' : 'Offline',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
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

  Widget _buildBrandIntroduction(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Orange Kicker Bar: "— BUILT FOR YOUR BUSINESS"
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 3,
                decoration: BoxDecoration(
                  color: AuthColors.accentOrange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'BUILT FOR YOUR BUSINESS',
                style: TextStyle(
                  color: Color(0xFFB45309),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Amharic Welcome Heading
        Text(
          'እንኳን ደህና መጡ!',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w900,
            color: textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),

        // English Welcome Heading
        Text(
          'WELCOME BACK',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            color: textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Log in to manage your inventory & sales.',
          style: TextStyle(
            fontSize: 13.5,
            color: textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

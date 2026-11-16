import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/services/app_lock_service.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/kera_logo_widget.dart';
import '../../../../data/local/database_provider.dart';
import '../../data/repositories/api_auth_repository.dart';
import '../controllers/auth_controller.dart';

/// Pixel-perfect native mobile login screen strictly matching Stitch Design Page 03.
///
/// Features:
/// - Faded heavy-machinery watermark backdrop (excavator & dump truck)
/// - Two-tone brand hero: "እንኳን ደህና መጡ!" + "WELCOME BACK"
/// - Phone Number field with Ethiopian flag pill [🇪🇹 +251 ▾] and phone icon
/// - Password field with lock icon and visibility eye toggle
/// - "Remember me" checkbox + "Forgot PIN?" link
/// - Deep Navy primary CTA: "ግቡ / Log In →"
/// - Trust banner: "ደህንነት የተረጋገጠ / Secure & Reliable Access" + Online indicator
/// - Biometric Quick Login: "እክ / Touch ID Login"
/// - Footer: "Don't have an account? Register Shop ›" + District Signature
/// - Bottom fluid accent waves in Brand Navy & Orange
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
      _isOfflineError = false;
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
              backgroundColor: context.isDark ? KeraColors.navy800 : Colors.white,
              title: Text(
                l10n.authDifferentOwnerConflictTitle,
                style: TextStyle(
                  color: context.isDark ? Colors.white : KeraColors.navy900,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                '${l10n.authDifferentOwnerConflictMessage}\n(${failure.previousOwnerName})',
                style: TextStyle(
                  color: context.isDark ? KeraColors.navy100 : KeraColors.textMutedColor,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    l10n.cancel,
                    style: const TextStyle(color: KeraColors.textMutedColor),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KeraColors.orange700,
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

        if (failure.code == 'SERVER_UNREACHABLE' || failure is NetworkFailure) {
          setState(() {
            _isOfflineError = true;
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

    return Scaffold(
      backgroundColor: isDark ? KeraColors.navy900 : KeraColors.navy50,
      body: Stack(
        children: [
          // Background ambient gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: isDark
                    ? const RadialGradient(
                        center: Alignment(0, -0.6),
                        radius: 1.2,
                        colors: [
                          KeraColors.splashRadialNavy,
                          KeraColors.navy900,
                        ],
                      )
                    : const RadialGradient(
                        center: Alignment(0, -0.7),
                        radius: 1.1,
                        colors: [
                          KeraColors.splashBgLightWarm,
                          KeraColors.splashBgLightNeutral,
                          KeraColors.navy50,
                        ],
                      ),
              ),
            ),
          ),

          // Main scrollable canvas
          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                _buildTopAppBar(context),

                // Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 6.0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Hero Brand & Watermark Section
                            _buildHeroSection(context),
                            const SizedBox(height: 16),

                            // 2. Error Banner (if any)
                            if (_errorMessage != null) ...[
                              _buildErrorBanner(context),
                              const SizedBox(height: 12),
                            ],

                            // 3. Main Form Card
                            _buildLoginFormCard(context),
                            const SizedBox(height: 18),

                            // 4. Footer & District Signature
                            _buildFooter(context),
                            const SizedBox(height: 38), // space for bottom wave
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Fluid Accent Waves (Brand Navy & Orange)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 18,
            child: IgnorePointer(
              child: CustomPaint(
                painter: _BottomWavePainter(isDark: isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top App Bar
  // ---------------------------------------------------------------------------
  Widget _buildTopAppBar(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : KeraColors.navy900,
              size: 24,
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/welcome');
              }
            },
            tooltip: 'ወደ ኋላ / Back',
          ),
          const SizedBox(width: 4),

          // Squircle Kera Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: KeraColors.navy900,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(5),
            child: const KeraLogoWidget(
              size: 26,
              borderRadius: 6,
              showShadow: false,
              backgroundColor: Colors.transparent,
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'KERA SPARE',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: KeraTypography.fontLatin,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: isDark ? Colors.white : KeraColors.navy900,
                  ),
                ),
                const Text(
                  'Login',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: KeraTypography.fontLatin,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: KeraColors.textMutedColor,
                  ),
                ),
              ],
            ),
          ),

          // Language Switcher Pill: [🌐 EN ▾]
          _buildLanguagePill(context),
          const SizedBox(width: 8),

          // Customer Support Pill [🎧]
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? KeraColors.navy800 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? KeraColors.navy600.withValues(alpha: 0.4)
                    : KeraColors.border,
                width: 1,
              ),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.headset_mic_outlined,
                size: 20,
                color: isDark ? Colors.white : KeraColors.navy800,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('የደንበኞች ድጋፍ: +251 911 000 000 / support@keraspares.com'),
                    backgroundColor: KeraColors.navy800,
                  ),
                );
              },
              tooltip: 'ድጋፍ / Support',
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _buildLanguagePill(BuildContext context) {
    final isDark = context.isDark;
    final currentLocale = ref.watch(localeControllerProvider);
    final isAmharic = currentLocale.languageCode == 'am';

    return InkWell(
      onTap: () {
        ref.read(localeControllerProvider.notifier).toggleLocale();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? KeraColors.navy800 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? KeraColors.navy600.withValues(alpha: 0.4)
                : KeraColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language_rounded,
              size: 16,
              color: isDark ? Colors.white : KeraColors.navy800,
            ),
            const SizedBox(width: 5),
            Text(
              isAmharic ? 'አማ' : 'EN',
              style: TextStyle(
                fontFamily: KeraTypography.fontLatin,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : KeraColors.navy900,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isDark ? KeraColors.navy100 : KeraColors.textMutedColor,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Hero Section with Machinery Watermarks & Official Logo
  // ---------------------------------------------------------------------------
  Widget _buildHeroSection(BuildContext context) {
    final isDark = context.isDark;
    final l10n = context.l10n;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Faded heavy machinery vector watermarks (Excavator on left, Truck on right)
        Positioned.fill(
          child: CustomPaint(
            painter: _MachineryWatermarkPainter(isDark: isDark),
          ),
        ),

        // Central Logo & Titles
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Center Logo Container
            Container(
              width: 105,
              height: 105,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? KeraColors.navy800 : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : KeraColors.navy800.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: KeraLogoWidget(
                  size: 85,
                  borderRadius: 14,
                  showShadow: false,
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Amharic Heading: "እንኳን ደህና መጡ!"
            Text(
              l10n.welcomeBackGreetingAm,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: KeraTypography.fontEthiopic,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : KeraColors.navy900,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),

            // Orange Heading: "WELCOME BACK"
            Text(
              l10n.welcomeBackCaps,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: KeraTypography.fontLatin,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: KeraColors.orange600,
              ),
            ),
            const SizedBox(height: 4),

            // Subtitle: "Log in to manage your inventory & sales"
            Text(
              l10n.loginHeroSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: KeraTypography.fontLatin,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: isDark ? KeraColors.navy100 : KeraColors.textMutedColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Error Banner
  // ---------------------------------------------------------------------------
  Widget _buildErrorBanner(BuildContext context) {
    final l10n = context.l10n;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? KeraColors.orange700.withValues(alpha: 0.2)
            : KeraColors.errorLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: KeraColors.orange500.withValues(alpha: 0.7),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: KeraColors.orange700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontFamily: KeraTypography.fontEthiopic,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: KeraColors.orange700,
                  ),
                ),
              ),
            ],
          ),
          if (_isOfflineError) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: KeraColors.orange700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 15),
                label: Text(
                  l10n.retry,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
                onPressed: _isLoading ? null : () => _handleLogin(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main Form Card
  // ---------------------------------------------------------------------------
  Widget _buildLoginFormCard(BuildContext context) {
    final isDark = context.isDark;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? KeraColors.navy800 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? KeraColors.navy600.withValues(alpha: 0.4)
              : KeraColors.border.withValues(alpha: 0.7),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : KeraColors.navy800.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Phone Number Label: ስልክ ቁጥር / Phone Number *
            _buildFieldLabel(context, label: l10n.phoneLabelWithAm, isRequired: true),
            const SizedBox(height: 6),
            _buildPhoneInputField(context),
            const SizedBox(height: 16),

            // 2. Password Label: የይለፍ ቃል / Password *
            _buildFieldLabel(context, label: l10n.passwordLabelWithAm, isRequired: true),
            const SizedBox(height: 6),
            _buildPasswordInputField(context),
            const SizedBox(height: 12),

            // 3. Options Sub-Row: Remember me & Forgot PIN?
            _buildOptionsSubRow(context),
            const SizedBox(height: 18),

            // 4. Primary CTA Button: "ግቡ / Log In →"
            _buildLoginButton(context),
            const SizedBox(height: 16),

            // 5. Trust & Connectivity Banner
            _buildTrustAndConnectivityBanner(context),
            const SizedBox(height: 14),

            // 6. Biometric Quick Login: "እክ / Touch ID Login"
            _buildBiometricButton(context),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Field Label with Required Asterisk
  // ---------------------------------------------------------------------------
  Widget _buildFieldLabel(
    BuildContext context, {
    required String label,
    required bool isRequired,
  }) {
    final isDark = context.isDark;

    return RichText(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: KeraTypography.fontLatin,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : KeraColors.navy900,
        ),
        children: isRequired
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: KeraColors.orange700,
                  ),
                ),
              ]
            : null,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phone Input Field with Ethiopian Flag Dropdown Pill & Receiver Icon
  // ---------------------------------------------------------------------------
  Widget _buildPhoneInputField(BuildContext context) {
    final isDark = context.isDark;
    final l10n = context.l10n;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? KeraColors.navy900.withValues(alpha: 0.5) : KeraColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? KeraColors.navy600.withValues(alpha: 0.4)
              : KeraColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Flag Container Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🇪🇹',
                  style: TextStyle(fontSize: 17),
                ),
                const SizedBox(width: 5),
                Text(
                  '+251',
                  style: TextStyle(
                    fontFamily: KeraTypography.fontLatin,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : KeraColors.navy900,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: isDark ? KeraColors.navy100 : KeraColors.textMutedColor,
                ),
              ],
            ),
          ),

          // Vertical Separator Line
          Container(
            width: 1,
            height: 24,
            color: isDark
                ? KeraColors.navy600.withValues(alpha: 0.5)
                : KeraColors.border,
          ),
          const SizedBox(width: 8),

          // Phone Number Input
          Expanded(
            child: TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(
                fontFamily: KeraTypography.fontLatin,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : KeraColors.navy900,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 13),
                hintText: l10n.phoneInputHint,
                hintStyle: const TextStyle(
                  fontFamily: KeraTypography.fontLatin,
                  fontSize: 13,
                  letterSpacing: 0.5,
                  color: KeraColors.textMutedColor,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
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
          ),

          // Phone Outline Icon on right
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Icon(
              Icons.phone_outlined,
              size: 20,
              color: isDark ? KeraColors.navy100 : KeraColors.textMutedColor,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Password Input Field with Lock Icon & Visibility Toggle
  // ---------------------------------------------------------------------------
  Widget _buildPasswordInputField(BuildContext context) {
    final isDark = context.isDark;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? KeraColors.navy900.withValues(alpha: 0.5) : KeraColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? KeraColors.navy600.withValues(alpha: 0.4)
              : KeraColors.border,
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: TextStyle(
          fontFamily: KeraTypography.fontLatin,
          fontSize: 14,
          color: isDark ? Colors.white : KeraColors.navy900,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          hintText: l10n.enterYourPasswordHint,
          hintStyle: const TextStyle(
            fontFamily: KeraTypography.fontLatin,
            fontSize: 13,
            color: KeraColors.textMutedColor,
          ),
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            size: 20,
            color: isDark ? KeraColors.navy100 : KeraColors.textMutedColor,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: isDark ? KeraColors.navy100 : KeraColors.textMutedColor,
              size: 20,
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
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
    );
  }

  // ---------------------------------------------------------------------------
  // Options Sub-Row: Remember Me Checkbox & Forgot PIN?
  // ---------------------------------------------------------------------------
  Widget _buildOptionsSubRow(BuildContext context) {
    final isDark = context.isDark;
    final l10n = context.l10n;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Remember Me
        InkWell(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _rememberMe ? KeraColors.navy900 : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: _rememberMe
                          ? KeraColors.navy900
                          : (isDark ? KeraColors.navy100 : KeraColors.border),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.rememberMeAm,
                      style: TextStyle(
                        fontFamily: KeraTypography.fontEthiopic,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : KeraColors.navy900,
                      ),
                    ),
                    Text(
                      l10n.rememberMeEn,
                      style: const TextStyle(
                        fontFamily: KeraTypography.fontLatin,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: KeraColors.textMutedColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Right: Forgot PIN? Link
        InkWell(
          onTap: () {
            context.push('/forgot-password');
          },
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.forgotPasswordAm,
                  style: TextStyle(
                    fontFamily: KeraTypography.fontEthiopic,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : KeraColors.navy900,
                  ),
                ),
                Text(
                  l10n.forgotPinOrange,
                  style: const TextStyle(
                    fontFamily: KeraTypography.fontLatin,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: KeraColors.orange600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Primary Submit CTA Button: "ግቡ / Log In →"
  // ---------------------------------------------------------------------------
  Widget _buildLoginButton(BuildContext context) {
    final l10n = context.l10n;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _handleLogin(),
        style: ElevatedButton.styleFrom(
          backgroundColor: KeraColors.navy900,
          foregroundColor: Colors.white,
          disabledBackgroundColor: KeraColors.navy900.withValues(alpha: 0.6),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    context.tr(
                      'ሰርቨር እየተገናኘ ነው...',
                      'Connecting to cloud...',
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.logInCta,
                    style: const TextStyle(
                      fontFamily: KeraTypography.fontLatin,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ],
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Trust & Connectivity Status Banner
  // ---------------------------------------------------------------------------
  Widget _buildTrustAndConnectivityBanner(BuildContext context) {
    final isDark = context.isDark;
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? KeraColors.navy900.withValues(alpha: 0.5)
            : KeraColors.flagContainerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? KeraColors.navy600.withValues(alpha: 0.3)
              : KeraColors.border.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Shield Icon Badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? KeraColors.navy800 : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.security_rounded,
              size: 19,
              color: KeraColors.navy800,
            ),
          ),
          const SizedBox(width: 10),

          // Security Titles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    text: '${l10n.secureReliableTitle} ',
                    style: TextStyle(
                      fontFamily: KeraTypography.fontEthiopic,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : KeraColors.navy900,
                    ),
                    children: [
                      TextSpan(
                        text: l10n.secureReliableAccess,
                        style: const TextStyle(
                          fontFamily: KeraTypography.fontLatin,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.secureReliableSubtitle,
                  style: const TextStyle(
                    fontFamily: KeraTypography.fontLatin,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: KeraColors.textMutedColor,
                  ),
                ),
              ],
            ),
          ),

          // Vertical Divider
          Container(
            width: 1,
            height: 28,
            color: isDark
                ? KeraColors.navy600.withValues(alpha: 0.4)
                : KeraColors.border,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),

          // Online Status
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Icon(
                    Icons.wifi_rounded,
                    size: 18,
                    color: isDark ? Colors.white : KeraColors.navy900,
                  ),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: KeraColors.orange500,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Online',
                style: TextStyle(
                  fontFamily: KeraTypography.fontLatin,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : KeraColors.navy900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Biometric Quick Login Button: "እክ / Touch ID Login"
  // ---------------------------------------------------------------------------
  Widget _buildBiometricButton(BuildContext context) {
    final isDark = context.isDark;
    final l10n = context.l10n;

    return Center(
      child: InkWell(
        onTap: _handleBiometricLogin,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? KeraColors.navy900.withValues(alpha: 0.7)
                : KeraColors.flagContainerBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? KeraColors.navy600.withValues(alpha: 0.35)
                  : KeraColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fingerprint_rounded,
                size: 20,
                color: isDark ? Colors.white : KeraColors.navy900,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.biometricLoginLabel,
                style: TextStyle(
                  fontFamily: KeraTypography.fontLatin,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : KeraColors.navy900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Footer & District Signature
  // ---------------------------------------------------------------------------
  Widget _buildFooter(BuildContext context) {
    final isDark = context.isDark;
    final l10n = context.l10n;

    return Column(
      children: [
        // Divider
        Divider(
          height: 1,
          thickness: 1,
          color: isDark
              ? KeraColors.navy600.withValues(alpha: 0.25)
              : KeraColors.border.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 14),

        // Don't have an account?
        Text(
          l10n.dontHaveAccountAmEn,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: KeraTypography.fontLatin,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? KeraColors.navy100 : KeraColors.textMutedColor,
          ),
        ),
        const SizedBox(height: 6),

        // Register Shop ›
        InkWell(
          onTap: () => context.go('/register'),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              l10n.registerShopLink,
              style: TextStyle(
                fontFamily: KeraTypography.fontLatin,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : KeraColors.navy900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // District Signature: KERA AUTOMOTIVE DISTRICT • ADDIS ABABA
        Text(
          l10n.keraDistrictFooter,
          style: const TextStyle(
            fontFamily: KeraTypography.fontLatin,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: KeraColors.textMutedColor,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Machinery Watermark Painter (Excavator on Left, Dump Truck on Right)
// =============================================================================
class _MachineryWatermarkPainter extends CustomPainter {
  final bool isDark;

  const _MachineryWatermarkPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = isDark
          ? KeraColors.navy600.withValues(alpha: 0.09)
          : KeraColors.navy800.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final fillPaint = Paint()
      ..color = isDark
          ? KeraColors.navy600.withValues(alpha: 0.04)
          : KeraColors.navy800.withValues(alpha: 0.02)
      ..style = PaintingStyle.fill;

    // 1. Excavator on left (boom, cab, tracks)
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.02, h * 0.70, w * 0.22, h * 0.16),
      const Radius.circular(6),
    );
    canvas.drawRRect(trackRect, fillPaint);
    canvas.drawRRect(trackRect, paint);

    // Cab
    final cabRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.48, w * 0.14, h * 0.22),
      const Radius.circular(4),
    );
    canvas.drawRRect(cabRect, fillPaint);
    canvas.drawRRect(cabRect, paint);

    // Boom arm
    final boomPath = Path()
      ..moveTo(w * 0.18, h * 0.54)
      ..lineTo(w * 0.04, h * 0.20)
      ..lineTo(w * 0.16, h * 0.12)
      ..lineTo(w * 0.24, h * 0.28);
    canvas.drawPath(boomPath, paint);

    // 2. Heavy Dump Truck on right (chassis, wheels, bed)
    final bedPath = Path()
      ..moveTo(w * 0.74, h * 0.38)
      ..lineTo(w * 0.96, h * 0.42)
      ..lineTo(w * 0.94, h * 0.68)
      ..lineTo(w * 0.76, h * 0.68)
      ..close();
    canvas.drawPath(bedPath, fillPaint);
    canvas.drawPath(bedPath, paint);

    // Cab
    final truckCab = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.68, h * 0.46, w * 0.10, h * 0.24),
      const Radius.circular(4),
    );
    canvas.drawRRect(truckCab, fillPaint);
    canvas.drawRRect(truckCab, paint);

    // Heavy wheels
    canvas.drawCircle(Offset(w * 0.72, h * 0.76), 11, paint);
    canvas.drawCircle(Offset(w * 0.88, h * 0.76), 11, paint);
  }

  @override
  bool shouldRepaint(covariant _MachineryWatermarkPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

// =============================================================================
// Bottom Ambient Wave Painter (Brand Navy & Orange Swooshes)
// =============================================================================
class _BottomWavePainter extends CustomPainter {
  final bool isDark;

  const _BottomWavePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Navy Wave
    final navyPaint = Paint()
      ..color = isDark ? KeraColors.navy800 : KeraColors.navy900
      ..style = PaintingStyle.fill;

    final navyPath = Path()
      ..moveTo(0, h * 0.4)
      ..quadraticBezierTo(w * 0.25, h * 0.8, w * 0.55, h * 0.3)
      ..quadraticBezierTo(w * 0.8, -h * 0.1, w, h * 0.5)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(navyPath, navyPaint);

    // Orange Accent Wave
    final orangePaint = Paint()
      ..color = KeraColors.orange500
      ..style = PaintingStyle.fill;

    final orangePath = Path()
      ..moveTo(w * 0.3, h)
      ..quadraticBezierTo(w * 0.55, h * 0.4, w * 0.8, h * 0.6)
      ..quadraticBezierTo(w * 0.92, h * 0.75, w, h * 0.2)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(orangePath, orangePaint);
  }

  @override
  bool shouldRepaint(covariant _BottomWavePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}


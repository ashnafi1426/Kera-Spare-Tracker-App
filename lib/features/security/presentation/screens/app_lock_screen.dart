import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/app_lock_service.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';

/// Screen displayed when the app is locked.
/// Features a large, accessible numeric keypad, visual PIN indicators,
/// biometric quick unlock, attempt throttling cooldown countdown,
/// and a secure "Forgot PIN" recovery flow via online login.
class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  String _enteredPin = '';
  String? _errorMessage;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(appLockServiceProvider).checkBiometricsSupport();
      if (mounted) {
        await _promptBiometricsIfEnabled();
      }
    });
  }

  Future<void> _promptBiometricsIfEnabled() async {
    final lockService = ref.read(appLockServiceProvider);
    final state = lockService.state;
    if (state.isBiometricsEnabled &&
        !state.isInCooldown &&
        !state.isMaxLocked) {
      final l10n = context.l10n;
      await lockService.authenticateWithBiometrics(l10n.biometricPromptReason);
    }
  }

  void _onDigitPressed(String digit) {
    final lockState = ref.watch(appLockStateProvider);
    if (lockState.isInCooldown || lockState.isMaxLocked || _isVerifying) return;
    if (_enteredPin.length >= 6) return;

    HapticFeedback.lightImpact();
    final newPin = _enteredPin + digit;
    setState(() {
      _enteredPin = newPin;
      _errorMessage = null;
    });

    final expectedLen = lockState.pinLength.clamp(4, 6);
    if (newPin.length == expectedLen) {
      _checkPin(newPin, recordFailure: true);
    } else if (newPin.length >= 4 && newPin.length < expectedLen) {
      // Check silently in case stored length is larger than actual PIN
      _checkPin(newPin, recordFailure: false);
    } else if (newPin.length == 6) {
      _checkPin(newPin, recordFailure: true);
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isEmpty || _isVerifying) return;
    HapticFeedback.selectionClick();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorMessage = null;
    });
  }

  Future<void> _checkPin(String pin, {bool recordFailure = true}) async {
    final lockService = ref.read(appLockServiceProvider);
    setState(() => _isVerifying = true);

    final success = await lockService.verifyPin(pin, recordFailure: recordFailure);
    if (!mounted) return;

    if (success) {
      await HapticFeedback.mediumImpact();
      setState(() {
        _enteredPin = '';
        _errorMessage = null;
        _isVerifying = false;
      });
    } else {
      if (recordFailure) {
        await HapticFeedback.vibrate();
        final currentState = lockService.state;
        setState(() {
          _enteredPin = '';
          _isVerifying = false;
          if (currentState.isMaxLocked) {
            _errorMessage = context.l10n.lockoutMaxReached;
          } else if (currentState.isInCooldown) {
            _errorMessage = context.l10n
                .lockoutCooldown(currentState.remainingCooldownSeconds);
          } else {
            _errorMessage = context.l10n
                .wrongPin(currentState.remainingAttemptsUntilLockout);
          }
        });
      } else {
        setState(() => _isVerifying = false);
      }
    }
  }

  void _showForgotPinDialog() {
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final pinController1 = TextEditingController();
    final pinController2 = TextEditingController();
    bool isSubmitting = false;
    String? dialogError;
    int currentStep = 0; // 0: Verify Phone/Password, 1: Enter New PIN

    // Prefill phone if user is logged in
    final currentUser = ref.read(authControllerProvider).value;
    if (currentUser != null) {
      phoneController.text = currentUser.phoneNumber;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final l10n = ctx.l10n;
            final colorScheme = ctx.colorScheme;

            return AlertDialog(
              title: Text(currentStep == 0
                  ? l10n.forgotPinTitle
                  : l10n.setPinTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentStep == 0) ...[
                      Text(
                        l10n.forgotPinDesc,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: l10n.phoneNumber,
                          prefixIcon: const Icon(Icons.phone_rounded),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: l10n.password,
                          prefixIcon: const Icon(Icons.lock_rounded),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ] else ...[
                      Text(
                        l10n.enterNewPin,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: pinController1,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: l10n.enterNewPin,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: pinController2,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: l10n.reenterPin,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        dialogError!,
                        style: TextStyle(
                          color: colorScheme.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (isSubmitting) ...[
                      const SizedBox(height: 16),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (currentStep == 0) {
                            final phone = phoneController.text.trim();
                            final pass = passwordController.text;
                            if (phone.isEmpty || pass.isEmpty) {
                              setDialogState(() {
                                dialogError = l10n.fieldRequired;
                              });
                              return;
                            }

                            setDialogState(() {
                              isSubmitting = true;
                              dialogError = null;
                            });

                            final result = await ref
                                .read(authControllerProvider.notifier)
                                .login(phoneNumber: phone, password: pass);

                            if (result.isSuccess) {
                              setDialogState(() {
                                isSubmitting = false;
                                currentStep = 1;
                                dialogError = null;
                              });
                            } else {
                              setDialogState(() {
                                isSubmitting = false;
                                dialogError = result.failureOrNull?.message ??
                                    'Authentication failed';
                              });
                            }
                          } else {
                            final pin1 = pinController1.text.trim();
                            final pin2 = pinController2.text.trim();
                            if (pin1.length < 4 || pin1.length > 6) {
                              setDialogState(() {
                                dialogError = l10n.pinLengthError;
                              });
                              return;
                            }
                            if (pin1 != pin2) {
                              setDialogState(() {
                                dialogError = l10n.pinsDoNotMatch;
                              });
                              return;
                            }

                            setDialogState(() {
                              isSubmitting = true;
                              dialogError = null;
                            });

                            final success = await ref
                                .read(appLockServiceProvider)
                                .setPin(pin1);

                            if (success) {
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                context.showSnackBar(l10n.pinSetSuccess);
                              }
                            } else {
                              setDialogState(() {
                                isSubmitting = false;
                                dialogError = 'Failed to save new PIN';
                              });
                            }
                          }
                        },
                  child: Text(currentStep == 0
                      ? l10n.loginToResetPin
                      : l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockStateProvider);
    final l10n = context.l10n;
    final colorScheme = context.colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        children: [
                          const Spacer(flex: 1),

                          // Lock icon
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_rounded,
                              size: 40,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // App title & subtitle
                          Text(
                            l10n.appName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lockState.isMaxLocked
                                ? l10n.lockoutMaxReached
                                : lockState.isInCooldown
                                    ? l10n.lockoutCooldown(
                                        lockState.remainingCooldownSeconds)
                                    : l10n.enterPinToUnlock,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: lockState.isMaxLocked || lockState.isInCooldown
                                  ? colorScheme.error
                                  : colorScheme.onSurfaceVariant,
                              fontWeight:
                                  lockState.isInCooldown || lockState.isMaxLocked
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // PIN Dots (dynamic: 4 to 6 based on configured PIN length)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(lockState.pinLength.clamp(4, 6), (index) {
                              final isFilled = index < _enteredPin.length;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isFilled
                                      ? colorScheme.primary
                                      : colorScheme.surfaceContainerHighest,
                                  border: Border.all(
                                    color: isFilled
                                        ? colorScheme.primary
                                        : colorScheme.outlineVariant,
                                    width: 2,
                                  ),
                                ),
                              );
                            }),
                          ),

                          // Error message
                          SizedBox(
                            height: 36,
                            child: Center(
                              child: _errorMessage != null
                                  ? Text(
                                      _errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: colorScheme.error,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  : null,
                            ),
                          ),

                          const Spacer(flex: 1),

                          // Accessible Numeric Keypad
                          if (!lockState.isMaxLocked) ...[
                            _buildKeypadRow(['1', '2', '3']),
                            const SizedBox(height: 12),
                            _buildKeypadRow(['4', '5', '6']),
                            const SizedBox(height: 12),
                            _buildKeypadRow(['7', '8', '9']),
                            const SizedBox(height: 12),
                            _buildBottomKeypadRow(lockState),
                          ] else ...[
                            // If max locked, direct to online login
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 52),
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                ),
                                icon: const Icon(Icons.login_rounded),
                                label: Text(
                                  l10n.loginToResetPin,
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                onPressed: _showForgotPinDialog,
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Forgot PIN button
                          if (!lockState.isMaxLocked)
                            TextButton(
                              onPressed: _showForgotPinDialog,
                              child: Text(
                                l10n.forgotPin,
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                          const Spacer(flex: 1),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((d) => _buildKeypadButton(d)).toList(),
    );
  }

  Widget _buildBottomKeypadRow(AppLockState lockState) {
    final showBiometric =
        lockState.isBiometricsSupported || lockState.isBiometricsEnabled;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Biometrics button
        if (showBiometric)
          _buildActionButton(
            icon: Icons.fingerprint_rounded,
            onPressed: () async {
              final l10n = context.l10n;
              final lockService = ref.read(appLockServiceProvider);
              final success = await lockService
                  .authenticateWithBiometrics(l10n.biometricPromptReason);
              if (success && !lockState.isBiometricsEnabled) {
                await lockService.setBiometricsEnabled(true);
              }
            },
          )
        else
          const SizedBox(width: 80, height: 64),

        _buildKeypadButton('0'),

        // Backspace button
        _buildActionButton(
          icon: Icons.backspace_outlined,
          onPressed: _onBackspacePressed,
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String digit) {
    final colorScheme = context.colorScheme;
    return Container(
      width: 80,
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: () => _onDigitPressed(digit),
          child: Center(
            child: Text(
              digit,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final colorScheme = context.colorScheme;
    return Container(
      width: 80,
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: onPressed,
          child: Center(
            child: Icon(
              icon,
              size: 28,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

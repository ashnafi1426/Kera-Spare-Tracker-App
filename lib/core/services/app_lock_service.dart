import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../utils/password_hasher.dart';
import 'storage_service.dart';

final appLockServiceProvider = Provider<AppLockService>((ref) {
  final service = AppLockService();
  service.init();
  ref.onDispose(service.dispose);
  return service;
});

class AppLockNotifier extends Notifier<AppLockState> {
  late final AppLockService _service;

  @override
  AppLockState build() {
    _service = ref.watch(appLockServiceProvider);
    final sub = _service.stateStream.listen((newState) {
      state = newState;
    });
    ref.onDispose(sub.cancel);
    return _service.state;
  }
}

final appLockStateProvider =
    NotifierProvider<AppLockNotifier, AppLockState>(AppLockNotifier.new);


enum AppLockTimeout {
  immediately(0),
  oneMinute(60),
  fiveMinutes(300);

  final int seconds;
  const AppLockTimeout(this.seconds);

  static AppLockTimeout fromSeconds(int seconds) {
    return AppLockTimeout.values.firstWhere(
      (t) => t.seconds == seconds,
      orElse: () => AppLockTimeout.immediately,
    );
  }
}

class AppLockState {
  final bool isEnabled;
  final bool isLocked;
  final bool isBiometricsEnabled;
  final bool isBiometricsSupported;
  final AppLockTimeout timeout;
  final int pinLength;
  final int failedAttempts;
  final int remainingCooldownSeconds;
  final bool isMaxLocked;

  const AppLockState({
    required this.isEnabled,
    required this.isLocked,
    required this.isBiometricsEnabled,
    required this.isBiometricsSupported,
    required this.timeout,
    this.pinLength = 4,
    required this.failedAttempts,
    required this.remainingCooldownSeconds,
    required this.isMaxLocked,
  });

  bool get isInCooldown => remainingCooldownSeconds > 0;
  int get remainingAttemptsUntilLockout => (10 - failedAttempts).clamp(0, 10);

  AppLockState copyWith({
    bool? isEnabled,
    bool? isLocked,
    bool? isBiometricsEnabled,
    bool? isBiometricsSupported,
    AppLockTimeout? timeout,
    int? pinLength,
    int? failedAttempts,
    int? remainingCooldownSeconds,
    bool? isMaxLocked,
  }) {
    return AppLockState(
      isEnabled: isEnabled ?? this.isEnabled,
      isLocked: isLocked ?? this.isLocked,
      isBiometricsEnabled: isBiometricsEnabled ?? this.isBiometricsEnabled,
      isBiometricsSupported: isBiometricsSupported ?? this.isBiometricsSupported,
      timeout: timeout ?? this.timeout,
      pinLength: pinLength ?? this.pinLength,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      remainingCooldownSeconds:
          remainingCooldownSeconds ?? this.remainingCooldownSeconds,
      isMaxLocked: isMaxLocked ?? this.isMaxLocked,
    );
  }
}

class AppLockService {
  static const String keyAppLockEnabled = 'kera_app_lock_enabled';
  static const String keyPinHash = 'kera_app_lock_pin_hash';
  static const String keyPinLength = 'kera_app_lock_pin_length';
  static const String keyBiometricsEnabled = 'kera_app_lock_biometrics_enabled';
  static const String keyTimeoutSeconds = 'kera_app_lock_timeout_seconds';
  static const String keyFailedAttempts = 'kera_app_lock_failed_attempts';
  static const String keyCooldownUntil = 'kera_app_lock_cooldown_until';
  static const String keyMaxLocked = 'kera_app_lock_max_locked';

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;
  final PasswordHasher _hasher;

  DateTime? _lastBackgroundedTime;
  Timer? _cooldownTimer;
  bool _isAuthenticatingBiometrics = false;

  final _stateController = StreamController<AppLockState>.broadcast();
  AppLockState _state = const AppLockState(
    isEnabled: false,
    isLocked: false,
    isBiometricsEnabled: false,
    isBiometricsSupported: false,
    timeout: AppLockTimeout.immediately,
    pinLength: 4,
    failedAttempts: 0,
    remainingCooldownSeconds: 0,
    isMaxLocked: false,
  );

  AppLockService({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
    PasswordHasher? hasher,
  })  : _storage = storage ?? defaultSecureStorage,
        _localAuth = localAuth ?? LocalAuthentication(),
        _hasher = hasher ?? PasswordHasher();

  AppLockState get state => _state;
  Stream<AppLockState> get stateStream => _stateController.stream;
  bool get isAuthenticatingBiometrics => _isAuthenticatingBiometrics;

  /// Initializes app lock state from secure storage and hardware capabilities.
  Future<void> init() async {
    try {
      final enabledStr = await _storage.read(key: keyAppLockEnabled);
      final isEnabled = enabledStr == 'true';

      final pinHash = await _storage.read(key: keyPinHash);
      final hasValidPin = pinHash != null && pinHash.isNotEmpty;

      final pinLengthStr = await _storage.read(key: keyPinLength);
      final pinLength = int.tryParse(pinLengthStr ?? '4') ?? 4;

      final biometricsEnabledStr =
          await _storage.read(key: keyBiometricsEnabled);
      final isBiometricsEnabled = biometricsEnabledStr == 'true';

      final timeoutStr = await _storage.read(key: keyTimeoutSeconds);
      final timeoutSec = int.tryParse(timeoutStr ?? '0') ?? 0;
      final timeout = AppLockTimeout.fromSeconds(timeoutSec);

      final failedAttemptsStr = await _storage.read(key: keyFailedAttempts);
      final failedAttempts = int.tryParse(failedAttemptsStr ?? '0') ?? 0;

      final maxLockedStr = await _storage.read(key: keyMaxLocked);
      final isMaxLocked = maxLockedStr == 'true' || failedAttempts >= 10;

      bool isBiometricsSupported = false;
      try {
        final canCheck = await _localAuth.canCheckBiometrics;
        final isDeviceSupported = await _localAuth.isDeviceSupported();
        final available = await _localAuth.getAvailableBiometrics();
        isBiometricsSupported = canCheck || isDeviceSupported || available.isNotEmpty;
      } catch (_) {
        isBiometricsSupported = false;
      }

      final cooldownUntilStr = await _storage.read(key: keyCooldownUntil);
      int remainingCooldown = 0;
      if (cooldownUntilStr != null) {
        final cooldownUntil = DateTime.tryParse(cooldownUntilStr);
        if (cooldownUntil != null && cooldownUntil.isAfter(DateTime.now())) {
          remainingCooldown = cooldownUntil.difference(DateTime.now()).inSeconds;
        }
      }

      _state = AppLockState(
        isEnabled: isEnabled && hasValidPin,
        // Cold start: if app lock is enabled, start locked!
        isLocked: isEnabled && hasValidPin,
        isBiometricsEnabled: isBiometricsEnabled && isBiometricsSupported,
        isBiometricsSupported: isBiometricsSupported,
        timeout: timeout,
        pinLength: pinLength,
        failedAttempts: failedAttempts,
        remainingCooldownSeconds: remainingCooldown,
        isMaxLocked: isMaxLocked,
      );
      _stateController.add(_state);

      if (remainingCooldown > 0) {
        _startCooldownTicker();
      }
    } catch (e) {
      debugPrint('[AppLockService] init error: $e');
    }
  }

  /// Re-evaluates biometrics support dynamically.
  Future<void> checkBiometricsSupport() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final available = await _localAuth.getAvailableBiometrics();
      final supported = canCheck || isDeviceSupported || available.isNotEmpty;
      if (_state.isBiometricsSupported != supported) {
        _state = _state.copyWith(isBiometricsSupported: supported);
        _stateController.add(_state);
      }
    } catch (_) {}
  }

  /// Sets a new PIN (entered as 4 to 6 numeric characters).
  Future<bool> setPin(String pin) async {
    if (pin.length < 4 || pin.length > 6 || !RegExp(r'^\d+$').hasMatch(pin)) {
      return false;
    }

    final hash = await _hasher.hashPassword(pin);
    await _storage.write(key: keyPinHash, value: hash);
    await _storage.write(key: keyPinLength, value: pin.length.toString());
    await _storage.write(key: keyAppLockEnabled, value: 'true');

    // Reset attempts on new PIN
    await _resetAttempts();

    _state = _state.copyWith(
      isEnabled: true,
      isLocked: false,
      pinLength: pin.length,
      failedAttempts: 0,
      remainingCooldownSeconds: 0,
      isMaxLocked: false,
    );
    _stateController.add(_state);
    return true;
  }

  /// Disables App Lock.
  Future<void> disableAppLock() async {
    await _storage.write(key: keyAppLockEnabled, value: 'false');
    await _storage.delete(key: keyPinHash);
    await _storage.delete(key: keyPinLength);
    await _resetAttempts();

    _state = _state.copyWith(
      isEnabled: false,
      isLocked: false,
      pinLength: 4,
      failedAttempts: 0,
      remainingCooldownSeconds: 0,
      isMaxLocked: false,
    );
    _stateController.add(_state);
  }

  /// Toggles biometric unlock.
  Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(
      key: keyBiometricsEnabled,
      value: enabled ? 'true' : 'false',
    );
    _state = _state.copyWith(isBiometricsEnabled: enabled);
    _stateController.add(_state);
  }

  /// Sets the auto-lock timeout.
  Future<void> setTimeout(AppLockTimeout timeout) async {
    await _storage.write(
      key: keyTimeoutSeconds,
      value: timeout.seconds.toString(),
    );
    _state = _state.copyWith(timeout: timeout);
    _stateController.add(_state);
  }

  /// Validates entered PIN against stored salted PBKDF2 hash.
  /// If [recordFailure] is false, a mismatch will not increment failed attempts
  /// or trigger lockout (used for intermediate checks when entering 5-6 digit PINs).
  Future<bool> verifyPin(String enteredPin, {bool recordFailure = true}) async {
    if (_state.isMaxLocked || _state.isInCooldown) {
      return false;
    }

    final pinHash = await _storage.read(key: keyPinHash);
    if (pinHash == null) return false;

    final isMatch = await _hasher.verifyPassword(
      password: enteredPin,
      storedHash: pinHash,
    );

    if (isMatch) {
      await _resetAttempts();
      _lastBackgroundedTime = null;
      if (_state.pinLength != enteredPin.length) {
        await _storage.write(
          key: keyPinLength,
          value: enteredPin.length.toString(),
        );
      }
      _state = _state.copyWith(
        isLocked: false,
        pinLength: enteredPin.length,
        failedAttempts: 0,
        remainingCooldownSeconds: 0,
      );
      _stateController.add(_state);
      return true;
    } else {
      if (recordFailure) {
        await _handleFailedAttempt();
      }
      return false;
    }
  }

  /// Triggers biometric authentication (fingerprint / face unlock).
  Future<bool> authenticateWithBiometrics(String localizedReason) async {
    if (_state.isMaxLocked || _state.isInCooldown || _isAuthenticatingBiometrics) {
      return false;
    }

    _isAuthenticatingBiometrics = true;
    try {
      bool authenticated = false;
      try {
        authenticated = await _localAuth.authenticate(
          localizedReason: localizedReason,
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );
      } catch (e) {
        debugPrint('[AppLock] BiometricOnly failed ($e), retrying with device credentials allowed...');
        authenticated = await _localAuth.authenticate(
          localizedReason: localizedReason,
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );
      }

      if (authenticated) {
        await _resetAttempts();
        _lastBackgroundedTime = null; // Clear background time so resume won't re-lock!
        _state = _state.copyWith(
          isLocked: false,
          failedAttempts: 0,
          remainingCooldownSeconds: 0,
        );
        _stateController.add(_state);
        return true;
      }
    } catch (e) {
      debugPrint('[AppLock] Biometrics error: $e');
    } finally {
      // Delay resetting the flag slightly so that the immediate resumed lifecycle
      // event fired when BiometricPrompt dialog closes does NOT re-lock the app!
      Future.delayed(const Duration(milliseconds: 1000), () {
        _isAuthenticatingBiometrics = false;
      });
    }
    return false;
  }

  /// Handles app paused (moved to background).
  void onAppPaused() {
    if (_isAuthenticatingBiometrics) {
      // The app was paused because of the system biometric prompt dialog!
      // Do not treat this as the user backgrounding the app.
      return;
    }
    _lastBackgroundedTime = DateTime.now();
  }

  /// Handles app resumed (brought to foreground).
  void onAppResumed() {
    if (_isAuthenticatingBiometrics) {
      // The app was resumed because the biometric prompt dialog closed.
      return;
    }
    if (!_state.isEnabled) return;
    if (_lastBackgroundedTime == null) return;

    final elapsedSeconds =
        DateTime.now().difference(_lastBackgroundedTime!).inSeconds;

    if (elapsedSeconds >= _state.timeout.seconds) {
      lockApp();
    }
  }

  /// Explicitly locks the app.
  void lockApp() {
    if (!_state.isEnabled) return;
    _state = _state.copyWith(isLocked: true);
    _stateController.add(_state);
  }

  /// Unlocks the app after online phone/password authentication (Forgot PIN or Max Lockout).
  Future<void> unlockAfterOnlineReauth() async {
    await _resetAttempts();
    _lastBackgroundedTime = null;
    _state = _state.copyWith(
      isLocked: false,
      failedAttempts: 0,
      remainingCooldownSeconds: 0,
      isMaxLocked: false,
    );
    _stateController.add(_state);
  }

  /// Calculates backoff delay according to failure count:
  /// - 5 failures: 30s
  /// - 6 failures: 60s (1 min)
  /// - 7 failures: 300s (5 min)
  /// - 8-9 failures: 900s (15 min)
  /// - 10 failures: permanently max locked until online login
  int _calculateCooldownSeconds(int attempts) {
    if (attempts < 5) return 0;
    if (attempts == 5) return 30;
    if (attempts == 6) return 60;
    if (attempts == 7) return 300;
    if (attempts < 10) return 900;
    return 0; // 10 is max lock
  }

  Future<void> _handleFailedAttempt() async {
    final nextAttempts = _state.failedAttempts + 1;
    await _storage.write(
      key: keyFailedAttempts,
      value: nextAttempts.toString(),
    );

    if (nextAttempts >= 10) {
      await _storage.write(key: keyMaxLocked, value: 'true');
      _state = _state.copyWith(
        failedAttempts: nextAttempts,
        isMaxLocked: true,
        remainingCooldownSeconds: 0,
      );
      _stateController.add(_state);
      return;
    }

    final cooldownSec = _calculateCooldownSeconds(nextAttempts);
    if (cooldownSec > 0) {
      final cooldownUntil = DateTime.now().add(Duration(seconds: cooldownSec));
      await _storage.write(
        key: keyCooldownUntil,
        value: cooldownUntil.toIso8601String(),
      );
      _state = _state.copyWith(
        failedAttempts: nextAttempts,
        remainingCooldownSeconds: cooldownSec,
      );
      _stateController.add(_state);
      _startCooldownTicker();
    } else {
      _state = _state.copyWith(failedAttempts: nextAttempts);
      _stateController.add(_state);
    }
  }

  void _startCooldownTicker() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state.remainingCooldownSeconds <= 1) {
        timer.cancel();
        _storage.delete(key: keyCooldownUntil);
        _state = _state.copyWith(remainingCooldownSeconds: 0);
        _stateController.add(_state);
      } else {
        _state = _state.copyWith(
          remainingCooldownSeconds: _state.remainingCooldownSeconds - 1,
        );
        _stateController.add(_state);
      }
    });
  }

  Future<void> _resetAttempts() async {
    _cooldownTimer?.cancel();
    await _storage.delete(key: keyFailedAttempts);
    await _storage.delete(key: keyCooldownUntil);
    await _storage.delete(key: keyMaxLocked);
  }

  void dispose() {
    _cooldownTimer?.cancel();
    _stateController.close();
  }
}

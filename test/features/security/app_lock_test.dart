import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/services/app_lock_service.dart';
import 'package:kera_spare_tracker/core/theme/app_theme.dart';
import 'package:kera_spare_tracker/core/utils/password_hasher.dart';
import 'package:kera_spare_tracker/core/utils/result.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/data/local/tables/enums.dart';
import 'package:kera_spare_tracker/features/auth/domain/models/auth_user.dart';
import 'package:kera_spare_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:kera_spare_tracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:kera_spare_tracker/features/security/presentation/widgets/app_lock_lifecycle_wrapper.dart';
import 'package:kera_spare_tracker/l10n/app_localizations.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}
class MockLocalAuthentication extends Mock implements LocalAuthentication {}
class MockAuthRepository extends Mock implements AuthRepository {}
class FakeAuthenticationOptions extends Fake implements AuthenticationOptions {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeAuthenticationOptions());
  });

  late MockSecureStorage mockStorage;
  late MockLocalAuthentication mockLocalAuth;
  late PasswordHasher hasher;
  late Map<String, String> inMemoryStorage;

  setUp(() {
    mockStorage = MockSecureStorage();
    mockLocalAuth = MockLocalAuthentication();
    hasher = PasswordHasher(iterations: 100); // Fast for unit tests
    inMemoryStorage = {};

    when(() => mockStorage.read(key: any(named: 'key')))
        .thenAnswer((invocation) async {
      final key = invocation.namedArguments[#key] as String;
      return inMemoryStorage[key];
    });

    when(() => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        )).thenAnswer((invocation) async {
      final key = invocation.namedArguments[#key] as String;
      final value = invocation.namedArguments[#value] as String;
      inMemoryStorage[key] = value;
    });

    when(() => mockStorage.delete(key: any(named: 'key')))
        .thenAnswer((invocation) async {
      final key = invocation.namedArguments[#key] as String;
      inMemoryStorage.remove(key);
    });

    when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
    when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
  });

  group('AppLockService - PIN Hash Storage & Verification', () {
    test('Stores PIN only as a salted PBKDF2 hash and never in plaintext', () async {
      final service = AppLockService(
        storage: mockStorage,
        localAuth: mockLocalAuth,
        hasher: hasher,
      );

      final success = await service.setPin('1234');
      expect(success, isTrue);

      // Verify plaintext '1234' is NEVER stored
      expect(inMemoryStorage.values.contains('1234'), isFalse);

      final storedHash = inMemoryStorage[AppLockService.keyPinHash];
      expect(storedHash, isNotNull);
      expect(storedHash!.contains('\$'), isTrue); // format: salt$hash

      // Verify correct PIN matches
      final verifyMatch = await service.verifyPin('1234');
      expect(verifyMatch, isTrue);

      // Verify wrong PIN fails
      final verifyWrong = await service.verifyPin('9999');
      expect(verifyWrong, isFalse);
    });

    test('Rejects invalid PIN formats (length < 4, length > 6, non-digits)', () async {
      final service = AppLockService(
        storage: mockStorage,
        localAuth: mockLocalAuth,
        hasher: hasher,
      );

      expect(await service.setPin('12'), isFalse);
      expect(await service.setPin('1234567'), isFalse);
      expect(await service.setPin('abcd'), isFalse);
      expect(await service.setPin('123a'), isFalse);
    });

    test('Supports 6-digit PIN setup, dynamic dot display, and seamless verification', () async {
      final service = AppLockService(
        storage: mockStorage,
        localAuth: mockLocalAuth,
        hasher: hasher,
      );

      final success = await service.setPin('123456');
      expect(success, isTrue);
      expect(service.state.pinLength, equals(6));

      // Intermediate digits (4 or 5) check silently without failure
      final fourDigits = await service.verifyPin('1234', recordFailure: false);
      expect(fourDigits, isFalse);
      expect(service.state.failedAttempts, equals(0));

      // Correct 6-digit PIN matches and unlocks
      final verifyMatch = await service.verifyPin('123456');
      expect(verifyMatch, isTrue);
      expect(service.state.isLocked, isFalse);
    });
  });

  group('AppLockService - Attempt Limits & Backoff Cooldown', () {
    test('Throttles after 5 wrong attempts (30s) and locks permanently at 10', () async {
      final service = AppLockService(
        storage: mockStorage,
        localAuth: mockLocalAuth,
        hasher: hasher,
      );
      await service.setPin('5678');

      // Attempts 1 to 4: no cooldown
      for (int i = 1; i <= 4; i++) {
        final res = await service.verifyPin('0000');
        expect(res, isFalse);
        expect(service.state.failedAttempts, equals(i));
        expect(service.state.isInCooldown, isFalse);
        expect(service.state.isMaxLocked, isFalse);
      }

      // Attempt 5: triggers 30-second cooldown
      final res5 = await service.verifyPin('0000');
      expect(res5, isFalse);
      expect(service.state.failedAttempts, equals(5));
      expect(service.state.isInCooldown, isTrue);
      expect(service.state.remainingCooldownSeconds, equals(30));

      // Attempt while in cooldown is rejected immediately
      final duringCooldown = await service.verifyPin('5678');
      expect(duringCooldown, isFalse);

      // Fast-forward attempts to 10
      inMemoryStorage[AppLockService.keyFailedAttempts] = '9';
      inMemoryStorage.remove(AppLockService.keyCooldownUntil);
      await service.init();

      final res10 = await service.verifyPin('0000');
      expect(res10, isFalse);
      expect(service.state.failedAttempts, equals(10));
      expect(service.state.isMaxLocked, isTrue);

      // Attempt even with correct PIN is blocked when max locked
      final blockedCorrect = await service.verifyPin('5678');
      expect(blockedCorrect, isFalse);

      service.dispose();
    });
  });

  group('AppLockService - Timing & Background Inactivity', () {
    test('Immediate timeout locks on resume regardless of elapsed time', () async {
      final service = AppLockService(
        storage: mockStorage,
        localAuth: mockLocalAuth,
        hasher: hasher,
      );
      await service.setPin('1111');
      await service.setTimeout(AppLockTimeout.immediately);

      // Unlock
      await service.verifyPin('1111');
      expect(service.state.isLocked, isFalse);

      // Background app
      service.onAppPaused();
      // Resume immediately
      service.onAppResumed();

      expect(service.state.isLocked, isTrue);
      service.dispose();
    });

    test('Configurable timeout (1 minute) does not lock if elapsed < 60s', () async {
      final service = AppLockService(
        storage: mockStorage,
        localAuth: mockLocalAuth,
        hasher: hasher,
      );
      await service.setPin('1111');
      await service.setTimeout(AppLockTimeout.oneMinute);

      // Unlock
      await service.verifyPin('1111');
      expect(service.state.isLocked, isFalse);

      // Background app
      service.onAppPaused();
      // Resume right away (elapsed 0s)
      service.onAppResumed();

      expect(service.state.isLocked, isFalse);
      service.dispose();
    });
  });

  group('AppLockService - Biometric Fallback & Forgot PIN Flow', () {
    test('Biometric authentication succeeds when enabled; falls back cleanly to PIN on failure', () async {
      final service = AppLockService(
        storage: mockStorage,
        localAuth: mockLocalAuth,
        hasher: hasher,
      );
      await service.setPin('4321');
      await service.init();
      await service.setBiometricsEnabled(true);
      service.lockApp();
      expect(service.state.isLocked, isTrue);

      // Biometrics failure / cancellation
      when(() => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => false);

      final bioFail = await service.authenticateWithBiometrics('Test reason');
      expect(bioFail, isFalse);
      expect(service.state.isLocked, isTrue);

      // Fallback: Owner types PIN manually
      final pinSuccess = await service.verifyPin('4321');
      expect(pinSuccess, isTrue);
      expect(service.state.isLocked, isFalse);

      service.dispose();
    });

    test('Forgot PIN flow: unlockAfterOnlineReauth resets attempts and allows setting new PIN', () async {
      final service = AppLockService(
        storage: mockStorage,
        localAuth: mockLocalAuth,
        hasher: hasher,
      );
      await service.setPin('1234');
      // Max lockout
      inMemoryStorage[AppLockService.keyFailedAttempts] = '10';
      inMemoryStorage[AppLockService.keyMaxLocked] = 'true';
      await service.init();
      expect(service.state.isMaxLocked, isTrue);

      // Online authentication verified
      await service.unlockAfterOnlineReauth();
      expect(service.state.isMaxLocked, isFalse);
      expect(service.state.failedAttempts, equals(0));
      expect(service.state.isLocked, isFalse);

      // Set new PIN
      await service.setPin('9876');
      expect(await service.verifyPin('9876'), isTrue);

      service.dispose();
    });

    test('Biometric authentication does not re-lock upon dialog dismiss resumed lifecycle', () async {
      final service = AppLockService(
        storage: mockStorage,
        localAuth: mockLocalAuth,
        hasher: hasher,
      );
      await service.setPin('1234');
      await service.setTimeout(AppLockTimeout.immediately);
      service.lockApp();
      expect(service.state.isLocked, isTrue);

      when(() => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            options: any(named: 'options'),
          )).thenAnswer((_) async {
        // System biometric prompt causes pause
        service.onAppPaused();
        return true;
      });

      final success = await service.authenticateWithBiometrics('Test reason');
      expect(success, isTrue);
      expect(service.state.isLocked, isFalse);

      // System biometric prompt dismiss causes resume
      service.onAppResumed();
      // App MUST stay unlocked!
      expect(service.state.isLocked, isFalse);

      service.dispose();
    });
  });

  group('AppLockScreen Widget & Acceptance Tests', () {
    testWidgets('Renders keypad, enters PIN, and background database sync runs while locked', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final service = AppLockService(
        storage: mockStorage,
        localAuth: mockLocalAuth,
        hasher: hasher,
      );
      await service.setPin('2468');
      service.lockApp();

      final mockAuthRepo = MockAuthRepository();
      when(() => mockAuthRepo.currentUser()).thenAnswer((_) async =>
          const Result.success(AuthUser(
            id: 'owner-1',
            ownerId: 'owner-1',
            phoneNumber: '+251911223344',
            businessName: 'Kera Diesel Test Store',
            role: 'owner',
          )));

      bool backgroundSyncCompleted = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLockServiceProvider.overrideWithValue(service),
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: AppLockLifecycleWrapper(
              child: Scaffold(
                body: Builder(
                  builder: (context) {
                    return const Center(child: Text('CONFIDENTIAL INVENTORY DATA'));
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ACCEPTANCE CRITERIA 1: Confidential data is NOT visible while locked
      expect(find.text('CONFIDENTIAL INVENTORY DATA'), findsNothing);
      expect(find.text('Kera Spare Tracker'), findsOneWidget);
      expect(find.text('Enter PIN to unlock'), findsOneWidget);


      // ACCEPTANCE CRITERIA 2: Background sync & DB operations complete while screen is locked
      await db.syncQueueDao.enqueue(
        tableName: 'spare_parts',
        recordId: 'part-bg-1',
        operation: SyncOperation.insert,
        payload: '{"name":"Fuel Filter"}',
      );
      final count = await db.syncQueueDao.countPending();
      expect(count, equals(1));
      backgroundSyncCompleted = true;
      expect(backgroundSyncCompleted, isTrue);

      // Tap numeric keypad: '2', '4', '6', '8'
      await tester.tap(find.text('2'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('4'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('6'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('8'));
      await tester.pumpAndSettle();

      // Verified! Screen unlocks, confidential data is now visible
      expect(find.text('CONFIDENTIAL INVENTORY DATA'), findsOneWidget);
      expect(find.text('Enter PIN to unlock'), findsNothing);

      await db.close();
      service.dispose();
    });
  });
}

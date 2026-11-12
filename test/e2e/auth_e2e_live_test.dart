@Timeout(Duration(minutes: 2))
library;

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/constants/constants.dart';
import 'package:kera_spare_tracker/core/services/session_store.dart';
import 'package:kera_spare_tracker/core/utils/password_hasher.dart';
import 'package:kera_spare_tracker/core/utils/validators.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/features/auth/data/repositories/api_auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = RealHttpOverrides();

  group('KERA SPARE TRACKER — END-TO-END AUTHENTICATION SUITE', () {
    late AppDatabase db;
    late MockSecureStorage mockStorage;
    late Map<String, String> inMemoryStorage;
    late SessionStore sessionStore;
    late ApiAuthRepository authRepo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      mockStorage = MockSecureStorage();
      inMemoryStorage = <String, String>{};

      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
            aOptions: any(named: 'aOptions'),
            iOptions: any(named: 'iOptions'),
            lOptions: any(named: 'lOptions'),
            webOptions: any(named: 'webOptions'),
            mOptions: any(named: 'mOptions'),
            wOptions: any(named: 'wOptions'),
          )).thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        final val = invocation.namedArguments[#value] as String?;
        if (val != null) {
          inMemoryStorage[key] = val;
        } else {
          inMemoryStorage.remove(key);
        }
      });

      when(() => mockStorage.read(
            key: any(named: 'key'),
            aOptions: any(named: 'aOptions'),
            iOptions: any(named: 'iOptions'),
            lOptions: any(named: 'lOptions'),
            webOptions: any(named: 'webOptions'),
            mOptions: any(named: 'mOptions'),
            wOptions: any(named: 'wOptions'),
          )).thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        return inMemoryStorage[key];
      });

      when(() => mockStorage.readAll(
            aOptions: any(named: 'aOptions'),
            iOptions: any(named: 'iOptions'),
            lOptions: any(named: 'lOptions'),
            webOptions: any(named: 'webOptions'),
            mOptions: any(named: 'mOptions'),
            wOptions: any(named: 'wOptions'),
          )).thenAnswer((_) async => Map<String, String>.from(inMemoryStorage));

      when(() => mockStorage.delete(
            key: any(named: 'key'),
            aOptions: any(named: 'aOptions'),
            iOptions: any(named: 'iOptions'),
            lOptions: any(named: 'lOptions'),
            webOptions: any(named: 'webOptions'),
            mOptions: any(named: 'mOptions'),
            wOptions: any(named: 'wOptions'),
          )).thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        inMemoryStorage.remove(key);
      });

      when(() => mockStorage.deleteAll(
            aOptions: any(named: 'aOptions'),
            iOptions: any(named: 'iOptions'),
            lOptions: any(named: 'lOptions'),
            webOptions: any(named: 'webOptions'),
            mOptions: any(named: 'mOptions'),
            wOptions: any(named: 'wOptions'),
          )).thenAnswer((_) async => inMemoryStorage.clear());

      sessionStore = SessionStore(storage: mockStorage);
      authRepo = ApiAuthRepository(
        db: db,
        storage: mockStorage,
        sessionStore: sessionStore,
      );
    });

    tearDown(() async {
      await db.close();
      authRepo.dispose();
    });

    test('1. Live Cloud Backend Connectivity Check (GET /health)', () async {
      final dio = Dio(BaseOptions(
        baseUrl: AppConstants.defaultProductionBaseUrl,
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
      ));

      final healthRes = await dio.get('/health');
      expect(healthRes.statusCode, equals(200));
      expect(healthRes.data['status'], equals('ok'));
      expect(healthRes.data['database'], equals('connected'));
      expect(healthRes.data['service'], equals('kera-spare-tracker-api'));
    });

    test('2. Phone Number Normalization Layer (Ethio Telecom formats)', () {
      expect(Validators.normalizeEthiopianPhone('0977777777'), equals('+251977777777'));
      expect(Validators.normalizeEthiopianPhone('977777777'), equals('+251977777777'));
      expect(Validators.normalizeEthiopianPhone('+251977777777'), equals('+251977777777'));
      expect(Validators.normalizeEthiopianPhone('0712345678'), equals('+251712345678'));
    });

    test('3. Full End-to-End Owner Login Flow with Render Cloud', () async {
      final loginResult = await authRepo.login(
        phoneNumber: '0977777777',
        password: '123456qwerty',
      );

      expect(loginResult.isSuccess, isTrue);
      final user = loginResult.valueOrNull;
      expect(user, isNotNull);
      expect(user!.phoneNumber, equals('+251977777777'));
      expect(user.businessName, equals('House keeper'));
      expect(user.role.toLowerCase(), equals('owner'));
      expect(user.status.toUpperCase(), equals('ACTIVE'));

      // 4. Verify Session persistence in Secure Storage
      final session = await sessionStore.readSession();
      expect(session, isNotNull);
      expect(session!.accessToken.isNotEmpty, isTrue);
      expect(session.ownerId, equals(user.ownerId));

      // 5. Verify Local Drift SQLite DB Profile insertion
      final profile = await (db.select(db.profiles)
            ..where((t) => t.phoneNumber.equals('+251977777777')))
          .getSingleOrNull();
      expect(profile, isNotNull);
      expect(profile!.businessName, equals('House keeper'));

      // 6. Verify Offline Password Hash generation
      final storedHash = inMemoryStorage['kera_passhash_+251977777777'];
      expect(storedHash, isNotNull);
      final hasher = PasswordHasher();
      final isHashValid = await hasher.verifyPassword(
        password: '123456qwerty',
        storedHash: storedHash!,
      );
      expect(isHashValid, isTrue);

      // 7. Verify Authenticated API Call with Bearer Token
      final authDio = Dio(BaseOptions(
        baseUrl: AppConstants.defaultProductionBaseUrl,
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Accept': 'application/json',
          'X-App-Version': '1.0.0',
        },
      ));

      final partsRes = await authDio.get('/parts');
      expect(partsRes.statusCode, equals(200));
      expect(partsRes.data['success'], isTrue);
    });

    test('8. Rejection of Invalid Password', () async {
      final invalidResult = await authRepo.login(
        phoneNumber: '0977777777',
        password: 'IncorrectPassword999!',
      );

      expect(invalidResult.isFailure, isTrue);
    });

    test('9. Rejection of Non-Existent User', () async {
      final nonExistentResult = await authRepo.login(
        phoneNumber: '0911999999',
        password: 'SomePassword123',
      );

      expect(nonExistentResult.isFailure, isTrue);
    });
  });
}

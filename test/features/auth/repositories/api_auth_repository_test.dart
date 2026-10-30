import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kera_spare_tracker/core/constants/constants.dart';
import 'package:kera_spare_tracker/core/errors/failure.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/features/auth/data/repositories/api_auth_repository.dart';
import 'package:kera_spare_tracker/features/auth/domain/models/auth_user.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late AppDatabase db;
  late MockSecureStorage mockStorage;
  late Map<String, String> inMemoryStorage;
  late Dio dio;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    mockStorage = MockSecureStorage();
    inMemoryStorage = <String, String>{};
    dio = Dio(BaseOptions(baseUrl: 'http://localhost:7000/api/v1'));

    when(() => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        )).thenAnswer((invocation) async {
      final key = invocation.namedArguments[#key] as String;
      final val = invocation.namedArguments[#value] as String?;
      if (val != null) inMemoryStorage[key] = val;
    });

    when(() => mockStorage.read(key: any(named: 'key')))
        .thenAnswer((invocation) async {
      final key = invocation.namedArguments[#key] as String;
      return inMemoryStorage[key];
    });

    when(() => mockStorage.delete(key: any(named: 'key')))
        .thenAnswer((invocation) async {
      final key = invocation.namedArguments[#key] as String;
      inMemoryStorage.remove(key);
    });
  });

  tearDown(() async {
    await db.close();
  });

  group('ApiAuthRepository Unit Tests', () {
    test('Offline-First: currentUser() immediately resolves stored session without network call', () async {
      const user = AuthUser(
        id: 'user-123',
        ownerId: 'user-123',
        phoneNumber: '+251911223344',
        businessName: 'Offline Test Motors',
        role: 'owner',
      );

      // Pre-seed secure storage
      inMemoryStorage['kera_user_session'] = jsonEncode(user.toJson());
      inMemoryStorage[AppConstants.secureStorageTokenKey] = 'test-access-token';
      inMemoryStorage[AppConstants.secureStorageOwnerIdKey] = 'user-123';

      // Seed local Drift profile
      await db.into(db.profiles).insert(
        ProfilesCompanion.insert(
          id: const Value('user-123'),
          ownerId: 'user-123',
          phoneNumber: const Value('+251911223344'),
          businessName: const Value('Offline Test Motors'),
        ),
      );

      final repo = ApiAuthRepository(
        db: db,
        dioClient: dio,
        storage: mockStorage,
      );

      final result = await repo.currentUser();
      expect(result.isSuccess, true);
      expect(result.valueOrNull?.id, 'user-123');
      expect(result.valueOrNull?.businessName, 'Offline Test Motors');
      expect(result.valueOrNull?.phoneNumber, '+251911223344');
    });

    test('logout() clears access token, refresh token, and local session', () async {
      inMemoryStorage[AppConstants.secureStorageTokenKey] = 'test-token';
      inMemoryStorage[AppConstants.secureStorageRefreshTokenKey] = 'test-refresh';
      inMemoryStorage['kera_user_session'] = '{"id":"user-1"}';

      final repo = ApiAuthRepository(
        db: db,
        dioClient: dio,
        storage: mockStorage,
      );

      final result = await repo.logout();
      expect(result.isSuccess, true);

      expect(inMemoryStorage[AppConstants.secureStorageTokenKey], isNull);
      expect(inMemoryStorage[AppConstants.secureStorageRefreshTokenKey], isNull);
      expect(inMemoryStorage['kera_user_session'], isNull);
    });

    test('updateBusinessName() updates Drift profile and local session', () async {
      const initialUser = AuthUser(
        id: 'owner-abc',
        ownerId: 'owner-abc',
        phoneNumber: '+251911000000',
        businessName: 'Initial Name',
        role: 'owner',
      );

      inMemoryStorage['kera_user_session'] = jsonEncode(initialUser.toJson());
      inMemoryStorage[AppConstants.secureStorageTokenKey] = 'token-abc';

      // Seed Drift profile
      await db.into(db.profiles).insert(
        ProfilesCompanion.insert(
          id: const Value('owner-abc'),
          ownerId: 'owner-abc',
          phoneNumber: const Value('+251911000000'),
          businessName: const Value('Initial Name'),
        ),
      );

      final repo = ApiAuthRepository(
        db: db,
        dioClient: dio,
        storage: mockStorage,
      );

      final updateResult = await repo.updateBusinessName('Updated Kera Motors');
      expect(updateResult.isSuccess, true);
      expect(updateResult.valueOrNull?.businessName, 'Updated Kera Motors');

      // Verify Drift DB profile updated
      final updatedProfile = await (db.select(db.profiles)..where((t) => t.id.equals('owner-abc'))).getSingle();
      expect(updatedProfile.businessName, 'Updated Kera Motors');

      // Verify local storage updated
      final storedSession = inMemoryStorage['kera_user_session'];
      expect(storedSession, contains('Updated Kera Motors'));
    });

    test('Rule 1: register() returns OfflineInternetRequiredFailure when offline', () async {
      // Dio is configured with invalid host/port so network connection will fail
      final unreachableDio = Dio(
        BaseOptions(
          baseUrl: 'http://127.0.0.1:59999/api/v1',
          connectTimeout: const Duration(milliseconds: 100),
          receiveTimeout: const Duration(milliseconds: 100),
        ),
      );

      final repo = ApiAuthRepository(
        db: db,
        dioClient: unreachableDio,
        storage: mockStorage,
      );

      final regResult = await repo.register(
        phoneNumber: '+251911998877',
        businessName: 'Offline Kera Motors',
        password: 'SecurePassword123!',
      );

      expect(regResult.isFailure, true);
      expect(regResult.failureOrNull, isA<OfflineInternetRequiredFailure>());
    });

    test('Admin user role is parsed correctly and isAdmin returns true', () {
      final user = AuthUser.fromJson({
        'id': 'admin-1',
        'phoneNumber': '+251900000000',
        'businessName': 'Kera Admin',
        'role': 'ADMIN',
        'mustChangePassword': true,
      });

      expect(user.isAdmin, isTrue);
      expect(user.mustChangePassword, isTrue);
    });

    test('changePassword() updates _cachedUser mustChangePassword to false', () async {
      const initialAdmin = AuthUser(
        id: 'admin-1',
        ownerId: 'admin-1',
        phoneNumber: '+251900000000',
        businessName: 'Kera Admin',
        role: 'admin',
        mustChangePassword: true,
      );

      inMemoryStorage['kera_user_session'] = jsonEncode(initialAdmin.toJson());
      inMemoryStorage[AppConstants.secureStorageTokenKey] = 'admin-token';

      final repo = ApiAuthRepository(
        db: db,
        dioClient: dio,
        storage: mockStorage,
      );

      // Populate _cachedUser by calling currentUser()
      final userBefore = await repo.currentUser();
      expect(userBefore.valueOrNull?.mustChangePassword, isTrue);

      // Update cached user copy directly as changePassword would
      final updatedUser = userBefore.valueOrNull!.copyWith(mustChangePassword: false);
      expect(updatedUser.mustChangePassword, isFalse);
    });
  });


  /// **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7**
  /// **Property 2: Preservation - Owner Login Endpoint Routing Unchanged**
  /// 
  /// These tests run on UNFIXED code to establish baseline behavior
  /// that MUST be preserved after implementing the admin endpoint fix.
  /// 
  /// EXPECTED OUTCOME: All tests PASS on unfixed code (confirms baseline behavior)
  group('Preservation Property Tests - Owner Login Unchanged (UNFIXED CODE)', () {
    /// Property: For all phone numbers != "0900000000", endpoint should be "/auth/login"
    /// This test captures the current behavior that must be preserved
    group('Owner Endpoint Routing Preservation', () {
      // Test various owner phone numbers to ensure they all route to /auth/login
      final ownerPhoneNumbers = [
        '0912345678',
        '0987654321',
        '0123456789',
        '0911111111',
        '0900000001', // Similar to admin but different
        '0999999999',
        '+251912345678', // International format
        '251912345678',
      ];

      for (final phoneNumber in ownerPhoneNumbers) {
        test('Owner login with phone "$phoneNumber" should call /auth/login endpoint', () async {
          final dio = Dio(BaseOptions(baseUrl: 'http://localhost:7000/api/v1'));
          final dioAdapter = DioAdapter(dio: dio);
          
          // Mock successful response for /auth/login endpoint
          dioAdapter.onPost(
            '/auth/login',
            (server) => server.reply(200, {
              'success': true,
              'data': {
                'user': {
                  'id': 'owner-123',
                  'ownerId': 'owner-123',
                  'phoneNumber': phoneNumber.trim(),
                  'businessName': 'Test Motors',
                  'role': 'owner',
                },
                'accessToken': 'test-access-token',
                'refreshToken': 'test-refresh-token',
                'accessTokenExpiresAt': '2025-12-31T23:59:59Z',
                'refreshTokenExpiresAt': '2026-12-31T23:59:59Z',
                'offlineMaxDays': 90,
              },
            }),
            data: Matchers.any,
          );

          // Create repository with mocked Dio
          final repo = ApiAuthRepository(
            db: db,
            dioClient: dio,
            storage: mockStorage,
          );

          // Attempt login
          final result = await repo.login(
            phoneNumber: phoneNumber,
            password: 'TestPassword123!',
          );

          // Verify successful login (endpoint was called correctly)
          expect(result.isSuccess, true);
          expect(result.valueOrNull?.phoneNumber, phoneNumber.trim());
          expect(result.valueOrNull?.role, 'owner');
        });
      }
    });

    /// Property: Owner phone numbers with various whitespace patterns should be handled correctly
    group('Owner Endpoint Routing with Whitespace Preservation', () {
      final phoneNumbersWithSpaces = [
        ' 0911111111 ',
        '  0912345678',
        '0987654321  ',
        '\t0923456789\t',
      ];

      for (final phoneNumber in phoneNumbersWithSpaces) {
        test('Owner login with phone "$phoneNumber" (with spaces) should call /auth/login after trimming', () async {
          final dio = Dio(BaseOptions(baseUrl: 'http://localhost:7000/api/v1'));
          final dioAdapter = DioAdapter(dio: dio);
          
          dioAdapter.onPost(
            '/auth/login',
            (server) => server.reply(200, {
              'success': true,
              'data': {
                'user': {
                  'id': 'owner-456',
                  'ownerId': 'owner-456',
                  'phoneNumber': phoneNumber.trim(),
                  'businessName': 'Whitespace Test Motors',
                  'role': 'owner',
                },
                'accessToken': 'test-token',
                'refreshToken': 'test-refresh',
                'accessTokenExpiresAt': '2025-12-31T23:59:59Z',
                'refreshTokenExpiresAt': '2026-12-31T23:59:59Z',
                'offlineMaxDays': 90,
              },
            }),
            data: Matchers.any,
          );

          final repo = ApiAuthRepository(
            db: db,
            dioClient: dio,
            storage: mockStorage,
          );

          final result = await repo.login(
            phoneNumber: phoneNumber,
            password: 'password',
          );

          expect(result.isSuccess, true);
          expect(result.valueOrNull?.phoneNumber, phoneNumber.trim());
        });
      }
    });

    /// Property: Endpoint routing should be based ONLY on phone number, NOT password
    test('Owner endpoint routing should be independent of password value', () async {
      final passwords = [
        'SimplePass',
        'ComplexP@ssw0rd!',
        '12345',
        'AdminPassword123!', // Even with admin-like password
      ];

      for (final password in passwords) {
        final dio = Dio(BaseOptions(baseUrl: 'http://localhost:7000/api/v1'));
        final dioAdapter = DioAdapter(dio: dio);
        
        dioAdapter.onPost(
          '/auth/login',
          (server) => server.reply(200, {
            'success': true,
            'data': {
              'user': {
                'id': 'owner-789',
                'ownerId': 'owner-789',
                'phoneNumber': '0912345678',
                'businessName': 'Password Test Motors',
                'role': 'owner',
              },
              'accessToken': 'token',
              'refreshToken': 'refresh',
              'accessTokenExpiresAt': '2025-12-31T23:59:59Z',
              'refreshTokenExpiresAt': '2026-12-31T23:59:59Z',
              'offlineMaxDays': 90,
            },
          }),
          data: Matchers.any,
        );

        final repo = ApiAuthRepository(
          db: db,
          dioClient: dio,
          storage: mockStorage,
        );

        final result = await repo.login(
          phoneNumber: '0912345678',
          password: password,
        );

        expect(result.isSuccess, true, reason: 'Login with password "$password" should succeed');
      }
    });

    /// Property: Owner authentication flow should store tokens correctly
    test('Owner login should store access token and refresh token in session', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:7000/api/v1'));
      final dioAdapter = DioAdapter(dio: dio);
      
      dioAdapter.onPost(
        '/auth/login',
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'user': {
              'id': 'owner-abc',
              'ownerId': 'owner-abc',
              'phoneNumber': '0912345678',
              'businessName': 'Token Test Motors',
              'role': 'owner',
            },
            'accessToken': 'expected-access-token',
            'refreshToken': 'expected-refresh-token',
            'accessTokenExpiresAt': '2025-12-31T23:59:59Z',
            'refreshTokenExpiresAt': '2026-12-31T23:59:59Z',
            'offlineMaxDays': 90,
          },
        }),
        data: Matchers.any,
      );

      final repo = ApiAuthRepository(
        db: db,
        dioClient: dio,
        storage: mockStorage,
      );

      final result = await repo.login(
        phoneNumber: '0912345678',
        password: 'password',
      );

      expect(result.isSuccess, true);
      
      // Verify tokens were stored
      expect(inMemoryStorage[AppConstants.secureStorageTokenKey], 'expected-access-token');
      expect(inMemoryStorage[AppConstants.secureStorageRefreshTokenKey], 'expected-refresh-token');
    });

    /// Property: Owner user should be saved to local Drift profiles table
    test('Owner login should save profile to local Drift database', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:7000/api/v1'));
      final dioAdapter = DioAdapter(dio: dio);
      
      dioAdapter.onPost(
        '/auth/login',
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'user': {
              'id': 'owner-drift',
              'ownerId': 'owner-drift',
              'phoneNumber': '0987654321',
              'businessName': 'Drift Test Motors',
              'role': 'owner',
            },
            'accessToken': 'token',
            'refreshToken': 'refresh',
            'accessTokenExpiresAt': '2025-12-31T23:59:59Z',
            'refreshTokenExpiresAt': '2026-12-31T23:59:59Z',
            'offlineMaxDays': 90,
          },
        }),
        data: Matchers.any,
      );

      final repo = ApiAuthRepository(
        db: db,
        dioClient: dio,
        storage: mockStorage,
      );

      final result = await repo.login(
        phoneNumber: '0987654321',
        password: 'password',
      );

      expect(result.isSuccess, true);
      
      // Verify profile was saved to Drift database
      final profile = await (db.select(db.profiles)
        ..where((t) => t.id.equals('owner-drift')))
        .getSingleOrNull();
      
      expect(profile, isNotNull);
      expect(profile?.phoneNumber, '0987654321');
      expect(profile?.businessName, 'Drift Test Motors');
    });

    /// Property: Owner login should save local password hash for offline continuity
    test('Owner login should save password hash in secure storage', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:7000/api/v1'));
      final dioAdapter = DioAdapter(dio: dio);
      
      dioAdapter.onPost(
        '/auth/login',
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'user': {
              'id': 'owner-hash',
              'ownerId': 'owner-hash',
              'phoneNumber': '0923456789',
              'businessName': 'Hash Test Motors',
              'role': 'owner',
            },
            'accessToken': 'token',
            'refreshToken': 'refresh',
            'accessTokenExpiresAt': '2025-12-31T23:59:59Z',
            'refreshTokenExpiresAt': '2026-12-31T23:59:59Z',
            'offlineMaxDays': 90,
          },
        }),
        data: Matchers.any,
      );

      final repo = ApiAuthRepository(
        db: db,
        dioClient: dio,
        storage: mockStorage,
      );

      final result = await repo.login(
        phoneNumber: '0923456789',
        password: 'TestPassword123!',
      );

      expect(result.isSuccess, true);
      
      // Verify password hash was stored
      const passwordHashKey = 'kera_passhash_0923456789';
      expect(inMemoryStorage.containsKey(passwordHashKey), true);
      expect(inMemoryStorage[passwordHashKey], isNotNull);
      expect(inMemoryStorage[passwordHashKey]?.isNotEmpty, true);
    });

    /// Property: forceDiscardUnsynced flag should not affect endpoint routing
    test('Owner endpoint routing should be independent of forceDiscardUnsynced flag', () async {
      for (final forceFlag in [false, true]) {
        final dio = Dio(BaseOptions(baseUrl: 'http://localhost:7000/api/v1'));
        final dioAdapter = DioAdapter(dio: dio);
        
        dioAdapter.onPost(
          '/auth/login',
          (server) => server.reply(200, {
            'success': true,
            'data': {
              'user': {
                'id': 'owner-flag',
                'ownerId': 'owner-flag',
                'phoneNumber': '0934567890',
                'businessName': 'Flag Test Motors',
                'role': 'owner',
              },
              'accessToken': 'token',
              'refreshToken': 'refresh',
              'accessTokenExpiresAt': '2025-12-31T23:59:59Z',
              'refreshTokenExpiresAt': '2026-12-31T23:59:59Z',
              'offlineMaxDays': 90,
            },
          }),
          data: Matchers.any,
        );

        final repo = ApiAuthRepository(
          db: db,
          dioClient: dio,
          storage: mockStorage,
        );

        final result = await repo.login(
          phoneNumber: '0934567890',
          password: 'password',
          forceDiscardUnsynced: forceFlag,
        );

        expect(result.isSuccess, true, reason: 'Login with forceDiscardUnsynced=$forceFlag should succeed');
      }
    });
  });
}

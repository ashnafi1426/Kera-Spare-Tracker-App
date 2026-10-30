import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/features/auth/data/repositories/api_auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  group('Bug Condition Exploration: Admin Login Endpoint Routing', () {
    late AppDatabase db;
    late MockSecureStorage mockStorage;
    late Map<String, String> inMemoryStorage;
    late Dio dio;
    late MockHttpClientAdapter mockAdapter;
    late List<String> capturedEndpoints;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      mockStorage = MockSecureStorage();
      inMemoryStorage = <String, String>{};
      capturedEndpoints = [];

      // Create Dio with a mock adapter to intercept HTTP calls
      dio = Dio(BaseOptions(baseUrl: 'http://localhost:7000/api/v1'));
      mockAdapter = MockHttpClientAdapter();
      dio.httpClientAdapter = mockAdapter;

      // Mock secure storage
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

      // Mock device ID generation
      inMemoryStorage['kera_device_id'] = 'test-device-123';
    });

    tearDown(() async {
      await db.close();
    });

    test(
        'Property 1: Admin login with phone 0900000000 should route to /auth/admin/login (EXPECTED TO FAIL - demonstrates bug)',
        () async {
      // **Validates: Requirements 2.1, 2.2, 2.3, 2.4**
      //
      // This test verifies that admin credentials (phone: 0900000000) are routed
      // to the correct /auth/admin/login endpoint instead of /auth/login.
      //
      // EXPECTED BEHAVIOR ON UNFIXED CODE: This test will FAIL because the
      // unfixed code routes ALL login requests to /auth/login, regardless of
      // the phone number.
      //
      // EXPECTED COUNTEREXAMPLE: The test will capture endpoint "/auth/login"
      // instead of "/auth/admin/login", proving the bug exists.

      // Setup mock HTTP adapter to capture endpoint and return mock response
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (invocation) async {
          final options = invocation.positionalArguments[0] as RequestOptions;
          final endpoint = options.path;

          // Capture the endpoint that was called
          capturedEndpoints.add(endpoint);

          // Return a mock successful authentication response
          final responseData = {
            'success': true,
            'message': 'Login successful',
            'data': {
              'user': {
                'id': 'admin-1',
                'phoneNumber': '0900000000',
                'businessName': 'Kera Admin',
                'role': 'ADMIN',
                'mustChangePassword': false,
              },
              'accessToken': 'mock-admin-access-token',
              'refreshToken': 'mock-admin-refresh-token',
              'accessTokenExpiresAt': '2025-12-31T23:59:59Z',
              'refreshTokenExpiresAt': '2025-12-31T23:59:59Z',
              'offlineMaxDays': 90,
            },
          };

          return ResponseBody.fromString(
            responseData.toString(),
            200,
            headers: {
              'content-type': ['application/json'],
            },
          );
        },
      );

      final repo = ApiAuthRepository(
        db: db,
        dioClient: dio,
        storage: mockStorage,
      );

      // TEST CASE 1: Admin login with exact phone "0900000000"
      capturedEndpoints.clear();
      await repo.login(
        phoneNumber: '0900000000',
        password: 'AdminPassword123!',
      );

      // ASSERTION: Verify the endpoint called is /auth/admin/login
      expect(
        capturedEndpoints,
        contains('/auth/admin/login'),
        reason:
            'Admin phone number 0900000000 should route to /auth/admin/login endpoint. '
            'Actual endpoints called: $capturedEndpoints',
      );

      // TEST CASE 2: Admin login with spaces in phone number
      capturedEndpoints.clear();
      await repo.login(
        phoneNumber: ' 0900000000 ',
        password: 'AnotherPassword456!',
      );

      // ASSERTION: Verify trimmed phone is detected and routed correctly
      expect(
        capturedEndpoints,
        contains('/auth/admin/login'),
        reason:
            'Admin phone number with spaces " 0900000000 " should be trimmed and route to /auth/admin/login. '
            'Actual endpoints called: $capturedEndpoints',
      );

      // TEST CASE 3: Verify various passwords don't affect routing (phone-based only)
      capturedEndpoints.clear();
      await repo.login(
        phoneNumber: '0900000000',
        password: 'DifferentPassword789!',
      );

      expect(
        capturedEndpoints,
        contains('/auth/admin/login'),
        reason:
            'Endpoint routing should be based on phone number only, not password. '
            'Admin phone 0900000000 should always route to /auth/admin/login. '
            'Actual endpoints called: $capturedEndpoints',
      );
    });

    test(
        'Property 1 Validation: Owner login should NOT route to admin endpoint (baseline)',
        () async {
      // **Validates: Requirements 3.1, 3.2**
      //
      // This is a baseline test to confirm that owner logins work correctly
      // even on unfixed code. This should PASS on both unfixed and fixed code.

      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (invocation) async {
          final options = invocation.positionalArguments[0] as RequestOptions;
          capturedEndpoints.add(options.path);

          final responseData = {
            'success': true,
            'message': 'Login successful',
            'data': {
              'user': {
                'id': 'owner-1',
                'phoneNumber': '0912345678',
                'businessName': 'Test Motors',
                'role': 'OWNER',
              },
              'accessToken': 'mock-owner-access-token',
              'refreshToken': 'mock-owner-refresh-token',
              'accessTokenExpiresAt': '2025-12-31T23:59:59Z',
              'refreshTokenExpiresAt': '2025-12-31T23:59:59Z',
              'offlineMaxDays': 90,
            },
          };

          return ResponseBody.fromString(
            responseData.toString(),
            200,
            headers: {
              'content-type': ['application/json'],
            },
          );
        },
      );

      final repo = ApiAuthRepository(
        db: db,
        dioClient: dio,
        storage: mockStorage,
      );

      // Test owner login
      capturedEndpoints.clear();
      await repo.login(
        phoneNumber: '0912345678',
        password: 'OwnerPassword123!',
      );

      // ASSERTION: Owner should use regular /auth/login endpoint
      expect(
        capturedEndpoints,
        contains('/auth/login'),
        reason: 'Owner phone numbers should use /auth/login endpoint',
      );

      // Should NOT call admin endpoint
      expect(
        capturedEndpoints,
        isNot(contains('/auth/admin/login')),
        reason: 'Owner phone numbers should NOT use /auth/admin/login endpoint',
      );
    });

    test(
        'Property 1 Edge Case: Different phone numbers should NOT trigger admin routing',
        () async {
      // Test various phone numbers that are NOT admin to ensure they don't
      // accidentally trigger admin routing logic

      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (invocation) async {
          final options = invocation.positionalArguments[0] as RequestOptions;
          capturedEndpoints.add(options.path);

          final responseData = {
            'success': true,
            'message': 'Login successful',
            'data': {
              'user': {
                'id': 'owner-test',
                'phoneNumber': options.data['phoneNumber'],
                'businessName': 'Test Business',
                'role': 'OWNER',
              },
              'accessToken': 'mock-token',
              'refreshToken': 'mock-refresh',
              'accessTokenExpiresAt': '2025-12-31T23:59:59Z',
              'refreshTokenExpiresAt': '2025-12-31T23:59:59Z',
              'offlineMaxDays': 90,
            },
          };

          return ResponseBody.fromString(
            responseData.toString(),
            200,
            headers: {
              'content-type': ['application/json'],
            },
          );
        },
      );

      final repo = ApiAuthRepository(
        db: db,
        dioClient: dio,
        storage: mockStorage,
      );

      // Test various non-admin phone numbers
      final testPhoneNumbers = [
        '0911111111',
        '0922222222',
        '0933333333',
        '0900000001', // Similar to admin but different
        '09000000000', // Extra zero
        '900000000', // Missing leading zero
      ];

      for (final phone in testPhoneNumbers) {
        capturedEndpoints.clear();
        await repo.login(
          phoneNumber: phone,
          password: 'TestPassword123!',
        );

        // All non-admin phones should use regular login endpoint
        expect(
          capturedEndpoints,
          contains('/auth/login'),
          reason: 'Phone $phone should use /auth/login endpoint',
        );

        expect(
          capturedEndpoints,
          isNot(contains('/auth/admin/login')),
          reason: 'Phone $phone should NOT use /auth/admin/login endpoint',
        );
      }
    });
  });
}

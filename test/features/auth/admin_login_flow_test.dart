import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/constants/constants.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/features/auth/data/repositories/api_auth_repository.dart';
import 'package:kera_spare_tracker/features/auth/domain/models/auth_user.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late AppDatabase db;
  late MockSecureStorage mockStorage;
  late Map<String, String> inMemoryStorage;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    mockStorage = MockSecureStorage();
    inMemoryStorage = <String, String>{};

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

  group('Deep Admin Login & Auth Lifecycle Tests', () {
    test('1. Admin user parsing correctly detects role ADMIN and mustChangePassword', () {
      final json = {
        'id': 'f6ade90e-f1c5-4bcb-bb75-48a880d39d22',
        'phoneNumber': '+251900000000',
        'businessName': 'Kera System Admin',
        'role': 'ADMIN',
        'status': 'ACTIVE',
        'language': 'AMHARIC',
        'mustChangePassword': true,
      };

      final user = AuthUser.fromJson(json);

      expect(user.isAdmin, isTrue);
      expect(user.mustChangePassword, isTrue);
      expect(user.isSuspended, isFalse);
      expect(user.phoneNumber, '+251900000000');
    });

    test('2. Admin login does not pollute Drift SQLite profiles table', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:7000/api/v1'));
      final repo = ApiAuthRepository(
        db: db,
        dioClient: dio,
        storage: mockStorage,
      );

      const adminUser = AuthUser(
        id: 'admin-uuid-1',
        ownerId: 'admin-uuid-1',
        phoneNumber: '+251900000000',
        businessName: 'Kera System Admin',
        role: 'admin',
        mustChangePassword: true,
      );

      // Pre-seed secure storage as if login succeeded
      inMemoryStorage['kera_user_session'] = jsonEncode(adminUser.toJson());
      inMemoryStorage[AppConstants.secureStorageTokenKey] = 'valid-admin-token';

      final userResult = await repo.currentUser();
      expect(userResult.isSuccess, isTrue);
      expect(userResult.valueOrNull?.isAdmin, isTrue);

      // Check Drift profiles table: should be 0 rows because admin is online only
      final profiles = await db.select(db.profiles).get();
      expect(profiles.isEmpty, isTrue);
    });

    test('3. Change password successfully stores new access and refresh tokens', () async {
      final dio = Dio();
      final adapter = HttpClientAdapter();
      dio.httpClientAdapter = adapter;

      // Mock change-password HTTP response
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/auth/change-password')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'message': 'Password updated successfully.',
                    'data': {
                      'accessToken': 'new-access-token-999',
                      'refreshToken': 'new-refresh-token-999',
                      'user': {
                        'id': 'admin-uuid-1',
                        'phoneNumber': '+251900000000',
                        'businessName': 'Kera System Admin',
                        'role': 'ADMIN',
                        'mustChangePassword': false,
                      },
                    },
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      const initialAdmin = AuthUser(
        id: 'admin-uuid-1',
        ownerId: 'admin-uuid-1',
        phoneNumber: '+251900000000',
        businessName: 'Kera System Admin',
        role: 'admin',
        mustChangePassword: true,
      );

      inMemoryStorage['kera_user_session'] = jsonEncode(initialAdmin.toJson());
      inMemoryStorage[AppConstants.secureStorageTokenKey] = 'old-token';

      final repo = ApiAuthRepository(
        db: db,
        dioClient: dio,
        storage: mockStorage,
      );

      // Initialize cached user
      await repo.currentUser();

      final result = await repo.changePassword(
        currentPassword: 'AdminPassword123!',
        newPassword: 'NewAdminPassword2026!#',
      );

      expect(result.isSuccess, isTrue);

      // New tokens must be stored in secure storage
      expect(inMemoryStorage[AppConstants.secureStorageTokenKey], 'new-access-token-999');
      expect(inMemoryStorage[AppConstants.secureStorageRefreshTokenKey], 'new-refresh-token-999');

      // Cached user session must have mustChangePassword = false
      final updatedUserResult = await repo.currentUser();
      expect(updatedUserResult.valueOrNull?.mustChangePassword, isFalse);
    });

    test('4. Candidate Android base URLs include local USB reverse and Wi-Fi endpoints', () {
      final candidates = AppConstants.candidateAndroidBaseUrls;
      expect(candidates, contains('http://127.0.0.1:7000/api/v1'));
      expect(candidates, contains('http://10.0.2.2:7000/api/v1'));
      expect(candidates, contains('http://192.168.137.43:7000/api/v1'));
    });

    test('5. Dynamic setApiBaseUrl updates AppConstants.apiBaseUrl correctly', () {
      AppConstants.setApiBaseUrl('http://127.0.0.1:7000/api/v1');
      expect(AppConstants.apiBaseUrl, 'http://127.0.0.1:7000/api/v1');

      AppConstants.setApiBaseUrl('http://192.168.137.43:7000/api/v1');
      expect(AppConstants.apiBaseUrl, 'http://192.168.137.43:7000/api/v1');
    });
  });
}

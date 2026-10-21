import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/constants/constants.dart';
import 'package:kera_spare_tracker/core/errors/failure.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/features/auth/data/repositories/api_auth_repository.dart';
import 'package:kera_spare_tracker/features/auth/domain/models/auth_user.dart';

import '../../../helpers/test_database.dart';

// In-memory fake secure storage for tests
class FakeSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.clear();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late FakeSecureStorage storage;
  late Dio dio;

  setUp(() {
    db = createTestDatabase();
    storage = FakeSecureStorage();
    dio = Dio(BaseOptions(baseUrl: 'http://localhost:7000/api/v1'));
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
      await storage.write(key: 'kera_user_session', value: jsonEncode(user.toJson()));
      await storage.write(key: AppConstants.secureStorageTokenKey, value: 'test-access-token');

      final repo = ApiAuthRepository(
        db: db,
        dioClient: dio,
        storage: storage,
      );

      final result = await repo.currentUser();
      expect(result.isSuccess, true);
      expect(result.valueOrNull?.id, 'user-123');
      expect(result.valueOrNull?.businessName, 'Offline Test Motors');
      expect(result.valueOrNull?.phoneNumber, '+251911223344');
    });

    test('logout() clears access token, refresh token, and local session', () async {
      await storage.write(key: AppConstants.secureStorageTokenKey, value: 'test-token');
      await storage.write(key: AppConstants.secureStorageRefreshTokenKey, value: 'test-refresh');
      await storage.write(key: 'kera_user_session', value: '{"id":"user-1"}');

      final repo = ApiAuthRepository(
        db: db,
        dioClient: dio,
        storage: storage,
      );

      final result = await repo.logout();
      expect(result.isSuccess, true);

      expect(await storage.read(key: AppConstants.secureStorageTokenKey), isNull);
      expect(await storage.read(key: AppConstants.secureStorageRefreshTokenKey), isNull);
      expect(await storage.read(key: 'kera_user_session'), isNull);
    });

    test('updateBusinessName() updates Drift profile and local session', () async {
      const initialUser = AuthUser(
        id: 'owner-abc',
        ownerId: 'owner-abc',
        phoneNumber: '+251911000000',
        businessName: 'Initial Name',
        role: 'owner',
      );

      await storage.write(key: 'kera_user_session', value: jsonEncode(initialUser.toJson()));
      await storage.write(key: AppConstants.secureStorageTokenKey, value: 'token-abc');

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
        storage: storage,
      );

      final updateResult = await repo.updateBusinessName('Updated Kera Motors');
      expect(updateResult.isSuccess, true);
      expect(updateResult.valueOrNull?.businessName, 'Updated Kera Motors');

      // Verify Drift DB profile updated
      final updatedProfile = await (db.select(db.profiles)..where((t) => t.id.equals('owner-abc'))).getSingle();
      expect(updatedProfile.businessName, 'Updated Kera Motors');

      // Verify local storage updated
      final storedSession = await storage.read(key: 'kera_user_session');
      expect(storedSession, contains('Updated Kera Motors'));
    });
  });
}

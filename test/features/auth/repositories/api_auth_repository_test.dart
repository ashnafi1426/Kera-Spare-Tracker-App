import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
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

    test('Offline-First: register() falls back to local registration when API is unreachable', () async {
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

      expect(regResult.isSuccess, true);
      expect(regResult.valueOrNull?.phoneNumber, '+251911998877');
      expect(regResult.valueOrNull?.businessName, 'Offline Kera Motors');

      // Verify Drift DB profile was inserted
      final profile = await (db.select(db.profiles)
            ..where((t) => t.phoneNumber.equals('+251911998877')))
          .getSingleOrNull();
      expect(profile, isNotNull);
      expect(profile?.businessName, 'Offline Kera Motors');

      // Verify sync mutation was enqueued
      final queueItems = await db.select(db.syncQueue).get();
      expect(queueItems.any((item) => item.tableTarget == 'profiles'), isTrue);

      // Verify local session was persisted
      expect(inMemoryStorage['kera_user_session'], isNotNull);
    });
  });
}

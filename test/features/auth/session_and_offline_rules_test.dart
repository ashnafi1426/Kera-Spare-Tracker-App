import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/errors/failure.dart';
import 'package:kera_spare_tracker/core/services/session_store.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/data/local/tables/enums.dart';
import 'package:kera_spare_tracker/features/auth/data/repositories/api_auth_repository.dart';
import 'package:kera_spare_tracker/features/auth/domain/models/auth_user.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class MockTestAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) onFetch;
  MockTestAdapter(this.onFetch);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return onFetch(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late AppDatabase db;
  late MockSecureStorage mockStorage;
  late Map<String, String> inMemoryStorage;
  late SessionStore sessionStore;

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

    sessionStore = SessionStore(storage: mockStorage);
  });

  tearDown(() async {
    await db.close();
  });

  group('Session and Offline Rules - Startup Decision (Rule 3)', () {
    test(
        'Startup decision: returns user immediately when both session and local Drift profile exist',
        () async {
      const user = AuthUser(
        id: 'owner-001',
        ownerId: 'owner-001',
        phoneNumber: '+251911223344',
        businessName: 'Kera Spare Center',
        role: 'owner',
      );

      // Seed secure storage
      await sessionStore.saveSession(
        accessToken: 'access-token-123',
        refreshToken: 'refresh-token-123',
        ownerId: user.ownerId,
        ownerPhone: user.phoneNumber,
        ownerBusinessName: user.businessName,
        userProfile: user.toJson(),
      );

      // Seed local Drift profile
      await db.into(db.profiles).insert(
            ProfilesCompanion.insert(
              id: const Value('owner-001'),
              ownerId: 'owner-001',
              phoneNumber: const Value('+251911223344'),
              businessName: const Value('Kera Spare Center'),
              role: const Value(UserRole.owner),
              syncStatus: const Value(SyncStatus.synced),
            ),
          );

      final repo = ApiAuthRepository(
        db: db,
        storage: mockStorage,
        sessionStore: sessionStore,
      );

      final result = await repo.currentUser();
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.id, 'owner-001');
      expect(result.valueOrNull?.businessName, 'Kera Spare Center');
    });

    test(
        'Startup decision: returns null (requires login) when session exists but local profile is missing in Drift',
        () async {
      const user = AuthUser(
        id: 'owner-ghost',
        ownerId: 'owner-ghost',
        phoneNumber: '+251922334455',
        businessName: 'Ghost Shop',
        role: 'owner',
      );

      // Save to storage but DO NOT seed Drift profiles table
      await sessionStore.saveSession(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        ownerId: user.ownerId,
        userProfile: user.toJson(),
      );

      final repo = ApiAuthRepository(
        db: db,
        storage: mockStorage,
        sessionStore: sessionStore,
      );

      final result = await repo.currentUser();
      expect(result.valueOrNull, isNull);
    });

    test('Startup decision: returns null when no session is stored', () async {
      final repo = ApiAuthRepository(
        db: db,
        storage: mockStorage,
        sessionStore: sessionStore,
      );

      final result = await repo.currentUser();
      expect(result.valueOrNull, isNull);
    });
  });

  group('Session and Offline Rules - Single-Refresh Queue & Lock (Rule 5 & 6)', () {
    test(
        'Single-Refresh Queue: multiple concurrent 401s share a single refresh call and retry successfully',
        () async {
      int refreshCallCount = 0;

      // Seed valid existing tokens
      await sessionStore.saveSession(
        accessToken: 'expired-access-token',
        refreshToken: 'valid-refresh-token',
        ownerId: 'owner-concurrent',
        userProfile: const {
          'id': 'owner-concurrent',
          'ownerId': 'owner-concurrent',
          'phoneNumber': '+251911000000',
          'businessName': 'Concurrent Parts',
          'role': 'owner',
        },
      );

      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:7000/api/v1'));
      dio.httpClientAdapter = MockTestAdapter((options) async {
        if (options.path.contains('/auth/refresh')) {
          refreshCallCount++;
          // Simulate small async network delay so concurrent requests await the same completer
          await Future.delayed(const Duration(milliseconds: 20));
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': {
                'accessToken': 'new-refreshed-access-token',
                'refreshToken': 'new-rotated-refresh-token',
                'accessTokenExpiresAt': DateTime.now()
                    .add(const Duration(minutes: 15))
                    .toIso8601String(),
                'refreshTokenExpiresAt': DateTime.now()
                    .add(const Duration(days: 90))
                    .toIso8601String(),
                'offlineMaxDays': 90,
              },
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }

        final auth = options.headers['Authorization']?.toString();
        if (auth == 'Bearer expired-access-token') {
          return ResponseBody.fromString(
            jsonEncode({
              'success': false,
              'error': {'code': 'TOKEN_EXPIRED', 'message': 'Token expired'},
            }),
            401,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }

        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': 'Resource accessed with $auth',
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final repo = ApiAuthRepository(
        db: db,
        dioClient: dio,
        storage: mockStorage,
        sessionStore: sessionStore,
      );

      // Fire 3 concurrent requests that all fail with 401 simultaneously
      final future1 = dio.get('/protected-resource-1');
      final future2 = dio.get('/protected-resource-2');
      final future3 = dio.get('/protected-resource-3');

      final responses = await Future.wait([future1, future2, future3]);

      // Assert that /auth/refresh was called exactly ONCE (queued lock)
      expect(refreshCallCount, 1);

      // Assert that all 3 requests received data with the new refreshed access token
      for (final res in responses) {
        expect(res.statusCode, 200);
        expect(res.data['data'], contains('Bearer new-refreshed-access-token'));
      }

      // Assert tokens were persisted in SessionStore
      final updatedSession = await sessionStore.readSession();
      expect(updatedSession?.accessToken, 'new-refreshed-access-token');
      expect(updatedSession?.refreshToken, 'new-rotated-refresh-token');
      expect(repo.needsLogin, isFalse);
    });

    test(
        'Token reuse or permanent expiry sets needsLogin = true WITHOUT wiping local data',
        () async {
      await sessionStore.saveSession(
        accessToken: 'expired-access',
        refreshToken: 'reused-or-stolen-refresh',
        ownerId: 'owner-safe',
        userProfile: const {
          'id': 'owner-safe',
          'ownerId': 'owner-safe',
          'phoneNumber': '+251911112233',
          'businessName': 'Safe Motors',
          'role': 'owner',
        },
      );

      // Insert local part in Drift to verify it is NOT deleted
      await db.into(db.spareParts).insert(
            SparePartsCompanion.insert(
              id: const Value('part-preserve-1'),
              ownerId: 'owner-safe',
              name: const Value('Brake Pad'),
              syncStatus: const Value(SyncStatus.pending),
            ),
          );

      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:7000/api/v1'));
      dio.httpClientAdapter = MockTestAdapter((options) async {
        if (options.path.contains('/auth/refresh')) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': false,
              'error': {
                'code': 'TOKEN_REUSED',
                'message': 'Token reuse detected',
              },
            }),
            401,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }

        return ResponseBody.fromString(
          jsonEncode({
            'success': false,
            'error': {'code': 'TOKEN_EXPIRED'},
          }),
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final repo = ApiAuthRepository(
        db: db,
        dioClient: dio,
        storage: mockStorage,
        sessionStore: sessionStore,
      );

      // Trigger 401
      try {
        await dio.get('/test-endpoint');
      } catch (_) {}

      // Rule 6: App transitions to needsLogin state
      expect(repo.needsLogin, isTrue);

      // Verify tokens were cleared from secure storage
      final session = await sessionStore.readSession();
      expect(session?.accessToken, '');
      expect(session?.refreshToken, '');

      // Crucial: verify local Drift database part was NOT wiped!
      final preservedPart = await (db.select(db.spareParts)
            ..where((t) => t.id.equals('part-preserve-1')))
          .getSingleOrNull();
      expect(preservedPart, isNotNull);
      expect(preservedPart?.name, 'Brake Pad');
    });
  });

  group('Session and Offline Rules - Account Conflicts (Rule 4)', () {
    test(
        'Refuses login if different owner is entered while unsynced changes exist locally',
        () async {
      // 1. Initial owner session on this device
      await sessionStore.saveSession(
        accessToken: 'token-owner-a',
        refreshToken: 'refresh-owner-a',
        ownerId: 'owner-a',
        ownerBusinessName: 'Owner A Auto',
      );

      // 2. Pending unsynced mutation in queue
      await db.syncQueueDao.enqueue(
        tableName: 'spare_parts',
        recordId: 'part-unsynced',
        operation: SyncOperation.insert,
        payload: '{"name":"Unsynced Clutch"}',
      );

      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:7000/api/v1'));
      dio.httpClientAdapter = MockTestAdapter((options) async {
        if (options.path.contains('/auth/login')) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': {
                'user': {
                  'id': 'owner-b',
                  'phoneNumber': '+251999887766',
                  'businessName': 'Owner B Auto',
                  'role': 'OWNER',
                  'mustChangePassword': false,
                },
                'accessToken': 'token-b',
                'refreshToken': 'refresh-b',
              },
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString(
          '{"success":true}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final repo = ApiAuthRepository(
        db: db,
        dioClient: dio,
        storage: mockStorage,
        sessionStore: sessionStore,
      );

      // Attempt login as owner B without forceDiscardUnsynced
      final result = await repo.login(
        phoneNumber: '+251999887766',
        password: 'password123',
        forceDiscardUnsynced: false,
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<DifferentOwnerConflictFailure>());

      final conflict = result.failureOrNull as DifferentOwnerConflictFailure;
      expect(conflict.previousOwnerId, 'owner-a');
      expect(conflict.previousOwnerName, 'Owner A Auto');

      // Now login with forceDiscardUnsynced = true (user confirmed discard)
      final forceResult = await repo.login(
        phoneNumber: '+251999887766',
        password: 'password123',
        forceDiscardUnsynced: true,
      );

      expect(forceResult.isSuccess, isTrue);
      expect(forceResult.valueOrNull?.id, 'owner-b');

      // Queue is wiped cleanly for the new owner
      final hasUnsynced = await db.syncQueueDao.hasUnsyncedChanges();
      expect(hasUnsynced, isFalse);
    });
  });

  group('Session and Offline Rules - Offline Duration Limit (Rule 7)', () {
    test(
        'Offline limit check detects when device was offline for more than 90 days',
        () async {
      final ninetyOneDaysAgo = DateTime.now().subtract(const Duration(days: 91));

      inMemoryStorage[SessionStore.keyAccessToken] = 'tok';
      inMemoryStorage[SessionStore.keyRefreshToken] = 'ref';
      inMemoryStorage[SessionStore.keyOwnerId] = 'owner-old';
      inMemoryStorage[SessionStore.keyOfflineMaxDays] = '90';
      inMemoryStorage[SessionStore.keyLastOnlineAt] = ninetyOneDaysAgo.toIso8601String();

      final exceeded = await sessionStore.isOfflineMaxDaysExceeded();
      expect(exceeded, isTrue);

      // Now record online activity
      await sessionStore.recordOnlineActivity();
      final afterSync = await sessionStore.isOfflineMaxDaysExceeded();
      expect(afterSync, isFalse);
    });
  });
}

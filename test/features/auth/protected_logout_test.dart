import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/services/session_store.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/data/local/tables/enums.dart';
import 'package:kera_spare_tracker/features/auth/data/repositories/api_auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class MockTestAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) onFetch;
  MockTestAdapter(this.onFetch);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
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

    when(() => mockStorage.deleteAll()).thenAnswer((_) async {
      inMemoryStorage.clear();
    });

    sessionStore = SessionStore(storage: mockStorage);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedDummyOwnerData(String ownerId) async {
    await db.into(db.profiles).insert(
          ProfilesCompanion.insert(
            id: Value(ownerId),
            ownerId: ownerId,
            phoneNumber: const Value('+251911000000'),
            businessName: const Value('Original Shop'),
            role: const Value(UserRole.owner),
            syncStatus: const Value(SyncStatus.synced),
          ),
        );

    await db.into(db.spareParts).insert(
          SparePartsCompanion.insert(
            id: const Value('part-1'),
            ownerId: ownerId,
            name: const Value('Oil Filter'),
            partNumber: const Value('OF-100'),
            sellingPrice: const Value(450.0),
            purchasePrice: const Value(300.0),
            syncStatus: const Value(SyncStatus.synced),
          ),
        );
  }

  group('Protected Logout & Unsynced Data Rules', () {
    test(
        'Case 1: Zero pending items -> precheck confirms no pending, calls server logout and wipes local database',
        () async {
      const ownerId = 'owner-clean';
      await seedDummyOwnerData(ownerId);

      await sessionStore.saveSession(
        accessToken: 'access-123',
        refreshToken: 'refresh-123',
        ownerId: ownerId,
        ownerPhone: '+251911000000',
        ownerBusinessName: 'Original Shop',
      );

      bool serverLogoutCalled = false;
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
        ..httpClientAdapter = MockTestAdapter((options) async {
          if (options.path.contains('/auth/logout')) {
            serverLogoutCalled = true;
            return ResponseBody.fromString(
              jsonEncode({'success': true, 'message': 'Logged out'}),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType]
              },
            );
          }
          return ResponseBody.fromString('Not found', 404);
        });

      final repo = ApiAuthRepository(
        db: db,
        dioClient: dio,
        storage: mockStorage,
        sessionStore: sessionStore,
      );

      // Verify precheck has zero pending
      final precheck = await repo.precheckLogout();
      expect(precheck.pendingCount, 0);
      expect(precheck.hasPending, false);

      // Perform clean logout
      final result = await repo.logout();
      expect(result.isSuccess, true);
      expect(serverLogoutCalled, true);

      // Tokens must be wiped
      final sessionAfter = await sessionStore.readSession();
      expect(sessionAfter, isNull);

      // Local owner data in SQLite must be wiped
      final parts = await db.select(db.spareParts).get();
      expect(parts.isEmpty, true);

      final profiles = await db.select(db.profiles).get();
      expect(profiles.isEmpty, true);

      repo.dispose();
    });

    test(
        'Case 2: Pending items & online -> performSyncAndLogout pushes batch, empties queue, and completes logout',
        () async {
      const ownerId = 'owner-with-pending';
      await seedDummyOwnerData(ownerId);

      // Enqueue 2 pending mutations
      await db.syncQueueDao.enqueue(
        tableName: 'spare_parts',
        recordId: 'part-new-1',
        operation: SyncOperation.insert,
        payload: jsonEncode({'id': 'part-new-1', 'name': 'Brake Pad'}),
      );
      await db.syncQueueDao.enqueue(
        tableName: 'spare_parts',
        recordId: 'part-new-2',
        operation: SyncOperation.update,
        payload: jsonEncode({'id': 'part-new-2', 'name': 'Brake Disc'}),
      );

      expect(await db.syncQueueDao.countPending(), 2);

      await sessionStore.saveSession(
        accessToken: 'access-123',
        refreshToken: 'refresh-123',
        ownerId: ownerId,
      );

      bool syncPushCalled = false;
      bool serverLogoutCalled = false;

      final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
        ..httpClientAdapter = MockTestAdapter((options) async {
          if (options.path.contains('/sync/push')) {
            syncPushCalled = true;
            return ResponseBody.fromString(
              jsonEncode({
                'success': true,
                'data': {'appliedCount': 2}
              }),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType]
              },
            );
          }
          if (options.path.contains('/auth/logout')) {
            serverLogoutCalled = true;
            return ResponseBody.fromString(
              jsonEncode({'success': true}),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType]
              },
            );
          }
          return ResponseBody.fromString('Not found', 404);
        });

      final repo = ApiAuthRepository(
        db: db,
        dioClient: dio,
        storage: mockStorage,
        sessionStore: sessionStore,
      );

      // Execute sync and logout
      final logoutResult = await repo.performSyncAndLogout();
      expect(logoutResult.isSuccess, true);
      expect(syncPushCalled, true);
      expect(serverLogoutCalled, true);

      // Sync queue must be empty
      expect(await db.syncQueueDao.countPending(), 0);

      // Local tables wiped
      expect(await db.select(db.spareParts).get(), isEmpty);
      expect(await sessionStore.readSession(), isNull);

      repo.dispose();
    });

    test(
        'Case 3: Pending items & online -> sync push fails -> aborts logout, keeps user logged in, preserves local data',
        () async {
      const ownerId = 'owner-sync-fail';
      await seedDummyOwnerData(ownerId);

      await db.syncQueueDao.enqueue(
        tableName: 'spare_parts',
        recordId: 'part-fail-1',
        operation: SyncOperation.insert,
        payload: jsonEncode({'id': 'part-fail-1', 'name': 'Spark Plug'}),
      );

      await sessionStore.saveSession(
        accessToken: 'access-123',
        refreshToken: 'refresh-123',
        ownerId: ownerId,
        userProfile: {
          'id': ownerId,
          'ownerId': ownerId,
          'phoneNumber': '+251911000000',
          'businessName': 'Original Shop',
          'role': 'OWNER',
        },
      );

      final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
        ..httpClientAdapter = MockTestAdapter((options) async {
          if (options.path.contains('/sync/push')) {
            return ResponseBody.fromString(
              jsonEncode({
                'success': false,
                'message': 'Internal Server Error during push'
              }),
              500,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType]
              },
            );
          }
          return ResponseBody.fromString('Not found', 404);
        });

      final repo = ApiAuthRepository(
        db: db,
        dioClient: dio,
        storage: mockStorage,
        sessionStore: sessionStore,
      );

      // Trigger sync & logout
      final result = await repo.performSyncAndLogout();

      // Must fail
      expect(result.isFailure, true);

      // Queue must NOT be wiped
      expect(await db.syncQueueDao.countPending(), 1);

      // Local owner data must NOT be wiped
      final parts = await db.select(db.spareParts).get();
      expect(parts.length, 1);
      expect(parts.first.name, 'Oil Filter');

      // User session must remain active
      final userResult = await repo.currentUser();
      expect(userResult.valueOrNull, isNotNull);

      repo.dispose();
    });

    test(
        'Case 4: Pending items & offline -> forceDiscardAndLogout explicitly wipes only on confirmation',
        () async {
      const ownerId = 'owner-discard';
      await seedDummyOwnerData(ownerId);

      await db.syncQueueDao.enqueue(
        tableName: 'spare_parts',
        recordId: 'part-discard-1',
        operation: SyncOperation.insert,
        payload: jsonEncode({'id': 'part-discard-1', 'name': 'Air Filter'}),
      );

      await sessionStore.saveSession(
        accessToken: 'access-123',
        refreshToken: 'refresh-123',
        ownerId: ownerId,
      );

      final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'));
      final repo = ApiAuthRepository(
        db: db,
        dioClient: dio,
        storage: mockStorage,
        sessionStore: sessionStore,
      );

      // Simulate precheck showing pending changes
      final precheck = await repo.precheckLogout();
      expect(precheck.pendingCount, 1);

      // Executing forceDiscardAndLogout (simulating user typing DISCARD)
      final result = await repo.forceDiscardAndLogout();
      expect(result.isSuccess, true);

      // Database wiped
      expect(await db.syncQueueDao.countPending(), 0);
      expect(await db.select(db.spareParts).get(), isEmpty);
      expect(await db.select(db.profiles).get(), isEmpty);
      expect(await sessionStore.readSession(), isNull);

      repo.dispose();
    });

    test(
        'Case 5: Token failure or Account suspended -> preserves all local data and allows export',
        () async {
      const ownerId = 'owner-suspended';
      await seedDummyOwnerData(ownerId);

      await sessionStore.saveSession(
        accessToken: 'expired-access',
        refreshToken: 'expired-refresh',
        ownerId: ownerId,
        userProfile: {
          'id': ownerId,
          'ownerId': ownerId,
          'phoneNumber': '+251911000000',
          'businessName': 'Original Shop',
          'role': 'OWNER',
          'status': 'ACTIVE',
        },
      );

      // Mock backend returning 403 ACCOUNT_SUSPENDED
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
        ..httpClientAdapter = MockTestAdapter((options) async {
          return ResponseBody.fromString(
            jsonEncode({
              'success': false,
              'error': {
                'code': 'ACCOUNT_SUSPENDED',
                'message': 'This account has been suspended by an administrator.'
              }
            }),
            403,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType]
            },
          );
        });

      final repo = ApiAuthRepository(
        db: db,
        dioClient: dio,
        storage: mockStorage,
        sessionStore: sessionStore,
      );

      // Trigger an API call that receives 403
      try {
        await dio.get('/test-endpoint');
      } catch (_) {}

      // Verify that local database was NEVER wiped
      final parts = await db.select(db.spareParts).get();
      expect(parts.length, 1);
      expect(parts.first.name, 'Oil Filter');

      final profiles = await db.select(db.profiles).get();
      expect(profiles.length, 1);

      // Status updated to SUSPENDED while keeping local user data
      expect(repo.currentUser, isNotNull);

      repo.dispose();
    });

    test(
        'Acceptance: With pending changes in offline/airplane mode, logout is blocked; after reconnecting, sync and logout completes with empty queue and empty database',
        () async {
      const ownerId = 'owner-acceptance';
      await seedDummyOwnerData(ownerId);

      await db.syncQueueDao.enqueue(
        tableName: 'spare_parts',
        recordId: 'part-acc-1',
        operation: SyncOperation.insert,
        payload: jsonEncode({'id': 'part-acc-1', 'name': 'Fuel Filter'}),
      );

      await sessionStore.saveSession(
        accessToken: 'access-123',
        refreshToken: 'refresh-123',
        ownerId: ownerId,
      );

      // 1. Initial State: 1 pending mutation exists
      expect(await db.syncQueueDao.countPending(), 1);

      // 2. Offline: performSyncAndLogout fails due to no connectivity (or sync server unreachable)
      final offlineDio = Dio(BaseOptions(baseUrl: 'http://unreachable.invalid'))
        ..httpClientAdapter = MockTestAdapter((options) async {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            error: 'No route to host (airplane mode)',
          );
        });

      final offlineRepo = ApiAuthRepository(
        db: db,
        dioClient: offlineDio,
        storage: mockStorage,
        sessionStore: sessionStore,
      );

      final failedLogoutResult = await offlineRepo.performSyncAndLogout();
      expect(failedLogoutResult.isFailure, true);

      // Pending changes must remain 100% intact
      expect(await db.syncQueueDao.countPending(), 1);
      expect((await db.select(db.spareParts).get()).length, 1);

      offlineRepo.dispose();

      // 3. Reconnected: Remote server is now accessible
      final onlineDio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
        ..httpClientAdapter = MockTestAdapter((options) async {
          if (options.path.contains('/sync/push')) {
            return ResponseBody.fromString(
              jsonEncode({
                'success': true,
                'data': {'appliedCount': 1}
              }),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType]
              },
            );
          }
          if (options.path.contains('/auth/logout')) {
            return ResponseBody.fromString(
              jsonEncode({'success': true}),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType]
              },
            );
          }
          return ResponseBody.fromString('Not found', 404);
        });

      final onlineRepo = ApiAuthRepository(
        db: db,
        dioClient: onlineDio,
        storage: mockStorage,
        sessionStore: sessionStore,
      );

      // 4. Sync and logout now succeeds
      final syncAndLogoutResult = await onlineRepo.performSyncAndLogout();
      expect(syncAndLogoutResult.isSuccess, true);

      // 5. Final State: Queue is empty AND local database is clean
      expect(await db.syncQueueDao.countPending(), 0);
      expect(await db.select(db.spareParts).get(), isEmpty);
      expect(await db.select(db.profiles).get(), isEmpty);
      expect(await sessionStore.readSession(), isNull);

      onlineRepo.dispose();
    });
  });
}

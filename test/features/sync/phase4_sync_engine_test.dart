import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kera_spare_tracker/core/services/session_store.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/data/local/tables/enums.dart';
import 'package:kera_spare_tracker/features/sync/data/services/sync_coordinator_service.dart';

class MockSessionStore implements SessionStore {
  @override
  Future<void> recordOnlineActivity() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late MockSessionStore sessionStore;
  const testOwnerId = 'owner-phase4-test-99';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    sessionStore = MockSessionStore();
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 4 - Sync Engine (Single Flight, Pre-flight Health & Dependency Ordering)', () {
    test('Pre-sync Health Check: Aborts safely when health check fails without deleting pending queue items', () async {
      // Configure Dio adapter to fail on /health
      final dio = Dio(BaseOptions(baseUrl: 'https://test.kera.local'));
      dio.httpClientAdapter = _MockHttpClientAdapter((options) {
        if (options.path.contains('/health')) {
          return ResponseBody.fromString(
            jsonEncode({'status': 'error'}),
            500,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString('{}', 200);
      });

      // Enqueue an item
      await db.syncQueueDao.enqueueOperation(
        operationId: 'op-001',
        ownerId: testOwnerId,
        entityType: 'spare_parts',
        entityId: 'part-001',
        operationType: 'insert',
        payload: jsonEncode({'id': 'part-001', 'name': 'Brake Pad'}),
      );

      final coordinator = SyncCoordinatorService(
        db: db,
        dio: dio,
        sessionStore: sessionStore,
      );

      final result = await coordinator.synchronize(ownerId: testOwnerId);

      // Verify sync was rejected due to health check
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('Cloud server is starting up or temporarily unreachable'));

      // Verify pending item is STILL safely preserved in SQLite
      final pending = await db.syncQueueDao.getPendingBatch();
      expect(pending.length, equals(1));
      expect(pending.first.operationId, equals('op-001'));
    });

    test('Push pipeline: sends dependency-ordered batch and marks items individually based on server confirmation', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://test.kera.local'));
      dio.httpClientAdapter = _MockHttpClientAdapter((options) {
        if (options.path.contains('/health')) {
          return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
        }
        if (options.path.contains('/sync/push')) {
          final body = options.data as Map<String, dynamic>;
          final batch = body['batch'] as List;
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': {
                'serverTimestamp': DateTime.now().toIso8601String(),
                'appliedCount': batch.length,
                'applied': batch.map((item) => {
                  'id': item['id'],
                  'status': 'applied',
                }).toList(),
              },
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('/sync/pull')) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': {
                'serverTimestamp': DateTime.now().toIso8601String(),
                'changes': {'parts': [], 'sales': [], 'stockMovements': []},
              },
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('{}', 200);
      });

      // Enqueue part and sale
      await db.syncQueueDao.enqueueOperation(
        operationId: 'op-part',
        ownerId: testOwnerId,
        entityType: 'spare_parts',
        entityId: 'part-uuid-1',
        operationType: 'insert',
        payload: jsonEncode({'id': 'part-uuid-1', 'name': 'Fuel Filter'}),
      );

      await db.syncQueueDao.enqueueOperation(
        operationId: 'op-sale',
        ownerId: testOwnerId,
        entityType: 'sales',
        entityId: 'sale-uuid-1',
        operationType: 'insert',
        dependsOn: 'op-part',
        payload: jsonEncode({'id': 'sale-uuid-1', 'totalAmount': 500.0}),
      );

      final coordinator = SyncCoordinatorService(
        db: db,
        dio: dio,
        sessionStore: sessionStore,
      );

      final result = await coordinator.synchronize(ownerId: testOwnerId);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.pushedCount, equals(2));

      // Both operations should now be confirmed and removed from queue
      final remaining = await db.syncQueueDao.getPendingBatch();
      expect(remaining.isEmpty, isTrue);
    });

    test('Pull pipeline: never overwrites locally dirty records (syncStatus == pending)', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://test.kera.local'));
      dio.httpClientAdapter = _MockHttpClientAdapter((options) {
        if (options.path.contains('/health')) {
          return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
        }
        if (options.path.contains('/sync/pull')) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'data': {
                'serverTimestamp': '2026-11-05T15:00:00Z',
                'changes': {
                  'parts': [
                    {
                      'id': 'part-locally-modified',
                      'name': 'Server Name (Stale Overwrite Attempt)',
                      'sellingPrice': 9999.0,
                      'cachedQuantity': 50.0,
                      'updatedAt': '2026-11-05T14:30:00Z',
                    },
                    {
                      'id': 'part-clean',
                      'name': 'Server Clean Part',
                      'sellingPrice': 450.0,
                      'cachedQuantity': 20.0,
                      'updatedAt': '2026-11-05T14:30:00Z',
                    },
                  ],
                  'sales': [],
                  'stockMovements': [],
                },
              },
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString('{}', 200);
      });

      // 1. Insert a locally modified part with syncStatus = pending
      await db.into(db.spareParts).insert(
            SparePartsCompanion.insert(
              id: const drift.Value('part-locally-modified'),
              ownerId: testOwnerId,
              name: const drift.Value('My Unsynced Local Edit'),
              sellingPrice: const drift.Value(1234.0),
              cachedQuantity: const drift.Value(5.0),
              syncStatus: const drift.Value(SyncStatus.pending),
            ),
          );

      // 2. Insert a clean part with syncStatus = synced
      await db.into(db.spareParts).insert(
            SparePartsCompanion.insert(
              id: const drift.Value('part-clean'),
              ownerId: testOwnerId,
              name: const drift.Value('Old Local Clean Part'),
              sellingPrice: const drift.Value(300.0),
              cachedQuantity: const drift.Value(10.0),
              syncStatus: const drift.Value(SyncStatus.synced),
            ),
          );

      final coordinator = SyncCoordinatorService(
        db: db,
        dio: dio,
        sessionStore: sessionStore,
      );

      final result = await coordinator.synchronize(ownerId: testOwnerId);
      expect(result.isSuccess, isTrue);

      // Verify locally dirty part was NOT overwritten
      final localDirtyPart = await (db.select(db.spareParts)..where((t) => t.id.equals('part-locally-modified'))).getSingle();
      expect(localDirtyPart.name, equals('My Unsynced Local Edit'));
      expect(localDirtyPart.sellingPrice, equals(1234.0));

      // Verify clean part WAS updated by the pull
      final cleanPart = await (db.select(db.spareParts)..where((t) => t.id.equals('part-clean'))).getSingle();
      expect(cleanPart.name, equals('Server Clean Part'));
      expect(cleanPart.sellingPrice, equals(450.0));
      expect(cleanPart.cachedQuantity, equals(20.0));

      // Verify sync cursor was saved
      final cursor = await db.syncQueueDao.getSyncState(testOwnerId);
      expect(cursor?.lastPullCursor, equals('2026-11-05T15:00:00Z'));
    });
  });
}

class _MockHttpClientAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) handler;

  _MockHttpClientAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}


import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/enums.dart';
import '../tables/sync_queue_table.dart';
import '../tables/sync_state_table.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueue, SyncState])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  /// Enqueues a mutation operation for offline synchronization (backward-compatible).
  Future<int> enqueue({
    required String tableName,
    required String recordId,
    required SyncOperation operation,
    required String payload,
    String? ownerId,
    String? operationId,
  }) {
    final opId = operationId ?? const Uuid().v4();
    return into(syncQueue).insert(
      SyncQueueCompanion.insert(
        operationId: Value(opId),
        ownerId: Value(ownerId),
        entityType: Value(tableName),
        tableTarget: tableName,
        entityId: Value(recordId),
        recordId: recordId,
        operationType: Value(operation.name),
        operation: operation,
        payload: payload,
        queueStatus: const Value('pending'),
      ),
    );
  }

  /// Full-featured outbox enqueue with operationId, dependencies, and base version.
  Future<int> enqueueOperation({
    required String entityType,
    required String entityId,
    required String operationType,
    required String payload,
    String? ownerId,
    String? operationId,
    int? baseVersion,
    String? dependsOn,
  }) {
    final opId = operationId ?? const Uuid().v4();
    final syncOp = operationType.toLowerCase() == 'delete'
        ? SyncOperation.delete
        : operationType.toLowerCase() == 'update'
            ? SyncOperation.update
            : SyncOperation.insert;

    return into(syncQueue).insert(
      SyncQueueCompanion.insert(
        operationId: Value(opId),
        ownerId: Value(ownerId),
        entityType: Value(entityType),
        tableTarget: entityType,
        entityId: Value(entityId),
        recordId: entityId,
        operationType: Value(operationType),
        operation: syncOp,
        baseVersion: Value(baseVersion),
        payload: payload,
        dependsOn: Value(dependsOn),
        queueStatus: const Value('pending'),
      ),
    );
  }

  /// Retrieves a batch of pending mutations to push to remote server.
  Future<List<SyncQueueItem>> getPendingBatch({int limit = 50}) {
    return (select(syncQueue)
          ..where((t) =>
              t.queueStatus.equals('pending') |
              t.queueStatus.equals('in_progress'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Claims a batch for single-flight processing, marking claimedAt and queueStatus = in_progress.
  Future<List<SyncQueueItem>> claimBatch({int limit = 50}) async {
    final now = DateTime.now();
    final items = await (select(syncQueue)
          ..where((t) =>
              t.queueStatus.equals('pending') |
              (t.queueStatus.equals('in_progress') &
                  t.claimedAt.isSmallerThanValue(
                      now.subtract(const Duration(minutes: 5)))))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();

    final updatedItems = <SyncQueueItem>[];
    for (final item in items) {
      await (update(syncQueue)..where((t) => t.id.equals(item.id))).write(
        SyncQueueCompanion(
          claimedAt: Value(now),
          queueStatus: const Value('in_progress'),
          lastAttemptAt: Value(now),
        ),
      );
      updatedItems.add(item.copyWith(
        claimedAt: Value(now),
        queueStatus: 'in_progress',
        lastAttemptAt: Value(now),
      ));
    }

    return updatedItems;
  }

  /// Removes an item from the sync queue after successful sync.
  Future<int> deleteItem(int id) {
    return (delete(syncQueue)..where((t) => t.id.equals(id))).go();
  }

  /// Marks an operation as synced or deletes it.
  Future<int> markOperationSynced(String operationId) {
    return (delete(syncQueue)..where((t) => t.operationId.equals(operationId)))
        .go();
  }

  /// Increments retry attempt and logs last error when sync fails.
  Future<int> recordAttemptFailure(int id, String error,
      {String? errorCode}) async {
    final item = await (select(syncQueue)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (item == null) return 0;

    final newAttempts = item.attempts + 1;
    final nextRetry =
        DateTime.now().add(Duration(seconds: 2 * newAttempts * newAttempts));

    return (update(syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(
        attempts: Value(newAttempts),
        retryCount: Value(newAttempts),
        lastError: Value(error),
        errorMessage: Value(error),
        errorCode: Value(errorCode),
        lastAttemptAt: Value(DateTime.now()),
        nextRetryAt: Value(nextRetry),
        queueStatus: Value(newAttempts > 5 ? 'failed' : 'pending'),
        claimedAt: const Value(null),
      ),
    );
  }

  /// Clears all completed or queued operations.
  Future<int> clearQueue() {
    return delete(syncQueue).go();
  }

  /// Returns true if there are any pending mutations in the queue.
  Future<bool> hasUnsyncedChanges() async {
    final item = await (select(syncQueue)
          ..where((t) => t.queueStatus.equals('pending') | t.queueStatus.equals('in_progress'))
          ..limit(1))
        .getSingleOrNull();
    return item != null;
  }

  /// Returns count of pending sync queue items.
  Future<int> countPending() async {
    final countExp = syncQueue.id.count();
    final query = selectOnly(syncQueue)
      ..where(syncQueue.queueStatus.equals('pending') |
          syncQueue.queueStatus.equals('in_progress'))
      ..addColumns([countExp]);
    final result = await query.map((row) => row.read(countExp)).getSingle();
    return result ?? 0;
  }

  /// Watches the count of pending sync queue items as a reactive stream.
  Stream<int> watchCountPending() {
    final countExp = syncQueue.id.count();
    final query = selectOnly(syncQueue)
      ..where(syncQueue.queueStatus.equals('pending') |
          syncQueue.queueStatus.equals('in_progress'))
      ..addColumns([countExp]);
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }

  /// Retrieves sync state for an owner.
  Future<SyncStateEntry?> getSyncState(String ownerId) {
    return (select(syncState)..where((t) => t.ownerId.equals(ownerId)))
        .getSingleOrNull();
  }

  /// Upserts sync cursor and timestamp for an owner.
  Future<int> saveSyncCursor(String ownerId, String cursor) {
    return into(syncState).insertOnConflictUpdate(
      SyncStateCompanion.insert(
        ownerId: ownerId,
        lastPullCursor: Value(cursor),
        lastSuccessAt: Value(DateTime.now()),
      ),
    );
  }
}

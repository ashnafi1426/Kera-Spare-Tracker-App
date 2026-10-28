import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/enums.dart';
import '../tables/sync_queue_table.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  /// Enqueues a mutation operation for offline synchronization.
  Future<int> enqueue({
    required String tableName,
    required String recordId,
    required SyncOperation operation,
    required String payload,
  }) {
    return into(syncQueue).insert(
      SyncQueueCompanion.insert(
        tableTarget: tableName,
        recordId: recordId,
        operation: operation,
        payload: payload,
      ),
    );
  }

  /// Retrieves a batch of pending mutations to push to remote server.
  Future<List<SyncQueueItem>> getPendingBatch({int limit = 50}) {
    return (select(syncQueue)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Removes an item from the sync queue after successful sync.
  Future<int> deleteItem(int id) {
    return (delete(syncQueue)..where((t) => t.id.equals(id))).go();
  }

  /// Increments retry attempt and logs last error when sync fails.
  Future<int> recordAttemptFailure(int id, String error) async {
    final item = await (select(syncQueue)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (item == null) return 0;

    return (update(syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(
        attempts: Value(item.attempts + 1),
        lastError: Value(error),
      ),
    );
  }

  /// Clears all completed or queued operations.
  Future<int> clearQueue() {
    return delete(syncQueue).go();
  }

  /// Returns true if there are any pending mutations in the queue.
  Future<bool> hasUnsyncedChanges() async {
    final item = await (select(syncQueue)..limit(1)).getSingleOrNull();
    return item != null;
  }

  /// Returns count of pending sync queue items.
  Future<int> countPending() async {
    final countExp = syncQueue.id.count();
    final query = selectOnly(syncQueue)..addColumns([countExp]);
    final result = await query.map((row) => row.read(countExp)).getSingle();
    return result ?? 0;
  }

  /// Watches the count of pending sync queue items as a reactive stream.
  Stream<int> watchCountPending() {
    final countExp = syncQueue.id.count();
    final query = selectOnly(syncQueue)..addColumns([countExp]);
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }
}

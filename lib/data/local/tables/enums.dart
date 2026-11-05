/// Enums representing database states, sync lifecycle, and domain types.
library;

/// Synchronization status for offline-first records.
enum SyncStatus {
  pending,
  synced,
  failed,
}

/// Status for sync queue operations.
enum QueueStatus {
  pending,
  inProgress,
  synced,
  failed,
  needsAttention,
  conflict,
}

/// Operation type for sync queue items.
enum SyncOperation {
  insert,
  update,
  delete,
}

/// Movement type in the append-only stock ledger.
enum MovementType {
  initial,
  purchase,
  stockIn,
  sale,
  stockOut,
  adjustment,
  returned,
  returnMovement,
}

/// User authorization roles.
enum UserRole {
  owner,
  admin,
}

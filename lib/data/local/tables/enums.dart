/// Enums representing database states, sync lifecycle, and domain types.
library;

/// Synchronization status for offline-first records.
enum SyncStatus {
  pending,
  synced,
  failed,
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
  sale,
  adjustment,
  returned,
}

/// User authorization roles.
enum UserRole {
  owner,
  admin,
}

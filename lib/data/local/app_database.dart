/// Local database layer using Drift / SQLite.
///
/// Per PROJECT_CONTEXT.md:
/// - UI and providers read and write ONLY the local Drift database through repositories.
/// - All IDs are UUIDs generated on the device.
/// - Every synced table has: id, owner_id, created_at, updated_at, deleted_at (soft delete).
/// - Stock quantity is the sum of stock_movements (a ledger).
library;

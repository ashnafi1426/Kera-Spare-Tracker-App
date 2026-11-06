import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/constants.dart';
import 'daos/parts_dao.dart';
import 'daos/sales_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/stock_dao.dart';
import 'daos/sync_queue_dao.dart';
import 'tables/app_settings_table.dart';
import 'tables/brands_table.dart';
import 'tables/categories_table.dart';
import 'tables/enums.dart';
import 'tables/locations_table.dart';
import 'tables/profiles_table.dart';
import 'tables/sale_items_table.dart';
import 'tables/sales_table.dart';
import 'tables/spare_parts_table.dart';
import 'tables/stock_movements_table.dart';
import 'tables/sync_meta_table.dart';
import 'tables/sync_queue_table.dart';
import 'tables/sync_state_table.dart';

export 'package:uuid/uuid.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Profiles,
    Brands,
    Categories,
    Locations,
    SpareParts,
    StockMovements,
    Sales,
    SaleItems,
    SyncQueue,
    SyncMeta,
    SyncState,
    AppSettings,
  ],
  daos: [
    PartsDao,
    StockDao,
    SalesDao,
    SyncQueueDao,
    SettingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  final String? dbOwnerId;

  AppDatabase([QueryExecutor? executor, this.dbOwnerId])
      : super(executor ?? _openConnection(dbOwnerId));

  factory AppDatabase.forOwner(String ownerId, [QueryExecutor? executor]) {
    return AppDatabase(executor, ownerId);
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();

        // Seed global default brands on first run
        for (final brandName in AppConstants.defaultBrands) {
          await into(brands).insert(
            BrandsCompanion.insert(
              ownerId: 'global',
              name: brandName,
              isDefault: const Value(true),
            ),
          );
        }

        // Seed global default shelf storage locations
        for (final shelfName in AppConstants.defaultShelves) {
          await into(locations).insert(
            LocationsCompanion.insert(
              ownerId: 'global',
              name: shelfName,
            ),
          );
        }
      },
      beforeOpen: (details) async {
        // Enforce foreign key constraints in SQLite
        await customStatement('PRAGMA foreign_keys = ON;');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          Future<void> safeAddColumn(TableInfo table, GeneratedColumn column) async {
            try {
              final pragma = await customSelect('PRAGMA table_info("${table.actualTableName}")').get();
              final exists = pragma.any((row) => row.read<String>('name') == column.$name);
              if (!exists) {
                await m.addColumn(table, column);
              }
            } catch (e) {
              debugPrint('[Migration] Column ${column.$name} check/add failed: $e');
            }
          }

          // 1. Create SyncState table if not exists
          try {
            await m.createTable(syncState);
          } catch (_) {}

          // 2. Add columns to spare_parts
          await safeAddColumn(spareParts, spareParts.serverId);
          await safeAddColumn(spareParts, spareParts.brand);
          await safeAddColumn(spareParts, spareParts.category);
          await safeAddColumn(spareParts, spareParts.storageLocation);
          await safeAddColumn(spareParts, spareParts.specifications);
          await safeAddColumn(spareParts, spareParts.minimumStock);
          await safeAddColumn(spareParts, spareParts.quantity);
          await safeAddColumn(spareParts, spareParts.serverVersion);

          // 3. Add columns to sales
          await safeAddColumn(sales, sales.serverId);
          await safeAddColumn(sales, sales.saleNumber);
          await safeAddColumn(sales, sales.totalCost);
          await safeAddColumn(sales, sales.saleDate);

          // 4. Add columns to sale_items
          await safeAddColumn(saleItems, saleItems.serverId);
          await safeAddColumn(saleItems, saleItems.sparePartId);
          await safeAddColumn(saleItems, saleItems.subtotal);
          await safeAddColumn(saleItems, saleItems.profit);

          // 5. Add columns to stock_movements
          await safeAddColumn(stockMovements, stockMovements.sparePartId);
          await safeAddColumn(stockMovements, stockMovements.movementType);
          await safeAddColumn(stockMovements, stockMovements.quantityBefore);
          await safeAddColumn(stockMovements, stockMovements.quantityAfter);

          // 6. Add columns to sync_queue
          await safeAddColumn(syncQueue, syncQueue.operationId);
          await safeAddColumn(syncQueue, syncQueue.ownerId);
          await safeAddColumn(syncQueue, syncQueue.entityType);
          await safeAddColumn(syncQueue, syncQueue.entityId);
          await safeAddColumn(syncQueue, syncQueue.operationType);
          await safeAddColumn(syncQueue, syncQueue.baseVersion);
          await safeAddColumn(syncQueue, syncQueue.dependsOn);
          await safeAddColumn(syncQueue, syncQueue.retryCount);
          await safeAddColumn(syncQueue, syncQueue.lastAttemptAt);
          await safeAddColumn(syncQueue, syncQueue.nextRetryAt);
          await safeAddColumn(syncQueue, syncQueue.claimedAt);
          await safeAddColumn(syncQueue, syncQueue.queueStatus);
          await safeAddColumn(syncQueue, syncQueue.errorCode);
          await safeAddColumn(syncQueue, syncQueue.errorMessage);

          // 7. Ensure index exists for operation_id
          try {
            await customStatement('CREATE INDEX IF NOT EXISTS idx_sync_queue_op_id ON sync_queue (operation_id);');
          } catch (_) {}
        }
      },
    );
  }

  static QueryExecutor _openConnection([String? ownerId]) {
    final dbName = (ownerId != null && ownerId.trim().isNotEmpty)
        ? 'kera_owner_${ownerId.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}'
        : 'kera_spare_tracker';
    return driftDatabase(name: dbName);
  }

  /// Wipes all tenant-specific data when a user confirms switching to another owner
  /// or discarding unsynced changes.
  Future<void> clearAllOwnerData() async {
    await transaction(() async {
      await delete(syncQueue).go();
      await delete(saleItems).go();
      await delete(sales).go();
      await delete(stockMovements).go();
      await delete(spareParts).go();
      await delete(profiles).go();
    });
  }
}

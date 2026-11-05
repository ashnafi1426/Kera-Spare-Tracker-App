import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
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
          // 1. Create SyncState table
          await m.createTable(syncState);

          // 2. Add columns to spare_parts
          await m.addColumn(spareParts, spareParts.serverId);
          await m.addColumn(spareParts, spareParts.brand);
          await m.addColumn(spareParts, spareParts.category);
          await m.addColumn(spareParts, spareParts.storageLocation);
          await m.addColumn(spareParts, spareParts.specifications);
          await m.addColumn(spareParts, spareParts.minimumStock);
          await m.addColumn(spareParts, spareParts.quantity);
          await m.addColumn(spareParts, spareParts.serverVersion);

          // 3. Add columns to sales
          await m.addColumn(sales, sales.serverId);
          await m.addColumn(sales, sales.saleNumber);
          await m.addColumn(sales, sales.totalCost);
          await m.addColumn(sales, sales.saleDate);

          // 4. Add columns to sale_items
          await m.addColumn(saleItems, saleItems.serverId);
          await m.addColumn(saleItems, saleItems.sparePartId);
          await m.addColumn(saleItems, saleItems.subtotal);
          await m.addColumn(saleItems, saleItems.profit);

          // 5. Add columns to stock_movements
          await m.addColumn(stockMovements, stockMovements.sparePartId);
          await m.addColumn(stockMovements, stockMovements.movementType);
          await m.addColumn(stockMovements, stockMovements.quantityBefore);
          await m.addColumn(stockMovements, stockMovements.quantityAfter);

          // 6. Add columns to sync_queue
          await m.addColumn(syncQueue, syncQueue.operationId);
          await m.addColumn(syncQueue, syncQueue.ownerId);
          await m.addColumn(syncQueue, syncQueue.entityType);
          await m.addColumn(syncQueue, syncQueue.entityId);
          await m.addColumn(syncQueue, syncQueue.operationType);
          await m.addColumn(syncQueue, syncQueue.baseVersion);
          await m.addColumn(syncQueue, syncQueue.dependsOn);
          await m.addColumn(syncQueue, syncQueue.retryCount);
          await m.addColumn(syncQueue, syncQueue.lastAttemptAt);
          await m.addColumn(syncQueue, syncQueue.nextRetryAt);
          await m.addColumn(syncQueue, syncQueue.claimedAt);
          await m.addColumn(syncQueue, syncQueue.queueStatus);
          await m.addColumn(syncQueue, syncQueue.errorCode);
          await m.addColumn(syncQueue, syncQueue.errorMessage);
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

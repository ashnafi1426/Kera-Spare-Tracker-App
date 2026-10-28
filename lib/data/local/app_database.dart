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
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

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
        // Schema migration steps for future versions
      },
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'kera_spare_tracker');
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

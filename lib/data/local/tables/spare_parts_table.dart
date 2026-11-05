import 'package:drift/drift.dart';
import 'base_table.dart';

/// Spare parts inventory catalog table.
/// All fields are nullable except id and owner_id per requirements.
@TableIndex(name: 'idx_parts_name', columns: {#name})
@TableIndex(name: 'idx_parts_part_number', columns: {#partNumber})
@TableIndex(name: 'idx_parts_brand_id', columns: {#brandId})
@TableIndex(name: 'idx_parts_category_id', columns: {#categoryId})
@TableIndex(name: 'idx_parts_location_id', columns: {#locationId})
@TableIndex(name: 'idx_parts_owner_id', columns: {#ownerId})
@TableIndex(name: 'idx_parts_server_id', columns: {#serverId})
@TableIndex(name: 'idx_parts_sync_status', columns: {#syncStatus})
@DataClassName('SparePart')
class SpareParts extends Table with SyncedTableMixin {
  TextColumn get serverId => text().nullable()();
  TextColumn get name => text().nullable()();
  TextColumn get partNumber => text().nullable()();
  TextColumn get photoLocalPath => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  TextColumn get brand => text().nullable()();
  TextColumn get brandId => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get storageLocation => text().nullable()();
  TextColumn get locationId => text().nullable()();
  TextColumn get customLocation => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get unit => text().nullable()();
  RealColumn get purchasePrice => real().nullable()();
  RealColumn get sellingPrice => real().nullable()();
  RealColumn get quantity => real().nullable()();
  RealColumn get cachedQuantity => real().nullable()();
  RealColumn get minimumStock => real().nullable()();
  RealColumn get lowStockLevel => real().nullable()();
  TextColumn get specifications => text().nullable()();
  TextColumn get sizeSpecs => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get serverVersion => integer().withDefault(const Constant(1))();
}

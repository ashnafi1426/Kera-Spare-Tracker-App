import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/enums.dart';
import '../tables/spare_parts_table.dart';
import '../tables/stock_movements_table.dart';

part 'parts_dao.g.dart';

@DriftAccessor(tables: [SpareParts, StockMovements])
class PartsDao extends DatabaseAccessor<AppDatabase> with _$PartsDaoMixin {
  PartsDao(super.db);

  /// Watches all active (non-deleted) parts for an owner.
  Stream<List<SparePart>> watchActiveParts(String ownerId) {
    return (select(spareParts)
          ..where((t) => t.ownerId.equals(ownerId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Retrieves all active parts for an owner.
  Future<List<SparePart>> getActiveParts(String ownerId) {
    return (select(spareParts)
          ..where((t) => t.ownerId.equals(ownerId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Retrieves a specific part by ID.
  Future<SparePart?> getPartById(String id, String ownerId) {
    return (select(spareParts)
          ..where((t) =>
              t.id.equals(id) & t.ownerId.equals(ownerId) & t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// Searches active parts by query, brand, category, or location.
  Future<List<SparePart>> searchParts({
    required String ownerId,
    String? query,
    String? brandId,
    String? categoryId,
    String? locationId,
  }) {
    final statement = select(spareParts)
      ..where((t) => t.ownerId.equals(ownerId) & t.deletedAt.isNull());

    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim().toLowerCase()}%';
      statement.where((t) =>
          t.name.lower().like(q) |
          t.partNumber.lower().like(q) |
          t.description.lower().like(q));
    }

    if (brandId != null) {
      statement.where((t) => t.brandId.equals(brandId));
    }
    if (categoryId != null) {
      statement.where((t) => t.categoryId.equals(categoryId));
    }
    if (locationId != null) {
      statement.where((t) => t.locationId.equals(locationId));
    }

    return statement.get();
  }

  /// Inserts a new spare part.
  Future<int> insertPart(SparePartsCompanion part) {
    return into(spareParts).insert(part);
  }

  /// Updates an existing spare part.
  Future<bool> updatePart(SparePartsCompanion part) {
    return update(spareParts).replace(part);
  }

  /// Updates cached quantity on the spare part.
  Future<int> updateCachedQuantity(String partId, double quantity) {
    return (update(spareParts)..where((t) => t.id.equals(partId))).write(
      SparePartsCompanion(
        cachedQuantity: Value(quantity),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Soft deletes a spare part and marks it for syncing.
  Future<int> softDeletePart(String id, String ownerId) {
    final now = DateTime.now();
    return (update(spareParts)
          ..where((t) => t.id.equals(id) & t.ownerId.equals(ownerId)))
        .write(
      SparePartsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value(SyncStatus.pending),
      ),
    );
  }
}

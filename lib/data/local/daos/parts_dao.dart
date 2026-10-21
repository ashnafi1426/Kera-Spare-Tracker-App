import 'package:drift/drift.dart';
import 'package:kera_spare_tracker/features/parts/domain/models/inventory_filter.dart';
import 'package:kera_spare_tracker/features/parts/domain/models/paged_result.dart';
import 'package:kera_spare_tracker/features/parts/domain/models/part_item.dart';
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

  /// Builds a combined WHERE expression for search and filtering.
  Expression<bool> _buildFilterExpression({
    required String ownerId,
    String? query,
    String? brandId,
    String? categoryId,
    String? locationId,
    StockFilter stockFilter = StockFilter.all,
  }) {
    Expression<bool> expr =
        spareParts.ownerId.equals(ownerId) & spareParts.deletedAt.isNull();

    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim().toLowerCase()}%';
      final searchExpr = spareParts.name.lower().like(q) |
          spareParts.partNumber.lower().like(q) |
          spareParts.customLocation.lower().like(q) |
          db.brands.name.lower().like(q) |
          db.categories.name.lower().like(q) |
          db.locations.name.lower().like(q);
      expr = expr & searchExpr;
    }

    if (brandId != null) {
      expr = expr & spareParts.brandId.equals(brandId);
    }
    if (categoryId != null) {
      expr = expr & spareParts.categoryId.equals(categoryId);
    }
    if (locationId != null) {
      expr = expr & spareParts.locationId.equals(locationId);
    }

    switch (stockFilter) {
      case StockFilter.all:
        break;
      case StockFilter.inStock:
        expr = expr &
            spareParts.cachedQuantity.isBiggerThanValue(0.0) &
            (spareParts.lowStockLevel.isNull() |
                spareParts.cachedQuantity.isBiggerThan(spareParts.lowStockLevel)) &
            spareParts.cachedQuantity.isBiggerThanValue(5.0);
        break;
      case StockFilter.lowStock:
        expr = expr &
            spareParts.cachedQuantity.isBiggerThanValue(0.0) &
            ((spareParts.lowStockLevel.isNotNull() &
                    spareParts.cachedQuantity.isSmallerOrEqual(spareParts.lowStockLevel)) |
                spareParts.cachedQuantity.isSmallerOrEqualValue(5.0));
        break;
      case StockFilter.outOfStock:
        expr = expr &
            (spareParts.cachedQuantity.isNull() |
                spareParts.cachedQuantity.isSmallerOrEqualValue(0.0));
        break;
    }

    return expr;
  }

  /// Paged search and filtering query with joined brand, category, and location metadata.
  Future<PagedResult<PartItem>> getPagedParts({
    required String ownerId,
    InventoryFilter filter = const InventoryFilter(),
    int limit = 50,
    int offset = 0,
  }) async {
    final whereExpr = _buildFilterExpression(
      ownerId: ownerId,
      query: filter.query,
      brandId: filter.brandId,
      categoryId: filter.categoryId,
      locationId: filter.locationId,
      stockFilter: filter.stockFilter,
    );

    // 1. Total count query
    final countQuery = selectOnly(spareParts).join([
      leftOuterJoin(db.brands, db.brands.id.equalsExp(spareParts.brandId)),
      leftOuterJoin(
          db.categories, db.categories.id.equalsExp(spareParts.categoryId)),
      leftOuterJoin(
          db.locations, db.locations.id.equalsExp(spareParts.locationId)),
    ])
      ..addColumns([countAll()])
      ..where(whereExpr);

    final countRow = await countQuery.getSingle();
    final totalCount = countRow.read(countAll()) ?? 0;

    // 2. Ordering terms
    final List<OrderingTerm> ordering = [];
    final mode =
        filter.sortAscending ? OrderingMode.asc : OrderingMode.desc;

    switch (filter.sortBy) {
      case PartsSortBy.name:
        ordering.add(OrderingTerm(
          expression: spareParts.name.lower(),
          mode: filter.sortAscending ? OrderingMode.asc : OrderingMode.desc,
        ));
        break;
      case PartsSortBy.newest:
        ordering.add(OrderingTerm(
          expression: spareParts.createdAt,
          mode: filter.sortAscending ? OrderingMode.asc : OrderingMode.desc,
        ));
        break;
      case PartsSortBy.quantity:
        ordering.add(OrderingTerm(
          expression: spareParts.cachedQuantity,
          mode: mode,
        ));
        break;
      case PartsSortBy.price:
        ordering.add(OrderingTerm(
          expression: spareParts.sellingPrice,
          mode: mode,
        ));
        break;
    }

    // Secondary sort tiebreaker
    ordering.add(OrderingTerm(
      expression: spareParts.createdAt,
      mode: OrderingMode.desc,
    ));

    // 3. Paged data query
    final dataQuery = select(spareParts).join([
      leftOuterJoin(db.brands, db.brands.id.equalsExp(spareParts.brandId)),
      leftOuterJoin(
          db.categories, db.categories.id.equalsExp(spareParts.categoryId)),
      leftOuterJoin(
          db.locations, db.locations.id.equalsExp(spareParts.locationId)),
    ])
      ..where(whereExpr)
      ..orderBy(ordering)
      ..limit(limit, offset: offset);

    final rows = await dataQuery.get();

    final items = rows.map((row) {
      final p = row.readTable(spareParts);
      final b = row.readTableOrNull(db.brands);
      final c = row.readTableOrNull(db.categories);
      final l = row.readTableOrNull(db.locations);

      return PartItem(
        id: p.id,
        ownerId: p.ownerId,
        name: p.name,
        partNumber: p.partNumber,
        photoLocalPath: p.photoLocalPath,
        photoUrl: p.photoUrl,
        brandId: p.brandId,
        brandName: b?.name,
        categoryId: p.categoryId,
        categoryName: c?.name,
        locationId: p.locationId,
        locationName: l?.name,
        customLocation: p.customLocation,
        description: p.description,
        unit: p.unit,
        purchasePrice: p.purchasePrice,
        sellingPrice: p.sellingPrice,
        sizeSpecs: p.sizeSpecs,
        notes: p.notes,
        lowStockLevel: p.lowStockLevel,
        cachedQuantity: p.cachedQuantity ?? 0.0,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
        deletedAt: p.deletedAt,
      );
    }).toList();

    return PagedResult<PartItem>(
      items: items,
      totalCount: totalCount,
      offset: offset,
      limit: limit,
    );
  }

  /// Bulk inserts multiple parts efficiently in a single batch.
  Future<void> batchInsertParts(List<SparePartsCompanion> parts) {
    return batch((b) {
      b.insertAll(spareParts, parts);
    });
  }

  /// Deletes generated test parts for an owner.
  Future<int> deleteTestParts(String ownerId) {
    return (delete(spareParts)
          ..where((t) =>
              t.ownerId.equals(ownerId) & t.notes.like('%[TEST_SEED]%')))
        .go();
  }
}

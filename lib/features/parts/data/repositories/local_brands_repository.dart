import 'dart:convert';
import 'package:drift/drift.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../../data/local/app_database.dart';
import '../../../../data/local/tables/enums.dart';
import '../../domain/models/brand_item.dart';
import '../../domain/repositories/brands_repository.dart';

/// SQLite and sync_queue backed implementation of [BrandsRepository].
class LocalBrandsRepository implements BrandsRepository {
  final AppDatabase db;
  final Uuid uuid;

  LocalBrandsRepository({
    required this.db,
    this.uuid = const Uuid(),
  });

  @override
  Stream<List<BrandItem>> watchBrands(String ownerId) {
    final query = db.select(db.brands)
      ..where((t) =>
          (t.ownerId.equals(ownerId) | t.ownerId.equals('global')) &
          t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm.desc(t.isDefault),
        (t) => OrderingTerm.asc(t.name),
      ]);

    return query.watch().map((rows) => rows.map(_mapRowToBrandItem).toList());
  }

  @override
  Future<Result<List<BrandItem>>> getBrands(String ownerId) async {
    try {
      final query = db.select(db.brands)
        ..where((t) =>
            (t.ownerId.equals(ownerId) | t.ownerId.equals('global')) &
            t.deletedAt.isNull())
        ..orderBy([
          (t) => OrderingTerm.desc(t.isDefault),
          (t) => OrderingTerm.asc(t.name),
        ]);

      final rows = await query.get();
      return Result.success(rows.map(_mapRowToBrandItem).toList());
    } catch (e) {
      return Result.failure(DatabaseFailure(
        message: 'Failed to query brands: $e',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<BrandItem>> createBrand({
    required String ownerId,
    required String name,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const Result.failure(ValidationFailure(message: 'Brand name is required'));
    }

    try {
      // Check for duplicate name (case-insensitive) among active brands for this owner or global
      final isDuplicate = await _checkDuplicate(
        ownerId: ownerId,
        name: trimmedName,
      );
      if (isDuplicate) {
        return const Result.failure(
          ValidationFailure(message: 'An item with this name already exists'),
        );
      }

      final brandId = uuid.v4();
      final now = DateTime.now();

      final brand = await db.transaction(() async {
        await db.into(db.brands).insert(
              BrandsCompanion.insert(
                id: Value(brandId),
                ownerId: ownerId,
                name: trimmedName,
                isDefault: const Value(false),
                createdAt: Value(now),
                updatedAt: Value(now),
                syncStatus: const Value(SyncStatus.pending),
              ),
            );

        // Record offline mutation in sync_queue
        await db.syncQueueDao.enqueue(
          tableName: 'brands',
          recordId: brandId,
          operation: SyncOperation.insert,
          payload: jsonEncode({
            'id': brandId,
            'owner_id': ownerId,
            'name': trimmedName,
            'is_default': false,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          }),
        );

        return BrandItem(
          id: brandId,
          ownerId: ownerId,
          name: trimmedName,
          isDefault: false,
          createdAt: now,
          updatedAt: now,
        );
      });

      return Result.success(brand);
    } catch (e) {
      return Result.failure(DatabaseFailure(
        message: 'Failed to create brand: $e',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<BrandItem>> updateBrand({
    required String ownerId,
    required String id,
    required String name,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const Result.failure(ValidationFailure(message: 'Brand name is required'));
    }

    try {
      final existing = await (db.select(db.brands)
            ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
          .getSingleOrNull();

      if (existing == null) {
        return const Result.failure(NotFoundFailure(message: 'Brand not found'));
      }

      if (existing.isDefault || existing.ownerId != ownerId) {
        return const Result.failure(
          AuthFailure(message: 'Default brands cannot be modified'),
        );
      }

      // Check duplicate name excluding current ID
      final isDuplicate = await _checkDuplicate(
        ownerId: ownerId,
        name: trimmedName,
        excludeId: id,
      );
      if (isDuplicate) {
        return const Result.failure(
          ValidationFailure(message: 'An item with this name already exists'),
        );
      }

      final now = DateTime.now();

      final updated = await db.transaction(() async {
        await (db.update(db.brands)..where((t) => t.id.equals(id))).write(
          BrandsCompanion(
            name: Value(trimmedName),
            updatedAt: Value(now),
            syncStatus: const Value(SyncStatus.pending),
          ),
        );

        await db.syncQueueDao.enqueue(
          tableName: 'brands',
          recordId: id,
          operation: SyncOperation.update,
          payload: jsonEncode({
            'id': id,
            'owner_id': ownerId,
            'name': trimmedName,
            'updated_at': now.toIso8601String(),
          }),
        );

        return BrandItem(
          id: id,
          ownerId: ownerId,
          name: trimmedName,
          isDefault: false,
          createdAt: existing.createdAt,
          updatedAt: now,
        );
      });

      return Result.success(updated);
    } catch (e) {
      return Result.failure(DatabaseFailure(
        message: 'Failed to update brand: $e',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<void>> deactivateBrand({
    required String ownerId,
    required String id,
  }) async {
    try {
      final existing = await (db.select(db.brands)
            ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
          .getSingleOrNull();

      if (existing == null) {
        return const Result.failure(NotFoundFailure(message: 'Brand not found'));
      }

      if (existing.isDefault || existing.ownerId != ownerId) {
        return const Result.failure(
          AuthFailure(message: 'Default brands cannot be deactivated'),
        );
      }

      final now = DateTime.now();

      await db.transaction(() async {
        await (db.update(db.brands)..where((t) => t.id.equals(id))).write(
          BrandsCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
            syncStatus: const Value(SyncStatus.pending),
          ),
        );

        await db.syncQueueDao.enqueue(
          tableName: 'brands',
          recordId: id,
          operation: SyncOperation.delete,
          payload: jsonEncode({
            'id': id,
            'owner_id': ownerId,
            'deleted_at': now.toIso8601String(),
          }),
        );
      });

      return const Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure(
        message: 'Failed to deactivate brand: $e',
        cause: e,
      ));
    }
  }

  Future<bool> _checkDuplicate({
    required String ownerId,
    required String name,
    String? excludeId,
  }) async {
    final activeBrands = await (db.select(db.brands)
          ..where((t) =>
              (t.ownerId.equals(ownerId) | t.ownerId.equals('global')) &
              t.deletedAt.isNull()))
        .get();

    final targetLower = name.trim().toLowerCase();
    return activeBrands.any((b) =>
        (excludeId == null || b.id != excludeId) &&
        b.name.trim().toLowerCase() == targetLower);
  }

  BrandItem _mapRowToBrandItem(Brand row) {
    return BrandItem(
      id: row.id,
      ownerId: row.ownerId,
      name: row.name,
      isDefault: row.isDefault,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

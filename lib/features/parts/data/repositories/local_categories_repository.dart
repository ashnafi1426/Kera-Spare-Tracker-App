import 'dart:convert';
import 'package:drift/drift.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../../data/local/app_database.dart';
import '../../../../data/local/tables/enums.dart';
import '../../domain/models/category_item.dart';
import '../../domain/repositories/categories_repository.dart';

/// SQLite and sync_queue backed implementation of [CategoriesRepository].
class LocalCategoriesRepository implements CategoriesRepository {
  final AppDatabase db;
  final Uuid uuid;

  LocalCategoriesRepository({
    required this.db,
    this.uuid = const Uuid(),
  });

  @override
  Stream<List<CategoryItem>> watchCategories(String ownerId) {
    final query = db.select(db.categories)
      ..where((t) =>
          (t.ownerId.equals(ownerId) | t.ownerId.equals('global')) &
          t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);

    return query
        .watch()
        .map((rows) => rows.map(_mapRowToCategoryItem).toList());
  }

  @override
  Future<Result<List<CategoryItem>>> getCategories(String ownerId) async {
    try {
      final query = db.select(db.categories)
        ..where((t) =>
            (t.ownerId.equals(ownerId) | t.ownerId.equals('global')) &
            t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.name)]);

      final rows = await query.get();
      return Result.success(rows.map(_mapRowToCategoryItem).toList());
    } catch (e) {
      return Result.failure(DatabaseFailure(
        message: 'Failed to query categories: $e',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<CategoryItem>> createCategory({
    required String ownerId,
    required String name,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Category name is required'),
      );
    }

    try {
      final isDuplicate = await _checkDuplicate(
        ownerId: ownerId,
        name: trimmedName,
      );
      if (isDuplicate) {
        return const Result.failure(
          ValidationFailure(message: 'An item with this name already exists'),
        );
      }

      final categoryId = uuid.v4();
      final now = DateTime.now();

      final category = await db.transaction(() async {
        await db.into(db.categories).insert(
              CategoriesCompanion.insert(
                id: Value(categoryId),
                ownerId: ownerId,
                name: trimmedName,
                createdAt: Value(now),
                updatedAt: Value(now),
                syncStatus: const Value(SyncStatus.pending),
              ),
            );

        // Record offline mutation in sync_queue
        await db.syncQueueDao.enqueue(
          tableName: 'categories',
          recordId: categoryId,
          operation: SyncOperation.insert,
          payload: jsonEncode({
            'id': categoryId,
            'owner_id': ownerId,
            'name': trimmedName,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          }),
        );

        return CategoryItem(
          id: categoryId,
          ownerId: ownerId,
          name: trimmedName,
          createdAt: now,
          updatedAt: now,
        );
      });

      return Result.success(category);
    } catch (e) {
      return Result.failure(DatabaseFailure(
        message: 'Failed to create category: $e',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<CategoryItem>> updateCategory({
    required String ownerId,
    required String id,
    required String name,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Category name is required'),
      );
    }

    try {
      final existing = await (db.select(db.categories)
            ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
          .getSingleOrNull();

      if (existing == null) {
        return const Result.failure(NotFoundFailure(message: 'Category not found'));
      }

      if (existing.ownerId != ownerId) {
        return const Result.failure(
          AuthFailure(message: 'Cannot modify another owner\'s category'),
        );
      }

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
        await (db.update(db.categories)..where((t) => t.id.equals(id))).write(
          CategoriesCompanion(
            name: Value(trimmedName),
            updatedAt: Value(now),
            syncStatus: const Value(SyncStatus.pending),
          ),
        );

        await db.syncQueueDao.enqueue(
          tableName: 'categories',
          recordId: id,
          operation: SyncOperation.update,
          payload: jsonEncode({
            'id': id,
            'owner_id': ownerId,
            'name': trimmedName,
            'updated_at': now.toIso8601String(),
          }),
        );

        return CategoryItem(
          id: id,
          ownerId: ownerId,
          name: trimmedName,
          createdAt: existing.createdAt,
          updatedAt: now,
        );
      });

      return Result.success(updated);
    } catch (e) {
      return Result.failure(DatabaseFailure(
        message: 'Failed to update category: $e',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<void>> deactivateCategory({
    required String ownerId,
    required String id,
  }) async {
    try {
      final existing = await (db.select(db.categories)
            ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
          .getSingleOrNull();

      if (existing == null) {
        return const Result.failure(NotFoundFailure(message: 'Category not found'));
      }

      if (existing.ownerId != ownerId) {
        return const Result.failure(
          AuthFailure(message: 'Cannot deactivate another owner\'s category'),
        );
      }

      final now = DateTime.now();

      await db.transaction(() async {
        await (db.update(db.categories)..where((t) => t.id.equals(id))).write(
          CategoriesCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
            syncStatus: const Value(SyncStatus.pending),
          ),
        );

        await db.syncQueueDao.enqueue(
          tableName: 'categories',
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
        message: 'Failed to deactivate category: $e',
        cause: e,
      ));
    }
  }

  Future<bool> _checkDuplicate({
    required String ownerId,
    required String name,
    String? excludeId,
  }) async {
    final activeCategories = await (db.select(db.categories)
          ..where((t) =>
              (t.ownerId.equals(ownerId) | t.ownerId.equals('global')) &
              t.deletedAt.isNull()))
        .get();

    final targetLower = name.trim().toLowerCase();
    return activeCategories.any((c) =>
        (excludeId == null || c.id != excludeId) &&
        c.name.trim().toLowerCase() == targetLower);
  }

  CategoryItem _mapRowToCategoryItem(Category row) {
    return CategoryItem(
      id: row.id,
      ownerId: row.ownerId,
      name: row.name,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

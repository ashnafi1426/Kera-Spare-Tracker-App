import 'dart:convert';
import 'package:drift/drift.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../../data/local/app_database.dart';
import '../../../../data/local/tables/enums.dart';
import '../../domain/models/location_item.dart';
import '../../domain/repositories/locations_repository.dart';

/// SQLite and sync_queue backed implementation of [LocationsRepository].
class LocalLocationsRepository implements LocationsRepository {
  final AppDatabase db;
  final Uuid uuid;

  LocalLocationsRepository({
    required this.db,
    this.uuid = const Uuid(),
  });

  @override
  Stream<List<LocationItem>> watchLocations(String ownerId) {
    final query = db.select(db.locations)
      ..where((t) =>
          (t.ownerId.equals(ownerId) | t.ownerId.equals('global')) &
          t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm.desc(t.ownerId.equals('global')),
        (t) => OrderingTerm.asc(t.name),
      ]);

    return query.watch().map((rows) => rows.map(_mapRowToLocationItem).toList());
  }

  @override
  Future<Result<List<LocationItem>>> getLocations(String ownerId) async {
    try {
      final query = db.select(db.locations)
        ..where((t) =>
            (t.ownerId.equals(ownerId) | t.ownerId.equals('global')) &
            t.deletedAt.isNull())
        ..orderBy([
          (t) => OrderingTerm.desc(t.ownerId.equals('global')),
          (t) => OrderingTerm.asc(t.name),
        ]);

      final rows = await query.get();
      return Result.success(rows.map(_mapRowToLocationItem).toList());
    } catch (e) {
      return Result.failure(DatabaseFailure(
        message: 'Failed to query locations: $e',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<LocationItem>> createLocation({
    required String ownerId,
    required String name,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Location name is required'),
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

      final locationId = uuid.v4();
      final now = DateTime.now();

      final location = await db.transaction(() async {
        await db.into(db.locations).insert(
              LocationsCompanion.insert(
                id: Value(locationId),
                ownerId: ownerId,
                name: trimmedName,
                createdAt: Value(now),
                updatedAt: Value(now),
                syncStatus: const Value(SyncStatus.pending),
              ),
            );

        // Record offline mutation in sync_queue
        await db.syncQueueDao.enqueue(
          tableName: 'locations',
          recordId: locationId,
          operation: SyncOperation.insert,
          payload: jsonEncode({
            'id': locationId,
            'owner_id': ownerId,
            'name': trimmedName,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          }),
        );

        return LocationItem(
          id: locationId,
          ownerId: ownerId,
          name: trimmedName,
          isDefault: false,
          createdAt: now,
          updatedAt: now,
        );
      });

      return Result.success(location);
    } catch (e) {
      return Result.failure(DatabaseFailure(
        message: 'Failed to create location: $e',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<LocationItem>> updateLocation({
    required String ownerId,
    required String id,
    required String name,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Location name is required'),
      );
    }

    try {
      final existing = await (db.select(db.locations)
            ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
          .getSingleOrNull();

      if (existing == null) {
        return const Result.failure(NotFoundFailure(message: 'Location not found'));
      }

      if (existing.ownerId == 'global' || existing.ownerId != ownerId) {
        return const Result.failure(
          AuthFailure(message: 'Default shelf locations cannot be modified'),
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
        await (db.update(db.locations)..where((t) => t.id.equals(id))).write(
          LocationsCompanion(
            name: Value(trimmedName),
            updatedAt: Value(now),
            syncStatus: const Value(SyncStatus.pending),
          ),
        );

        await db.syncQueueDao.enqueue(
          tableName: 'locations',
          recordId: id,
          operation: SyncOperation.update,
          payload: jsonEncode({
            'id': id,
            'owner_id': ownerId,
            'name': trimmedName,
            'updated_at': now.toIso8601String(),
          }),
        );

        return LocationItem(
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
        message: 'Failed to update location: $e',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<void>> deactivateLocation({
    required String ownerId,
    required String id,
  }) async {
    try {
      final existing = await (db.select(db.locations)
            ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
          .getSingleOrNull();

      if (existing == null) {
        return const Result.failure(NotFoundFailure(message: 'Location not found'));
      }

      if (existing.ownerId == 'global' || existing.ownerId != ownerId) {
        return const Result.failure(
          AuthFailure(message: 'Default shelf locations cannot be deactivated'),
        );
      }

      final now = DateTime.now();

      await db.transaction(() async {
        await (db.update(db.locations)..where((t) => t.id.equals(id))).write(
          LocationsCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
            syncStatus: const Value(SyncStatus.pending),
          ),
        );

        await db.syncQueueDao.enqueue(
          tableName: 'locations',
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
        message: 'Failed to deactivate location: $e',
        cause: e,
      ));
    }
  }

  Future<bool> _checkDuplicate({
    required String ownerId,
    required String name,
    String? excludeId,
  }) async {
    final activeLocations = await (db.select(db.locations)
          ..where((t) =>
              (t.ownerId.equals(ownerId) | t.ownerId.equals('global')) &
              t.deletedAt.isNull()))
        .get();

    final targetLower = name.trim().toLowerCase();
    return activeLocations.any((loc) =>
        (excludeId == null || loc.id != excludeId) &&
        loc.name.trim().toLowerCase() == targetLower);
  }

  LocationItem _mapRowToLocationItem(Location row) {
    return LocationItem(
      id: row.id,
      ownerId: row.ownerId,
      name: row.name,
      isDefault: row.ownerId == 'global',
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

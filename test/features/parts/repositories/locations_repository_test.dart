import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/constants/constants.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/data/local/tables/enums.dart';
import 'package:kera_spare_tracker/features/parts/data/repositories/local_locations_repository.dart';

void main() {
  late AppDatabase db;
  late LocalLocationsRepository repo;
  const ownerA = 'owner_111';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = LocalLocationsRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('LocationsRepository - Query & Default Shelves', () {
    test('returns default seeded shelves (Shelf 1, Shelf 2...) by default',
        () async {
      final res = await repo.getLocations(ownerA);
      expect(res.isSuccess, isTrue);

      final locations = res.valueOrNull!;
      expect(locations.length, equals(AppConstants.defaultShelves.length));
      expect(locations.every((l) => l.isDefault), isTrue);
      expect(locations.map((l) => l.name), contains('Shelf 1'));
    });
  });

  group('LocationsRepository - Create & SyncQueue', () {
    test('creates custom storage location and writes mutation to sync_queue',
        () async {
      final createRes = await repo.createLocation(
        ownerId: ownerA,
        name: 'Drawer B-12',
      );

      expect(createRes.isSuccess, isTrue);
      final loc = createRes.valueOrNull!;
      expect(loc.name, equals('Drawer B-12'));
      expect(loc.isDefault, isFalse);

      final queue = await db.syncQueueDao.getPendingBatch();
      expect(queue.length, equals(1));
      expect(queue.first.tableTarget, equals('locations'));
      expect(queue.first.operation, equals(SyncOperation.insert));

      final payload = jsonDecode(queue.first.payload) as Map<String, dynamic>;
      expect(payload['name'], equals('Drawer B-12'));
    });

    test('rejects duplicate location name case-insensitively with default shelf',
        () async {
      final res =
          await repo.createLocation(ownerId: ownerA, name: 'shelf 1');
      expect(res.isFailure, isTrue);
      expect(res.failureOrNull?.message,
          equals('An item with this name already exists'));
    });

    test('rejects duplicate location name for existing custom location',
        () async {
      await repo.createLocation(ownerId: ownerA, name: 'Warehouse Rack A');
      final res = await repo.createLocation(
          ownerId: ownerA, name: ' warehouse rack a ');
      expect(res.isFailure, isTrue);
      expect(res.failureOrNull?.message,
          equals('An item with this name already exists'));
    });
  });

  group('LocationsRepository - Update & Deactivate', () {
    test('updates custom location and enqueues update in sync_queue', () async {
      final created =
          (await repo.createLocation(ownerId: ownerA, name: 'Box 1'))
              .valueOrNull!;

      final updateRes = await repo.updateLocation(
        ownerId: ownerA,
        id: created.id,
        name: 'Box 1 - Front',
      );

      expect(updateRes.isSuccess, isTrue);
      final updated = updateRes.valueOrNull!;
      expect(updated.name, equals('Box 1 - Front'));

      final queue = await db.syncQueueDao.getPendingBatch();
      expect(queue.any((q) => q.operation == SyncOperation.update), isTrue);
    });

    test('prevents updating default shelf locations', () async {
      final shelf = (await repo.getLocations(ownerA)).valueOrNull!.first;
      expect(shelf.isDefault, isTrue);

      final res = await repo.updateLocation(
        ownerId: ownerA,
        id: shelf.id,
        name: 'Modified Shelf',
      );

      expect(res.isFailure, isTrue);
      expect(res.failureOrNull?.message,
          equals('Default shelf locations cannot be modified'));
    });

    test('deactivates custom location with soft delete and enqueues delete mutation',
        () async {
      final created =
          (await repo.createLocation(ownerId: ownerA, name: 'Temporary Shelf'))
              .valueOrNull!;

      final deactRes =
          await repo.deactivateLocation(ownerId: ownerA, id: created.id);
      expect(deactRes.isSuccess, isTrue);

      final locations = (await repo.getLocations(ownerA)).valueOrNull!;
      expect(locations.any((l) => l.id == created.id), isFalse);

      final queue = await db.syncQueueDao.getPendingBatch();
      expect(queue.any((q) => q.operation == SyncOperation.delete), isTrue);
    });

    test('prevents deactivating default shelf locations', () async {
      final shelf = (await repo.getLocations(ownerA)).valueOrNull!.first;

      final res =
          await repo.deactivateLocation(ownerId: ownerA, id: shelf.id);
      expect(res.isFailure, isTrue);
      expect(res.failureOrNull?.message,
          equals('Default shelf locations cannot be deactivated'));
    });
  });
}

import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/constants/constants.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/data/local/tables/enums.dart';
import 'package:kera_spare_tracker/features/parts/data/repositories/local_brands_repository.dart';

void main() {
  late AppDatabase db;
  late LocalBrandsRepository repo;
  const ownerA = 'owner_111';
  const ownerB = 'owner_222';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = LocalBrandsRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('BrandsRepository - Query & Global Defaults', () {
    test('returns 7 global brands for any owner by default', () async {
      final result = await repo.getBrands(ownerA);
      expect(result.isSuccess, isTrue);

      final brands = result.valueOrNull!;
      expect(brands.length, equals(AppConstants.defaultBrands.length));
      expect(brands.every((b) => b.isDefault), isTrue);
      expect(brands.map((b) => b.name), contains('CAT'));
      expect(brands.map((b) => b.name), contains('Doosan'));
    });

    test('watchBrands emits updates when new custom brand is added', () async {
      final expectation = expectLater(
        repo.watchBrands(ownerA),
        emitsThrough(hasLength(8)),
      );

      await repo.createBrand(ownerId: ownerA, name: 'Toyota');
      await expectation;
    });
  });

  group('BrandsRepository - Create & SyncQueue', () {
    test('creates custom brand and enqueues insert operation in sync_queue',
        () async {
      final createRes = await repo.createBrand(
        ownerId: ownerA,
        name: 'Cummins',
      );

      expect(createRes.isSuccess, isTrue);
      final brand = createRes.valueOrNull!;
      expect(brand.name, equals('Cummins'));
      expect(brand.ownerId, equals(ownerA));
      expect(brand.isDefault, isFalse);

      // Verify sync_queue entry
      final queueItems = await db.syncQueueDao.getPendingBatch();
      expect(queueItems.length, equals(1));
      final item = queueItems.first;
      expect(item.tableTarget, equals('brands'));
      expect(item.recordId, equals(brand.id));
      expect(item.operation, equals(SyncOperation.insert));

      final payload = jsonDecode(item.payload) as Map<String, dynamic>;
      expect(payload['name'], equals('Cummins'));
      expect(payload['owner_id'], equals(ownerA));
    });

    test('rejects duplicate brand name case-insensitively for global brands',
        () async {
      // "cat" vs seeded "CAT"
      final res = await repo.createBrand(ownerId: ownerA, name: 'cat');
      expect(res.isFailure, isTrue);
      expect(res.failureOrNull?.message,
          equals('An item with this name already exists'));
    });

    test('rejects duplicate brand name for existing owner custom brand',
        () async {
      await repo.createBrand(ownerId: ownerA, name: 'Bosch');
      final res = await repo.createBrand(ownerId: ownerA, name: '  bosch  ');
      expect(res.isFailure, isTrue);
      expect(res.failureOrNull?.message,
          equals('An item with this name already exists'));
    });

    test('multi-tenant isolation: different owners can have same custom brand name',
        () async {
      final resA = await repo.createBrand(ownerId: ownerA, name: 'Perkins');
      expect(resA.isSuccess, isTrue);

      final resB = await repo.createBrand(ownerId: ownerB, name: 'Perkins');
      expect(resB.isSuccess, isTrue);
    });

    test('rejects empty or whitespace-only brand name', () async {
      final res = await repo.createBrand(ownerId: ownerA, name: '   ');
      expect(res.isFailure, isTrue);
      expect(res.failureOrNull?.message, equals('Brand name is required'));
    });
  });

  group('BrandsRepository - Update & Deactivate', () {
    test('updates custom brand name and enqueues update in sync_queue',
        () async {
      final created =
          (await repo.createBrand(ownerId: ownerA, name: 'Scania')).valueOrNull!;

      final updateRes = await repo.updateBrand(
        ownerId: ownerA,
        id: created.id,
        name: 'Scania Heavy',
      );

      expect(updateRes.isSuccess, isTrue);
      final updated = updateRes.valueOrNull!;
      expect(updated.name, equals('Scania Heavy'));

      final queue = await db.syncQueueDao.getPendingBatch();
      expect(queue.any((q) => q.operation == SyncOperation.update), isTrue);
    });

    test('prevents updating global default brands', () async {
      final globalBrand = (await repo.getBrands(ownerA)).valueOrNull!.first;
      expect(globalBrand.isDefault, isTrue);

      final res = await repo.updateBrand(
        ownerId: ownerA,
        id: globalBrand.id,
        name: 'Modified Global',
      );

      expect(res.isFailure, isTrue);
      expect(res.failureOrNull?.message,
          equals('Default brands cannot be modified'));
    });

    test('deactivates custom brand with soft delete and sync_queue entry',
        () async {
      final created =
          (await repo.createBrand(ownerId: ownerA, name: 'Volvo')).valueOrNull!;

      final deactRes =
          await repo.deactivateBrand(ownerId: ownerA, id: created.id);
      expect(deactRes.isSuccess, isTrue);

      // Verify soft delete: no longer returned in getBrands
      final brands = (await repo.getBrands(ownerA)).valueOrNull!;
      expect(brands.any((b) => b.id == created.id), isFalse);

      final queue = await db.syncQueueDao.getPendingBatch();
      expect(queue.any((q) => q.operation == SyncOperation.delete), isTrue);
    });

    test('prevents deactivating global default brands', () async {
      final globalBrand = (await repo.getBrands(ownerA)).valueOrNull!.first;

      final res =
          await repo.deactivateBrand(ownerId: ownerA, id: globalBrand.id);
      expect(res.isFailure, isTrue);
      expect(res.failureOrNull?.message,
          equals('Default brands cannot be deactivated'));
    });
  });
}

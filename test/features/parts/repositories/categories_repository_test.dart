import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/data/local/tables/enums.dart';
import 'package:kera_spare_tracker/features/parts/data/repositories/local_categories_repository.dart';

void main() {
  late AppDatabase db;
  late LocalCategoriesRepository repo;
  const ownerA = 'owner_111';
  const ownerB = 'owner_222';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = LocalCategoriesRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoriesRepository - CRUD & SyncQueue', () {
    test('creates new category and writes mutation to sync_queue', () async {
      final createRes = await repo.createCategory(
        ownerId: ownerA,
        name: 'Engine Parts',
      );

      expect(createRes.isSuccess, isTrue);
      final category = createRes.valueOrNull!;
      expect(category.name, equals('Engine Parts'));
      expect(category.ownerId, equals(ownerA));

      // Verify sync_queue entry
      final queue = await db.syncQueueDao.getPendingBatch();
      expect(queue.length, equals(1));
      expect(queue.first.tableTarget, equals('categories'));
      expect(queue.first.operation, equals(SyncOperation.insert));

      final payload = jsonDecode(queue.first.payload) as Map<String, dynamic>;
      expect(payload['name'], equals('Engine Parts'));
    });

    test('validates duplicate category name case-insensitively', () async {
      await repo.createCategory(ownerId: ownerA, name: 'Hydraulic');
      final duplicateRes =
          await repo.createCategory(ownerId: ownerA, name: '  HYDRAULIC  ');

      expect(duplicateRes.isFailure, isTrue);
      expect(duplicateRes.failureOrNull?.message,
          equals('An item with this name already exists'));
    });

    test('multi-tenant isolation: categories of different owners are separated',
        () async {
      await repo.createCategory(ownerId: ownerA, name: 'Transmission');
      await repo.createCategory(ownerId: ownerB, name: 'Transmission');

      final listA = (await repo.getCategories(ownerA)).valueOrNull!;
      final listB = (await repo.getCategories(ownerB)).valueOrNull!;

      expect(listA.length, equals(1));
      expect(listB.length, equals(1));
      expect(listA.first.ownerId, equals(ownerA));
      expect(listB.first.ownerId, equals(ownerB));
    });

    test('updates category name and enqueues update in sync_queue', () async {
      final created =
          (await repo.createCategory(ownerId: ownerA, name: 'Brake')).valueOrNull!;

      final updateRes = await repo.updateCategory(
        ownerId: ownerA,
        id: created.id,
        name: 'Brake Systems',
      );

      expect(updateRes.isSuccess, isTrue);
      final updated = updateRes.valueOrNull!;
      expect(updated.name, equals('Brake Systems'));

      final queue = await db.syncQueueDao.getPendingBatch();
      expect(queue.any((q) => q.operation == SyncOperation.update), isTrue);
    });

    test('deactivates category with soft delete and enqueues delete mutation',
        () async {
      final created =
          (await repo.createCategory(ownerId: ownerA, name: 'Filters')).valueOrNull!;

      final deactRes =
          await repo.deactivateCategory(ownerId: ownerA, id: created.id);
      expect(deactRes.isSuccess, isTrue);

      final categories = (await repo.getCategories(ownerA)).valueOrNull!;
      expect(categories.any((c) => c.id == created.id), isFalse);

      final queue = await db.syncQueueDao.getPendingBatch();
      expect(queue.any((q) => q.operation == SyncOperation.delete), isTrue);
    });
  });
}

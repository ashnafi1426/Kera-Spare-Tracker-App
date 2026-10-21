import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/data/local/tables/enums.dart';
import 'package:kera_spare_tracker/features/parts/data/repositories/local_parts_repository.dart';

void main() {
  late AppDatabase db;
  late LocalPartsRepository repo;
  const ownerA = 'owner_111';
  const ownerB = 'owner_222';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = LocalPartsRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('PartsRepository - Create & All Fields Optional', () {
    test('creates part with only name provided (all other fields null)',
        () async {
      final res = await repo.createPart(
        ownerId: ownerA,
        name: 'Oil Filter',
      );

      expect(res.isSuccess, isTrue);
      final part = res.valueOrNull!;
      expect(part.name, equals('Oil Filter'));
      expect(part.partNumber, isNull);
      expect(part.cachedQuantity, equals(0.0));
      expect(part.purchasePrice, isNull);
      expect(part.sellingPrice, isNull);
      expect(part.photoLocalPath, isNull);
      expect(part.isActive, isTrue);

      // Verify sync_queue entry
      final queue = await db.syncQueueDao.getPendingBatch();
      expect(queue.length, equals(1));
      expect(queue.first.tableTarget, equals('spare_parts'));
      expect(queue.first.operation, equals(SyncOperation.insert));
      expect(queue.first.recordId, equals(part.id));
    });

    test('creates part with all fields and initial stock ledger movement',
        () async {
      final res = await repo.createPart(
        ownerId: ownerA,
        name: 'Hydraulic Cylinder Seal Kit',
        partNumber: '1R-0716',
        photoLocalPath: '/data/app/parts_photos/seal_kit.jpg',
        brandId: 'brand_cat_1',
        categoryId: 'cat_hydraulics_1',
        locationId: 'loc_shelf_2',
        customLocation: 'Bin 4B Top',
        description: 'Heavy duty cylinder seal kit',
        unit: 'set',
        purchasePrice: 1200.0,
        sellingPrice: 1850.0,
        sizeSpecs: 'Standard 45mm Bore',
        notes: 'OEM replacement part',
        lowStockLevel: 3.0,
        initialQuantity: 15.0,
      );

      expect(res.isSuccess, isTrue);
      final part = res.valueOrNull!;
      expect(part.name, equals('Hydraulic Cylinder Seal Kit'));
      expect(part.partNumber, equals('1R-0716'));
      expect(part.unit, equals('set'));
      expect(part.purchasePrice, equals(1200.0));
      expect(part.sellingPrice, equals(1850.0));
      expect(part.unitProfit, equals(650.0));
      expect(part.cachedQuantity, equals(15.0));

      // Verify initial stock movement in ledger table
      final movements = await db.stockDao.getMovementsForPart(part.id, ownerA);
      expect(movements.length, equals(1));
      final movement = movements.first;
      expect(movement.type, equals(MovementType.initial));
      expect(movement.quantityChange, equals(15.0));
      expect(movement.unitCost, equals(1200.0));

      // Verify stock calculation matches ledger sum
      final stockOnHand = await db.stockDao.calculateStockForPart(part.id, ownerA);
      expect(stockOnHand, equals(15.0));

      // Verify sync_queue contains entries for both spare_parts and stock_movements
      final queue = await db.syncQueueDao.getPendingBatch();
      expect(queue.length, equals(2));

      final partQueue = queue.firstWhere((q) => q.tableTarget == 'spare_parts');
      expect(partQueue.operation, equals(SyncOperation.insert));

      final movementQueue =
          queue.firstWhere((q) => q.tableTarget == 'stock_movements');
      expect(movementQueue.operation, equals(SyncOperation.insert));
      final movementPayload =
          jsonDecode(movementQueue.payload) as Map<String, dynamic>;
      expect(movementPayload['quantity_change'], equals(15.0));
    });

    test('validates negative price and negative quantity', () async {
      final negativePriceRes = await repo.createPart(
        ownerId: ownerA,
        name: 'Test Part',
        purchasePrice: -50.0,
      );
      expect(negativePriceRes.isFailure, isTrue);

      final negativeSellingRes = await repo.createPart(
        ownerId: ownerA,
        name: 'Test Part',
        sellingPrice: -100.0,
      );
      expect(negativeSellingRes.isFailure, isTrue);

      final negativeQtyRes = await repo.createPart(
        ownerId: ownerA,
        name: 'Test Part',
        initialQuantity: -5.0,
      );
      expect(negativeQtyRes.isFailure, isTrue);
    });
  });

  group('PartsRepository - Read & Multi-Tenancy', () {
    test('multi-tenant isolation: owner cannot see parts of another owner',
        () async {
      await repo.createPart(ownerId: ownerA, name: 'Part for Owner A');
      await repo.createPart(ownerId: ownerB, name: 'Part for Owner B');

      final partsA = (await repo.getActiveParts(ownerA)).valueOrNull!;
      final partsB = (await repo.getActiveParts(ownerB)).valueOrNull!;

      expect(partsA.length, equals(1));
      expect(partsA.first.name, equals('Part for Owner A'));

      expect(partsB.length, equals(1));
      expect(partsB.first.name, equals('Part for Owner B'));
    });

    test('getPartById returns part for owner and notFound for non-existent',
        () async {
      final created =
          (await repo.createPart(ownerId: ownerA, name: 'Brake Pad')).valueOrNull!;

      final found = await repo.getPartById(ownerId: ownerA, id: created.id);
      expect(found.isSuccess, isTrue);
      expect(found.valueOrNull?.name, equals('Brake Pad'));

      final otherOwnerFound =
          await repo.getPartById(ownerId: ownerB, id: created.id);
      expect(otherOwnerFound.isFailure, isTrue);
    });
  });

  group('PartsRepository - Update & Soft Delete', () {
    test('updates part details and enqueues update in sync_queue', () async {
      final created = (await repo.createPart(
        ownerId: ownerA,
        name: 'Alternator',
        sellingPrice: 4000.0,
      ))
          .valueOrNull!;

      final updateRes = await repo.updatePart(
        ownerId: ownerA,
        id: created.id,
        name: 'Alternator 24V Heavy',
        sellingPrice: 4500.0,
        notes: 'Updated specs',
      );

      expect(updateRes.isSuccess, isTrue);
      final updated = updateRes.valueOrNull!;
      expect(updated.name, equals('Alternator 24V Heavy'));
      expect(updated.sellingPrice, equals(4500.0));
      expect(updated.notes, equals('Updated specs'));

      final queue = await db.syncQueueDao.getPendingBatch();
      expect(queue.any((q) => q.operation == SyncOperation.update), isTrue);
    });

    test('soft deletes part: excluded from active list but row preserved',
        () async {
      final created =
          (await repo.createPart(ownerId: ownerA, name: 'Turbine Wheel'))
              .valueOrNull!;

      final deleteRes =
          await repo.deletePart(ownerId: ownerA, id: created.id);
      expect(deleteRes.isSuccess, isTrue);

      // Verify no longer returned in active parts
      final activeParts = (await repo.getActiveParts(ownerA)).valueOrNull!;
      expect(activeParts.any((p) => p.id == created.id), isFalse);

      // Verify row still exists in database with deleted_at set (preserves foreign keys/sales)
      final rawRow = await (db.select(db.spareParts)
            ..where((t) => t.id.equals(created.id)))
          .getSingle();
      expect(rawRow.deletedAt, isNotNull);

      // Verify sync_queue contains delete operation
      final queue = await db.syncQueueDao.getPendingBatch();
      expect(queue.any((q) => q.operation == SyncOperation.delete), isTrue);
    });
  });
}

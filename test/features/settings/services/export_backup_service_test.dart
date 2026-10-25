// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/data/local/app_database.dart';
import 'package:kera_spare_tracker/data/local/database_provider.dart';
import 'package:kera_spare_tracker/features/settings/data/services/export_backup_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

class MockSharePlatform extends Fake
    with MockPlatformInterfaceMixin
    implements SharePlatform {
  List<XFile> sharedFiles = [];

  @override
  Future<ShareResult> share(ShareParams params) async {
    sharedFiles = params.files ?? [];
    return const ShareResult('success', ShareResultStatus.success);
  }
}

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory tempDir;
  MockPathProviderPlatform(this.tempDir);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir.path;

  @override
  Future<String?> getTemporaryPath() async => tempDir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;
  late ExportBackupService service;
  late MockSharePlatform mockShare;
  late Directory tempDir;
  const ownerId = 'owner-test-123';

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('kera_test_export_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir);

    mockShare = MockSharePlatform();
    SharePlatform.instance = mockShare;

    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        exportBackupServiceProvider.overrideWith(
          (ref) => ExportBackupService(ref, sharePlus: SharePlus.custom(mockShare)),
        ),
      ],
    );
    service = container.read(exportBackupServiceProvider);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('ExportBackupService CSV Generation', () {
    test('exports inventory CSV with accurate headers and part rows', () async {
      // 1. Insert test parts
      await db.into(db.spareParts).insert(
            SparePartsCompanion.insert(
              ownerId: ownerId,
              name: const Value('CAT Oil Filter'),
              partNumber: const Value('1R-0716'),
              purchasePrice: const Value(1200.0),
              sellingPrice: const Value(1800.0),
              cachedQuantity: const Value(15.0),
              unit: const Value('Pcs'),
              description: const Value('High efficiency filter, 10 micron'),
            ),
          );

      await db.into(db.spareParts).insert(
            SparePartsCompanion.insert(
              ownerId: ownerId,
              name: const Value('Doosan "Special" Seal'),
              partNumber: const Value('DS-9900'),
              purchasePrice: const Value(350.0),
              sellingPrice: const Value(600.0),
              cachedQuantity: const Value(40.0),
              unit: const Value('Pcs'),
            ),
          );

      // 2. Export
      final file = await service.exportInventoryCsv(ownerId: ownerId);
      expect(file.existsSync(), isTrue);

      final content = await file.readAsString();
      expect(content, contains('Part Name,Part Number,Brand,Category,Quantity In Stock'));
      expect(content, contains('CAT Oil Filter,1R-0716'));
      expect(content, contains('"High efficiency filter, 10 micron"'));
      expect(content, contains('"Doosan ""Special"" Seal"'));
      expect(mockShare.sharedFiles.length, equals(1));

      // Cleanup
      if (file.existsSync()) await file.delete();
    });

    test('exports sales CSV with headers, line items, and totals', () async {
      // 1. Insert test sale
      const saleId = 'sale-exp-1';
      await db.into(db.sales).insert(
            SalesCompanion.insert(
              id: const Value(saleId),
              ownerId: ownerId,
              receiptNumber: const Value('REC-777'),
              soldAt: Value(DateTime(2026, 10, 21, 10, 30)),
              subtotal: 3600.0,
              discount: const Value(100.0),
              totalAmount: 3500.0,
              totalProfit: 1100.0,
              notes: const Value('Express delivery, paid in cash'),
              paymentMethod: const Value('Cash'),
            ),
          );

      await db.into(db.saleItems).insert(
            SaleItemsCompanion.insert(
              saleId: saleId,
              ownerId: ownerId,
              partId: 'part-filter',
              partNameSnapshot: 'CAT Oil Filter',
              quantity: 2.0,
              unitPrice: 1800.0,
              unitCost: 1200.0,
              lineTotal: 3600.0,
              lineProfit: 1200.0,
            ),
          );

      // 2. Export
      final file = await service.exportSalesCsv(ownerId: ownerId);
      expect(file.existsSync(), isTrue);

      final content = await file.readAsString();
      expect(content, contains('Receipt Number,Date,Time,Customer Notes'));
      expect(content, contains('REC-777'));
      expect(content, contains('2026-10-21'));
      expect(content, contains('"Express delivery, paid in cash"'));
      expect(content, contains('CAT Oil Filter'));
      expect(mockShare.sharedFiles.length, equals(1));

      // Cleanup
      if (file.existsSync()) await file.delete();
    });
  });
}

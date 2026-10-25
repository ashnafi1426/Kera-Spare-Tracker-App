import 'dart:io';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../data/local/app_database.dart';
import '../../../../data/local/database_provider.dart';

/// Provider for ExportBackupService.
final exportBackupServiceProvider = Provider<ExportBackupService>((ref) {
  return ExportBackupService(ref);
});

/// Service managing CSV data exports and SQLite database backups/restores.
class ExportBackupService {
  final Ref _ref;
  final SharePlus _sharePlus;

  ExportBackupService(this._ref, {SharePlus? sharePlus})
      : _sharePlus = sharePlus ?? SharePlus.instance;

  AppDatabase get _db => _ref.read(appDatabaseProvider);

  /// Helper to escape and format CSV cells according to RFC 4180.
  String _formatCsvField(dynamic value) {
    if (value == null) return '';
    final str = value.toString();
    if (str.contains(',') ||
        str.contains('"') ||
        str.contains('\n') ||
        str.contains('\r')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }

  String _toCsvLine(List<dynamic> fields) {
    return fields.map(_formatCsvField).join(',');
  }

  /// Exports the complete inventory for the given owner to a CSV file and triggers the share sheet.
  Future<File> exportInventoryCsv({required String ownerId}) async {
    final parts = await (_db.select(_db.spareParts)
          ..where((t) => t.ownerId.equals(ownerId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();

    final brands = await (_db.select(_db.brands)
          ..where((t) =>
              (t.ownerId.equals(ownerId) | t.ownerId.equals('global')) &
              t.deletedAt.isNull()))
        .get();
    final categories = await (_db.select(_db.categories)
          ..where((t) => t.ownerId.equals(ownerId) & t.deletedAt.isNull()))
        .get();
    final locations = await (_db.select(_db.locations)
          ..where((t) =>
              (t.ownerId.equals(ownerId) | t.ownerId.equals('global')) &
              t.deletedAt.isNull()))
        .get();

    final brandMap = {for (final b in brands) b.id: b.name};
    final categoryMap = {for (final c in categories) c.id: c.name};
    final locationMap = {for (final l in locations) l.id: l.name};

    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln(_toCsvLine([
      'Part Name',
      'Part Number',
      'Brand',
      'Category',
      'Quantity In Stock',
      'Unit',
      'Purchase Price (ETB)',
      'Selling Price (ETB)',
      'Estimated Unit Profit (ETB)',
      'Storage Location',
      'Custom Location',
      'Size / Specs',
      'Description',
      'Notes',
    ]));

    for (final part in parts) {
      final brandName =
          part.brandId != null ? (brandMap[part.brandId] ?? '') : '';
      final categoryName =
          part.categoryId != null ? (categoryMap[part.categoryId] ?? '') : '';
      final locationName =
          part.locationId != null ? (locationMap[part.locationId] ?? '') : '';

      final profit =
          (part.sellingPrice != null && part.purchasePrice != null)
              ? (part.sellingPrice! - part.purchasePrice!)
              : '';

      buffer.writeln(_toCsvLine([
        part.name,
        part.partNumber ?? '',
        brandName,
        categoryName,
        part.cachedQuantity,
        part.unit,
        part.purchasePrice ?? '',
        part.sellingPrice ?? '',
        profit,
        locationName,
        part.customLocation ?? '',
        part.sizeSpecs ?? '',
        part.description ?? '',
        part.notes ?? '',
      ]));
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final exportFile = File(p.join(docsDir.path, 'kera_inventory_$timestamp.csv'));
    await exportFile.writeAsString(buffer.toString());

    // Share via native share sheet
    await _sharePlus.share(
      ShareParams(
        files: [XFile(exportFile.path, mimeType: 'text/csv')],
        subject: 'Kera Spare Tracker - Inventory Export',
        text: 'Exported inventory list (${parts.length} parts)',
      ),
    );

    return exportFile;
  }

  /// Exports all sales and snapshots for the given owner to a CSV file and triggers the share sheet.
  Future<File> exportSalesCsv({required String ownerId}) async {
    final salesList = await (_db.select(_db.sales)
          ..where((t) => t.ownerId.equals(ownerId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.soldAt)]))
        .get();

    final allItems = await (_db.select(_db.saleItems)
          ..where((t) => t.ownerId.equals(ownerId) & t.deletedAt.isNull()))
        .get();

    final itemsBySaleId = <String, List<SaleItem>>{};
    for (final item in allItems) {
      itemsBySaleId.putIfAbsent(item.saleId, () => []).add(item);
    }

    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln(_toCsvLine([
      'Receipt Number',
      'Date',
      'Time',
      'Customer Notes',
      'Payment Method',
      'Items Count',
      'Subtotal (ETB)',
      'Discount (ETB)',
      'Total Amount (ETB)',
      'Estimated Profit (ETB)',
      'Items Breakdown',
    ]));

    for (final s in salesList) {
      final items = itemsBySaleId[s.id] ?? [];
      final itemsBreakdown = items
          .map((i) =>
              '${i.quantity}x ${i.partNameSnapshot} @ ETB ${i.unitPrice} (Line: ETB ${i.lineTotal})')
          .join('; ');

      buffer.writeln(_toCsvLine([
        s.receiptNumber ?? 'N/A',
        DateFormat('yyyy-MM-dd').format(s.soldAt),
        DateFormat('HH:mm').format(s.soldAt),
        s.notes ?? '',
        s.paymentMethod ?? 'Cash',
        items.length,
        s.subtotal,
        s.discount,
        s.totalAmount,
        s.totalProfit,
        itemsBreakdown,
      ]));
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final exportFile = File(p.join(docsDir.path, 'kera_sales_$timestamp.csv'));
    await exportFile.writeAsString(buffer.toString());

    // Share via native share sheet
    await _sharePlus.share(
      ShareParams(
        files: [XFile(exportFile.path, mimeType: 'text/csv')],
        subject: 'Kera Spare Tracker - Sales Export',
        text: 'Exported sales history (${salesList.length} sales)',
      ),
    );

    return exportFile;
  }

  /// Checkpoints SQLite WAL and creates a timestamped copy of the database file.
  Future<File> backupDatabase() async {
    // 1. Flush SQLite WAL to database file
    try {
      await _db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
    } catch (e) {
      debugPrint('wal_checkpoint error (proceeding anyway): $e');
    }

    // 2. Locate active database file
    final docsDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(docsDir.path, 'kera_spare_tracker.sqlite'));

    if (!await dbFile.exists()) {
      throw const FileSystemException(
          'Active database file was not found on device.');
    }

    // 3. Create backup copy
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final backupFile = File(
      p.join(docsDir.path, 'kera_spare_backup_$timestamp.sqlite'),
    );
    await dbFile.copy(backupFile.path);

    // 4. Share backup
    await _sharePlus.share(
      ShareParams(
        files: [XFile(backupFile.path)],
        subject: 'Kera Spare Tracker - Database Backup',
        text: 'Local SQLite database backup taken on $timestamp',
      ),
    );

    return backupFile;
  }

  /// Prompts the user to pick a backup SQLite file and restores it.
  Future<bool> restoreDatabase() async {
    final pickedFiles = await FilePicker.pickFiles(
      type: FileType.any,
    );

    if (pickedFiles.isEmpty) {
      return false;
    }

    final path = pickedFiles.first.path;
    if (path == null) return false;

    final pickedFile = File(path);
    if (!await pickedFile.exists()) return false;

    // Validate size
    final length = await pickedFile.length();
    if (length < 100) {
      throw const FormatException('Selected file is not a valid SQLite database.');
    }

    // 1. Close current database
    await _db.close();

    // 2. Overwrite local database
    final docsDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(docsDir.path, 'kera_spare_tracker.sqlite'));

    // Remove WAL & SHM files if existing
    final walFile = File('${dbFile.path}-wal');
    final shmFile = File('${dbFile.path}-shm');
    if (await walFile.exists()) await walFile.delete();
    if (await shmFile.exists()) await shmFile.delete();

    await pickedFile.copy(dbFile.path);

    // 3. Invalidate database provider to re-open connection
    _ref.invalidate(appDatabaseProvider);

    return true;
  }
}

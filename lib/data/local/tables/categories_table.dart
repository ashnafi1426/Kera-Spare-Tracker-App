import 'package:drift/drift.dart';
import 'base_table.dart';

/// Categories table (e.g. Engine, Hydraulic, Transmission, etc.).
@DataClassName('Category')
class Categories extends Table with SyncedTableMixin {
  TextColumn get name => text()();
}

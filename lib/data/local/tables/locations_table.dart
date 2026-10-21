import 'package:drift/drift.dart';
import 'base_table.dart';

/// Storage locations table (e.g. Shelf 1, Shelf 2, etc.).
@DataClassName('Location')
class Locations extends Table with SyncedTableMixin {
  TextColumn get name => text()();
}

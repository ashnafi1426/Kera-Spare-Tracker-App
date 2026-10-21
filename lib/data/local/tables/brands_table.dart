import 'package:drift/drift.dart';
import 'base_table.dart';

/// Configurable brands table (e.g. CAT, Doosan, Develon, etc.).
@DataClassName('Brand')
class Brands extends Table with SyncedTableMixin {
  TextColumn get name => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
}

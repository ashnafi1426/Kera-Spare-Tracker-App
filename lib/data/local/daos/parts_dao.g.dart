// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parts_dao.dart';

// ignore_for_file: type=lint
mixin _$PartsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SparePartsTable get spareParts => attachedDatabase.spareParts;
  $StockMovementsTable get stockMovements => attachedDatabase.stockMovements;
  PartsDaoManager get managers => PartsDaoManager(this);
}

class PartsDaoManager {
  final _$PartsDaoMixin _db;
  PartsDaoManager(this._db);
  $$SparePartsTableTableManager get spareParts =>
      $$SparePartsTableTableManager(_db.attachedDatabase, _db.spareParts);
  $$StockMovementsTableTableManager get stockMovements =>
      $$StockMovementsTableTableManager(
        _db.attachedDatabase,
        _db.stockMovements,
      );
}

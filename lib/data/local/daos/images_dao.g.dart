// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'images_dao.dart';

// ignore_for_file: type=lint
mixin _$ImagesDaoMixin on DatabaseAccessor<AppDatabase> {
  $InventoryImagesTable get inventoryImages => attachedDatabase.inventoryImages;
  $SparePartsTable get spareParts => attachedDatabase.spareParts;
  ImagesDaoManager get managers => ImagesDaoManager(this);
}

class ImagesDaoManager {
  final _$ImagesDaoMixin _db;
  ImagesDaoManager(this._db);
  $$InventoryImagesTableTableManager get inventoryImages =>
      $$InventoryImagesTableTableManager(
        _db.attachedDatabase,
        _db.inventoryImages,
      );
  $$SparePartsTableTableManager get spareParts =>
      $$SparePartsTableTableManager(_db.attachedDatabase, _db.spareParts);
}

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Inventory image upload state lifecycle.
enum ImageUploadStatus {
  localOnly,
  pendingUpload,
  uploading,
  uploaded,
  failed,
  pendingDeletion,
}

/// Offline-first inventory images table tracking local files, remote URLs, and sync lifecycle.
@TableIndex(name: 'idx_inv_images_owner_part', columns: {#ownerId, #partId})
@TableIndex(name: 'idx_inv_images_part_primary', columns: {#partId, #isPrimary})
@TableIndex(name: 'idx_inv_images_upload_status', columns: {#uploadStatus})
@DataClassName('InventoryImageLocal')
class InventoryImages extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get ownerId => text()();
  TextColumn get partId => text()();
  TextColumn get localFilePath => text()();
  TextColumn get localThumbnailPath => text().nullable()();
  TextColumn get remoteImageId => text().nullable()();
  TextColumn get remoteImageUrl => text().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();
  TextColumn get imageType => text().withDefault(const Constant('inventory'))();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  TextColumn get uploadStatus => text().withDefault(const Constant('pending_upload'))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}


import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/inventory_images_table.dart';
import '../tables/spare_parts_table.dart';

part 'images_dao.g.dart';

@DriftAccessor(tables: [InventoryImages, SpareParts])
class ImagesDao extends DatabaseAccessor<AppDatabase> with _$ImagesDaoMixin {
  ImagesDao(super.db);

  /// Streams active images for a spare part ordered by primary status first.
  Stream<List<InventoryImageLocal>> watchImagesForPart(String ownerId, String partId) {
    return (select(inventoryImages)
          ..where((tbl) =>
              tbl.ownerId.equals(ownerId) &
              tbl.partId.equals(partId) &
              tbl.deletedAt.isNull() &
              tbl.uploadStatus.isNotIn(const ['pending_deletion']))
          ..orderBy([
            (t) => OrderingTerm(expression: t.isPrimary, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// Gets list of active images for a spare part.
  Future<List<InventoryImageLocal>> getImagesForPart(String ownerId, String partId) {
    return (select(inventoryImages)
          ..where((tbl) =>
              tbl.ownerId.equals(ownerId) &
              tbl.partId.equals(partId) &
              tbl.deletedAt.isNull() &
              tbl.uploadStatus.isNotIn(const ['pending_deletion']))
          ..orderBy([
            (t) => OrderingTerm(expression: t.isPrimary, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// Inserts a new image record.
  Future<int> insertImage(InventoryImagesCompanion companion) {
    return into(inventoryImages).insert(companion);
  }

  /// Inserts multiple images in a single transaction.
  Future<void> insertImages(List<InventoryImagesCompanion> companions) async {
    await batch((b) {
      b.insertAll(inventoryImages, companions);
    });
  }

  /// Sets an image as the primary photo for a spare part.
  Future<void> setPrimaryImage({
    required String ownerId,
    required String partId,
    required String imageId,
  }) async {
    await transaction(() async {
      // 1. Unset existing primary
      await (update(inventoryImages)
            ..where((tbl) =>
                tbl.ownerId.equals(ownerId) &
                tbl.partId.equals(partId) &
                tbl.isPrimary.equals(true)))
          .write(const InventoryImagesCompanion(isPrimary: Value(false)));

      // 2. Set target image as primary
      await (update(inventoryImages)
            ..where((tbl) => tbl.id.equals(imageId) & tbl.partId.equals(partId)))
          .write(const InventoryImagesCompanion(isPrimary: Value(true)));

      // 3. Mirror onto spare_parts.photoLocalPath and photoUrl if available
      final target = await (select(inventoryImages)..where((t) => t.id.equals(imageId))).getSingleOrNull();
      if (target != null) {
        await (update(spareParts)..where((p) => p.id.equals(partId))).write(
          SparePartsCompanion(
            photoLocalPath: Value(target.localFilePath),
            photoUrl: target.remoteImageUrl != null ? Value(target.remoteImageUrl) : const Value.absent(),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  /// Marks an image as pending deletion or removes it.
  Future<void> markPendingDeletion(String imageId) async {
    await (update(inventoryImages)..where((tbl) => tbl.id.equals(imageId))).write(
      InventoryImagesCompanion(
        uploadStatus: const Value('pending_deletion'),
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Deletes an image record completely from SQLite.
  Future<int> deleteImagePermanently(String imageId) {
    return (delete(inventoryImages)..where((tbl) => tbl.id.equals(imageId))).go();
  }

  /// Gets all images that are pending upload for the sync engine.
  Future<List<InventoryImageLocal>> getPendingUploads(String ownerId) {
    return (select(inventoryImages)
          ..where((tbl) =>
              tbl.ownerId.equals(ownerId) &
              tbl.uploadStatus.isIn(const ['pending_upload', 'failed']) &
              tbl.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc)]))
        .get();
  }

  /// Updates upload status to 'uploading'.
  Future<void> markUploading(String imageId) {
    return (update(inventoryImages)..where((tbl) => tbl.id.equals(imageId))).write(
      const InventoryImagesCompanion(uploadStatus: Value('uploading')),
    );
  }

  /// Updates upload status to 'uploaded' and stores remote IDs.
  Future<void> markUploaded({
    required String imageId,
    required String remoteImageId,
    required String remoteImageUrl,
    String? thumbnailUrl,
  }) async {
    await (update(inventoryImages)..where((tbl) => tbl.id.equals(imageId))).write(
      InventoryImagesCompanion(
        uploadStatus: const Value('uploaded'),
        remoteImageId: Value(remoteImageId),
        remoteImageUrl: Value(remoteImageUrl),
        thumbnailUrl: Value(thumbnailUrl),
        updatedAt: Value(DateTime.now()),
        errorMessage: const Value(null),
      ),
    );

    // If primary, mirror to spare_parts.photoUrl
    final img = await (select(inventoryImages)..where((t) => t.id.equals(imageId))).getSingleOrNull();
    if (img != null && img.isPrimary) {
      await (update(spareParts)..where((p) => p.id.equals(img.partId))).write(
        SparePartsCompanion(
          photoUrl: Value(remoteImageUrl),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Marks upload as failed with error message and incremented retry count.
  Future<void> markUploadFailed(String imageId, String error) async {
    final current = await (select(inventoryImages)..where((t) => t.id.equals(imageId))).getSingleOrNull();
    final retries = (current?.retryCount ?? 0) + 1;

    await (update(inventoryImages)..where((tbl) => tbl.id.equals(imageId))).write(
      InventoryImagesCompanion(
        uploadStatus: const Value('failed'),
        retryCount: Value(retries),
        errorMessage: Value(error),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Gets all images pending remote deletion.
  Future<List<InventoryImageLocal>> getPendingDeletions(String ownerId) {
    return (select(inventoryImages)
          ..where((tbl) =>
              tbl.ownerId.equals(ownerId) &
              tbl.uploadStatus.equals('pending_deletion') &
              tbl.remoteImageId.isNotNull()))
        .get();
  }
}

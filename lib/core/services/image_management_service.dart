import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/app_database.dart';
import '../../data/local/daos/images_dao.dart';
import '../../data/local/database_provider.dart';
import '../../features/auth/data/repositories/api_auth_repository.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../constants/constants.dart';

final imageManagementServiceProvider = Provider<ImageManagementService>((ref) {
  final imagesDao = ref.watch(imagesDaoProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  Dio dioClient;
  if (authRepo is ApiAuthRepository) {
    dioClient = authRepo.dio;
  } else {
    dioClient = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));
  }
  return ImageManagementService(imagesDao: imagesDao, dio: dioClient);
});

/// Centralized Image Management Service for Kera Spare Tracker.
/// Handles:
/// - Camera & multi-image gallery capture
/// - Native isolate compression and thumbnail generation
/// - Persistent local storage management
/// - Offline-first SQLite queueing and immediate local rendering
/// - Multipart background uploading and fail-safe remote synchronization
class ImageManagementService {
  final ImagesDao _imagesDao;
  final Dio _dio;
  final ImagePicker _picker;
  final Uuid _uuid;

  ImageManagementService({
    required ImagesDao imagesDao,
    required Dio dio,
    ImagePicker? picker,
    Uuid? uuid,
  })  : _imagesDao = imagesDao,
        _dio = dio,
        _picker = picker ?? ImagePicker(),
        _uuid = uuid ?? const Uuid();

  // ===========================================================================
  // 1. OWNER PROFILE PHOTO MANAGEMENT
  // ===========================================================================

  /// Captures or selects an owner profile avatar, crops square, compresses,
  /// saves to persistent app storage, and uploads if connected.
  Future<String?> pickAndStoreProfileAvatar({
    required ImageSource source,
    required String ownerId,
  }) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );
      if (picked == null) return null;

      final rawFile = File(picked.path);
      final size = await rawFile.length();
      if (size > 5 * 1024 * 1024) {
        throw Exception('File size exceeds 5MB limit');
      }

      final docsDir = await getApplicationDocumentsDirectory();
      final profileDir = Directory(p.join(docsDir.path, 'profile_photos', ownerId));
      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }

      final targetPath = p.join(
        profileDir.path,
        'profile_${_uuid.v4()}.jpg',
      );

      final bytes = await rawFile.readAsBytes();
      final compressed = await compute(_cropSquareAndCompress, _CompressParams(
        bytes: bytes,
        maxWidth: 512,
        maxHeight: 512,
        quality: 85,
      ));

      if (compressed != null) {
        await File(targetPath).writeAsBytes(compressed);
      } else {
        await rawFile.copy(targetPath);
      }

      return targetPath;
    } catch (e) {
      debugPrint('[ImageManagementService] Error picking profile avatar: $e');
      rethrow;
    }
  }

  /// Uploads a stored profile avatar to the backend server.
  Future<String?> uploadProfileAvatarToServer({
    required String localPath,
  }) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) return null;

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          file.path,
          filename: p.basename(file.path),
        ),
      });

      final response = await _dio.post('/profile/image', data: formData);
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data['data'];
        if (data is Map && data['photoUrl'] != null) {
          return data['photoUrl'] as String;
        }
      }
      return null;
    } catch (e) {
      debugPrint('[ImageManagementService] Network upload profile avatar failed (will rely on offline cache): $e');
      return null;
    }
  }

  /// Deletes profile photo from the backend server.
  Future<bool> deleteProfileAvatarFromServer() async {
    try {
      final response = await _dio.delete('/profile/image');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ImageManagementService] Delete profile avatar from server failed: $e');
      return false;
    }
  }

  // ===========================================================================
  // 2. INVENTORY SPARE-PARTS MULTI-IMAGE MANAGEMENT
  // ===========================================================================

  /// Picks multiple images from gallery or captures single image from camera.
  /// Compresses each image, creates thumbnails, saves to persistent storage,
  /// and writes to SQLite with 'pending_upload' status.
  Future<List<InventoryImageLocal>> captureOrPickInventoryImages({
    required ImageSource source,
    required String ownerId,
    required String partId,
    bool isPrimaryIfFirst = true,
  }) async {
    final List<XFile> pickedFiles = [];

    if (source == ImageSource.gallery) {
      try {
        final multiple = await _picker.pickMultiImage(
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
        );
        if (multiple.isNotEmpty) {
          pickedFiles.addAll(multiple);
        }
      } catch (_) {
        // Fallback to single pick if multi-picker not supported
        final single = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
        );
        if (single != null) pickedFiles.add(single);
      }
    } else {
      final single = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (single != null) pickedFiles.add(single);
    }

    if (pickedFiles.isEmpty) return [];

    final docsDir = await getApplicationDocumentsDirectory();
    final partsDir = Directory(p.join(docsDir.path, 'parts_photos', ownerId, partId));
    final thumbsDir = Directory(p.join(docsDir.path, 'parts_thumbs', ownerId, partId));

    if (!await partsDir.exists()) await partsDir.create(recursive: true);
    if (!await thumbsDir.exists()) await thumbsDir.create(recursive: true);

    // Check if part already has images
    final existingImages = await _imagesDao.getImagesForPart(ownerId, partId);
    final hasPrimary = existingImages.any((img) => img.isPrimary);

    final List<InventoryImageLocal> results = [];

    for (int i = 0; i < pickedFiles.length; i++) {
      final picked = pickedFiles[i];
      final imageId = _uuid.v4();
      final fullPath = p.join(partsDir.path, '$imageId.jpg');
      final thumbPath = p.join(thumbsDir.path, '${imageId}_thumb.jpg');

      final rawFile = File(picked.path);
      final bytes = await rawFile.readAsBytes();

      // Compress full image
      final fullBytes = await compute(_compressImage, _CompressParams(
        bytes: bytes,
        maxWidth: 1600,
        maxHeight: 1600,
        quality: 85,
      ));

      if (fullBytes != null) {
        await File(fullPath).writeAsBytes(fullBytes);
      } else {
        await rawFile.copy(fullPath);
      }

      // Generate thumbnail
      final thumbBytes = await compute(_compressImage, _CompressParams(
        bytes: bytes,
        maxWidth: 320,
        maxHeight: 320,
        quality: 75,
      ));

      if (thumbBytes != null) {
        await File(thumbPath).writeAsBytes(thumbBytes);
      }

      final isPrimary = isPrimaryIfFirst && !hasPrimary && i == 0 && results.isEmpty;

      final companion = InventoryImagesCompanion(
        id: drift.Value(imageId),
        ownerId: drift.Value(ownerId),
        partId: drift.Value(partId),
        localFilePath: drift.Value(fullPath),
        localThumbnailPath: drift.Value(thumbPath),
        isPrimary: drift.Value(isPrimary),
        uploadStatus: const drift.Value('pending_upload'),
        createdAt: drift.Value(DateTime.now()),
        updatedAt: drift.Value(DateTime.now()),
      );

      await _imagesDao.insertImage(companion);

      final inserted = InventoryImageLocal(
        id: imageId,
        ownerId: ownerId,
        partId: partId,
        localFilePath: fullPath,
        localThumbnailPath: thumbPath,
        remoteImageId: null,
        remoteImageUrl: null,
        thumbnailUrl: null,
        imageType: 'inventory',
        isPrimary: isPrimary,
        uploadStatus: 'pending_upload',
        retryCount: 0,
        errorMessage: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        deletedAt: null,
      );

      results.add(inserted);
    }

    return results;
  }

  /// Sets an image as primary both locally in SQLite and on the server.
  Future<void> setPrimaryImage({
    required String ownerId,
    required String partId,
    required String imageId,
    String? remoteImageId,
  }) async {
    // 1. Update local database immediately
    await _imagesDao.setPrimaryImage(
      ownerId: ownerId,
      partId: partId,
      imageId: imageId,
    );

    // 2. If online and has remote image ID, notify backend
    if (remoteImageId != null && remoteImageId.isNotEmpty) {
      try {
        await _dio.patch('/spare-parts/$partId/images/$remoteImageId/primary');
      } catch (e) {
        debugPrint('[ImageManagementService] Remote primary update delayed: $e');
      }
    }
  }

  /// Deletes an inventory image locally and queues/executes remote deletion.
  Future<void> deleteImage({
    required InventoryImageLocal image,
  }) async {
    // 1. Mark local status as pending deletion
    await _imagesDao.markPendingDeletion(image.id);

    // 2. If it has a remote ID, send remote DELETE request
    if (image.remoteImageId != null && image.remoteImageId!.isNotEmpty) {
      try {
        await _dio.delete('/spare-parts/${image.partId}/images/${image.remoteImageId}');
      } catch (e) {
        debugPrint('[ImageManagementService] Remote delete queued: $e');
      }
    }

    // 3. Clean up local files
    try {
      final file = File(image.localFilePath);
      if (await file.exists()) await file.delete();
      if (image.localThumbnailPath != null) {
        final thumb = File(image.localThumbnailPath!);
        if (await thumb.exists()) await thumb.delete();
      }
    } catch (e) {
      debugPrint('[ImageManagementService] Cleanup local file error: $e');
    }

    // 4. Delete permanently from SQLite
    await _imagesDao.deleteImagePermanently(image.id);
  }

  // ===========================================================================
  // 3. BACKGROUND SYNCHRONIZATION QUEUE
  // ===========================================================================

  /// Synchronizes all pending image uploads for an owner.
  /// Does not block parts or sales sync on failure.
  Future<void> syncPendingImages(String ownerId) async {
    try {
      final pendingList = await _imagesDao.getPendingUploads(ownerId);
      if (pendingList.isEmpty) return;

      for (final imgRecord in pendingList) {
        // Enforce max 5 retries before pausing
        if (imgRecord.retryCount >= 5) continue;

        final file = File(imgRecord.localFilePath);
        if (!await file.exists()) {
          await _imagesDao.markUploadFailed(imgRecord.id, 'Local file not found on device');
          continue;
        }

        await _imagesDao.markUploading(imgRecord.id);

        try {
          final formData = FormData.fromMap({
            'images': await MultipartFile.fromFile(
              file.path,
              filename: p.basename(file.path),
            ),
          });

          final response = await _dio.post(
            '/spare-parts/${imgRecord.partId}/images',
            data: formData,
          );

          if (response.statusCode == 201 && response.data is Map) {
            final dataList = response.data['data'];
            if (dataList is List && dataList.isNotEmpty) {
              final remote = dataList[0];
              await _imagesDao.markUploaded(
                imageId: imgRecord.id,
                remoteImageId: remote['id'] as String,
                remoteImageUrl: remote['imageUrl'] as String,
                thumbnailUrl: remote['thumbnailUrl'] as String?,
              );
              continue;
            }
          }

          await _imagesDao.markUploadFailed(
            imgRecord.id,
            'Upload returned unexpected status ${response.statusCode}',
          );
        } catch (e) {
          debugPrint('[ImageManagementService] Image upload failed for ${imgRecord.id}: $e');
          await _imagesDao.markUploadFailed(imgRecord.id, e.toString());
        }
      }
    } catch (err) {
      debugPrint('[ImageManagementService] syncPendingImages error: $err');
    }
  }
}

// =============================================================================
// COMPRESSION HELPER FUNCTIONS (RUN IN ISOLATE VIA COMPUTE)
// =============================================================================

class _CompressParams {
  final Uint8List bytes;
  final int maxWidth;
  final int maxHeight;
  final int quality;

  const _CompressParams({
    required this.bytes,
    required this.maxWidth,
    required this.maxHeight,
    required this.quality,
  });
}

Uint8List? _compressImage(_CompressParams params) {
  try {
    final image = img.decodeImage(params.bytes);
    if (image == null) return null;

    img.Image resized = image;
    if (image.width > params.maxWidth || image.height > params.maxHeight) {
      resized = img.copyResize(
        image,
        width: image.width >= image.height ? params.maxWidth : null,
        height: image.height > image.width ? params.maxHeight : null,
      );
    }

    return Uint8List.fromList(img.encodeJpg(resized, quality: params.quality));
  } catch (_) {
    return null;
  }
}

Uint8List? _cropSquareAndCompress(_CompressParams params) {
  try {
    final image = img.decodeImage(params.bytes);
    if (image == null) return null;

    final cropSize = image.width < image.height ? image.width : image.height;
    final x = (image.width - cropSize) ~/ 2;
    final y = (image.height - cropSize) ~/ 2;
    final cropped = img.copyCrop(image, x: x, y: y, width: cropSize, height: cropSize);

    final resized = img.copyResize(cropped, width: params.maxWidth, height: params.maxHeight);
    return Uint8List.fromList(img.encodeJpg(resized, quality: params.quality));
  } catch (_) {
    return null;
  }
}


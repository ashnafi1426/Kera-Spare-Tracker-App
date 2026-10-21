import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Result container holding local file paths of processed full image and thumbnail.
class ProcessedPhoto {
  final String fullPath;
  final String? thumbnailPath;

  const ProcessedPhoto({
    required this.fullPath,
    this.thumbnailPath,
  });
}

/// Service handling camera/gallery picking, compression, and local storage.
class ImageService {
  final ImagePicker _picker;
  final Uuid _uuid;

  ImageService({
    ImagePicker? picker,
    Uuid? uuid,
  })  : _picker = picker ?? ImagePicker(),
        _uuid = uuid ?? const Uuid();

  /// Prompts camera or gallery, compresses image to ~1024px max, creates a thumbnail,
  /// and saves both into app documents storage.
  Future<ProcessedPhoto?> captureOrPickPhoto({
    required ImageSource source,
  }) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 95,
      );

      if (pickedFile == null) return null;

      return await processImageFile(File(pickedFile.path));
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Compresses and saves an existing image file into local app storage.
  Future<ProcessedPhoto> processImageFile(File rawFile) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(docsDir.path, 'parts_photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final id = _uuid.v4();
    final fullTarget = p.join(photosDir.path, 'part_$id.jpg');
    final thumbTarget = p.join(photosDir.path, 'part_${id}_thumb.jpg');

    String? savedFullPath;
    String? savedThumbPath;

    try {
      // Compress main image (max 1024x1024, quality 85)
      final compressedFull = await FlutterImageCompress.compressAndGetFile(
        rawFile.absolute.path,
        fullTarget,
        minWidth: 1024,
        minHeight: 1024,
        quality: 85,
        format: CompressFormat.jpeg,
      );

      if (compressedFull != null) {
        savedFullPath = compressedFull.path;
      }
    } catch (e) {
      debugPrint('Compression fallback for full image: $e');
    }

    // Fallback if native compress not supported in environment
    if (savedFullPath == null || !File(savedFullPath).existsSync()) {
      final copied = await rawFile.copy(fullTarget);
      savedFullPath = copied.path;
    }

    try {
      // Create thumbnail (max 200x200, quality 75)
      final compressedThumb = await FlutterImageCompress.compressAndGetFile(
        rawFile.absolute.path,
        thumbTarget,
        minWidth: 200,
        minHeight: 200,
        quality: 75,
        format: CompressFormat.jpeg,
      );

      if (compressedThumb != null) {
        savedThumbPath = compressedThumb.path;
      }
    } catch (e) {
      debugPrint('Compression fallback for thumbnail: $e');
    }

    return ProcessedPhoto(
      fullPath: savedFullPath,
      thumbnailPath: savedThumbPath,
    );
  }
}

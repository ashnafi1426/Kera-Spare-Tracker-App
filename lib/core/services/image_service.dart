import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
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
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
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

    String savedFullPath = fullTarget;
    String? savedThumbPath;

    try {
      final bytes = await rawFile.readAsBytes();
      final decoded = await compute(_decodeAndResizeImage, _ResizeParams(
        bytes: bytes,
        maxWidth: 1024,
        maxHeight: 1024,
        quality: 85,
      ));

      if (decoded != null) {
        await File(fullTarget).writeAsBytes(decoded);
        savedFullPath = fullTarget;
      } else {
        await rawFile.copy(fullTarget);
        savedFullPath = fullTarget;
      }

      final thumbBytes = await compute(_decodeAndResizeImage, _ResizeParams(
        bytes: bytes,
        maxWidth: 200,
        maxHeight: 200,
        quality: 75,
      ));

      if (thumbBytes != null) {
        await File(thumbTarget).writeAsBytes(thumbBytes);
        savedThumbPath = thumbTarget;
      }
    } catch (e) {
      debugPrint('Image compression fallback: $e');
      if (!File(fullTarget).existsSync()) {
        final copied = await rawFile.copy(fullTarget);
        savedFullPath = copied.path;
      }
    }

    return ProcessedPhoto(
      fullPath: savedFullPath,
      thumbnailPath: savedThumbPath,
    );
  }
}

class _ResizeParams {
  final Uint8List bytes;
  final int maxWidth;
  final int maxHeight;
  final int quality;

  const _ResizeParams({
    required this.bytes,
    required this.maxWidth,
    required this.maxHeight,
    required this.quality,
  });
}

Uint8List? _decodeAndResizeImage(_ResizeParams params) {
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

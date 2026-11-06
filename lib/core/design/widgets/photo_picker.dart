import 'dart:io';
import 'package:flutter/material.dart';
import '../../utils/context_extensions.dart';
import '../tokens/kera_colors.dart';
import '../tokens/kera_radii.dart';

/// Image picker square widget with touch target.
class PhotoPicker extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final double size;

  const PhotoPicker({
    super.key,
    this.imagePath,
    required this.onTap,
    this.onRemove,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(KeraRadii.md),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(KeraRadii.md),
              border: Border.all(
                color: hasImage ? KeraColors.orange500 : context.borderColor,
                width: 1.2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage
                ? (imagePath!.startsWith('http')
                    ? Image.network(imagePath!, fit: BoxFit.cover)
                    : Image.file(File(imagePath!), fit: BoxFit.cover))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        color: KeraColors.navy800,
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Photo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (hasImage && onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: KeraColors.navy900,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }
}


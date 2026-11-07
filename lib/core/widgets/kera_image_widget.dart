import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../design/tokens/kera_colors.dart';

/// Helper to convert relative or local paths to fully qualified URLs or valid local paths.
String? resolveImageUrl(String? pathOrUrl, {bool cacheBust = false}) {
  if (pathOrUrl == null || pathOrUrl.trim().isEmpty) return null;
  var clean = pathOrUrl.trim().replaceAll(r'\', '/');

  // 1. If already full http(s) URL
  if (clean.startsWith('http://') || clean.startsWith('https://')) {
    if (cacheBust && !clean.contains('?t=')) {
      final sep = clean.contains('?') ? '&' : '?';
      return '$clean${sep}t=${DateTime.now().millisecondsSinceEpoch}';
    }
    return clean;
  }

  // 2. Check if local device file path (especially on Android where paths start with /data or /storage)
  try {
    final localFile = File(clean);
    if (localFile.existsSync()) {
      return clean;
    }
  } catch (_) {}

  // 3. If server relative URL (e.g. /uploads/profiles/... or /uploads/parts/...)
  if (clean.startsWith('uploads') ||
      clean.startsWith('/uploads') ||
      clean.startsWith('api/v1/uploads') ||
      clean.startsWith('/api/v1/uploads') ||
      (clean.startsWith('/') &&
          !clean.startsWith('/data/') &&
          !clean.startsWith('/storage/'))) {
    if (!clean.startsWith('/')) clean = '/$clean';
    final base = AppConstants.apiBaseUrl.replaceAll('/api/v1', '');
    var full = '$base$clean';
    if (cacheBust && !full.contains('?t=')) {
      final sep = full.contains('?') ? '&' : '?';
      full = '$full${sep}t=${DateTime.now().millisecondsSinceEpoch}';
    }
    return full;
  }

  return clean;
}

/// Robust, theme-aware Avatar widget supporting local file paths, remote URLs,
/// server static paths, cache-busting, and initials placeholder fallback.
class KeraAvatarWidget extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;
  final bool isDark;
  final Color? backgroundColor;
  final Color? textColor;

  const KeraAvatarWidget({
    super.key,
    required this.photoUrl,
    required this.name,
    this.radius = 20,
    this.isDark = false,
    this.backgroundColor,
    this.textColor,
  });

  String _getInitials(String input) {
    final parts = input.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveImageUrl(photoUrl);
    final initials = _getInitials(name);
    final size = radius * 2;
    final defaultBg = isDark ? const Color(0xFF1E3A8A) : const Color(0xFF0C2340);
    const defaultTxt = Colors.white;

    Widget fallback() {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? defaultBg,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: TextStyle(
            color: textColor ?? defaultTxt,
            fontSize: radius * 0.75,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (resolved == null || resolved.isEmpty) {
      return fallback();
    }

    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
    final cacheDim = (!size.isFinite || size <= 0) ? null : (size * dpr).round().clamp(16, 2048);

    // Check if local file
    try {
      final localFile = File(resolved);
      if (localFile.existsSync()) {
        return ClipOval(
          child: Image.file(
            localFile,
            width: size,
            height: size,
            cacheWidth: cacheDim,
            cacheHeight: cacheDim,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => fallback(),
          ),
        );
      }
    } catch (_) {}

    // Check if network URL
    if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
      return ClipOval(
        child: Image.network(
          resolved,
          width: size,
          height: size,
          cacheWidth: cacheDim,
          cacheHeight: cacheDim,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => fallback(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: backgroundColor ?? defaultBg,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(KeraColors.brandOrange),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return fallback();
  }
}

/// Reusable Spare Part Photo Thumbnail & Full View Widget with placeholder.
class KeraPartImage extends StatelessWidget {
  final String? localPath;
  final String? remoteUrl;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;

  const KeraPartImage({
    super.key,
    this.localPath,
    this.remoteUrl,
    this.width = 64,
    this.height = 64,
    this.borderRadius = 10,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    Widget placeholder() {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: KeraColors.navy50,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: KeraColors.border),
        ),
        child: const Icon(
          Icons.settings_suggest_rounded,
          color: KeraColors.navy800,
          size: 24,
        ),
      );
    }

    final cacheW = (width.isFinite && width > 0) ? (width * 2).round().clamp(16, 4096) : null;
    final cacheH = (height.isFinite && height > 0) ? (height * 2).round().clamp(16, 4096) : null;

    // 1. Try local file if available
    if (localPath != null && localPath!.isNotEmpty) {
      try {
        final file = File(localPath!);
        if (file.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.file(
              file,
              width: width,
              height: height,
              cacheWidth: cacheW,
              cacheHeight: cacheH,
              fit: fit,
              errorBuilder: (ctx, err, stack) => placeholder(),
            ),
          );
        }
      } catch (_) {}
    }

    // 2. Try remote URL or resolved path
    final resolved = resolveImageUrl(remoteUrl);
    if (resolved != null && resolved.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          resolved,
          width: width,
          height: height,
          cacheWidth: cacheW,
          cacheHeight: cacheH,
          fit: fit,
          errorBuilder: (ctx, err, stack) => placeholder(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: KeraColors.navy50,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: const Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(KeraColors.brandOrange),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return placeholder();
  }
}

/// Helper dialog to view any photo in full resolution with pinch-to-zoom.
void showFullPhotoViewer(BuildContext context, {required String? photoUrl, required String title}) {
  final resolved = resolveImageUrl(photoUrl);
  if (resolved == null || resolved.isEmpty) return;

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: Colors.black87,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
                maxWidth: double.infinity,
              ),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: resolved.startsWith('http://') || resolved.startsWith('https://')
                    ? Image.network(
                        resolved,
                        fit: BoxFit.contain,
                        loadingBuilder: (c, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(color: Colors.orange),
                            ),
                          );
                        },
                        errorBuilder: (c, e, s) => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Icon(Icons.broken_image_rounded, color: Colors.white70, size: 48),
                          ),
                        ),
                      )
                    : Image.file(File(resolved), fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'ለማሳደግ በሁለት ጣት ይጎትቱ (Pinch to zoom)',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

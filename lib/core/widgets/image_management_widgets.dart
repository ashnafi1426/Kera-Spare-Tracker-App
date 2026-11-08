import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/utils/context_extensions.dart';
import '../../data/local/app_database.dart';
import '../services/image_management_service.dart';
import 'kera_image_widget.dart';

// =============================================================================
// 1. REUSABLE PROFILE IMAGE PICKER WIDGET
// =============================================================================

class ProfileImagePicker extends ConsumerStatefulWidget {
  final String? initialPhotoUrl;
  final String ownerName;
  final double radius;
  final bool isDark;
  final ValueChanged<String?> onPhotoChanged;

  const ProfileImagePicker({
    super.key,
    required this.initialPhotoUrl,
    required this.ownerName,
    required this.onPhotoChanged,
    this.radius = 48,
    this.isDark = false,
  });

  @override
  ConsumerState<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends ConsumerState<ProfileImagePicker> {
  String? _localPreviewPath;
  bool _isLoading = false;

  void _showPickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.isDark ? const Color(0xFF131D31) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('የመገለጫ ፎቶ ቀይር', 'Change Profile Photo'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.photo_camera_rounded, color: Color(0xFF102B4C)),
                ),
                title: Text(context.tr('ካሜራ አንሳ', 'Take Photo')),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFF7ED),
                  child: Icon(Icons.photo_library_rounded, color: Color(0xFFF7941D)),
                ),
                title: Text(context.tr('ከስልክ ማዕከለ-ስዕላት ምረጥ', 'Choose from Gallery')),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              if (_localPreviewPath != null || (widget.initialPhotoUrl != null && widget.initialPhotoUrl!.isNotEmpty))
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFEF2F2),
                    child: Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                  ),
                  title: Text(
                    context.tr('ፎቶ አውጣ', 'Remove Photo'),
                    style: const TextStyle(color: Color(0xFFDC2626)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removePhoto();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() => _isLoading = true);
    try {
      final imageService = ref.read(imageManagementServiceProvider);
      final storedPath = await imageService.pickAndStoreProfileAvatar(
        source: source,
        ownerId: 'owner_profile',
      );

      if (storedPath != null && mounted) {
        setState(() => _localPreviewPath = storedPath);
        widget.onPhotoChanged(storedPath);

        // Upload in background to remote server
        unawaited(imageService.uploadProfileAvatarToServer(localPath: storedPath));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removePhoto() async {
    setState(() {
      _localPreviewPath = null;
    });
    widget.onPhotoChanged(null);
    final imageService = ref.read(imageManagementServiceProvider);
    await imageService.deleteProfileAvatarFromServer();
  }

  @override
  Widget build(BuildContext context) {
    final photoToShow = _localPreviewPath ?? widget.initialPhotoUrl;

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFF7941D),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: photoToShow != null && File(photoToShow).existsSync()
                ? ClipOval(
                    child: Image.file(
                      File(photoToShow),
                      width: widget.radius * 2,
                      height: widget.radius * 2,
                      fit: BoxFit.cover,
                    ),
                  )
                : KeraAvatarWidget(
                    photoUrl: photoToShow,
                    name: widget.ownerName,
                    radius: widget.radius,
                    isDark: widget.isDark,
                  ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black45,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _showPickerBottomSheet,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9E1B), Color(0xFFF7941D)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF7941D).withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 2. INVENTORY MULTI-IMAGE PICKER WIDGET
// =============================================================================

class InventoryImagePickerItem {
  final String id;
  final String? localPath;
  final String? remoteUrl;
  final bool isPrimary;

  const InventoryImagePickerItem({
    required this.id,
    this.localPath,
    this.remoteUrl,
    this.isPrimary = false,
  });

  InventoryImagePickerItem copyWith({bool? isPrimary}) {
    return InventoryImagePickerItem(
      id: id,
      localPath: localPath,
      remoteUrl: remoteUrl,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}

class InventoryImagePickerGrid extends StatelessWidget {
  final List<InventoryImagePickerItem> images;
  final VoidCallback onAddPressed;
  final ValueChanged<int> onRemovePressed;
  final ValueChanged<int> onSetPrimary;
  final bool isDark;

  const InventoryImagePickerGrid({
    super.key,
    required this.images,
    required this.onAddPressed,
    required this.onRemovePressed,
    required this.onSetPrimary,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('የዕቃው ፎቶዎች', 'Part Photos'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF102B4C),
              ),
            ),
            Text(
              '${images.length} ${context.tr('ፎቶዎች', 'photos')}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add photo button
              GestureDetector(
                onTap: onAddPressed,
                child: Container(
                  width: 95,
                  height: 105,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFF7941D).withValues(alpha: 0.6),
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7941D).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_a_photo_rounded,
                          color: Color(0xFFF7941D),
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr('ፎቶ ጨምር', '+ Add'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF7941D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Image items
              ...List.generate(images.length, (index) {
                final item = images[index];
                return Container(
                  width: 95,
                  height: 105,
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      // Thumbnail
                      GestureDetector(
                        onTap: () => onSetPrimary(index),
                        child: Container(
                          width: 95,
                          height: 105,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: item.isPrimary
                                  ? const Color(0xFFF7941D)
                                  : (isDark ? Colors.white24 : Colors.black12),
                              width: item.isPrimary ? 2.5 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: item.localPath != null && File(item.localPath!).existsSync()
                              ? Image.file(
                                  File(item.localPath!),
                                  fit: BoxFit.cover,
                                )
                              : KeraPartImage(
                                  remoteUrl: item.remoteUrl,
                                  width: 95,
                                  height: 105,
                                ),
                        ),
                      ),

                      // Primary badge
                      if (item.isPrimary)
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7941D),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 10, color: Colors.white),
                                const SizedBox(width: 2),
                                Text(
                                  context.tr('ዋና', 'Main'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Remove button
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => onRemovePressed(index),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 3. INVENTORY IMAGE GALLERY CAROUSEL FOR PART DETAILS
// =============================================================================

class InventoryImageGallery extends StatefulWidget {
  final List<InventoryImageLocal> images;
  final String? fallbackPhotoUrl;
  final String? fallbackLocalPath;
  final String partName;
  final Function(InventoryImageLocal)? onSetPrimary;
  final Function(InventoryImageLocal)? onDelete;

  const InventoryImageGallery({
    super.key,
    required this.images,
    this.fallbackPhotoUrl,
    this.fallbackLocalPath,
    required this.partName,
    this.onSetPrimary,
    this.onDelete,
  });

  @override
  State<InventoryImageGallery> createState() => _InventoryImageGalleryState();
}

class _InventoryImageGalleryState extends State<InventoryImageGallery> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      // Single fallback image display
      return SizedBox(
        height: 220,
        width: double.infinity,
        child: KeraPartImage(
          localPath: widget.fallbackLocalPath,
          remoteUrl: widget.fallbackPhotoUrl,
          width: double.infinity,
          height: 220,
          borderRadius: 16,
        ),
      );
    }

    final currentImage = widget.images[_currentIndex.clamp(0, widget.images.length - 1)];

    return Column(
      children: [
        // Main view carousel
        SizedBox(
          height: 230,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                onPageChanged: (idx) => setState(() => _currentIndex = idx),
                itemBuilder: (context, index) {
                  final img = widget.images[index];
                  return GestureDetector(
                    onTap: () {
                      showFullPhotoViewer(
                        context,
                        photoUrl: img.remoteImageUrl ?? img.localFilePath,
                        title: widget.partName,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.black12,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: File(img.localFilePath).existsSync()
                          ? Image.file(
                              File(img.localFilePath),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                          : KeraPartImage(
                              remoteUrl: img.remoteImageUrl,
                              width: double.infinity,
                              height: 230,
                            ),
                    ),
                  );
                },
              ),

              // Primary indicator pill
              if (currentImage.isPrimary)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7941D),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          context.tr('ዋና ፎቶ', 'Primary Image'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Dots indicator
              if (widget.images.length > 1)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.images.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentIndex == i ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentIndex == i
                              ? const Color(0xFFF7941D)
                              : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Thumbnail strip
        if (widget.images.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 54,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                final img = widget.images[index];
                final isSelected = _currentIndex == index;

                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 54,
                    height: 54,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFF7941D) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: File(img.localFilePath).existsSync()
                        ? Image.file(File(img.localFilePath), fit: BoxFit.cover)
                        : KeraPartImage(remoteUrl: img.remoteImageUrl, width: 54, height: 54),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}


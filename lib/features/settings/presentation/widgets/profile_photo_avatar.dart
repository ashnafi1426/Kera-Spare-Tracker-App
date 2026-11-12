import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../../../../core/services/image_service.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/kera_image_widget.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Reusable profile avatar with camera badge and bottom sheet photo picker.
/// Supports both Admin and Owner settings screens with instant reactive updates.
class ProfilePhotoAvatar extends ConsumerStatefulWidget {
  final double radius;
  final bool canEdit;
  final String? fallbackInitials;

  const ProfilePhotoAvatar({
    super.key,
    this.radius = 36,
    this.canEdit = true,
    this.fallbackInitials,
  });

  @override
  ConsumerState<ProfilePhotoAvatar> createState() => _ProfilePhotoAvatarState();
}

class _ProfilePhotoAvatarState extends ConsumerState<ProfilePhotoAvatar> {
  bool _isProcessing = false;

  Future<void> _showPhotoPickerSheet() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('እባክዎ መጀመሪያ ይግቡ', 'Please log in to manage profile photo')),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  ctx.tr('የመገለጫ ፎቶ · Profile Photo', 'Update Profile Photo'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ctx.textPrimaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AdminColors.keraOrange),
                title: Text(
                  ctx.tr('ፎቶ አንሳ', 'Take Photo (Camera)'),
                  style: TextStyle(color: ctx.textPrimaryColor, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AdminColors.keraOrange),
                title: Text(
                  ctx.tr('ከጋለሪ ምረጥ', 'Choose from Gallery'),
                  style: TextStyle(color: ctx.textPrimaryColor, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                  title: Text(
                    ctx.tr('ፎቶ አስወግድ', 'Remove Photo'),
                    style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref.read(authControllerProvider.notifier).updateProfilePhoto(null);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.tr('ፎቶ ተሰርዟል', 'Profile photo removed'))),
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    setState(() => _isProcessing = true);
    try {
      final imageService = ref.read(imageServiceProvider);
      final photoPath = await imageService.pickAndProcessProfilePhoto(
        source: source,
        userId: user.id,
      );

      if (photoPath != null && mounted) {
        final res = await ref.read(authControllerProvider.notifier).updateProfilePhoto(photoPath);
        if (mounted) {
          if (res.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.tr(
                    'የመገለጫ ፎቶ በተሳካ ሁኔታ ተቀይሯል',
                    'Profile photo updated successfully',
                  ),
                ),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.tr(
                    'ፎቶ መጫን አልተሳካም፡ ${res.failureOrNull?.message ?? ""}',
                    'Failed to update photo: ${res.failureOrNull?.message ?? ""}',
                  ),
                ),
                backgroundColor: const Color(0xFFDC2626),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('5 MB')
                  ? context.tr('የፎቶው መጠን ከ 5 MB መብለጥ የለበትም', 'Photo size must not exceed 5 MB')
                  : context.tr('ፎቶ መጫን አልተሳካም', 'Failed to load photo'),
            ),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final photoUrl = user?.photoUrl ?? user?.avatarUrl;
    final name = (widget.fallbackInitials != null && widget.fallbackInitials!.isNotEmpty)
        ? widget.fallbackInitials!
        : (user?.businessName != null && user!.businessName.isNotEmpty)
            ? user.businessName
            : (user?.phoneNumber ?? 'KS');
    final isDark = context.isDark;

    final badgeSize = (widget.radius * 0.77).clamp(20.0, 28.0);
    final badgeIconSize = (widget.radius * 0.42).clamp(11.0, 14.0);

    Widget avatarContent;
    if (_isProcessing) {
      avatarContent = const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AdminColors.keraOrange),
        ),
      );
    } else {
      avatarContent = KeraAvatarWidget(
        photoUrl: photoUrl,
        name: name,
        radius: widget.radius,
        isDark: isDark,
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: widget.canEdit ? _showPhotoPickerSheet : null,
          child: Container(
            width: widget.radius * 2,
            height: widget.radius * 2,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E3A5F) : AdminColors.headerNavy,
              shape: BoxShape.circle,
              border: Border.all(
                color: AdminColors.keraOrange,
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: avatarContent,
          ),
        ),
        if (widget.canEdit)
          Positioned(
            right: -2,
            bottom: -2,
            child: InkWell(
              onTap: _showPhotoPickerSheet,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: AdminColors.keraOrange,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.cardBg,
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x20000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: badgeIconSize,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}


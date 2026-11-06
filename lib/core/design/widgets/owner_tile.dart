import 'package:flutter/material.dart';
import '../../utils/context_extensions.dart';
import '../tokens/kera_colors.dart';
import '../tokens/kera_radii.dart';
import 'status_badge.dart';

/// Admin portal owner list tile.
class OwnerTile extends StatelessWidget {
  final String businessName;
  final String ownerName;
  final String phoneNumber;
  final int partsCount;
  final bool isActive;
  final VoidCallback? onTap;

  const OwnerTile({
    super.key,
    required this.businessName,
    required this.ownerName,
    required this.phoneNumber,
    required this.partsCount,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KeraRadii.md),
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(KeraRadii.md),
          border: Border.all(color: context.borderColor, width: 0.8),
        ),
        child: Row(
          children: [
            // Store Avatar
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: KeraColors.navy100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: KeraColors.navy800,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Business & Owner Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    businessName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$ownerName · $phoneNumber',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Parts count & Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$partsCount parts',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                isActive
                    ? StatusBadge.active(label: 'Active')
                    : StatusBadge.suspended(label: 'Suspended'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


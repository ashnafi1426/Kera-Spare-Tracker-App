import 'package:flutter/material.dart';
import '../../utils/context_extensions.dart';
import '../tokens/kera_colors.dart';

/// Slim top offline notification banner.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: KeraColors.navy100,
        border: Border(
          bottom: BorderSide(color: KeraColors.navy600, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 16, color: KeraColors.navy800),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              context.l10n.offlineBannerNotice,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: KeraColors.navy800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}


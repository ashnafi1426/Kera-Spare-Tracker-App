import 'package:flutter/material.dart';

import '../../utils/context_extensions.dart';
import '../tokens/kera_colors.dart';

/// Shimmer skeleton loader box.
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.isDark ? KeraColors.darkCardElevated : KeraColors.navy100,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}


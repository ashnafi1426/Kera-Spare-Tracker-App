import 'package:flutter/material.dart';
import '../tokens/kera_colors.dart';
import '../tokens/kera_radii.dart';

/// Lightweight shimmering skeleton placeholder widget.
/// Respects reduced motion settings for accessibility.
class KeraSkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const KeraSkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = KeraRadii.defaultRadius,
    this.margin,
  });

  /// Factory for a text line skeleton.
  factory KeraSkeletonLoader.text({
    Key? key,
    double width = double.infinity,
    double height = 16.0,
    EdgeInsetsGeometry? margin,
  }) {
    return KeraSkeletonLoader(
      key: key,
      width: width,
      height: height,
      borderRadius: 4.0,
      margin: margin,
    );
  }

  /// Factory for a product or metric card skeleton.
  factory KeraSkeletonLoader.card({
    Key? key,
    double height = 80.0,
    EdgeInsetsGeometry? margin = const EdgeInsets.only(bottom: 8.0),
  }) {
    return KeraSkeletonLoader(
      key: key,
      width: double.infinity,
      height: height,
      borderRadius: KeraRadii.defaultRadius,
      margin: margin,
    );
  }

  /// Factory for a circle avatar or icon bubble skeleton.
  factory KeraSkeletonLoader.circle({
    Key? key,
    required double size,
    EdgeInsetsGeometry? margin,
  }) {
    return KeraSkeletonLoader(
      key: key,
      width: size,
      height: size,
      borderRadius: size / 2,
      margin: margin,
    );
  }

  /// Helper rendering a vertical list of shimmering card skeletons.
  static Widget list({
    int count = 6,
    double cardHeight = 80.0,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
  }) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: padding,
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 8.0),
      itemBuilder: (_, _) => KeraSkeletonLoader.card(height: cardHeight, margin: EdgeInsets.zero),
    );
  }

  @override
  State<KeraSkeletonLoader> createState() => _KeraSkeletonLoaderState();
}

class _KeraSkeletonLoaderState extends State<KeraSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final disableAnimations = mediaQuery?.disableAnimations ?? false;

    if (disableAnimations) {
      return Container(
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        decoration: BoxDecoration(
          color: KeraColors.surfaceContainer,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: Color.lerp(
              KeraColors.surfaceContainerHigh,
              KeraColors.surfaceCanvas,
              _animation.value,
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: KeraColors.outlineBorder.withAlpha(50),
              width: 1,
            ),
          ),
        );
      },
    );
  }
}


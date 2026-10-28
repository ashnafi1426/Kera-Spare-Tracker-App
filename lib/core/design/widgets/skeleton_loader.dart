import 'package:flutter/material.dart';
import '../tokens/admin_colors.dart';
import '../tokens/admin_spacing.dart';

/// Lightweight shimmering skeleton loader for loading states.
/// Respects reduced motion settings for accessibility.
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AdminSpacing.radiusField,
    this.margin,
  });

  factory SkeletonLoader.text({
    double width = double.infinity,
    double height = 16.0,
    EdgeInsetsGeometry? margin,
  }) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: 4.0,
      margin: margin,
    );
  }

  factory SkeletonLoader.card({
    double height = 90.0,
    EdgeInsetsGeometry? margin = const EdgeInsets.only(bottom: AdminSpacing.md),
  }) {
    return SkeletonLoader(
      width: double.infinity,
      height: height,
      borderRadius: AdminSpacing.radiusCard,
      margin: margin,
    );
  }

  factory SkeletonLoader.circle({
    required double size,
  }) {
    return SkeletonLoader(
      width: size,
      height: size,
      borderRadius: size / 2,
    );
  }

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AdminColors.darkSurfaceRaised : const Color(0xFFE2E8F0);

    if (MediaQuery.of(context).disableAnimations) {
      return Container(
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        decoration: BoxDecoration(
          color: baseColor.withAlpha(120),
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
            color: baseColor.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Convenience list placeholder that builds multiple card skeletons.
class SkeletonListLoader extends StatelessWidget {
  final int count;

  const SkeletonListLoader({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, _) => SkeletonLoader.card(),
    );
  }
}

/// Convenience placeholder for dashboard metric grids.
class SkeletonMetricLoader extends StatelessWidget {
  const SkeletonMetricLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AdminSpacing.md,
      mainAxisSpacing: AdminSpacing.md,
      childAspectRatio: 1.4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(
        4,
        (_) => const SkeletonLoader(
          width: double.infinity,
          height: double.infinity,
          borderRadius: AdminSpacing.radiusCard,
        ),
      ),
    );
  }
}

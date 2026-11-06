import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../utils/context_extensions.dart';

/// Professional branded loading indicator for Kera Spare Tracker.
///
/// Features smooth continuous rotation with branded dual-gradient arcs
/// (Kera Orange and Navy/Teal), dark-theme adaptability, and optional text.
class KeraLoadingIndicator extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Color? primaryColor;
  final Color? secondaryColor;
  final Color? color;
  final String? message;
  final String? label;

  const KeraLoadingIndicator({
    super.key,
    this.size = 36.0,
    this.strokeWidth = 3.2,
    this.primaryColor,
    this.secondaryColor,
    this.color,
    this.message,
    this.label,
  });

  /// Compact spinner suited for buttons and small badges
  const KeraLoadingIndicator.small({
    super.key,
    this.size = 18.0,
    this.strokeWidth = 2.2,
    this.primaryColor,
    this.secondaryColor,
    this.color,
    this.message,
    this.label,
  });

  /// Large spinner suited for full-screen loading states
  const KeraLoadingIndicator.large({
    super.key,
    this.size = 54.0,
    this.strokeWidth = 4.0,
    this.primaryColor,
    this.secondaryColor,
    this.color,
    this.message,
    this.label,
  });

  @override
  State<KeraLoadingIndicator> createState() => _KeraLoadingIndicatorState();
}

class _KeraLoadingIndicatorState extends State<KeraLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = widget.color ?? widget.primaryColor ?? const Color(0xFFF7941D); // Brand Orange
    final secondary = widget.color != null
        ? widget.color!.withValues(alpha: 0.5)
        : widget.secondaryColor ??
            (isDark ? const Color(0xFFE6ECF7) : const Color(0xFF0B2A5B));

    final spinner = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _DualArcSpinnerPainter(
              primaryColor: primary,
              secondaryColor: secondary,
              strokeWidth: widget.strokeWidth,
              progress: _controller.value,
            ),
          ),
        );
      },
    );

    final effectiveMessage = widget.message ?? widget.label;
    if (effectiveMessage == null) {
      return spinner;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        spinner,
        const SizedBox(height: 12),
        Text(
          effectiveMessage,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: context.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _DualArcSpinnerPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final double strokeWidth;
  final double progress;

  _DualArcSpinnerPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.strokeWidth,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final primaryPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final secondaryPaint = Paint()
      ..color = secondaryColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Primary Arc (140 degrees)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2.44, // ~140 deg
      false,
      primaryPaint,
    );

    // Secondary Arc on the opposite side (100 degrees)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14, // 180 deg
      1.74, // ~100 deg
      false,
      secondaryPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DualArcSpinnerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Standalone Full-screen or Container Loading View
class KeraLoadingView extends StatelessWidget {
  final String? message;

  const KeraLoadingView({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: KeraLoadingIndicator(
          size: 44,
          strokeWidth: 3.5,
          message: message ?? 'በመጫን ላይ...',
        ),
      ),
    );
  }
}

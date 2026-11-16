import 'package:flutter/material.dart';
import '../../../../core/design/tokens/admin_colors.dart';

/// Reusable dark navy header for Kera Spare Tracker Admin Console screens.
/// Faithfully reproduces the deep navy banner with rounded bottom corners,
/// title, subtitle, optional search bar, and action buttons.
class AdminHeaderBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? bottomContent;
  final double bottomPadding;

  const AdminHeaderBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.bottomContent,
    this.bottomPadding = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AdminColors.headerNavy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(


  final String? tooltip;

  const AdminHeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.hasBadge = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AdminColors.headerButtonBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            if (hasBadge)
              Positioned(
                top: 9,
                right: 9,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

/// Search input bar matching the admin header design in the mockups.
class AdminHeaderSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final String hintText;
  final bool readOnly;

  const AdminHeaderSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onTap,
    this.hintText = 'ፈልግ · Search owners, phones',
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 14,
        ),
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF5E6D82),
            size: 20,
          ),
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF5E6D82),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

/// Upward sparkline curve painter for the dashboard registered owners metric.
class SparklinePainter extends CustomPainter {
  final Color color;
  const SparklinePainter({this.color = AdminColors.keraOrange});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.85);
    path.lineTo(size.width * 0.22, size.height * 0.65);
    path.lineTo(size.width * 0.40, size.height * 0.75);
    path.lineTo(size.width * 0.60, size.height * 0.40);
    path.lineTo(size.width * 0.78, size.height * 0.48);
    path.lineTo(size.width, size.height * 0.10);

    canvas.drawPath(path, paint);

    // End point dot
    final dotPaint = Paint()..color = color;
    canvas.drawCircle(Offset(size.width, size.height * 0.10), 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


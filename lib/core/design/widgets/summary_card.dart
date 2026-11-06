import 'package:flutter/material.dart';
import '../tokens/kera_colors.dart';
import '../tokens/kera_radii.dart';

/// Deep navy overview card (#0B2A5B) with big tabular figures and sparkline.
class SummaryCard extends StatelessWidget {
  final String title;
  final String mainAmount;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SummaryCard({
    super.key,
    required this.title,
    required this.mainAmount,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KeraRadii.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: KeraColors.navy800,
          borderRadius: BorderRadius.circular(KeraRadii.lg),
          boxShadow: [
            BoxShadow(
              color: KeraColors.navy800.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: KeraColors.border,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 8),
            Text(
              mainAmount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: KeraColors.border,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


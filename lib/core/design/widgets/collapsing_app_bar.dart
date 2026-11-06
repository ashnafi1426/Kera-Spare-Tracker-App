import 'package:flutter/material.dart';
import '../../utils/context_extensions.dart';
import '../tokens/kera_colors.dart';
import '../tokens/kera_typography.dart';

/// Modern collapsing sliver app bar with large title.
class CollapsingAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final double expandedHeight;
  final bool pinned;

  const CollapsingAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.expandedHeight = 110,
    this.pinned = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return SliverAppBar(
      pinned: pinned,
      expandedHeight: expandedHeight,
      backgroundColor: context.cardBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: leading,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 14),
        centerTitle: false,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? KeraColors.textWhite : KeraColors.navy900,
            fontFamily: KeraTypography.fontEthiopic,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}


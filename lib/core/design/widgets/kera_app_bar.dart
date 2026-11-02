import 'package:flutter/material.dart';
import '../tokens/kera_colors.dart';
import '../tokens/kera_radii.dart';
import '../tokens/kera_typography.dart';
import 'kera_status_badge.dart';

/// Top application bar adhering to the Google Stitch Pragmatic Modern-Industrial design.
/// Features solid Navy background (#172B4D) and network sync pill.
class KeraAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final String? titleText;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showSyncPill;
  final bool isSynced;
  final int pendingSyncCount;
  final VoidCallback? onSyncPillTap;
  final PreferredSizeWidget? bottom;

  const KeraAppBar({
    super.key,
    this.title,
    this.titleText,
    this.leading,
    this.actions,
    this.showSyncPill = false,
    this.isSynced = true,
    this.pendingSyncCount = 0,
    this.onSyncPillTap,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    final titleWidget = title ??
        (titleText != null
            ? Text(
                titleText!,
                style: KeraTypography.titleMedium(color: KeraColors.textWhite).copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              )
            : null);

    final actionList = <Widget>[...?actions];

    if (showSyncPill) {
      actionList.insert(
        0,
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: onSyncPillTap,
              borderRadius: KeraRadii.borderMicro,
              child: isSynced && pendingSyncCount == 0
                  ? KeraStatusBadge.synced()
                  : KeraStatusBadge.syncPending(count: pendingSyncCount),
            ),
          ),
        ),
      );
    }

    return AppBar(
      backgroundColor: KeraColors.primaryNavy,
      foregroundColor: KeraColors.textWhite,
      elevation: 0,
      scrolledUnderElevation: 2,
      centerTitle: false,
      leading: leading,
      title: titleWidget,
      actions: actionList,
      bottom: bottom,
      iconTheme: const IconThemeData(color: KeraColors.textWhite, size: 22),
      actionsIconTheme: const IconThemeData(color: KeraColors.textWhite, size: 22),
    );
  }
}


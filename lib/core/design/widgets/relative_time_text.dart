import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../tokens/admin_colors.dart';
import '../tokens/admin_typography.dart';

/// Formats timestamps into readable relative strings (e.g. "Just now", "2h ago", "Never synced").
class RelativeTimeText extends StatelessWidget {
  final DateTime? timestamp;
  final TextStyle? style;
  final String? fallbackText;

  const RelativeTimeText({
    super.key,
    DateTime? timestamp,
    DateTime? dateTime,
    this.style,
    this.fallbackText,
  }) : timestamp = timestamp ?? dateTime;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final text = _format(context, l10n);

    return Text(
      text,
      style: style ?? AdminTypography.captionOf(isDark).copyWith(
        color: AdminColors.textSecondaryOf(isDark),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _format(BuildContext context, AppLocalizations? l10n) {
    if (timestamp == null) {
      return fallbackText ?? l10n?.adminNeverSynced ?? 'Never synced';
    }

    final now = DateTime.now();
    final diff = now.difference(timestamp!);

    if (diff.inSeconds < 60) {
      return l10n?.adminSyncJustNow ?? 'Just now';
    }
    if (diff.inMinutes < 60) {
      return l10n?.adminSyncMinutesAgo(diff.inMinutes.toString()) ?? '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return l10n?.adminSyncHoursAgo(diff.inHours.toString()) ?? '${diff.inHours}h ago';
    }
    if (diff.inDays < 30) {
      return l10n?.adminSyncDaysAgo(diff.inDays.toString()) ?? '${diff.inDays}d ago';
    }
    return l10n?.adminSyncMonthsAgo((diff.inDays ~/ 30).toString()) ?? '${diff.inDays ~/ 30}mo ago';
  }
}

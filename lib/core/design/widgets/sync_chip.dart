import 'package:flutter/material.dart';
import '../../utils/context_extensions.dart';
import 'status_badge.dart';

/// Real-time sync indicator chip (Synced / Syncing / Offline).
class SyncChip extends StatelessWidget {
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final VoidCallback? onTap;

  const SyncChip({
    super.key,
    required this.isOnline,
    this.isSyncing = false,
    this.pendingCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!isOnline) {
      return StatusBadge.offline(
        label: l10n.statusOffline,
      );
    }
    if (isSyncing) {
      return StatusBadge.syncing(
        label: l10n.statusSyncing,
      );
    }
    if (pendingCount > 0) {
      return StatusBadge.pending(
        count: pendingCount,
        defaultLabel: l10n.statusPending,
      );
    }
    return StatusBadge.synced(
      label: l10n.statusSynced,
    );
  }
}


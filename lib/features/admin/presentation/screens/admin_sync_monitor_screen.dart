import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../widgets/admin_header_bar.dart';

/// Screen 6: Admin Sync Monitor matching Sync monitor.png.
class AdminSyncMonitorScreen extends StatefulWidget {
  const AdminSyncMonitorScreen({super.key});

  @override
  State<AdminSyncMonitorScreen> createState() => _AdminSyncMonitorScreenState();
}

class _AdminSyncMonitorScreenState extends State<AdminSyncMonitorScreen> {
  bool _conflictResolved = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Navy Header matching Sync monitor.png
            _buildNavyHeader(context),

            // 2. Body Metrics, Conflicts & Status Feed
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 4 Stat Tiles (Synced owners, Pending, Conflicts, Offline 7d+)
                  _buildStatCards(),
                  const SizedBox(height: 18),

                  // Conflict Resolution Card
                  if (!_conflictResolved) ...[
                    _buildConflictCard(),
                    const SizedBox(height: 18),
                  ],

                  // Owner Sync Status List Card
                  _buildOwnerSyncStatusCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavyHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AdminColors.headerNavy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Back button + Title + Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AdminHeaderIconButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => context.pop(),
                  ),
                  const Text(
                    'Sync monitor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.settings_suggest_rounded,
                        color: AdminColors.headerNavy,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status badges row: Healthy 98%, Updated 2 min ago
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AdminColors.successBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Healthy 98%',
                      style: TextStyle(
                        color: AdminColors.navy,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Updated 2 min ago',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.15,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Synced owners
        _buildSyncTile(
          icon: Icons.refresh_rounded,
          badge: '92%',
          badgeColor: AdminColors.navy,
          value: '118',
          label: 'Synced owners',
        ),

        // Pending
        _buildSyncTile(
          icon: Icons.refresh_rounded,
          badge: 'uploading',
          badgeColor: AdminColors.warning,
          value: '7',
          label: 'Pending',
        ),

        // Conflicts
        _buildSyncTile(
          icon: Icons.notifications_none_rounded,
          badge: 'review',
          badgeColor: AdminColors.danger,
          value: '2',
          label: 'Conflicts',
        ),

        // Offline 7d+
        _buildSyncTile(
          icon: Icons.notifications_none_rounded,
          badge: 'check',
          badgeColor: AdminColors.danger,
          value: '1',
          label: 'Offline 7d+',
        ),
      ],
    );
  }

  Widget _buildSyncTile({
    required IconData icon,
    required String badge,
    required Color badgeColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EBF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AdminColors.warningBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: AdminColors.warning),
              ),
              Text(
                badge,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C2340),
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF5E6D82),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Conflict Resolution Card matching Sync monitor.png
  Widget _buildConflictCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EBF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Conflict · Meseret CAT Parts',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0C2340),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Part CTP-4412 quantity edited on two devices',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF5E6D82),
            ),
          ),
          const SizedBox(height: 16),

          // Side-by-side values: Server: 24 vs Device: 19
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Server', style: TextStyle(fontSize: 12, color: Color(0xFF5E6D82))),
                      SizedBox(height: 4),
                      Text('24', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0C2340))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminColors.warningBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Device', style: TextStyle(fontSize: 12, color: AdminColors.warning)),
                      SizedBox(height: 4),
                      Text('19', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0C2340))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Actions: Keep server / Keep device
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0C2340),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    setState(() => _conflictResolved = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Server value (24) preserved')),
                    );
                  },
                  child: const Text('Keep server', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.keraOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    setState(() => _conflictResolved = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Device value (19) accepted')),
                    );
                  },
                  child: const Text('Keep device', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Owner Status Feed matching Sync monitor.png
  Widget _buildOwnerSyncStatusCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EBF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ባለቤት sync · Owner status',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0C2340),
            ),
          ),
          const SizedBox(height: 14),

          _buildSyncFeedItem(
            name: 'Meseret CAT Parts',
            detail: '14 changes pending · last sync 1h',
            isWarning: true,
          ),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          _buildSyncFeedItem(
            name: 'አበበ ስፔር ፓርትስ',
            detail: 'Synced · last sync 2h',
            isWarning: false,
          ),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          _buildSyncFeedItem(
            name: 'Tsegaye Machinery Parts',
            detail: 'Synced · last sync 5m',
            isWarning: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSyncFeedItem({
    required String name,
    required String detail,
    required bool isWarning,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isWarning ? AdminColors.keraOrange : AdminColors.navy,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C2340),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF5E6D82),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../widgets/admin_header_bar.dart';

/// Screen 7: Admin Notifications & Audit Log matching Notifications and audit.png.
class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  int _selectedFilter = 0; // 0: ሁሉም (All), 1: Sync, 2: Accounts

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Navy Header with Filter Tabs (Notifications and audit.png)
            _buildNavyHeader(context),

            // 2. Notifications & Audit Log Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notifications List Card
                  _buildNotificationsCard(),
                  const SizedBox(height: 18),

                  // Audit Log Card
                  _buildAuditLogCard(),
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
                    'ማሳወቂያ · Notifications',
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
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.settings_suggest_rounded,
                        color: AdminColors.headerNavy,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Segmented Filter Tabs: ሁሉም, Sync, Accounts
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _buildFilterTab(0, 'ሁሉም'),
                    _buildFilterTab(1, 'Sync'),
                    _buildFilterTab(2, 'Accounts'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab(int index, String label) {
    final isSelected = _selectedFilter == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0C2340) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AdminColors.headerTextSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsCard() {
    final notifications = [
      {
        'type': 'sync',
        'title': 'Sync conflict',
        'subtitle': 'Meseret CAT Parts · part CTP-4412 · 1h ago',
        'color': const Color(0xFFEF4444),
      },
      {
        'type': 'accounts',
        'title': 'New owner waiting',
        'subtitle': 'አበበ ስፔር ፓርትስ · 2h ago',
        'color': AdminColors.keraOrange,
      },
      {
        'type': 'sync',
        'title': 'Backup completed',
        'subtitle': 'Today 03:00',
        'color': const Color(0xFF10B981),
      },
      {
        'type': 'accounts',
        'title': 'Owner offline 9 days',
        'subtitle': 'Kera Sany Depot',
        'color': const Color(0xFFEF4444),
      },
      {
        'type': 'accounts',
        'title': 'Owner suspended',
        'subtitle': 'Admin action · yesterday',
        'color': const Color(0xFF0C2340),
      },
    ];

    final filtered = _selectedFilter == 0
        ? notifications
        : _selectedFilter == 1
            ? notifications.where((n) => n['type'] == 'sync').toList()
            : notifications.where((n) => n['type'] == 'accounts').toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EBF2)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < filtered.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: filtered[i]['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          filtered[i]['title'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0C2340),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          filtered[i]['subtitle'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5E6D82),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (i != filtered.length - 1)
              const Divider(height: 14, color: Color(0xFFF1F5F9)),
          ],
        ],
      ),
    );
  }

  Widget _buildAuditLogCard() {
    final auditLogs = [
      {
        'title': 'Admin approved Hana Doosan Center',
        'timestamp': '1 Nov 10:12',
      },
      {
        'title': 'Admin reset password: Tsegaye Machinery',
        'timestamp': '30 Oct 16:40',
      },
      {
        'title': 'Admin added brand: Develon',
        'timestamp': '28 Oct 09:05',
      },
    ];

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
            'የእንቅስቃሴ መዝገብ · Audit log',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0C2340),
            ),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < auditLogs.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0C2340),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auditLogs[i]['title']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0C2340),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          auditLogs[i]['timestamp']!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5E6D82),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (i != auditLogs.length - 1)
              const Divider(height: 14, color: Color(0xFFF1F5F9)),
          ],
        ],
      ),
    );
  }
}


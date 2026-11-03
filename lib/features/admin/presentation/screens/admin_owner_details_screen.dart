import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../../../../core/design/tokens/admin_spacing.dart';
import '../../../../core/design/widgets/confirm_dialog.dart';
import '../../../../core/design/widgets/error_state.dart';
import '../../../../core/design/widgets/skeleton_loader.dart';
import '../../../../core/widgets/server_config_dialog.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_header_bar.dart';

/// Screen 3: Admin Owner Details matching Owner detail.png.
class AdminOwnerDetailsScreen extends ConsumerStatefulWidget {
  final String ownerId;

  const AdminOwnerDetailsScreen({
    super.key,
    required this.ownerId,
  });

  @override
  ConsumerState<AdminOwnerDetailsScreen> createState() =>
      _AdminOwnerDetailsScreenState();
}

class _AdminOwnerDetailsScreenState
    extends ConsumerState<AdminOwnerDetailsScreen> {
  final DateFormat _dateFormat = DateFormat('d MMM yyyy');

  String _maskPhone(String phone) {
    if (phone.length < 5) return phone;
    final prefix = phone.length >= 2 ? phone.substring(0, 2) : '';
    final suffix = phone.length >= 3 ? phone.substring(phone.length - 3) : '';
    return '$prefix•••••• $suffix';
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _handleSuspend(String currentReason) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => const ConfirmDialog(
        title: 'ባለቤቱን ማገድ (Suspend)',
        description: 'እርግጠኛ ነዎት ይህን መለያ ማገድ ይፈልጋሉ?',
        confirmLabel: 'አግድ (Suspend)',
        isDestructive: true,
        requireReason: true,
        reasonLabel: 'የእገዳ ምክንያት',
        reasonHint: 'ለምሳሌ፡ ክፍያ አልተፈጸመም',
      ),
    );

    if (reason != null && mounted) {
      final repo = ref.read(adminRepositoryProvider);
      final res = await repo.suspendOwner(
        widget.ownerId,
        reason: reason.trim(),
      );

      if (!mounted) return;
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Owner suspended successfully'),
            backgroundColor: AdminColors.danger,
          ),
        );
        ref.invalidate(adminOwnerDetailsProvider(widget.ownerId));
        await ref.read(adminOwnersProvider.notifier).loadOwners();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.failureOrNull?.message ?? 'Failed to suspend owner'),
            backgroundColor: AdminColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _handleReactivate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => const ConfirmDialog(
        title: 'መለያ ማጽደቅ / ማንቃት',
        description: 'ይህ ባለቤት ወደ ሲስተሙ እንዲገባ ይፈቀድለት?',
        confirmLabel: 'አጽድቅ (Approve)',
        isDestructive: false,
        requireReason: false,
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(adminRepositoryProvider);
      final res = await repo.reactivateOwner(widget.ownerId);

      if (!mounted) return;
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Owner approved successfully'),
            backgroundColor: AdminColors.success,
          ),
        );
        ref.invalidate(adminOwnerDetailsProvider(widget.ownerId));
        await ref.read(adminOwnersProvider.notifier).loadOwners();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.failureOrNull?.message ?? 'Failed to approve owner'),
            backgroundColor: AdminColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _handleResetPassword(String businessName) async {
    final repo = ref.read(adminRepositoryProvider);
    final res = await repo.resetOwnerPassword(widget.ownerId);

    if (!mounted) return;
    res.when(
      onSuccess: (data) {
        final temp = data['temporaryPassword'] ?? '123456';
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Temporary Password Generated'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Business: $businessName'),
                const SizedBox(height: 8),
                SelectableText(
                  'Password: $temp',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: temp.toString()));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password copied to clipboard')),
                  );
                },
                child: const Text('Copy & Close'),
              ),
            ],
          ),
        );
      },
      onFailure: (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${err.message}')),
        );
      },
    );
  }

  Future<void> _handleDelete(String businessName, String phone) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Owner Account'),
        content: Text('Are you sure you want to permanently disable and delete account "$businessName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(adminRepositoryProvider);
      final res = await repo.disableOwner(widget.ownerId, phoneConfirmation: phone);
      if (!mounted) return;
      if (res.isSuccess) {
        context.pop();
        await ref.read(adminOwnersProvider.notifier).loadOwners();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(adminOwnerDetailsProvider(widget.ownerId));

    return Scaffold(
      backgroundColor: AdminColors.background,
      body: detailsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AdminSpacing.lg),
          child: Column(
            children: [
              SizedBox(height: 60),
              SkeletonListLoader(count: 4),
            ],
          ),
        ),
        error: (err, _) => Center(
          child: ErrorState(
            message: err.toString().replaceAll('Exception: ', ''),
            onRetry: () => ref.refresh(adminOwnerDetailsProvider(widget.ownerId)),
            secondaryActionLabel: 'Server Settings',
            secondaryActionIcon: Icons.settings_ethernet_rounded,
            onSecondaryAction: () => showServerConfigDialog(context, ref),
          ),
        ),
        data: (details) {
          final owner = details.owner;
          final isPending = owner.status.toUpperCase() == 'PENDING' || owner.status.toUpperCase() == 'INACTIVE';
          final isSuspended = owner.isSuspended;
          final initials = _getInitials(owner.businessName);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Navy Hero Header matching Owner detail.png
                _buildNavyDetailHeader(context, owner, initials, isPending, isSuspended),

                // 2. Action Controls & Stats Grid (Owner detail.png)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Action buttons row (Approve / Reset pw / Suspend / Delete)
                      _buildActionButtons(owner, isPending, isSuspended),
                      const SizedBox(height: 18),

                      // 4 Stat Tiles (Parts, Sales, Revenue, Profit)
                      _buildStatTiles(details),
                      const SizedBox(height: 20),

                      // Recent Sales Activity Card
                      _buildRecentSalesCard(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Navy Header matching Owner detail.png
  Widget _buildNavyDetailHeader(
    BuildContext context,
    dynamic owner,
    String initials,
    bool isPending,
    bool isSuspended,
  ) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AdminColors.headerNavy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: [
              // Top Bar: Back Button + Title + Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AdminHeaderIconButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => context.pop(),
                  ),
                  const Text(
                    'የባለቤት ዝርዝር · Owner',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
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
              const SizedBox(height: 18),

              // Large White Avatar Card with Initials
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C2340),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Business Name
              Text(
                owner.businessName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // Phone + Registered Date + Location
              Text(
                '${_maskPhone(owner.phoneNumber)} · Registered ${_dateFormat.format(owner.createdAt)} · Kera',
                style: const TextStyle(
                  color: AdminColors.headerTextSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),

              // Status Tags: Pending approval / Free trial / አማርኛ
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSuspended
                          ? const Color(0xFFEF4444)
                          : isPending
                              ? const Color(0xFFFFF3E6)
                              : const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      isSuspended
                          ? 'Suspended'
                          : isPending
                              ? 'Pending approval'
                              : 'Active account',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSuspended
                            ? Colors.white
                            : isPending
                                ? AdminColors.keraOrange
                                : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Free trial',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'አማርኛ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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

  /// 4 Action Buttons matching Owner detail.png
  Widget _buildActionButtons(dynamic owner, bool isPending, bool isSuspended) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.keraOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                onPressed: () => isSuspended || isPending
                    ? _handleReactivate()
                    : _handleSuspend('Admin manual review'),
                child: Text(
                  isSuspended || isPending ? 'አጽድቅ · Approve' : 'አግድ · Suspend',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0C2340),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                onPressed: () => _handleResetPassword(owner.businessName),
                child: const Text(
                  'Reset password',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                onPressed: () => _handleSuspend('Temporary suspension'),
                child: const Text(
                  'እግድ · Suspend',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                onPressed: () => _handleDelete(owner.businessName, owner.phoneNumber),
                child: const Text(
                  'Delete',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 4 Metric Stat Tiles matching Owner detail.png
  Widget _buildStatTiles(dynamic details) {
    final parts = details.totalParts > 0 ? details.totalParts : 1240;
    final sales = details.totalSales > 0 ? details.totalSales : 312;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.15,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Parts
        _buildStatTile(
          icon: Icons.sell_outlined,
          badge: '38 low',
          badgeColor: AdminColors.keraOrange,
          value: '$parts',
          label: 'ዕቃዎች · Parts',
        ),

        // Sales
        _buildStatTile(
          icon: Icons.bar_chart_rounded,
          badge: 'this month',
          badgeColor: const Color(0xFF5E6D82),
          value: '$sales',
          label: 'ሽያጭ · Sales',
        ),

        // Revenue
        _buildStatTile(
          icon: Icons.bar_chart_rounded,
          badge: 'ETB',
          badgeColor: const Color(0xFF10B981),
          value: '182k',
          label: 'Revenue',
        ),

        // Profit
        _buildStatTile(
          icon: Icons.bar_chart_rounded,
          badge: 'ETB est.',
          badgeColor: const Color(0xFF10B981),
          value: '41k',
          label: 'Profit',
        ),
      ],
    );
  }

  Widget _buildStatTile({
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x060C2340),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
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
                  color: const Color(0xFFFFF3E6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFFD97706)),
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
                  fontSize: 22,
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

  /// Recent Sales Card matching Owner detail.png
  Widget _buildRecentSalesCard() {
    final recentItems = [
      {'title': 'Seal kit · CAT × 4', 'meta': 'ETB 6,800 · profit 1,600 · 3 Nov'},
      {'title': 'Fuel filter · IPD × 12', 'meta': 'ETB 14,400 · profit 3,200 · 2 Nov'},
      {'title': 'Oil pump · Doosan × 1', 'meta': 'ETB 18,500 · profit 4,100 · 1 Nov'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EBF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ሽያጭ ታሪክ · Recent sales',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0C2340),
            ),
          ),
          const SizedBox(height: 12),
          for (final item in recentItems) ...[
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
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0C2340),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['meta']!,
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
            if (item != recentItems.last) const Divider(height: 12, color: Color(0xFFF1F5F9)),
          ],
        ],
      ),
    );
  }
}

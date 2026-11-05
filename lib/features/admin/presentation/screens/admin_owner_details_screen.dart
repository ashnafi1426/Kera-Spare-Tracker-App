import 'dart:io';
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
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/kera_image_widget.dart';
import '../../../../core/widgets/server_config_dialog.dart';
import '../../../../data/local/app_database.dart';
import '../../../../data/local/database_provider.dart';
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
  int _selectedTab = 0; // 0: Overview, 1: Inventory
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _stockFilter = 'ALL'; // ALL, IN_STOCK, LOW_STOCK, OUT_OF_STOCK

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

                // 2. Segmented Navigation Tabs: Overview vs Inventory
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedTab = 0),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0
                                    ? (context.isDark ? const Color(0xFF0F172A) : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                context.tr('አጠቃላይ መረጃ', 'Overview'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedTab == 0
                                      ? context.textPrimaryColor
                                      : context.textSecondaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() => _selectedTab = 1);
                              debugPrint('[Audit] Admin viewed inventory of owner: ${widget.ownerId}');
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1
                                    ? (context.isDark ? const Color(0xFF0F172A) : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 16,
                                    color: _selectedTab == 1
                                        ? AdminColors.keraOrange
                                        : context.textSecondaryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    context.tr('የዕቃዎች ክምችት', 'Inventory'),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedTab == 1
                                          ? context.textPrimaryColor
                                          : context.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Tab Body
                if (_selectedTab == 0)
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
                        _buildRecentSalesCard(details),
                        const SizedBox(height: 32),
                      ],
                    ),
                  )
                else
                  _buildOwnerInventoryTab(owner),
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

              // Large Avatar with photo or Initials (Tappable to view full photo)
              GestureDetector(
                onTap: () {
                  final p = owner.photoUrl ?? owner.thumbnailUrl;
                  if (p != null && p.isNotEmpty) {
                    showFullPhotoViewer(context, photoUrl: p, title: owner.businessName);
                  }
                },
                child: Column(
                  children: [
                    KeraAvatarWidget(
                      photoUrl: owner.photoUrl ?? owner.thumbnailUrl,
                      name: owner.businessName,
                      radius: 36,
                      isDark: false,
                      backgroundColor: Colors.white,
                      textColor: const Color(0xFF0C2340),
                    ),
                    if (owner.photoUrl != null && owner.photoUrl!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        context.tr('ሙሉ ፎቶ ለማየት ይንኩ', 'Tap to view full photo'),
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ],
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
    final parts = details.totalParts;
    final sales = details.totalSales;
    final rev = details.totalRevenue ?? 0.0;
    final prof = details.totalProfit ?? 0.0;

    final revFormatted = rev >= 1000 ? '${(rev / 1000).toStringAsFixed(1)}k' : rev.toStringAsFixed(0);
    final profFormatted = prof >= 1000 ? '${(prof / 1000).toStringAsFixed(1)}k' : prof.toStringAsFixed(0);

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
          badge: context.tr('አክሲዮን', 'Stock'),
          badgeColor: AdminColors.keraOrange,
          value: '$parts',
          label: context.tr('ዕቃዎች · Parts', 'Total Parts'),
        ),

        // Sales
        _buildStatTile(
          icon: Icons.bar_chart_rounded,
          badge: context.tr('ሽያጭ', 'Sales'),
          badgeColor: const Color(0xFF5E6D82),
          value: '$sales',
          label: context.tr('ሽያጭ · Sales', 'Total Sales'),
        ),

        // Revenue
        _buildStatTile(
          icon: Icons.bar_chart_rounded,
          badge: 'ETB',
          badgeColor: const Color(0xFF10B981),
          value: revFormatted,
          label: context.tr('ጠቅላላ ገቢ', 'Revenue'),
        ),

        // Profit
        _buildStatTile(
          icon: Icons.trending_up_rounded,
          badge: 'ETB',
          badgeColor: const Color(0xFF10B981),
          value: profFormatted,
          label: context.tr('ጠቅላላ ትርፍ', 'Profit'),
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

  /// Recent Activity Card showing real audit logs
  Widget _buildRecentSalesCard(dynamic details) {
    final logs = details.auditLogs as List;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('የቅርብ ጊዜ እንቅስቃሴ · Activity', 'Recent Account Activity'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  context.tr('የተመዘገበ እንቅስቃሴ የለም', 'No recent activity recorded'),
                  style: TextStyle(color: context.textSecondaryColor, fontSize: 13),
                ),
              ),
            )
          else
            for (final log in logs.take(5)) ...[
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
                            log.action,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd MMM yyyy, HH:mm').format(log.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (log != logs.take(5).last) Divider(height: 12, color: context.borderColor),
            ],
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(String key, String label) {
    final isSelected = _stockFilter == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: AdminColors.keraOrange,
      labelStyle: TextStyle(color: isSelected ? Colors.white : context.textPrimaryColor),
      onSelected: (_) => setState(() => _stockFilter = key),
    );
  }

  /// Owner's Inventory Tab with Search, Status Filters, Thumbnails & View-only Modal
  Widget _buildOwnerInventoryTab(dynamic owner) {
    final db = ref.watch(appDatabaseProvider);
    final partsStream = db.partsDao.watchActiveParts(widget.ownerId);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // View Only Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.isDark ? const Color(0xFF3B2404) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminColors.keraOrange.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline_rounded, size: 18, color: AdminColors.keraOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr(
                      'የማየት ፍቃድ ብቻ (View Only) · አስተዳዳሪ ዕቃዎችን ማረም ወይም መሰረዝ አይችልም',
                      'View Only (Admin Mode) · You cannot edit or delete this owner\'s parts',
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: context.isDark ? const Color(0xFFFDBA74) : const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Search Field
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              style: TextStyle(fontSize: 13, color: context.textPrimaryColor),
              decoration: InputDecoration(
                hintText: context.tr('ዕቃ በስም ወይም በኦሪጅናል ቁጥር (OEM) ፈልግ...', 'Search part by name or OEM #...'),
                hintStyle: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Stock Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusFilterChip('ALL', context.tr('ሁሉም', 'All')),
                const SizedBox(width: 8),
                _buildStatusFilterChip('IN_STOCK', context.tr('በክምችት አለ', 'In Stock')),
                const SizedBox(width: 8),
                _buildStatusFilterChip('LOW_STOCK', context.tr('አነስተኛ ክምችት', 'Low Stock')),
                const SizedBox(width: 8),
                _buildStatusFilterChip('OUT_OF_STOCK', context.tr('አልቋል', 'Out of Stock')),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Parts Stream List
          StreamBuilder<List<SparePart>>(
            stream: partsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final allParts = snapshot.data ?? [];
              final filtered = allParts.where((p) {
                final partName = p.name ?? '';
                final matchQuery = _searchQuery.isEmpty ||
                    partName.toLowerCase().contains(_searchQuery) ||
                    (p.partNumber != null && p.partNumber!.toLowerCase().contains(_searchQuery));
                if (!matchQuery) return false;

                final qty = p.cachedQuantity ?? 0.0;
                final threshold = p.lowStockLevel ?? 5.0;

                if (_stockFilter == 'IN_STOCK') {
                  return qty > threshold;
                } else if (_stockFilter == 'LOW_STOCK') {
                  return qty > 0 && qty <= threshold;
                } else if (_stockFilter == 'OUT_OF_STOCK') {
                  return qty <= 0;
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: context.textSecondaryColor),
                        const SizedBox(height: 10),
                        Text(
                          context.tr('ምንም መለዋወጫ ዕቃ አልተገኘም', 'No spare parts found'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final part = filtered[i];
                  final qty = part.cachedQuantity ?? 0.0;
                  final threshold = part.lowStockLevel ?? 5.0;
                  final isOut = qty <= 0;
                  final isLow = qty > 0 && qty <= threshold;

                  return Material(
                    color: context.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: context.borderColor),
                    ),
                    child: InkWell(
                      onTap: () => _showPartDetailModal(context, part),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Thumbnail Photo with Placeholder
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: context.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: context.borderColor),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: KeraPartImage(
                                localPath: part.photoLocalPath,
                                remoteUrl: part.photoUrl,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Part Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    part.name ?? context.tr('ያልተሰየመ መለዋወጫ', 'Unnamed Part'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimaryColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${part.partNumber ?? '-'} · ${part.brandId ?? 'OEM'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.textSecondaryColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (part.locationId != null && part.locationId!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '${context.tr('ቦታ', 'Loc')}: ${part.locationId}',
                                      style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Price & Quantity
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${part.sellingPrice?.toStringAsFixed(0) ?? '-'} ETB',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isOut
                                        ? const Color(0xFFFEE2E2)
                                        : (isLow ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isOut
                                        ? context.tr('አልቋል (0)', 'Out (0)')
                                        : '${qty.toStringAsFixed(0)} ${context.tr('ፍሬ', 'pcs')}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isOut
                                          ? const Color(0xFFDC2626)
                                          : (isLow ? const Color(0xFFD97706) : const Color(0xFF16A34A)),
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
                },
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Full-Screen / Modal Part Detail with Zoomable Photo and Stock History
  void _showPartDetailModal(BuildContext context, SparePart part) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // View Only Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      context.tr('የማየት ፍቃድ ብቻ (View Only)', 'View Only Mode'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Zoomable Full Photo
              if ((part.photoUrl != null && part.photoUrl!.isNotEmpty) ||
                  (part.photoLocalPath != null &&
                      part.photoLocalPath!.isNotEmpty &&
                      File(part.photoLocalPath!).existsSync())) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    color: context.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 3.5,
                      child: KeraPartImage(
                        localPath: part.photoLocalPath,
                        remoteUrl: part.photoUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    context.tr('ለማሳደግ በሁለት ጣት ይጎትቱ (Pinch to zoom)', 'Pinch to zoom photo'),
                    style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Part Title and Details
              Text(
                part.name ?? context.tr('ያልተሰየመ መለዋወጫ', 'Unnamed Part'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${context.tr('የኦሪጅናል ቁጥር (OEM)', 'OEM Part #')}: ${part.partNumber ?? '-'}',
                style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
              ),
              const SizedBox(height: 16),

              // Specification Grid
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  children: [
                    _buildModalSpecRow(context.tr('ብራንድ', 'Brand'), part.brandId ?? 'OEM'),
                    _buildModalSpecRow(context.tr('ምድብ', 'Category'), part.categoryId ?? '-'),
                    _buildModalSpecRow(context.tr('የመደርደሪያ ቦታ', 'Location'), part.locationId ?? '-'),
                    _buildModalSpecRow(context.tr('የመሸጫ ዋጋ', 'Selling Price'), '${part.sellingPrice?.toStringAsFixed(0) ?? '-'} ETB'),
                    if (part.purchasePrice != null)
                      _buildModalSpecRow(context.tr('የግዢ ዋጋ', 'Cost Price'), '${part.purchasePrice!.toStringAsFixed(0)} ETB'),
                    _buildModalSpecRow(context.tr('የአሁን ክምችት', 'Current Stock'), '${(part.cachedQuantity ?? 0.0).toStringAsFixed(0)} pcs'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stock Movements History
              Text(
                context.tr('የክምችት ዝውውር ታሪክ · Stock Movement History', 'Stock Movement History'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 10),
              StreamBuilder<List<StockMovement>>(
                stream: ref.watch(appDatabaseProvider).stockDao.watchMovementsForPart(part.id, widget.ownerId),
                builder: (context, mvSnapshot) {
                  final movements = mvSnapshot.data ?? [];
                  if (movements.isEmpty) {
                    return Text(
                      context.tr('ምንም የዝውውር ታሪክ አልተገኘም', 'No stock movement records'),
                      style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                    );
                  }
                  return Column(
                    children: movements.take(5).map((m) {
                      final isPositive = m.quantityChange > 0;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          isPositive ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                          color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                        title: Text(
                          m.type.name.toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.textPrimaryColor),
                        ),
                        subtitle: Text(
                          _dateFormat.format(m.movedAt),
                          style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                        ),
                        trailing: Text(
                          '${isPositive ? '+' : ''}${m.quantityChange.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimaryColor)),
        ],
      ),
    );
  }
}

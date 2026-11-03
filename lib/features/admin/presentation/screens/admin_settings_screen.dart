import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/widgets/server_config_dialog.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_header_bar.dart';

/// Screen 8: Admin Settings & Brands matching Settings & brands.png.
class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  // Brand switches state
  final Map<String, bool> _brandToggles = {
    'CAT': true,
    'Doosan': true,
    'Develon': true,
    'CTP': true,
  };

  void _showAddBrandDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('አዲስ ብራንድ ጨምር (Add Brand)'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Brand name (e.g. Komatsu, Hitachi)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ሰርዝ (Cancel)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.keraOrange,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() => _brandToggles[name] = true);
                ref.read(adminRepositoryProvider).createBrand(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('ጨምር (Add)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeControllerProvider);
    final isAmharic = currentLocale.languageCode == 'am';

    return Scaffold(
      backgroundColor: AdminColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Navy Header (Settings & brands.png)
            _buildNavyHeader(context),

            // 2. Settings Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                children: [
                  // Logo Card: Admin Console · v1.0
                  _buildLogoCard(),
                  const SizedBox(height: 16),

                  // Language Card: አማርኛ (ነባሪ) / English
                  _buildLanguageCard(isAmharic),
                  const SizedBox(height: 16),

                  // Brands Management Card with + ጨምር button
                  _buildBrandsCard(),
                  const SizedBox(height: 16),

                  // Administration Modules (Subscription plans, Backup, Sync, Server)
                  _buildAdminModulesCard(context),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
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
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ቅንብሮች · Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Brands, language, system',
                      style: TextStyle(
                        color: AdminColors.headerTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              AdminHeaderIconButton(
                icon: Icons.notifications_outlined,
                hasBadge: true,
                onTap: () => context.push('/admin/notifications'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EBF2)),
      ),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.settings_suggest_rounded,
                size: 64,
                color: Color(0xFF0C2340),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Admin Console · v1.0',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5E6D82),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(bool isAmharic) {
    return Container(
      width: double.infinity,
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
            'ቋንቋ · Language',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0C2340),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => ref.read(localeControllerProvider.notifier).setLocale(const Locale('am')),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isAmharic ? const Color(0xFF0C2340) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'አማርኛ (ነባሪ)',
                        style: TextStyle(
                          color: isAmharic ? Colors.white : const Color(0xFF5E6D82),
                          fontWeight: isAmharic ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => ref.read(localeControllerProvider.notifier).setLocale(const Locale('en')),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !isAmharic ? const Color(0xFF0C2340) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'English',
                        style: TextStyle(
                          color: !isAmharic ? Colors.white : const Color(0xFF5E6D82),
                          fontWeight: !isAmharic ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandsCard() {
    final brands = [
      {'name': 'CAT', 'sub': 'Caterpillar'},
      {'name': 'Doosan', 'sub': 'Doosan'},
      {'name': 'Develon', 'sub': 'Develon'},
      {'name': 'CTP', 'sub': 'CTP'},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EBF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ብራንዶች · Brands',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C2340),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.keraOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: _showAddBrandDialog,
                child: const Text(
                  '+ ጨምር',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final b in brands) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b['name']!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0C2340),
                        ),
                      ),
                      Text(
                        b['sub']!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5E6D82),
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _brandToggles[b['name']] ?? true,
                    activeThumbColor: const Color(0xFF0C2340),
                    onChanged: (val) {
                      setState(() => _brandToggles[b['name']!] = val);
                    },
                  ),
                ],
              ),
            ),
            if (b != brands.last) const Divider(height: 12, color: Color(0xFFF1F5F9)),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminModulesCard(BuildContext context) {
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
            'ተጨማሪ ሞጁሎች · Administration',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0C2340),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.card_membership_rounded, color: AdminColors.keraOrange),
            title: const Text('እቅዶች · Subscription plans', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            onTap: () => context.push('/admin/plans'),
          ),
          const Divider(height: 12, color: Color(0xFFF1F5F9)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.cloud_sync_rounded, color: Color(0xFF10B981)),
            title: const Text('ምትኬ · Backup & recovery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            onTap: () => context.push('/admin/backup'),
          ),
          const Divider(height: 12, color: Color(0xFFF1F5F9)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.sync_problem_rounded, color: Color(0xFF3B82F6)),
            title: const Text('Sync monitor', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            onTap: () => context.push('/admin/sync'),
          ),
          const Divider(height: 12, color: Color(0xFFF1F5F9)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.settings_ethernet_rounded, color: Color(0xFF0C2340)),
            title: const Text('ሰርቨር ማስተካከያ · Server Settings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            onTap: () => showServerConfigDialog(context, ref),
          ),
        ],
      ),
    );
  }
}

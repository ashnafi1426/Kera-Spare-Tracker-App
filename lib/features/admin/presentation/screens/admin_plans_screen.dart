import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/admin_colors.dart';
import '../widgets/admin_header_bar.dart';

/// Screen 9: Admin Subscription Plans matching Subscription plans.png.
class AdminPlansScreen extends StatelessWidget {
  const AdminPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Navy Header (Subscription plans.png)
            _buildNavyHeader(context),

            // 2. Plan Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
              child: Column(
                children: [
                  // Free Trial Card (Active)
                  _buildPlanCard(
                    title: 'Free trial',
                    badge: 'Active',
                    badgeBg: AdminColors.successBg,
                    badgeColor: AdminColors.navy,
                    price: '[PRICE]',
                    featureTitle: 'Inventory and sales',
                    featureSubtitle: 'Offline-first with sync',
                    ownerCount: '128 owners on this plan',
                    isHighlighted: true,
                  ),
                  const SizedBox(height: 16),

                  // Standard Card (Coming Soon)
                  _buildPlanCard(
                    title: 'Standard',
                    badge: 'Coming soon',
                    badgeBg: const Color(0xFFEFF6FF),
                    badgeColor: const Color(0xFF1E3A8A),
                    price: '[PRICE]',
                    featureTitle: 'Reports and export',
                    featureSubtitle: 'Sales and profit summaries',
                    showEditButton: true,
                  ),
                  const SizedBox(height: 16),

                  // Pro Card (Coming Soon)
                  _buildPlanCard(
                    title: 'Pro',
                    badge: 'Coming soon',
                    badgeBg: const Color(0xFFEFF6FF),
                    badgeColor: const Color(0xFF1E3A8A),
                    price: '[PRICE]',
                    featureTitle: 'Multiple staff and payments',
                    featureSubtitle: 'Payment provider [TO BE CHOSEN]',
                    showEditButton: true,
                  ),
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
              AdminHeaderIconButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => context.pop(),
              ),
              const Text(
                'እቅዶች · Subscription plans',
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
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String badge,
    required Color badgeBg,
    required Color badgeColor,
    required String price,
    required String featureTitle,
    required String featureSubtitle,
    String? ownerCount,
    bool isHighlighted = false,
    bool showEditButton = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHighlighted ? AdminColors.keraOrange : const Color(0xFFE5EBF2),
          width: isHighlighted ? 2.0 : 1.0,
        ),
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
        children: [
          // Header Row: Title & Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C2340),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Price
          Text(
            price,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0C2340),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),

          // Feature Row with Bullet
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 5),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isHighlighted ? AdminColors.navy : const Color(0xFF5E6D82),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      featureTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0C2340),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      featureSubtitle,
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

          if (ownerCount != null) ...[
            const SizedBox(height: 16),
            Text(
              ownerCount,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF5E6D82),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          if (showEditButton) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0C2340),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {},
                child: const Text(
                  'Edit plan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


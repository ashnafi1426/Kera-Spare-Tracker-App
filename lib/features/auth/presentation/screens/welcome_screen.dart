import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/widgets/primary_button.dart';
import '../../../../core/design/widgets/secondary_button.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/kera_logo_widget.dart';
import '../../../../core/widgets/language_selector_widget.dart';
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Bar: Brand Signature + Language Switcher
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const KeraLogoWidget(size: 32, borderRadius: 8),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        Text(
                          l10n.keraHubLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const LanguageSegmentedSwitch(),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1),

            // 2. Scrollable Value Proposition Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Headline Banner Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? KeraColors.navy900 : KeraColors.navy50,
                        borderRadius: BorderRadius.circular(KeraRadii.lg),
                        border: Border.all(
                          color: isDark ? KeraColors.navy600 : KeraColors.navy100,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: KeraColors.orange100,
                              borderRadius: KeraRadii.borderPill,
                              border: Border.all(color: KeraColors.orange600.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.offline_pin_rounded,
                                  size: 14,
                                  color: KeraColors.orange700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.offlineBadge,
                                  style: const TextStyle(
                                    color: KeraColors.orange700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            l10n.welcomeHeadline,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : KeraColors.navy900,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.welcomeSubtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? KeraColors.navy100 : KeraColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: KeraSpacing.lg),

                    // 3 Mobile Feature Tiles
                    _buildFeatureCard(
                      context: context,
                      icon: Icons.point_of_sale_rounded,
                      title: l10n.featurePosTitle,
                      description: l10n.featurePosDesc,
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      context: context,
                      icon: Icons.shelves,
                      title: l10n.featureInventoryTitle,
                      description: l10n.featureInventoryDesc,
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      context: context,
                      icon: Icons.cloud_off_rounded,
                      title: l10n.featureOfflineTitle,
                      description: l10n.featureOfflineDesc,
                    ),

                    const SizedBox(height: KeraSpacing.xl),

                    // Trust & Metrics Banner
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(KeraRadii.md),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetric(context, '3,500+', l10n.navParts),
                          Container(width: 1, height: 28, color: context.borderColor),
                          _buildMetric(context, '0.2s', l10n.search),
                          Container(width: 1, height: 28, color: context.borderColor),
                          _buildMetric(context, 'ETB', l10n.systemReady),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Fixed Bottom Action Container
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              decoration: BoxDecoration(
                color: context.cardBg,
                border: Border(top: BorderSide(color: context.borderColor)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrimaryButton(
                    label: l10n.loginToAccount,
                    icon: Icons.login_rounded,
                    onPressed: () => context.go('/login'),
                  ),
                  const SizedBox(height: 10),
                  SecondaryButton(
                    label: l10n.createNewAccount,
                    icon: Icons.store_rounded,
                    onPressed: () => context.push('/register'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kera Auto Spare Tracker · v${AppConstants.appVersion}',
                    style: TextStyle(
                      color: context.textSecondaryColor.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(KeraRadii.md),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? KeraColors.navy800 : KeraColors.navy50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? KeraColors.navy600 : KeraColors.navy100,
              ),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isDark ? KeraColors.orange500 : KeraColors.navy800,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.textSecondaryColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(BuildContext context, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: context.isDark ? KeraColors.orange500 : KeraColors.navy800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: context.textSecondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

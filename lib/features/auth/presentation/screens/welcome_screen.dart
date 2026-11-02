import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/design/design.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/language_selector_widget.dart';

/// Onboarding Welcome Screen strictly matching Google Stitch Screen `3ad7b1f3c1e34365ab1372a194619ca1`.
/// Showcases core value propositions: Fast POS, Shelf Locator, and 100% Offline-First reliability.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: KeraColors.surfaceCanvas,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: Container(
          color: KeraColors.primaryNavy,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded, color: KeraColors.textWhite, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'ኬራ ስፔር / Kera Spare',
                        style: KeraTypography.titleMedium(color: KeraColors.textWhite),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: KeraRadii.borderPill,
                      border: Border.all(color: Colors.white.withAlpha(50), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: KeraColors.utilityTeal,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ስርዓት ዝግጁ / Ready',
                          style: KeraTypography.labelSmall(color: KeraColors.textWhite),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Language Switcher Row
                    const Align(
                      alignment: Alignment.centerRight,
                      child: LanguageSegmentedSwitch(),
                    ),
                    const SizedBox(height: 12),

                    // Hero Feature Card
                    KeraCard(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Graphic Assembly Container
                          Container(
                            width: double.infinity,
                            height: 140,
                            decoration: BoxDecoration(
                              color: KeraColors.surfaceMuted,
                              borderRadius: KeraRadii.borderCard,
                              border: Border.all(color: KeraColors.outlineBorder),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.precision_manufacturing_rounded,
                                  size: 64,
                                  color: KeraColors.actionBlue,
                                ),
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: KeraColors.surfacePure,
                                      borderRadius: KeraRadii.borderMicro,
                                      border: Border.all(color: KeraColors.outlineBorder),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.qr_code_scanner_rounded, size: 14, color: KeraColors.actionBlue),
                                        const SizedBox(width: 4),
                                        Text('OEM #48510-09L', style: KeraTypography.labelSmall(color: KeraColors.primaryNavy)),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: KeraColors.surfacePure,
                                      borderRadius: KeraRadii.borderMicro,
                                      border: Border.all(color: KeraColors.outlineBorder),
                                    ),
                                    child: Text(
                                      'መደርደሪያ B-04',
                                      style: KeraTypography.labelSmall(color: KeraColors.textPrimary).copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: KeraSpacing.md),

                          // Inspiring Headline
                          Text(
                            'እንኳን ወደ ኬራ መለዋወጫ መከታተያ በደህና መጡ!',
                            textAlign: TextAlign.center,
                            style: KeraTypography.headlineSmall(color: KeraColors.primaryNavy).copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Welcome to Kera Spare Tracker',
                            textAlign: TextAlign.center,
                            style: KeraTypography.bodyMedium(color: KeraColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: KeraSpacing.md),

                    // 3 Core Value Propositions
                    _buildFeaturePill(
                      icon: Icons.point_of_sale_rounded,
                      title: 'ፈጣን ሽያጭ መመዝገቢያ',
                      subtitle: 'Fast POS • ለጅምላና ለችርቻሮ የተዘጋጀ',
                      tag: 'ሽያጭ',
                    ),
                    const SizedBox(height: 8),

                    _buildFeaturePill(
                      icon: Icons.inventory_2_rounded,
                      title: 'የዕቃዎች መደርደሪያ ቁጥጥር',
                      subtitle: 'Shelf Locator • ክፍል፣ መደርደሪያና ቁጥር',
                      tag: 'ክምችት',
                    ),
                    const SizedBox(height: 8),

                    _buildFeaturePill(
                      icon: Icons.cloud_off_rounded,
                      title: 'ያለ ኢንተርኔት ይሰራል',
                      subtitle: 'Works Offline • ኔትወርክ ሲቋረጥም ያለማቋረጥ ይሽጡ',
                      tag: '100% Offline',
                      tagColor: KeraColors.utilityTeal,
                      tagBg: KeraColors.utilityTealTint,
                    ),
                    const SizedBox(height: KeraSpacing.lg),

                    // Quick Metrics Social Proof
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: KeraColors.outlineBorder),
                          bottom: BorderSide(color: KeraColors.outlineBorder),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildProofItem('3,500+', 'መለዋወጫዎች'),
                          Container(width: 1, height: 24, color: KeraColors.outlineBorder),
                          _buildProofItem('0.3 ሰከንድ', 'ፍለጋ ፍጥነት'),
                          Container(width: 1, height: 24, color: KeraColors.outlineBorder),
                          _buildProofItem('ETB', 'ትክክለኛ ሂሳብ'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Fixed Bottom Action Canvas
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: KeraColors.surfacePure,
                border: Border(top: BorderSide(color: KeraColors.outlineBorder)),
                boxShadow: [KeraColors.shadowLevel1],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KeraButton.primary(
                    label: '${l10n.login} (Login)',
                    icon: Icons.login_rounded,
                    onPressed: () => context.go('/login'),
                  ),
                  const SizedBox(height: KeraSpacing.sm),
                  KeraButton.outlined(
                    label: '${l10n.register} (Create Business Account)',
                    icon: Icons.store_rounded,
                    onPressed: () => context.push('/register'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ኬራ የንግድ ማዕከል፣ አዲስ አበባ • Kera Auto Spare v${AppConstants.appVersion}',
                    style: KeraTypography.bodySmall(color: KeraColors.textMuted),
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

  Widget _buildFeaturePill({
    required IconData icon,
    required String title,
    required String subtitle,
    required String tag,
    Color tagColor = KeraColors.textSecondary,
    Color tagBg = KeraColors.surfaceMuted,
  }) {
    return KeraCard(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: KeraColors.actionBlueTint,
              borderRadius: KeraRadii.borderMicro,
            ),
            child: Icon(icon, color: KeraColors.actionBlue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: KeraTypography.titleSmall(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tagBg,
                        borderRadius: KeraRadii.borderMicro,
                      ),
                      child: Text(
                        tag,
                        style: KeraTypography.labelSmall(color: tagColor).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: KeraTypography.bodySmall(color: KeraColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: KeraTypography.titleMedium(color: KeraColors.primaryNavy)),
        const SizedBox(height: 2),
        Text(label, style: KeraTypography.bodySmall(color: KeraColors.textSecondary)),
      ],
    );
  }
}

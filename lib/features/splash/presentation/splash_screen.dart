import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/design/design.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/kera_logo_widget.dart';
import '../../../../core/widgets/language_selector_widget.dart';

/// Industrial, high-performance splash screen for Kera Spare Tracker
/// strictly matching Google Stitch Screen `4ee69d9cd07b4890a338fd75a5d1ad37`.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[STARTUP] SplashScreen first frame rendered');
    });

    return Scaffold(
      backgroundColor: KeraColors.primaryNavy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Top System Ambient Header (Kera Hub & Offline Ready + Language)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: KeraColors.primaryNavyDark.withAlpha(160),
                        borderRadius: KeraRadii.borderPill,
                        border: Border.all(
                          color: KeraColors.outlineVariant.withAlpha(60),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: KeraColors.utilityTeal,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              context.tr('አዲስ አበባ • ኬራ', 'Addis Ababa • Kera Hub'),
                              overflow: TextOverflow.ellipsis,
                              style: KeraTypography.labelSmall(color: KeraColors.textWhite).copyWith(
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const LanguageSegmentedSwitch(),
                ],
              ),

              const Spacer(flex: 2),

              // 2. Central Hero & Branding Cluster
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const KeraLogoWidget(size: 88, borderRadius: 20),
                  const SizedBox(height: KeraSpacing.lg),

                  // Bilingual Brand Identity Titles
                  Text(
                    context.tr('ኬራ ስፔር ትራከር', 'Kera Spare Tracker'),
                    textAlign: TextAlign.center,
                    style: KeraTypography.headlineLarge(color: KeraColors.textWhite).copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Exact Tagline: Track - Manage - Grow
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: KeraColors.primaryNavyDark.withAlpha(160),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: KeraColors.keraOrange.withAlpha(100)),
                    ),
                    child: Text(
                      context.tr('ተከታተል • አስተዳድር • አሳድግ', 'Track • Manage • Grow'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: KeraColors.keraOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 3),

              // 3. Bottom Technical Diagnostics & Loader Module
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(KeraColors.actionBlue),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.splashLoading,
                        style: KeraTypography.labelSmall(color: KeraColors.textWhite).copyWith(
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: KeraSpacing.lg),

                  // Bento-style Metadata Strip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: KeraColors.primaryNavyDark.withAlpha(180),
                      borderRadius: KeraRadii.borderCard,
                      border: Border.all(
                        color: KeraColors.outlineVariant.withAlpha(50),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Server Connectivity Ping
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: KeraColors.utilityTeal,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Addis Ababa Server • Live',
                                  overflow: TextOverflow.ellipsis,
                                  style: KeraTypography.labelSmall(color: KeraColors.textWhite),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Version Marker
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.offline_bolt_rounded,
                              size: 14,
                              color: KeraColors.utilityTeal,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'v${AppConstants.appVersion} Offline',
                              style: KeraTypography.labelSmall(color: KeraColors.textMuted),
                            ),
                          ],
                        ),
                      ],
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
}

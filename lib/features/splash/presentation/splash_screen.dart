import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/kera_logo_widget.dart';

/// Clean native mobile splash screen for Kera Spare Tracker.
///
/// Designed in the style of Google Pay and Square:
/// - Brand Deep Navy (#061B3F) background
/// - Centered crisp logo plate with rounded edges
/// - Single-language localized brand title & tagline
/// - Minimalist Brand Orange (#F7941D) circular loader
/// - Offline-first version signature at the bottom
class SplashScreen extends StatelessWidget {
  final double? progressValue;

  const SplashScreen({
    super.key,
    this.progressValue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: KeraColors.navy900,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Top subtle location identifier
              Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: KeraColors.navy800.withValues(alpha: 0.6),
                    borderRadius: KeraRadii.borderPill,
                    border: Border.all(
                      color: KeraColors.navy600.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: KeraColors.orange500,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          l10n.keraHubLocation,
                          overflow: TextOverflow.ellipsis,
                          style: KeraTypography.labelSmall(color: Colors.white).copyWith(
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Central Hero Branding Cluster
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const KeraLogoWidget(size: 96, borderRadius: 24),
                  const SizedBox(height: KeraSpacing.xl),
                  Text(
                    l10n.appName,
                    textAlign: TextAlign.center,
                    style: KeraTypography.headlineLarge(color: Colors.white).copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: KeraColors.navy800,
                      borderRadius: KeraRadii.borderPill,
                      border: Border.all(color: KeraColors.orange500.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      l10n.taglineTrackManageGrow,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: KeraColors.orange500,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              // 3. Bottom Loader & Offline Signature
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      value: progressValue,
                      strokeWidth: 2.4,
                      valueColor: const AlwaysStoppedAnimation<Color>(KeraColors.orange500),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.splashLoading,
                    style: KeraTypography.labelSmall(
                      color: Colors.white.withValues(alpha: 0.8),
                    ).copyWith(letterSpacing: 0.5),
                  ),
                  const SizedBox(height: KeraSpacing.lg),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: KeraColors.navy800.withValues(alpha: 0.5),
                      borderRadius: KeraRadii.borderCard,
                      border: Border.all(
                        color: KeraColors.navy600.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 15,
                          color: KeraColors.orange500,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'v${AppConstants.appVersion} · ${l10n.offlineBadge}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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

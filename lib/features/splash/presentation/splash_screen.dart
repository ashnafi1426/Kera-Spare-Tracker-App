import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/kera_logo_widget.dart';

/// Pixel-perfect native mobile splash screen matching the Stitch Design Page 01.
///
/// Layout:
/// - Clean ambient background with subtle warmth
/// - Prominent floating squircle app icon card (176x176) with soft drop shadow
/// - Two-tone brand title: "Kera" (Navy) + "Spare Tracker" (Orange)
/// - Bilingual Amharic subtitle: "የቄራ መለዋወጫ መከታተያ"
/// - Tagline pill badge: "መከታተል • ማስተዳደር • ማሳደግ"
/// - Sleek horizontal gradient progress bar (Navy -> Orange)
/// - Status line: "[✓] ስርዓቱ እየተዘጋጀ ነው... • Offline-Ready Sync"
/// - Version & district signature: "v1.0.0 • Addis Ababa, Ethiopia"
class SplashScreen extends StatelessWidget {
  final double? progressValue;

  const SplashScreen({
    super.key,
    this.progressValue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? KeraColors.navy900 : Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? const RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 1.1,
                  colors: [
                    KeraColors.splashRadialNavy,
                    KeraColors.navy900,
                  ],
                )
              : const RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 1.1,
                  colors: [
                    KeraColors.splashBgLightWarm,
                    KeraColors.splashBgLightNeutral,
                    Colors.white,
                  ],
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // 1. Central Hero Card (Squircle with Logo)
              Center(
                child: Container(
                  width: 176,
                  height: 176,
                  decoration: BoxDecoration(
                    color: isDark ? KeraColors.navy800 : Colors.white,
                    borderRadius: BorderRadius.circular(38),
                    border: Border.all(
                      color: isDark
                          ? KeraColors.navy600.withValues(alpha: 0.5)
                          : KeraColors.orange100.withValues(alpha: 0.7),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.45)
                            : KeraColors.navy800.withValues(alpha: 0.08),
                        blurRadius: 36,
                        offset: const Offset(0, 16),
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: isDark
                            ? KeraColors.orange500.withValues(alpha: 0.08)
                            : KeraColors.orange500.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  clipBehavior: Clip.antiAlias,
                  child: const Center(
                    child: KeraLogoWidget(
                      size: 140,
                      borderRadius: 20,
                      backgroundColor: Colors.transparent,
                      showShadow: false,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 2. Brand Titles Cluster
              // 2A. Two-tone Title: "Kera" (Navy) + "Spare Tracker" (Orange)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Kera',
                    style: TextStyle(
                      fontFamily: KeraTypography.fontLatin,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : KeraColors.navy900,
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'Spare Tracker',
                    style: TextStyle(
                      fontFamily: KeraTypography.fontLatin,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: KeraColors.orange500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 2B. Amharic Subtitle: "የቄራ መለዋወጫ መከታተያ"
              Text(
                'የቄራ መለዋወጫ መከታተያ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: KeraTypography.fontEthiopic,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: isDark
                      ? KeraColors.navy100
                      : KeraColors.navy800.withValues(alpha: 0.85),
                ),
              ),

              const SizedBox(height: 14),

              // 2C. Tagline Pill Container: "መከታተል • ማስተዳደር • ማሳደግ"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                decoration: BoxDecoration(
                  color: isDark
                      ? KeraColors.navy800.withValues(alpha: 0.8)
                      : Colors.white,
                  borderRadius: KeraRadii.borderPill,
                  border: Border.all(
                    color: isDark
                        ? KeraColors.orange500.withValues(alpha: 0.35)
                        : KeraColors.orange100,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: KeraColors.orange500.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.taglineTrackManageGrow,
                      style: TextStyle(
                        fontFamily: KeraTypography.fontEthiopic,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: isDark ? Colors.white : KeraColors.navy900,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // 3. Bottom Loader & Status Cluster
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 3A. Sleek Horizontal Gradient Progress Bar
                    Container(
                      width: 148,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isDark
                            ? KeraColors.navy800
                            : KeraColors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progressValue ?? 0.65,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                isDark ? Colors.white : KeraColors.navy900,
                                KeraColors.orange500,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 3B. Status Row: [✓] ስርዓቱ እየተዘጋጀ ነው... • Offline-Ready Sync
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: KeraColors.orange100,
                            borderRadius: BorderRadius.circular(3.5),
                            border: Border.all(
                              color: KeraColors.orange500,
                              width: 1.2,
                            ),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 11,
                            color: KeraColors.orange600,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            l10n.splashPreparing,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: KeraTypography.fontEthiopic,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : KeraColors.navy900,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: Text(
                            '•',
                            style: TextStyle(
                              color: isDark
                                  ? KeraColors.navy100.withValues(alpha: 0.5)
                                  : KeraColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            l10n.offlineReadySync,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: KeraTypography.fontLatin,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? KeraColors.navy100.withValues(alpha: 0.8)
                                  : KeraColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // 3C. Version & Location: v1.0.0 • Addis Ababa, Ethiopia
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'v${AppConstants.appVersion}',
                          style: TextStyle(
                            fontFamily: KeraTypography.fontLatin,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: KeraColors.textSecondary,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6.0),
                          child: Text(
                            '•',
                            style: TextStyle(
                              color: KeraColors.border,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            l10n.addisAbabaLocation,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: KeraTypography.fontLatin,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: KeraColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

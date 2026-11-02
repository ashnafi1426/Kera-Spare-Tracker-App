import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/design/widgets/kera_button.dart';
import '../../../../core/design/widgets/kera_card.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../data/local/database_provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/services/initial_sync_service.dart';

/// Stitch Design: Screen 6 — First-Time Setup & Initial Sync / የመጀመሪያ ማዋቀር
/// Screen displayed on first login on a new phone while pulling catalog from server (Rule 6).
/// As soon as the first page (50 items) is saved to Drift, automatically navigates to /home.
class InitialSyncScreen extends ConsumerStatefulWidget {
  const InitialSyncScreen({super.key});

  @override
  ConsumerState<InitialSyncScreen> createState() => _InitialSyncScreenState();
}

class _InitialSyncScreenState extends ConsumerState<InitialSyncScreen> {
  int _downloaded = 0;
  int _total = 0;
  bool _firstBatchReady = false;
  StreamSubscription<InitialSyncProgress>? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSync());
  }

  void _startSync() {
    final user = ref.read(authControllerProvider).value;
    if (user == null) {
      context.go('/login');
      return;
    }

    final repo = ref.read(apiAuthRepositoryProvider);
    final db = ref.read(appDatabaseProvider);
    final service = InitialSyncService(dio: repo.dio, db: db);

    _sub = service.pullInitialCatalog(user.ownerId).listen((progress) {
      if (!mounted) return;
      setState(() {
        _downloaded = progress.downloaded;
        _total = progress.total;
        _firstBatchReady = progress.firstBatchReady;
      });

      // Rule 6: Navigate to inventory screen as soon as the first page is written to Drift
      if (progress.firstBatchReady && mounted) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) context.go('/home');
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progressVal = (_total > 0) ? (_downloaded / _total).clamp(0.0, 1.0) : null;
    final percentInt = progressVal != null ? (progressVal * 100).toInt() : 0;

    return Scaffold(
      backgroundColor: KeraColors.surfaceCanvas,
      body: Column(
        children: [
          // Top System Bar
          _buildTopBanner(context),

          // Wizard Subheader Banner
          _buildWizardHeader(context, percentInt),

          // Main Scrollable Setup Canvas
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: KeraSpacing.lg,
                vertical: KeraSpacing.md,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Sync Progress Card
                      KeraCard(
                        padding: const EdgeInsets.all(KeraSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: KeraColors.actionBlueTint,
                                    borderRadius: BorderRadius.circular(KeraRadii.md),
                                  ),
                                  child: const Icon(
                                    Icons.cloud_sync_rounded,
                                    color: KeraColors.actionBlue,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: KeraSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.initialSyncTitle,
                                        style: KeraTypography.titleMedium(color: KeraColors.textPrimary).copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        l10n.initialSyncSubtitle,
                                        style: KeraTypography.bodySmall(color: KeraColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: KeraSpacing.lg),

                            // Linear Progress Indicator
                            ClipRRect(
                              borderRadius: BorderRadius.circular(KeraRadii.full),
                              child: LinearProgressIndicator(
                                value: progressVal,
                                minHeight: 10,
                                backgroundColor: KeraColors.borderOpaque,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  KeraColors.actionBlue,
                                ),
                              ),
                            ),
                            const SizedBox(height: KeraSpacing.sm),

                            // Counter & Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _total > 0
                                      ? '$_downloaded / $_total ዕቃዎች (Parts)'
                                      : 'ከአገልጋዩ ጋር እየተገናኘ ነው... (Connecting...)',
                                  style: KeraTypography.labelSmall(color: KeraColors.textPrimary).copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_total > 0)
                                  Text(
                                    '$percentInt%',
                                    style: KeraTypography.labelSmall(color: KeraColors.actionBlue).copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: KeraSpacing.md),

                      // Store Info / Configuration Summary Card
                      KeraCard(
                        padding: const EdgeInsets.all(KeraSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.hub_rounded, color: KeraColors.actionBlue, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'የመደብር አይነትና መገኛ / Store Focus',
                                  style: KeraTypography.labelLarge(color: KeraColors.textPrimary).copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20, color: KeraColors.borderOpaque),
                            Row(
                              children: [
                                const Icon(Icons.directions_car_rounded, size: 18, color: KeraColors.textSecondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'የስፔር ክፍል: ቶዮታ እና አጠቃላይ (Toyota & Multi-Brand)',
                                    style: KeraTypography.bodySmall(color: KeraColors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.pin_drop_rounded, size: 18, color: KeraColors.textSecondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'መገኛ: ኬራ የመለዋወጫ ግቢ (Kera Auto Hub)',
                                    style: KeraTypography.bodySmall(color: KeraColors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: KeraSpacing.md),

                      // Offline-First Assurance Banner (Stitch Screen 6)
                      Container(
                        padding: const EdgeInsets.all(KeraSpacing.md),
                        decoration: BoxDecoration(
                          color: KeraColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(KeraRadii.lg),
                          border: Border.all(color: KeraColors.borderOpaque),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_user_rounded,
                              color: KeraColors.utilityTeal,
                              size: 22,
                            ),
                            const SizedBox(width: KeraSpacing.sm),
                            Expanded(
                              child: Text(
                                'ሁሉም መረጃዎች በስልክዎ ውስጥ በከፊል ኦፍላይን (Offline-first) ይሰራሉ።',
                                style: KeraTypography.bodySmall(color: KeraColors.textPrimary).copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: KeraSpacing.lg),

                      // Immediate launch button when first batch is ready
                      if (_firstBatchReady)
                        KeraButton.primary(
                          label: 'ወደ ክምችት ይቀጥሉ / Launch App',
                          icon: Icons.celebration_rounded,
                          onPressed: () => context.go('/home'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBanner(BuildContext context) {
    return Container(
      color: KeraColors.primaryNavy,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: KeraSpacing.md),
          child: Row(
            children: [
              const Icon(
                Icons.storefront_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'ኬራ ስፔር / Kera Spare',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(KeraRadii.full),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: KeraColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'ኦንላይን',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWizardHeader(BuildContext context, int percent) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KeraSpacing.lg,
        vertical: KeraSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: KeraColors.borderOpaque)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: KeraColors.actionBlueTint,
                      borderRadius: BorderRadius.circular(KeraRadii.xs),
                    ),
                    child: Text(
                      'ደረጃ 2 ከ 2',
                      style: KeraTypography.labelSmall(color: KeraColors.actionBlue).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'መጨረሻ ደረጃ / Final Step',
                    style: KeraTypography.bodySmall(color: KeraColors.textSecondary),
                  ),
                ],
              ),
              Text(
                '$percent%',
                style: KeraTypography.labelMedium(color: KeraColors.actionBlue).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Segmented Progress Bar (Both active)
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: KeraColors.actionBlue,
                    borderRadius: BorderRadius.circular(KeraRadii.full),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: KeraColors.actionBlue,
                    borderRadius: BorderRadius.circular(KeraRadii.full),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'የመደብርዎን ማዋቀር ይጨርሱ',
            style: KeraTypography.titleMedium(color: KeraColors.textPrimary).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Complete Store Setup • ፈጣን የክምችት ማመሳሰል',
            style: KeraTypography.bodySmall(color: KeraColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

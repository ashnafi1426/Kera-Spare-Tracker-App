import 'package:flutter/material.dart';
import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/design/widgets/kera_button.dart';

/// Empty state onboarding dashboard matching Stitch Screen 10.
///
/// Displayed when the owner has 0 parts in catalog, giving a clear
/// store launch checklist, starter part actions, and merchant advice.
class DashboardEmptyOnboarding extends StatelessWidget {
  final VoidCallback onAddFirstPart;
  final VoidCallback? onLoadStarterParts;

  const DashboardEmptyOnboarding({
    super.key,
    required this.onAddFirstPart,
    this.onLoadStarterParts,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Store Launch Checklist Card
        Container(
          padding: const EdgeInsets.all(KeraSpacing.md),
          decoration: BoxDecoration(
            color: KeraColors.surfaceCard,
            borderRadius: BorderRadius.circular(KeraRadii.md),
            border: Border.all(color: KeraColors.borderVariant),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.rocket_launch_rounded,
                          color: KeraColors.actionBlue,
                          size: 20,
                        ),
                        const SizedBox(width: KeraSpacing.xs),
                        Flexible(
                          child: Text(
                            'የመደብር ማዋቀር ሂደት',
                            style: KeraTypography.titleMedium().copyWith(
                              fontWeight: FontWeight.bold,
                              color: KeraColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: KeraSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: KeraColors.actionBlue.withValues(alpha: 0.12),
                      borderRadius: KeraRadii.borderPill,
                    ),
                    child: const Text(
                      '1 ከ 4 ተጠናቋል',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: KeraColors.actionBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KeraSpacing.sm),

              // Progress bar (25%)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0.25,
                  minHeight: 6,
                  backgroundColor: KeraColors.borderNeutral,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    KeraColors.actionBlue,
                  ),
                ),
              ),
              const SizedBox(height: KeraSpacing.md),

              // Step 1: Completed
              _buildChecklistRow(
                stepNumber: '✓',
                titleAm: 'መለያ ተፈጥሯል',
                subtitleEn: 'Account Created & Verified',
                isCompleted: true,
              ),
              const Divider(height: 16, color: KeraColors.borderVariant),

              // Step 2: Active / In-progress
              _buildChecklistRow(
                stepNumber: '2',
                titleAm: 'የመጀመሪያ ዕቃዎችን ያስገቡ',
                subtitleEn: 'Add first 10 spare parts (OEM/Shelf)',
                isCurrent: true,
                onActionTap: onAddFirstPart,
                actionLabel: 'ጀምር',
              ),
              const Divider(height: 16, color: KeraColors.borderVariant),

              // Step 3: Locked
              _buildChecklistRow(
                stepNumber: '3',
                titleAm: 'የሽያጭ ዋጋ እና መደርደሪያ ያዘጋጁ',
                subtitleEn: 'Set prices & shelf locations',
                isLocked: true,
              ),
              const Divider(height: 16, color: KeraColors.borderVariant),

              // Step 4: Locked
              _buildChecklistRow(
                stepNumber: '4',
                titleAm: 'የመጀመሪያ ሽያጭ ይሞክሩ',
                subtitleEn: 'Try test sale receipt & SMS receipt',
                isLocked: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: KeraSpacing.md),

        // 2. Empty State Hero Visual & Guide
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(KeraSpacing.lg),
          decoration: BoxDecoration(
            color: KeraColors.surfaceCard,
            borderRadius: BorderRadius.circular(KeraRadii.md),
            border: Border.all(color: KeraColors.borderVariant),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              // Illustration icon container
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: KeraColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(KeraRadii.lg),
                      border: Border.all(color: KeraColors.borderVariant),
                    ),
                    child: const Icon(
                      Icons.shelves,
                      color: KeraColors.actionBlue,
                      size: 36,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: KeraColors.primaryNavy,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KeraSpacing.md),

              Text(
                'መደብርዎ ዝግጁ ነው!\nዕቃዎችን በማስገባት ይጀምሩ',
                textAlign: TextAlign.center,
                style: KeraTypography.titleMedium().copyWith(
                  fontWeight: FontWeight.bold,
                  color: KeraColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: KeraSpacing.xs),
              Text(
                'የቶዮታ፣ አይሱዙ ወይም ሲኖትራክ መለዋወጫዎችን በአንድ ቁልፍ ወይም ባርኮድ በመቃኘት በቀላሉ ያስመዝግቡ።',
                textAlign: TextAlign.center,
                style: KeraTypography.bodySmall().copyWith(
                  color: KeraColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: KeraSpacing.md),

              // Action Buttons
              KeraButton(
                label: '+ የመጀመሪያ ዕቃ ይመዝግቡ (Add Part)',
                onPressed: onAddFirstPart,
                icon: Icons.add_circle_outline_rounded,
                variant: KeraButtonVariant.primary,
              ),

              if (onLoadStarterParts != null) ...[
                const SizedBox(height: KeraSpacing.sm),
                KeraButton(
                  label: 'የተዘጋጀ የናሙና ዝርዝር ጫን (Starter Parts)',
                  onPressed: onLoadStarterParts,
                  icon: Icons.dataset_outlined,
                  variant: KeraButtonVariant.outlined,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: KeraSpacing.md),

        // 3. Advice Card
        Container(
          padding: const EdgeInsets.all(KeraSpacing.md),
          decoration: BoxDecoration(
            color: KeraColors.primaryNavy.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(KeraRadii.md),
            border: Border.all(
              color: KeraColors.primaryNavy.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: KeraColors.actionBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(KeraRadii.xs),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: KeraColors.actionBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: KeraSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'የኬራ ነጋዴዎች ምክር',
                      style: KeraTypography.labelSmall().copyWith(
                        fontWeight: FontWeight.bold,
                        color: KeraColors.primaryNavy,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'በብዛት የሚሸጡ የዘይት ማጣሪያ (Oil Filters) እና የፍሬን ሌather (Brake Pads) በማስገባት ይጀምሩ።',
                      style: KeraTypography.bodySmall().copyWith(
                        color: KeraColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistRow({
    required String stepNumber,
    required String titleAm,
    required String subtitleEn,
    bool isCompleted = false,
    bool isCurrent = false,
    bool isLocked = false,
    VoidCallback? onActionTap,
    String? actionLabel,
  }) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFFDCFCE7)
                : isCurrent
                    ? KeraColors.actionBlue
                    : KeraColors.borderNeutral,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            stepNumber,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isCompleted
                  ? const Color(0xFF16A34A)
                  : isCurrent
                      ? Colors.white
                      : KeraColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: KeraSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titleAm,
                style: KeraTypography.bodySmall().copyWith(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCurrent
                      ? KeraColors.actionBlue
                      : isCompleted
                          ? KeraColors.textSecondary
                          : KeraColors.textPrimary,
                  decoration:
                      isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(
                subtitleEn,
                style: KeraTypography.labelSmall().copyWith(
                  color: KeraColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        if (isCompleted)
          const Text(
            'ተጠናቋል',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF16A34A),
            ),
          )
        else if (isCurrent && onActionTap != null)
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: KeraColors.actionBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KeraRadii.xs),
              ),
            ),
            onPressed: onActionTap,
            child: Text(
              actionLabel ?? 'ጀምር',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          )
        else if (isLocked)
          const Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: KeraColors.textSecondary,
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/tokens/kera_typography.dart';

/// 4-column quick action grid matching Stitch Screen 7.
///
/// Direct access to critical workflows:
/// 1. + Part (አዲስ ዕቃ)
/// 2. New Sale (ሽያጭ መዝግብ)
/// 3. Restock (ክምችት አድስ)
/// 4. Scanner (ባርኮድ ቃኝ)
class DashboardQuickActions extends StatelessWidget {
  final VoidCallback onAddPart;
  final VoidCallback onNewSale;
  final VoidCallback onRestock;
  final VoidCallback onScanBarcode;

  const DashboardQuickActions({
    super.key,
    required this.onAddPart,
    required this.onNewSale,
    required this.onRestock,
    required this.onScanBarcode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ፈጣን ተግባራት / Quick Actions',
          style: KeraTypography.titleMedium().copyWith(
            color: KeraColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: KeraSpacing.sm),
        Row(
          children: [
            // Action 1: Add Part
            Expanded(
              child: _QuickActionButton(
                labelAm: 'አዲስ ዕቃ',
                labelEn: '+ Part',
                icon: Icons.add_circle_outline_rounded,
                iconBgColor: KeraColors.actionBlue,
                iconColor: Colors.white,
                onTap: onAddPart,
              ),
            ),
            const SizedBox(width: KeraSpacing.xs),

            // Action 2: New Sale
            Expanded(
              child: _QuickActionButton(
                labelAm: 'ሽያጭ መዝግብ',
                labelEn: 'New Sale',
                icon: Icons.point_of_sale_rounded,
                iconBgColor: KeraColors.primaryNavy,
                iconColor: Colors.white,
                onTap: onNewSale,
              ),
            ),
            const SizedBox(width: KeraSpacing.xs),

            // Action 3: Restock
            Expanded(
              child: _QuickActionButton(
                labelAm: 'ክምችት አድስ',
                labelEn: 'Restock',
                icon: Icons.update_rounded,
                iconBgColor: KeraColors.borderNeutral,
                iconColor: KeraColors.primaryNavy,
                onTap: onRestock,
              ),
            ),
            const SizedBox(width: KeraSpacing.xs),

            // Action 4: Barcode Scanner
            Expanded(
              child: _QuickActionButton(
                labelAm: 'ባርኮድ ቃኝ',
                labelEn: 'Scanner',
                icon: Icons.qr_code_scanner_rounded,
                iconBgColor: KeraColors.borderNeutral,
                iconColor: KeraColors.actionBlue,
                onTap: onScanBarcode,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String labelAm;
  final String labelEn;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.labelAm,
    required this.labelEn,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KeraColors.surfaceCard,
      borderRadius: BorderRadius.circular(KeraRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KeraRadii.md),
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: KeraSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KeraRadii.md),
            border: Border.all(color: KeraColors.borderVariant),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 4),
              Text(
                labelAm,
                style: KeraTypography.labelSmall().copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: KeraColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                labelEn,
                style: KeraTypography.labelSmall().copyWith(
                  fontSize: 9,
                  color: KeraColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/utils/context_extensions.dart';

/// Screen 5: Dedicated Language Selection Screen adhering to Google Stitch specs.
class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  late String _selectedCode;

  @override
  void initState() {
    super.initState();
    _selectedCode = ref.read(localeControllerProvider).languageCode;
  }

  Future<void> _applyLanguage() async {
    await ref
        .read(localeControllerProvider.notifier)
        .setLocale(Locale(_selectedCode));
    if (mounted) {
      context.showSnackBar(
        _selectedCode == 'am'
            ? 'ቋንቋው በተሳካ ሁኔታ ተቀይሯል!'
            : 'Language updated successfully!',
      );
      if (context.canPop()) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KeraColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: KeraColors.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'የቋንቋ ምርጫ / Language',
              style: KeraTypography.titleMedium(color: Colors.white),
            ),
            Text(
              'ኬራ መለዋወጫ መከታተያ',
              style: KeraTypography.labelSmall(
                color: Colors.white.withAlpha(200),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: KeraSpacing.screenPadding,
                children: [
                  const SizedBox(height: 8),

                  // Explanatory Header Card
                  Container(
                    padding: const EdgeInsets.all(KeraSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: KeraRadii.borderCard,
                      border: Border.all(color: KeraColors.borderVariant),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(6),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: KeraColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.g_translate_rounded,
                            color: KeraColors.actionBlue,
                          ),
                        ),
                        const SizedBox(width: KeraSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'የስራ ቋንቋዎን ይምረጡ',
                                style: KeraTypography.headlineSmall(),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Select App Interface Language',
                                style: KeraTypography.labelMedium(
                                  color: KeraColors.actionBlue,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'የመለዋወጫ ካታሎግ፣ ሽያጭ፣ ደረሰኝ እና የሪፖርት ፅሁፎች በተመረጠው ቋንቋ ይታያሉ። (Catalog, POS, receipts, and analytics will render in your preferred language.)',
                                style: KeraTypography.bodySmall(
                                  color: KeraColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: KeraSpacing.lg),

                  // Option 1: Amharic
                  _buildLanguageOption(
                    code: 'am',
                    glyph: 'አ',
                    title: 'አማርኛ',
                    subtitle: 'Amharic (Ethiopia)',
                    description: 'ነባሪ • በኬራ መደብሮች በስፋት ጥቅም ላይ የሚውል',
                    subDescription: 'Default recommended for local retail trade',
                    scriptTag: 'Ge\'ez Script',
                    isActiveNow: _selectedCode == 'am',
                    isSelected: _selectedCode == 'am',
                    onTap: () => setState(() => _selectedCode = 'am'),
                  ),

                  const SizedBox(height: KeraSpacing.md),

                  // Option 2: English
                  _buildLanguageOption(
                    code: 'en',
                    glyph: 'EN',
                    title: 'English',
                    subtitle: 'እንግሊዝኛ (International)',
                    description:
                        'Standard international automotive terminology (SKU, COGS, POS)',
                    subDescription: 'የአለም አቀፍ የዕቃ መጠሪያዎችና ምህፃረ-ቃላት',
                    scriptTag: 'Latin Script',
                    isActiveNow: _selectedCode == 'en',
                    isSelected: _selectedCode == 'en',
                    onTap: () => setState(() => _selectedCode = 'en'),
                  ),

                  const SizedBox(height: KeraSpacing.md),

                  // Option 3: Afaan Oromoo (Coming Soon)
                  Container(
                    padding: const EdgeInsets.all(KeraSpacing.lg),
                    decoration: BoxDecoration(
                      color: KeraColors.surfaceContainerLow.withAlpha(160),
                      borderRadius: KeraRadii.borderCard,
                      border: Border.all(color: KeraColors.borderVariant),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'AO',
                                style: KeraTypography.titleMedium(
                                  color: KeraColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: KeraSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Afaan Oromoo',
                                        style: KeraTypography.headlineSmall(
                                          color: KeraColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'ኦሮምኛ',
                                        style: KeraTypography.labelMedium(
                                          color: KeraColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Regional support in development for Sheger and Adama merchants',
                                    style: KeraTypography.bodySmall(
                                      color: KeraColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'የክልላዊ ገበያ ድጋፍ በዝግጅት ላይ ያለ',
                                    style: KeraTypography.labelSmall(
                                      color: KeraColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.schedule_rounded,
                              color: KeraColors.textMuted,
                              size: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: KeraSpacing.sm),
                        const Divider(height: 1),
                        const SizedBox(height: KeraSpacing.sm),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.lock_clock_rounded,
                                    size: 14,
                                    color: KeraColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'በቅርቡ የሚደርስ (Coming Soon)',
                                    style: KeraTypography.labelSmall(
                                      color: KeraColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Qubee Oromoo',
                              style: KeraTypography.labelSmall(
                                color: KeraColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: KeraSpacing.lg),

                  // Informational Live Switch Notice
                  Container(
                    padding: const EdgeInsets.all(KeraSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: KeraRadii.borderCard,
                      border: Border.all(color: KeraColors.borderVariant),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: KeraColors.utilityTeal.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.translate_rounded,
                            color: KeraColors.utilityTeal,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: KeraSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ቀጥታ የመቀየሪያ ማስታወሻ (Instant Preview)',
                                style: KeraTypography.titleSmall(),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ቋንቋውን ሲቀይሩ መተግበሪያውን እንደገና ማስነሳት አያስፈልግዎትም። ሁሉም የዕቃ ስሞች፣ የመደርደሪያ ኮዶች እና የደረሰኝ አብነቶች ወዲያውኑ ይስተካከላሉ።',
                                style: KeraTypography.bodySmall(
                                  color: KeraColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'No app restart required. Catalog, shelf tags, and thermal receipt layouts update immediately.',
                                style: KeraTypography.labelSmall(
                                  color: KeraColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Sticky Bottom Confirmation Bar
            Container(
              padding: const EdgeInsets.all(KeraSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  top: BorderSide(color: KeraColors.borderVariant),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 8,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KeraColors.primaryNavy,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: KeraRadii.borderButton,
                        ),
                      ),
                      onPressed: _applyLanguage,
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: Text(
                        'ቋንቋውን አረጋግጥ (Apply & Save Language)',
                        style: KeraTypography.titleSmall(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ምርጫዎ በሁሉም የኬራ መደብር መሳሪያዎች ላይ ይመሳሰላል • Auto-synced',
                    style: KeraTypography.labelSmall(
                      color: KeraColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String code,
    required String glyph,
    required String title,
    required String subtitle,
    required String description,
    required String subDescription,
    required String scriptTag,
    required bool isActiveNow,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: KeraRadii.borderCard,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(KeraSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: KeraRadii.borderCard,
          border: Border.all(
            color: isSelected ? KeraColors.actionBlue : KeraColors.borderVariant,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? KeraColors.actionBlue.withAlpha(15)
                  : Colors.black.withAlpha(4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Glyph Container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? KeraColors.actionBlue.withAlpha(20)
                        : KeraColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    glyph,
                    style: KeraTypography.headlineSmall(
                      color: isSelected
                          ? KeraColors.actionBlue
                          : KeraColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: KeraSpacing.md),
                // Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 2,
                        children: [
                          Text(
                            title,
                            style: KeraTypography.headlineSmall(
                              color: isSelected
                                  ? KeraColors.actionBlue
                                  : KeraColors.textPrimary,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: KeraTypography.labelMedium(
                              color: KeraColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: KeraTypography.bodySmall(
                          color: KeraColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subDescription,
                        style: KeraTypography.labelSmall(
                          color: KeraColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Selection Circle
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? KeraColors.actionBlue
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? KeraColors.actionBlue
                          : KeraColors.borderVariant,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: KeraSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: KeraSpacing.sm),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                if (isActiveNow)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: KeraColors.stockInBg,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: KeraColors.stockInText,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'አሁን የሚሰራበት (Currently Active)',
                          style: KeraTypography.labelSmall(
                            color: KeraColors.stockInText,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'Global Mode',
                    style: KeraTypography.labelSmall(
                      color: KeraColors.textSecondary,
                    ),
                  ),
                Text(
                  scriptTag,
                  style: KeraTypography.labelSmall(
                    color: isSelected
                        ? KeraColors.actionBlue
                        : KeraColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


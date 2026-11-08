import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/kera_colors.dart';
import '../../../../core/design/tokens/kera_radii.dart';
import '../../../../core/design/tokens/kera_spacing.dart';
import '../../../../core/design/tokens/kera_typography.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/image_management_widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/models/business_profile.dart';
import '../providers/business_profile_provider.dart';

/// Screen 2: Business Profile screen adhering to Google Stitch specs.
class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() =>
      _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _businessNameController;
  late TextEditingController _tinController;
  late TextEditingController _ownerNameController;
  late TextEditingController _primaryPhoneController;
  late TextEditingController _altPhoneController;
  late TextEditingController _shopNumberController;
  late TextEditingController _landmarkController;
  late TextEditingController _receiptFooterController;

  String _selectedCategory =
      'የከባድ እና አነስተኛ ተሽከርካሪ መለዋወጫ (Commercial Fleet & Light Auto Parts)';
  String _selectedDistrict =
      'ቂርቆስ ክፍለ ከተማ • ኬራ ዞን 4 (Kirkos Sub-City, Kera Zone 4)';
  bool _isVatRegistered = false;
  bool _isSaving = false;

  final List<String> _categories = [
    'የከባድ እና አነስተኛ ተሽከርካሪ መለዋወጫ (Commercial Fleet & Light Auto Parts)',
    'የሞተርና ጊርቦክስ ዕቃዎች (Engines & Transmissions)',
    'የኤሌክትሪክ እና ሴንሰር ክፍሎች (Auto Electronics & Sensors)',
    'የፍሬን እና እገዳ መለዋወጫ (Brake & Suspension Parts)',
  ];

  final List<String> _districts = [
    'ቂርቆስ ክፍለ ከተማ • ኬራ ዞን 4 (Kirkos Sub-City, Kera Zone 4)',
    'ቂርቆስ ክፍለ ከተማ • ጎፋ ሰፈር (Gofa Mazoria)',
    'ልደታ ክፍለ ከተማ • ተክለሃይማኖት ዞን 1 (Teklehaymanot)',
    'ቦሌ ክፍለ ከተማ • ቦሌ ሚካኤል (Bole Michael)',
  ];

  @override
  void initState() {
    super.initState();
    final profileAsync = ref.read(businessProfileProvider);
    final profile = profileAsync.value;

    _businessNameController = TextEditingController(
      text: profile?.businessName ?? 'ተስፋዬ እና ልጆቹ የጃፓን መለዋወጫ (Tesfaye & Sons Auto Spares)',
    );
    _tinController = TextEditingController(
      text: profile?.tinNumber ?? 'TIN-0048192847 • Addis Ababa Trade Bureau',
    );
    _ownerNameController = TextEditingController(
      text: profile?.ownerFullName ?? 'አቶ ተስፋዬ ገብረመስቀል (Tesfaye Gebremeskel)',
    );
    _primaryPhoneController = TextEditingController(
      text: profile?.primaryPhone.replaceFirst('+251', '').trim() ?? '911 458 920',
    );
    _altPhoneController = TextEditingController(
      text: profile?.alternatePhone.replaceFirst('+251', '').trim() ?? '922 104 555',
    );
    _shopNumberController = TextEditingController(
      text: profile?.shopNumber ?? 'ሱቅ ቁጥር 14 (Shop #14, Main Corridor)',
    );
    _landmarkController = TextEditingController(
      text: profile?.landmark ?? 'ከቄራ ቄራ እርድ ቤት ፊት ለፊት፣ በገነት ሆቴል መታጠፊያ',
    );
    _receiptFooterController = TextEditingController(
      text: profile?.receiptFooter ??
          'ለገዙን እናመሰግናለን! የተሸጡ ዕቃዎች በ3 ቀናት ውስጥ በደረሰኝ ይቀየራሉ። (Thank you for your business! Parts exchangeable within 3 days with receipt.)',
    );

    if (profile != null) {
      if (_categories.contains(profile.category)) {
        _selectedCategory = profile.category;
      }
      if (_districts.contains(profile.districtZone)) {
        _selectedDistrict = profile.districtZone;
      }
      _isVatRegistered = profile.isVatRegistered;
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _tinController.dispose();
    _ownerNameController.dispose();
    _primaryPhoneController.dispose();
    _altPhoneController.dispose();
    _shopNumberController.dispose();
    _landmarkController.dispose();
    _receiptFooterController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final currentProfile = ref.read(businessProfileProvider).value ??
        BusinessProfile.defaultProfile();

    final newProfile = currentProfile.copyWith(
      businessName: _businessNameController.text.trim(),
      tinNumber: _tinController.text.trim(),
      category: _selectedCategory,
      ownerFullName: _ownerNameController.text.trim(),
      primaryPhone: _primaryPhoneController.text.trim(),
      alternatePhone: _altPhoneController.text.trim(),
      districtZone: _selectedDistrict,
      shopNumber: _shopNumberController.text.trim(),
      landmark: _landmarkController.text.trim(),
      receiptFooter: _receiptFooterController.text.trim(),
      isVatRegistered: _isVatRegistered,
    );

    await ref
        .read(businessProfileProvider.notifier)
        .saveProfile(newProfile);

    setState(() => _isSaving = false);

    if (mounted) {
      context.showSnackBar('የንግድ መረጃ በተሳካ ሁኔታ ተቀምጧል! (Profile Saved)');
      if (context.canPop()) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authControllerProvider).value;
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
              'የንግድ መረጃ / Business Profile',
              style: KeraTypography.titleMedium(color: Colors.white),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: KeraColors.actionBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('አስቀምጥ (Save)'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Store Verification Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: KeraColors.borderVariant),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: KeraColors.stockInText,
                          ),
                        ),
                        Text(
                          'የተረጋገጠ የንግድ መደብር (Verified Merchant)',
                          style: KeraTypography.labelSmall(
                            color: KeraColors.textPrimary,
                          ),
                        ),
                        Text(
                          '•  Kera Automotive District',
                          style: KeraTypography.labelSmall(
                            color: KeraColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.verified_rounded,
                    color: KeraColors.stockInText,
                    size: 18,
                  ),
                ],
              ),
            ),

            // Scrollable Form Canvas
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: KeraSpacing.screenPadding,
                  children: [
                    const SizedBox(height: 8),

                    // 1. Business Logo & Branding
                    Container(
                      padding: const EdgeInsets.all(KeraSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: KeraRadii.borderCard,
                        border: Border.all(color: KeraColors.borderVariant),
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
                                      Icons.branding_watermark_rounded,
                                      color: KeraColors.actionBlue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'የንግድ ምልክት እና ሎጎ (Business Logo)',
                                        style: KeraTypography.titleMedium(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: KeraColors.actionBlue.withAlpha(20),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Active ID',
                                  style: KeraTypography.labelSmall(
                                    color: KeraColors.actionBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ProfileImagePicker(
                                initialPhotoUrl: authUser?.photoUrl,
                                ownerName: authUser?.businessName ?? 'Owner',
                                radius: 42,
                                isDark: context.isDark,
                                onPhotoChanged: (newPath) async {
                                  final res = await ref
                                      .read(authControllerProvider.notifier)
                                      .updateProfilePhoto(newPath);
                                  if (mounted) {
                                    if (res.isSuccess) {
                                      context.showSnackBar(
                                        'የንግድ ፎቶ በተሳካ ሁኔታ ተቀይሯል (Profile photo updated)',
                                      );
                                    } else {
                                      context.showSnackBar(
                                        res.failureOrNull?.message ??
                                            'Failed to update photo',
                                        isError: true,
                                      );
                                    }
                                  }
                                },
                              ),
                              const SizedBox(width: KeraSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      authUser?.businessName ??
                                          'Kera Spare Tracker',
                                      style: KeraTypography.titleSmall(
                                        color: context.isDark
                                            ? Colors.white
                                            : KeraColors.primaryNavy,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'የሚመከር መጠን 512x512 PNG ወይም JPG • ለደረሰኝ እና መገለጫ ይጠቅማል',
                                      style: KeraTypography.labelSmall(
                                        color: KeraColors.textMuted,
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

                    const SizedBox(height: KeraSpacing.lg),

                    // 2. Store Details Form
                    Container(
                      padding: const EdgeInsets.all(KeraSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: KeraRadii.borderCard,
                        border: Border.all(color: KeraColors.borderVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.storefront_rounded,
                                color: KeraColors.actionBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'የመደብሩ ዋና መረጃ (Store Details)',
                                  style: KeraTypography.titleMedium(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),

                          // Business Name
                          Text(
                            'የንግድ ስም (Business Name) *',
                            style: KeraTypography.labelMedium(),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _businessNameController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: KeraRadii.borderInput,
                              ),
                              isDense: true,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'የንግድ ስም ያስገቡ'
                                : null,
                          ),

                          const SizedBox(height: 12),

                          // TIN No.
                          Text(
                            'የንግድ ፈቃድ ቁጥር (Trade License / TIN No.) *',
                            style: KeraTypography.labelMedium(),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _tinController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: KeraRadii.borderInput,
                              ),
                              isDense: true,
                              suffixIcon: Icon(
                                Icons.check_circle_rounded,
                                color: KeraColors.stockInText,
                                size: 20,
                              ),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'የTIN ቁጥር ያስገቡ'
                                : null,
                          ),

                          const SizedBox(height: 12),

                          // Category
                          Text(
                            'የንግድ ዘርፍ / Category',
                            style: KeraTypography.labelMedium(),
                          ),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: KeraRadii.borderInput,
                              ),
                              isDense: true,
                            ),
                            isExpanded: true,
                            items: _categories
                                .map((cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(
                                        cat,
                                        style: KeraTypography.bodySmall(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCategory = val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: KeraSpacing.lg),

                    // 3. Owner & Contact Details
                    Container(
                      padding: const EdgeInsets.all(KeraSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: KeraRadii.borderCard,
                        border: Border.all(color: KeraColors.borderVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.badge_rounded,
                                color: KeraColors.actionBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'የባለቤት እና አድራሻ መረጃ (Owner & Contact)',
                                  style: KeraTypography.titleMedium(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),

                          // Owner Name
                          Text(
                            'የባለቤት ስም (Owner Full Name) *',
                            style: KeraTypography.labelMedium(),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _ownerNameController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: KeraRadii.borderInput,
                              ),
                              isDense: true,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'የባለቤት ስም ያስገቡ'
                                : null,
                          ),

                          const SizedBox(height: 12),

                          // Primary Phone
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'ዋና ስልክ ቁጥር (Primary Phone / Telebirr) *',
                                  style: KeraTypography.labelMedium(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: KeraColors.stockInBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'የተረጋገጠ (Verified)',
                                  style: KeraTypography.labelSmall(
                                    color: KeraColors.stockInText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _primaryPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              prefixIcon: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                alignment: Alignment.centerLeft,
                                width: 80,
                                child: const Text(
                                  '🇪🇹 +251',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              border: const OutlineInputBorder(
                                borderRadius: KeraRadii.borderInput,
                              ),
                              isDense: true,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'ስልክ ቁጥር ያስገቡ'
                                : null,
                          ),

                          const SizedBox(height: 12),

                          // Alternate Phone
                          Text(
                            'ተጨማሪ ስልክ ቁጥር (Alternate Phone)',
                            style: KeraTypography.labelMedium(),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _altPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              prefixIcon: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                alignment: Alignment.centerLeft,
                                width: 80,
                                child: const Text(
                                  '🇪🇹 +251',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              border: const OutlineInputBorder(
                                borderRadius: KeraRadii.borderInput,
                              ),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: KeraSpacing.lg),

                    // 4. Store Location & Hub
                    Container(
                      padding: const EdgeInsets.all(KeraSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: KeraRadii.borderCard,
                        border: Border.all(color: KeraColors.borderVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.pin_drop_rounded,
                                color: KeraColors.actionBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'የመደብሩ አድራሻ እና መገኛ (Store Location & Hub)',
                                  style: KeraTypography.titleMedium(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),

                          // District / Zone
                          Text(
                            'ቅርንጫፍ / ዞን (District / Zone) *',
                            style: KeraTypography.labelMedium(),
                          ),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedDistrict,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: KeraRadii.borderInput,
                              ),
                              isDense: true,
                            ),
                            isExpanded: true,
                            items: _districts
                                .map((dist) => DropdownMenuItem(
                                      value: dist,
                                      child: Text(
                                        dist,
                                        style: KeraTypography.bodySmall(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedDistrict = val);
                              }
                            },
                          ),

                          const SizedBox(height: 12),

                          // Shop Number
                          Text(
                            'የመደብር / ሱቅ ቁጥር (Shop / Booth Number) *',
                            style: KeraTypography.labelMedium(),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _shopNumberController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: KeraRadii.borderInput,
                              ),
                              isDense: true,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'የሱቅ ቁጥር ያስገቡ'
                                : null,
                          ),

                          const SizedBox(height: 12),

                          // Landmark
                          Text(
                            'የጎዳና ስም እና ልዩ ቦታ (Street & Landmark)',
                            style: KeraTypography.labelMedium(),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _landmarkController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: KeraRadii.borderInput,
                              ),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: KeraSpacing.lg),

                    // 5. Receipt Customization
                    Container(
                      padding: const EdgeInsets.all(KeraSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: KeraRadii.borderCard,
                        border: Border.all(color: KeraColors.borderVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.receipt_long_rounded,
                                color: KeraColors.actionBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'የደረሰኝ እና ታክስ ቅንብር (Receipt & Tax)',
                                  style: KeraTypography.titleMedium(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),

                          Text(
                            'በደረሰኝ ላይ የሚታተም መልዕክት (Receipt Footer Note)',
                            style: KeraTypography.labelMedium(),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _receiptFooterController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: KeraRadii.borderInput,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // VAT Toggle
                          Container(
                            padding: const EdgeInsets.all(KeraSpacing.md),
                            decoration: BoxDecoration(
                              color: KeraColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: KeraColors.borderVariant),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ተጨማሪ እሴት ታክስ (VAT 15%) አሳይ',
                                        style: KeraTypography.titleSmall(),
                                      ),
                                      Text(
                                        'ለጥቃቅን ነጋዴዎች አልተገደደም (Not mandatory for small retailers)',
                                        style: KeraTypography.labelSmall(
                                          color: KeraColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _isVatRegistered,
                                  onChanged: (val) =>
                                      setState(() => _isVatRegistered = val),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: KeraSpacing.md),

                    // Quick Cloud Sync Status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: KeraColors.actionBlue.withAlpha(12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: KeraColors.actionBlue.withAlpha(30),
                        ),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.cloud_sync_rounded,
                                color: KeraColors.actionBlue,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'የመጨረሻ ማመሳሰል: ዛሬ 11:42 ጠዋት',
                                style: KeraTypography.bodySmall(
                                  color: KeraColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'ደመና ላይ ተቀምጧል',
                            style: KeraTypography.labelSmall(
                              color: KeraColors.actionBlue,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Fixed Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(KeraSpacing.lg),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: KeraColors.borderVariant),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, -3),
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
                        backgroundColor: KeraColors.actionBlue,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: KeraRadii.borderButton,
                        ),
                      ),
                      onPressed: _isSaving ? null : _saveProfile,
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: Text(
                        'ለውጦችን መዝግብ (Save Business Changes)',
                        style: KeraTypography.titleSmall(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: TextButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        }
                      },
                      child: Text(
                        'ተመለስ (Discard Changes)',
                        style: KeraTypography.bodySmall(
                          color: KeraColors.textSecondary,
                        ),
                      ),
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
}


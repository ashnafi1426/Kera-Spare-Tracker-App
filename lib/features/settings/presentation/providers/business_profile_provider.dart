import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/local/database_provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/models/business_profile.dart';

class BusinessProfileNotifier extends AsyncNotifier<BusinessProfile> {
  @override
  Future<BusinessProfile> build() async {
    final db = ref.watch(appDatabaseProvider);
    final user = ref.watch(authControllerProvider).value;

    final defaultProfile = BusinessProfile.defaultProfile(
      businessName: user?.businessName.isNotEmpty == true
          ? user!.businessName
          : 'ተስፋዬ እና ልጆቹ የጃፓን መለዋወጫ',
      phoneNumber: user?.phoneNumber.isNotEmpty == true
          ? user!.phoneNumber
          : '0911458920',
    );

    try {
      final tin = await db.settingsDao.getSetting('profile_tin_number');
      final category = await db.settingsDao.getSetting('profile_category');
      final ownerName = await db.settingsDao.getSetting('profile_owner_name');
      final altPhone = await db.settingsDao.getSetting('profile_alt_phone');
      final district = await db.settingsDao.getSetting('profile_district_zone');
      final shop = await db.settingsDao.getSetting('profile_shop_number');
      final landmark = await db.settingsDao.getSetting('profile_landmark');
      final receiptFooter = await db.settingsDao.getSetting('profile_receipt_footer');
      final vatStr = await db.settingsDao.getSetting('profile_vat_registered');
      final logoPath = await db.settingsDao.getSetting('profile_logo_path');

      return defaultProfile.copyWith(
        businessName: user?.businessName.isNotEmpty == true
            ? user!.businessName
            : defaultProfile.businessName,
        tinNumber: tin ?? defaultProfile.tinNumber,
        category: category ?? defaultProfile.category,
        ownerFullName: ownerName ?? defaultProfile.ownerFullName,
        primaryPhone: user?.phoneNumber.isNotEmpty == true
            ? user!.phoneNumber
            : defaultProfile.primaryPhone,
        alternatePhone: altPhone ?? defaultProfile.alternatePhone,
        districtZone: district ?? defaultProfile.districtZone,
        shopNumber: shop ?? defaultProfile.shopNumber,
        landmark: landmark ?? defaultProfile.landmark,
        receiptFooter: receiptFooter ?? defaultProfile.receiptFooter,
        isVatRegistered: vatStr == 'true',
        logoPath: logoPath,
      );
    } catch (_) {
      return defaultProfile;
    }
  }

  Future<void> saveProfile(BusinessProfile profile) async {
    final db = ref.read(appDatabaseProvider);
    final settingsMap = profile.toSettingsMap();

    for (final entry in settingsMap.entries) {
      await db.settingsDao.setSetting(entry.key, entry.value);
    }

    // Sync business name with auth state if updated
    final currentUser = ref.read(authControllerProvider).value;
    if (currentUser != null && currentUser.businessName != profile.businessName) {
      await ref
          .read(authControllerProvider.notifier)
          .updateBusinessName(profile.businessName);
    }

    state = AsyncValue.data(profile);
  }
}

final businessProfileProvider =
    AsyncNotifierProvider<BusinessProfileNotifier, BusinessProfile>(
  BusinessProfileNotifier.new,
);


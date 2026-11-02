/// Domain model representing the business profile of a spare parts store in Kera.
class BusinessProfile {
  final String businessName;
  final String tinNumber;
  final String category;
  final String ownerFullName;
  final String primaryPhone;
  final String alternatePhone;
  final String districtZone;
  final String shopNumber;
  final String landmark;
  final String receiptFooter;
  final bool isVatRegistered;
  final String? logoPath;

  const BusinessProfile({
    required this.businessName,
    required this.tinNumber,
    required this.category,
    required this.ownerFullName,
    required this.primaryPhone,
    this.alternatePhone = '',
    required this.districtZone,
    required this.shopNumber,
    this.landmark = '',
    this.receiptFooter = 'ለገዙን እናመሰግናለን! የተሸጡ ዕቃዎች በ3 ቀናት ውስጥ በደረሰኝ ይቀየራሉ።',
    this.isVatRegistered = false,
    this.logoPath,
  });

  factory BusinessProfile.defaultProfile({
    String businessName = 'ተስፋዬ እና ልጆቹ የጃፓን መለዋወጫ',
    String phoneNumber = '0911458920',
  }) {
    return BusinessProfile(
      businessName: businessName,
      tinNumber: 'TIN-0048192847',
      category: 'የከባድ እና አነስተኛ ተሽከርካሪ መለዋወጫ (Commercial Fleet & Light Auto Parts)',
      ownerFullName: 'አቶ ተስፋዬ ገብረመስቀል',
      primaryPhone: phoneNumber,
      alternatePhone: '0922104555',
      districtZone: 'ቂርቆስ ክፍለ ከተማ • ኬራ ዞን 4 (Kirkos Sub-City, Kera Zone 4)',
      shopNumber: 'ሱቅ ቁጥር 14 (Shop #14, Main Corridor)',
      landmark: 'ከቄራ ቄራ እርድ ቤት ፊት ለፊት፣ በገነት ሆቴል መታጠፊያ',
      receiptFooter: 'ለገዙን እናመሰግናለን! የተሸጡ ዕቃዎች በ3 ቀናት ውስጥ በደረሰኝ ይቀየራሉ። (Thank you for your business! Parts exchangeable within 3 days with receipt.)',
      isVatRegistered: false,
    );
  }

  BusinessProfile copyWith({
    String? businessName,
    String? tinNumber,
    String? category,
    String? ownerFullName,
    String? primaryPhone,
    String? alternatePhone,
    String? districtZone,
    String? shopNumber,
    String? landmark,
    String? receiptFooter,
    bool? isVatRegistered,
    String? logoPath,
  }) {
    return BusinessProfile(
      businessName: businessName ?? this.businessName,
      tinNumber: tinNumber ?? this.tinNumber,
      category: category ?? this.category,
      ownerFullName: ownerFullName ?? this.ownerFullName,
      primaryPhone: primaryPhone ?? this.primaryPhone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      districtZone: districtZone ?? this.districtZone,
      shopNumber: shopNumber ?? this.shopNumber,
      landmark: landmark ?? this.landmark,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      isVatRegistered: isVatRegistered ?? this.isVatRegistered,
      logoPath: logoPath ?? this.logoPath,
    );
  }

  Map<String, String> toSettingsMap() {
    return {
      'profile_tin_number': tinNumber,
      'profile_category': category,
      'profile_owner_name': ownerFullName,
      'profile_alt_phone': alternatePhone,
      'profile_district_zone': districtZone,
      'profile_shop_number': shopNumber,
      'profile_landmark': landmark,
      'profile_receipt_footer': receiptFooter,
      'profile_vat_registered': isVatRegistered ? 'true' : 'false',
      if (logoPath != null) 'profile_logo_path': logoPath!,
    };
  }
}


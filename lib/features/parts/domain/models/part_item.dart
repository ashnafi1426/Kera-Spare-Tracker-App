/// Domain model representing a spare part item in inventory.
/// All catalog fields are optional except identity and tenant owner ID.
class PartItem {
  final String id;
  final String ownerId;
  final String? name;
  final String? partNumber;
  final String? photoLocalPath;
  final String? photoUrl;
  final String? brandId;
  final String? brandName;
  final String? categoryId;
  final String? categoryName;
  final String? locationId;
  final String? locationName;
  final String? customLocation;
  final String? description;
  final String? unit;
  final double? purchasePrice;
  final double? sellingPrice;
  final String? sizeSpecs;
  final String? notes;
  final double? lowStockLevel;
  final double cachedQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const PartItem({
    required this.id,
    required this.ownerId,
    this.name,
    this.partNumber,
    this.photoLocalPath,
    this.photoUrl,
    this.brandId,
    this.brandName,
    this.categoryId,
    this.categoryName,
    this.locationId,
    this.locationName,
    this.customLocation,
    this.description,
    this.unit,
    this.purchasePrice,
    this.sellingPrice,
    this.sizeSpecs,
    this.notes,
    this.lowStockLevel,
    this.cachedQuantity = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  /// True if the part is not soft-deleted.
  bool get isActive => deletedAt == null;

  /// Stock status helpers.
  bool get isOutOfStock => cachedQuantity <= 0;
  bool get isLowStock =>
      !isOutOfStock &&
      ((lowStockLevel != null && cachedQuantity <= lowStockLevel!) ||
          cachedQuantity <= 5.0);
  bool get isInStock => !isOutOfStock && !isLowStock;

  /// Returns the estimated profit per unit (selling price - purchase price).
  double? get unitProfit {
    if (sellingPrice != null && purchasePrice != null) {
      return sellingPrice! - purchasePrice!;
    }
    return null;
  }

  /// Display name fallback if part name is empty.
  String get displayName {
    if (name != null && name!.trim().isNotEmpty) {
      return name!.trim();
    }
    if (partNumber != null && partNumber!.trim().isNotEmpty) {
      return partNumber!.trim();
    }
    return 'Part #$id';
  }

  PartItem copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? partNumber,
    String? photoLocalPath,
    String? photoUrl,
    String? brandId,
    String? brandName,
    String? categoryId,
    String? categoryName,
    String? locationId,
    String? locationName,
    String? customLocation,
    String? description,
    String? unit,
    double? purchasePrice,
    double? sellingPrice,
    String? sizeSpecs,
    String? notes,
    double? lowStockLevel,
    double? cachedQuantity,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return PartItem(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      partNumber: partNumber ?? this.partNumber,
      photoLocalPath: photoLocalPath ?? this.photoLocalPath,
      photoUrl: photoUrl ?? this.photoUrl,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      customLocation: customLocation ?? this.customLocation,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      sizeSpecs: sizeSpecs ?? this.sizeSpecs,
      notes: notes ?? this.notes,
      lowStockLevel: lowStockLevel ?? this.lowStockLevel,
      cachedQuantity: cachedQuantity ?? this.cachedQuantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

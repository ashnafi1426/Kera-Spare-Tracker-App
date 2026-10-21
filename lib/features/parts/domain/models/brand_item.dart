import 'picker_item.dart';

/// Domain representation of a spare part brand.
class BrandItem {
  final String id;
  final String ownerId;
  final String name;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BrandItem({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  PickerItem toPickerItem() => PickerItem(
        id: id,
        name: name,
        isDefault: isDefault,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrandItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ownerId == other.ownerId &&
          name == other.name &&
          isDefault == other.isDefault;

  @override
  int get hashCode =>
      id.hashCode ^ ownerId.hashCode ^ name.hashCode ^ isDefault.hashCode;
}

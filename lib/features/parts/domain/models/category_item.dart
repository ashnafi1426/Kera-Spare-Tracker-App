import 'picker_item.dart';

/// Domain representation of a spare part category.
class CategoryItem {
  final String id;
  final String ownerId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryItem({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  PickerItem toPickerItem() => PickerItem(
        id: id,
        name: name,
        isDefault: false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ownerId == other.ownerId &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ ownerId.hashCode ^ name.hashCode;
}

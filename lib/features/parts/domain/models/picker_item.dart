/// Generic model for bottom sheet selection pickers across the app.
class PickerItem {
  final String id;
  final String name;
  final bool isDefault;
  final String? subtitle;

  const PickerItem({
    required this.id,
    required this.name,
    this.isDefault = false,
    this.subtitle,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PickerItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          isDefault == other.isDefault;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ isDefault.hashCode;
}

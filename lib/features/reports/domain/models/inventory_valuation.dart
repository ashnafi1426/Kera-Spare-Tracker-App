/// Inventory valuation metrics (total value, low stock count, active parts).
class InventoryValuation {
  final double totalStockValue;
  final int lowStockCount;
  final int totalActiveParts;

  const InventoryValuation({
    required this.totalStockValue,
    required this.lowStockCount,
    required this.totalActiveParts,
  });

  static const zero = InventoryValuation(
    totalStockValue: 0.0,
    lowStockCount: 0,
    totalActiveParts: 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryValuation &&
          runtimeType == other.runtimeType &&
          totalStockValue == other.totalStockValue &&
          lowStockCount == other.lowStockCount &&
          totalActiveParts == other.totalActiveParts;

  @override
  int get hashCode =>
      totalStockValue.hashCode ^
      lowStockCount.hashCode ^
      totalActiveParts.hashCode;

  @override
  String toString() =>
      'InventoryValuation(value: $totalStockValue, lowStock: $lowStockCount, parts: $totalActiveParts)';
}

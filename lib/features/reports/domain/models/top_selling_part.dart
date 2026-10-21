/// Represents a top selling spare part item ranked by volume or revenue.
class TopSellingPart {
  final String partId;
  final String partName;
  final double quantitySold;
  final double totalRevenue;

  const TopSellingPart({
    required this.partId,
    required this.partName,
    required this.quantitySold,
    required this.totalRevenue,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopSellingPart &&
          runtimeType == other.runtimeType &&
          partId == other.partId &&
          partName == other.partName &&
          quantitySold == other.quantitySold &&
          totalRevenue == other.totalRevenue;

  @override
  int get hashCode =>
      partId.hashCode ^
      partName.hashCode ^
      quantitySold.hashCode ^
      totalRevenue.hashCode;

  @override
  String toString() =>
      'TopSellingPart(part: $partName, qty: $quantitySold, revenue: $totalRevenue)';
}

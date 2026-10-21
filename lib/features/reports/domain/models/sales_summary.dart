/// High-level sales aggregate summary for an owner across a date range.
class SalesSummary {
  final int salesCount;
  final double totalRevenue;
  final double totalProfit;

  const SalesSummary({
    required this.salesCount,
    required this.totalRevenue,
    required this.totalProfit,
  });

  static const zero = SalesSummary(
    salesCount: 0,
    totalRevenue: 0.0,
    totalProfit: 0.0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SalesSummary &&
          runtimeType == other.runtimeType &&
          salesCount == other.salesCount &&
          totalRevenue == other.totalRevenue &&
          totalProfit == other.totalProfit;

  @override
  int get hashCode =>
      salesCount.hashCode ^ totalRevenue.hashCode ^ totalProfit.hashCode;

  @override
  String toString() =>
      'SalesSummary(count: $salesCount, revenue: $totalRevenue, profit: $totalProfit)';
}

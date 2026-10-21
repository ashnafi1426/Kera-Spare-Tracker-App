/// Represents a bucketed data point for sales bar charts.
class ChartPoint {
  final String label;
  final DateTime date;
  final double revenue;
  final double profit;

  const ChartPoint({
    required this.label,
    required this.date,
    required this.revenue,
    required this.profit,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartPoint &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          date == other.date &&
          revenue == other.revenue &&
          profit == other.profit;

  @override
  int get hashCode =>
      label.hashCode ^ date.hashCode ^ revenue.hashCode ^ profit.hashCode;

  @override
  String toString() =>
      'ChartPoint(label: $label, revenue: $revenue, profit: $profit)';
}

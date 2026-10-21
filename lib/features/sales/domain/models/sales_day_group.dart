import 'sale_model.dart';

/// Represents a collection of sales transactions that occurred on a specific day.
class SalesDayGroup {
  final DateTime date;
  final double totalAmount;
  final List<SaleModel> sales;

  const SalesDayGroup({
    required this.date,
    required this.totalAmount,
    required this.sales,
  });

  /// Groups a flat list of sales by day (calendar day: yyyy-MM-dd) ordered descending.
  static List<SalesDayGroup> groupSales(List<SaleModel> sales) {
    if (sales.isEmpty) return [];

    final Map<String, List<SaleModel>> map = {};
    for (final sale in sales) {
      final key =
          '${sale.soldAt.year.toString().padLeft(4, '0')}-${sale.soldAt.month.toString().padLeft(2, '0')}-${sale.soldAt.day.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => []).add(sale);
    }

    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));

    return sortedKeys.map((key) {
      final daySales = map[key]!;
      final first = daySales.first.soldAt;
      final dayDate = DateTime(first.year, first.month, first.day);
      final dayTotal = daySales.fold<double>(
        0.0,
        (sum, item) => sum + item.totalAmount,
      );

      return SalesDayGroup(
        date: dayDate,
        totalAmount: dayTotal,
        sales: daySales,
      );
    }).toList();
  }
}

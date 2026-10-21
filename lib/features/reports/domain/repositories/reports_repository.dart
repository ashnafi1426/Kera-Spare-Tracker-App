import '../../../../core/utils/result.dart';
import '../models/chart_point.dart';
import '../models/date_range_filter.dart';
import '../models/inventory_valuation.dart';
import '../models/report_period.dart';
import '../models/sales_summary.dart';
import '../models/top_selling_part.dart';

/// Contract for calculating sales reports, chart analytics, and inventory valuation.
abstract class ReportsRepository {
  /// Computes overall sales summary (count, revenue, profit) for the given date range using SQL aggregation.
  Future<Result<SalesSummary>> getSalesSummary({
    required String ownerId,
    required DateRange range,
  });

  /// Computes bucketed chart points for bar chart (daily, weekly, monthly) using SQL aggregation.
  Future<Result<List<ChartPoint>>> getChartPoints({
    required String ownerId,
    required ReportPeriod period,
    DateTime? referenceTime,
  });

  /// Computes top 5 selling parts ranked by quantity sold using SQL aggregation.
  Future<Result<List<TopSellingPart>>> getTopSellingParts({
    required String ownerId,
    DateRange? range,
    int limit = 5,
  });

  /// Computes current inventory valuation (total value, low stock count, active parts) using SQL aggregation.
  Future<Result<InventoryValuation>> getInventoryValuation(String ownerId);
}

import 'package:intl/intl.dart';

import '../../../../core/utils/result.dart';
import '../../../../data/local/app_database.dart';
import '../../domain/models/chart_point.dart';
import '../../domain/models/date_range_filter.dart';
import '../../domain/models/inventory_valuation.dart';
import '../../domain/models/report_period.dart';
import '../../domain/models/sales_summary.dart';
import '../../domain/models/top_selling_part.dart';
import '../../domain/repositories/reports_repository.dart';

/// Concrete implementation of ReportsRepository backed by Drift SQLite queries.
class LocalReportsRepository implements ReportsRepository {
  final AppDatabase db;

  const LocalReportsRepository({required this.db});

  @override
  Future<Result<SalesSummary>> getSalesSummary({
    required String ownerId,
    required DateRange range,
  }) async {
    try {
      final summary = await db.salesDao.getSalesSummary(
        ownerId: ownerId,
        startDate: range.start,
        endDate: range.end,
      );
      return Result.success(summary);
    } catch (e) {
      return Result.failure(
        DatabaseFailure(message: 'Failed to aggregate sales summary: $e', cause: e),
      );
    }
  }

  @override
  Future<Result<List<ChartPoint>>> getChartPoints({
    required String ownerId,
    required ReportPeriod period,
    DateTime? referenceTime,
  }) async {
    try {
      final now = referenceTime ?? DateTime.now();
      final points = <ChartPoint>[];

      switch (period) {
        case ReportPeriod.daily:
          // Last 7 days (6 days ago through today)
          for (var i = 6; i >= 0; i--) {
            final dayDate = now.subtract(Duration(days: i));
            final start = DateTime(dayDate.year, dayDate.month, dayDate.day, 0, 0, 0, 0);
            final end = DateTime(dayDate.year, dayDate.month, dayDate.day, 23, 59, 59, 999);
            final summary = await db.salesDao.getSalesSummary(
              ownerId: ownerId,
              startDate: start,
              endDate: end,
            );
            final label = DateFormat('E').format(start);
            points.add(
              ChartPoint(
                label: label,
                date: start,
                revenue: summary.totalRevenue,
                profit: summary.totalProfit,
              ),
            );
          }
          break;

        case ReportPeriod.weekly:
          // Last 4 weeks (3 weeks ago through current week)
          for (var w = 3; w >= 0; w--) {
            final target = now.subtract(Duration(days: w * 7));
            final dayOffset = target.weekday - 1;
            final startDay = target.subtract(Duration(days: dayOffset));
            final start = DateTime(startDay.year, startDay.month, startDay.day, 0, 0, 0, 0);
            final endDay = start.add(const Duration(days: 6));
            final end = DateTime(endDay.year, endDay.month, endDay.day, 23, 59, 59, 999);
            final summary = await db.salesDao.getSalesSummary(
              ownerId: ownerId,
              startDate: start,
              endDate: end,
            );
            final label = 'W${4 - w}';
            points.add(
              ChartPoint(
                label: label,
                date: start,
                revenue: summary.totalRevenue,
                profit: summary.totalProfit,
              ),
            );
          }
          break;

        case ReportPeriod.monthly:
          // Last 6 months (5 months ago through current month)
          for (var m = 5; m >= 0; m--) {
            final targetMonth = DateTime(now.year, now.month - m, 1);
            final start = DateTime(targetMonth.year, targetMonth.month, 1, 0, 0, 0, 0);
            final end = DateTime(targetMonth.year, targetMonth.month + 1, 0, 23, 59, 59, 999);
            final summary = await db.salesDao.getSalesSummary(
              ownerId: ownerId,
              startDate: start,
              endDate: end,
            );
            final label = DateFormat('MMM').format(start);
            points.add(
              ChartPoint(
                label: label,
                date: start,
                revenue: summary.totalRevenue,
                profit: summary.totalProfit,
              ),
            );
          }
          break;
      }

      return Result.success(points);
    } catch (e) {
      return Result.failure(
        DatabaseFailure(message: 'Failed to aggregate chart points: $e', cause: e),
      );
    }
  }

  @override
  Future<Result<List<TopSellingPart>>> getTopSellingParts({
    required String ownerId,
    DateRange? range,
    int limit = 5,
  }) async {
    try {
      final topParts = await db.salesDao.getTopSellingParts(
        ownerId: ownerId,
        startDate: range?.start,
        endDate: range?.end,
        limit: limit,
      );
      return Result.success(topParts);
    } catch (e) {
      return Result.failure(
        DatabaseFailure(message: 'Failed to aggregate top selling parts: $e', cause: e),
      );
    }
  }

  @override
  Future<Result<InventoryValuation>> getInventoryValuation(String ownerId) async {
    try {
      final valuation = await db.partsDao.getInventoryValuation(ownerId);
      return Result.success(valuation);
    } catch (e) {
      return Result.failure(
        DatabaseFailure(message: 'Failed to aggregate inventory valuation: $e', cause: e),
      );
    }
  }
}

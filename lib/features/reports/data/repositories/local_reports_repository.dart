import 'package:intl/intl.dart';

import '../../../../core/errors/failure.dart';
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
          // Hourly blocks for today (06:00 to 21:00)
          final blocks = [
            {'label': '06:00', 'startH': 6, 'endH': 9},
            {'label': '09:00', 'startH': 9, 'endH': 12},
            {'label': '12:00', 'startH': 12, 'endH': 15},
            {'label': '15:00', 'startH': 15, 'endH': 18},
            {'label': '18:00', 'startH': 18, 'endH': 21},
            {'label': '21:00', 'startH': 21, 'endH': 24},
          ];
          for (final b in blocks) {
            final start = DateTime(now.year, now.month, now.day, b['startH'] as int, 0, 0, 0);
            final end = DateTime(now.year, now.month, now.day, (b['endH'] as int) - 1, 59, 59, 999);
            final summary = await db.salesDao.getSalesSummary(
              ownerId: ownerId,
              startDate: start,
              endDate: end,
            );
            points.add(
              ChartPoint(
                label: b['label'] as String,
                date: start,
                revenue: summary.totalRevenue,
                profit: summary.totalProfit,
              ),
            );
          }
          break;

        case ReportPeriod.weekly:
          // Days of current week (Mon through Sun)
          final dayOffset = now.weekday - 1;
          final monday = now.subtract(Duration(days: dayOffset));
          for (var i = 0; i < 7; i++) {
            final day = monday.add(Duration(days: i));
            final start = DateTime(day.year, day.month, day.day, 0, 0, 0, 0);
            final end = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);
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

        case ReportPeriod.monthly:
          // Weeks of current month (W1 through W5)
          final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
          for (var w = 1; w <= 5; w++) {
            final startDay = (w - 1) * 7 + 1;
            if (startDay > lastDayOfMonth) break;
            final endDay = (w * 7).clamp(1, lastDayOfMonth);
            final start = DateTime(now.year, now.month, startDay, 0, 0, 0, 0);
            final end = DateTime(now.year, now.month, endDay, 23, 59, 59, 999);
            final summary = await db.salesDao.getSalesSummary(
              ownerId: ownerId,
              startDate: start,
              endDate: end,
            );
            points.add(
              ChartPoint(
                label: 'W$w',
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

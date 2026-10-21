import 'package:flutter/material.dart';

/// Supported date range filter options for sales history and reports.
enum DateRangeType {
  today,
  thisWeek,
  thisMonth,
  custom,
}

/// Represents an inclusive start and end timestamp for date queries.
class DateRange {
  final DateTime start;
  final DateTime end;
  final DateRangeType type;

  const DateRange({
    required this.start,
    required this.end,
    required this.type,
  });

  /// Computes the exact inclusive date range for a given filter type.
  /// An optional [referenceTime] can be supplied for predictable unit testing.
  factory DateRange.forType(
    DateRangeType type, {
    DateTime? referenceTime,
    DateTimeRange? customRange,
  }) {
    final now = referenceTime ?? DateTime.now();

    switch (type) {
      case DateRangeType.today:
        final start = DateTime(now.year, now.month, now.day, 0, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return DateRange(start: start, end: end, type: type);

      case DateRangeType.thisWeek:
        // Week starts on Monday (weekday 1) and ends on Sunday (weekday 7)
        final dayOffset = now.weekday - 1;
        final startDay = now.subtract(Duration(days: dayOffset));
        final start = DateTime(startDay.year, startDay.month, startDay.day, 0, 0, 0, 0);
        final endDay = start.add(const Duration(days: 6));
        final end = DateTime(endDay.year, endDay.month, endDay.day, 23, 59, 59, 999);
        return DateRange(start: start, end: end, type: type);

      case DateRangeType.thisMonth:
        final start = DateTime(now.year, now.month, 1, 0, 0, 0, 0);
        // Day 0 of next month is the last day of current month
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        return DateRange(start: start, end: end, type: type);

      case DateRangeType.custom:
        if (customRange != null) {
          final start = DateTime(
            customRange.start.year,
            customRange.start.month,
            customRange.start.day,
            0,
            0,
            0,
            0,
          );
          final end = DateTime(
            customRange.end.year,
            customRange.end.month,
            customRange.end.day,
            23,
            59,
            59,
            999,
          );
          return DateRange(start: start, end: end, type: type);
        }
        // Fallback to today if custom range is null
        return DateRange.forType(DateRangeType.today, referenceTime: now);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end &&
          type == other.type;

  @override
  int get hashCode => start.hashCode ^ end.hashCode ^ type.hashCode;

  @override
  String toString() => 'DateRange(type: $type, start: $start, end: $end)';
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/features/reports/domain/models/date_range_filter.dart';

void main() {
  group('DateRange Calculation', () {
    // Reference: Wednesday, October 21, 2026 at 14:30:15
    final referenceWednesday = DateTime(2026, 10, 21, 14, 30, 15);

    test('today range covers 00:00:00 to 23:59:59.999 of the reference day', () {
      final range = DateRange.forType(
        DateRangeType.today,
        referenceTime: referenceWednesday,
      );

      expect(range.type, DateRangeType.today);
      expect(range.start, DateTime(2026, 10, 21, 0, 0, 0, 0));
      expect(range.end, DateTime(2026, 10, 21, 23, 59, 59, 999));
    });

    test('thisWeek range starts Monday 00:00:00 and ends Sunday 23:59:59.999', () {
      final range = DateRange.forType(
        DateRangeType.thisWeek,
        referenceTime: referenceWednesday,
      );

      expect(range.type, DateRangeType.thisWeek);
      // October 21, 2026 is Wednesday (weekday 3)
      // Monday is Oct 19, Sunday is Oct 25
      expect(range.start, DateTime(2026, 10, 19, 0, 0, 0, 0));
      expect(range.end, DateTime(2026, 10, 25, 23, 59, 59, 999));
      expect(range.start.weekday, DateTime.monday);
      expect(range.end.weekday, DateTime.sunday);
    });

    test('thisMonth range starts 1st of month and ends on the last day of month', () {
      final range = DateRange.forType(
        DateRangeType.thisMonth,
        referenceTime: referenceWednesday,
      );

      expect(range.type, DateRangeType.thisMonth);
      expect(range.start, DateTime(2026, 10, 1, 0, 0, 0, 0));
      // October has 31 days
      expect(range.end, DateTime(2026, 10, 31, 23, 59, 59, 999));
    });

    test('thisMonth handles February in leap and non-leap years', () {
      // 2024 is a leap year (Feb 29 days)
      final leapFeb = DateTime(2024, 2, 14);
      final leapRange = DateRange.forType(DateRangeType.thisMonth, referenceTime: leapFeb);
      expect(leapRange.start, DateTime(2024, 2, 1, 0, 0, 0, 0));
      expect(leapRange.end, DateTime(2024, 2, 29, 23, 59, 59, 999));

      // 2025 is not a leap year (Feb 28 days)
      final normalFeb = DateTime(2025, 2, 10);
      final normalRange = DateRange.forType(DateRangeType.thisMonth, referenceTime: normalFeb);
      expect(normalRange.start, DateTime(2025, 2, 1, 0, 0, 0, 0));
      expect(normalRange.end, DateTime(2025, 2, 28, 23, 59, 59, 999));
    });

    test('custom range covers start at 00:00:00 and end at 23:59:59.999', () {
      final custom = DateTimeRange(
        start: DateTime(2026, 9, 15, 12, 0),
        end: DateTime(2026, 9, 20, 16, 0),
      );

      final range = DateRange.forType(
        DateRangeType.custom,
        customRange: custom,
        referenceTime: referenceWednesday,
      );

      expect(range.type, DateRangeType.custom);
      expect(range.start, DateTime(2026, 9, 15, 0, 0, 0, 0));
      expect(range.end, DateTime(2026, 9, 20, 23, 59, 59, 999));
    });
  });
}

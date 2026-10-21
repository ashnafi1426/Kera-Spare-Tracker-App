import 'package:flutter_test/flutter_test.dart';
import 'package:kera_spare_tracker/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formatEtb formats monetary amounts with thousands separators and ETB prefix', () {
      expect(CurrencyFormatter.formatEtb(0), 'ETB 0.00');
      expect(CurrencyFormatter.formatEtb(0.5), 'ETB 0.50');
      expect(CurrencyFormatter.formatEtb(150), 'ETB 150.00');
      expect(CurrencyFormatter.formatEtb(1250), 'ETB 1,250.00');
      expect(CurrencyFormatter.formatEtb(1500000.75), 'ETB 1,500,000.75');
      expect(CurrencyFormatter.formatEtb(null), 'ETB 0.00');
    });

    test('formatCount formats integer counts with thousands separators', () {
      expect(CurrencyFormatter.formatCount(0), '0');
      expect(CurrencyFormatter.formatCount(42), '42');
      expect(CurrencyFormatter.formatCount(1250), '1,250');
      expect(CurrencyFormatter.formatCount(2500000), '2,500,000');
      expect(CurrencyFormatter.formatCount(null), '0');
    });

    test('formatQuantity formats quantities without unnecessary decimal zeroes', () {
      expect(CurrencyFormatter.formatQuantity(5.0), '5');
      expect(CurrencyFormatter.formatQuantity(1250.0), '1,250');
      expect(CurrencyFormatter.formatQuantity(5.5), '5.5');
      expect(CurrencyFormatter.formatQuantity(10.75), '10.75');
      expect(CurrencyFormatter.formatQuantity(null), '0');
    });
  });
}

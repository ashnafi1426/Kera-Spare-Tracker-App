import 'package:intl/intl.dart';

/// Formatter utilities for ETB currency and numbers with thousands separators.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _integerFormat = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _decimalQuantityFormat = NumberFormat('#,##0.##', 'en_US');

  /// Formats a monetary amount into ETB currency with thousands separators.
  /// Example: 1250000.5 -> "ETB 1,250,000.50"
  static String format(num? amount) => formatEtb(amount);

  static String formatEtb(num? amount) {
    if (amount == null) return 'ETB 0.00';
    return 'ETB ${_currencyFormat.format(amount)}';
  }

  /// Formats large numbers compactly: e.g. 1.2M, 45.5K, or standard number.
  static String formatCompact(num? amount) {
    if (amount == null || amount == 0) return '0';
    final val = amount.toDouble();
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(1)}K';
    }
    return val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(1);
  }

  /// Formats an integer count with thousands separators.
  /// Example: 12500 -> "12,500"
  static String formatCount(int? count) {
    if (count == null) return '0';
    return _integerFormat.format(count);
  }

  /// Formats a quantity value. Drops trailing decimals if integer.
  /// Example: 5.0 -> "5", 5.5 -> "5.5"
  static String formatQuantity(num? quantity) {
    if (quantity == null) return '0';
    if (quantity % 1 == 0) {
      return _integerFormat.format(quantity.toInt());
    }
    return _decimalQuantityFormat.format(quantity);
  }
}

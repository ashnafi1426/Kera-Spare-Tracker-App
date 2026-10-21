import 'package:intl/intl.dart';

/// Formatter utilities for ETB currency and numbers with thousands separators.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _integerFormat = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _decimalQuantityFormat = NumberFormat('#,##0.##', 'en_US');

  /// Formats a monetary amount into ETB currency with thousands separators.
  /// Example: 1250000.5 -> "ETB 1,250,000.50"
  static String formatEtb(num? amount) {
    if (amount == null) return 'ETB 0.00';
    return 'ETB ${_currencyFormat.format(amount)}';
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

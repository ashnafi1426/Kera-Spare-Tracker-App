/// Validation helpers for user input in Kera Spare Tracker.
class Validators {
  Validators._();

  /// Validates Ethiopian phone numbers.
  ///
  /// Supports formats:
  /// - 09XXXXXXXX (Ethio Telecom, 10 digits)
  /// - 07XXXXXXXX (Safaricom Ethiopia, 10 digits)
  /// - +2519XXXXXXXX / +2517XXXXXXXX
  /// - 2519XXXXXXXX / 2517XXXXXXXX
  static String? validateEthiopianPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final trimmed = value.trim().replaceAll(RegExp(r'[\s\-]'), '');

    // Pattern for Ethiopian phone numbers
    final regex = RegExp(r'^(?:\+251|251|0)?([79]\d{8})$');
    if (!regex.hasMatch(trimmed)) {
      return 'Enter a valid Ethiopian phone number (e.g. 0912345678 or 0712345678)';
    }

    return null;
  }

  /// Normalizes an Ethiopian phone number to standard E.164 format (+2519... or +2517...).
  static String normalizeEthiopianPhone(String raw) {
    final cleaned = raw.trim().replaceAll(RegExp(r'[\s\-]'), '');
    final match = RegExp(r'^(?:\+251|251|0)?([79]\d{8})$').firstMatch(cleaned);
    if (match != null) {
      return '+251${match.group(1)}';
    }
    return cleaned;
  }

  /// Validates password strength (minimum 6 characters).
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates required text fields.
  static String? validateRequired(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates positive quantity (> 0).
  static String? validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Quantity is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return 'Quantity must be greater than 0';
    }
    return null;
  }

  /// Validates price (must be >= 0).
  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return 'Price must be 0 or greater';
    }
    return null;
  }
}

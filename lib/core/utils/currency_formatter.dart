import 'package:intl/intl.dart';

/// Formats numbers to Indian numbering format (Lakhs & Crores: ₹1,42,500)
class CurrencyFormatter {
  static final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _inrWithDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Format as integer rupee: 8140 -> ₹8,140
  static String format(double amount) {
    if (amount % 1 == 0) {
      return _inrFormat.format(amount);
    }
    return _inrWithDecimals.format(amount);
  }

  /// Format raw number without currency symbol: 8140 -> 8,140
  static String formatNumber(double amount) {
    final format = NumberFormat('#,##,###.##', 'en_IN');
    return format.format(amount);
  }
}

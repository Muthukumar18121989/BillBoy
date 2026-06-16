import 'package:intl/intl.dart';

class CurrencyUtils {
  static String format(double amount, {String symbol = '₹'}) {
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    return '$symbol${formatter.format(amount)}';
  }

  static String formatCompact(double amount, {String symbol = '₹'}) {
    if (amount >= 10000000) return '$symbol${(amount / 10000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000) return '$symbol${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    return format(amount, symbol: symbol);
  }

  static double? parse(String value) {
    final cleaned = value.replaceAll(RegExp(r'[₹,\s]'), '');
    return double.tryParse(cleaned);
  }
}

import 'package:intl/intl.dart';

class AppDateUtils {
  static const String displayFormat = 'dd MMM yyyy';
  static const String apiFormat = 'yyyy-MM-dd';
  static const String fullFormat = 'dd MMM yyyy, hh:mm a';

  static String format(DateTime date, [String pattern = displayFormat]) {
    return DateFormat(pattern).format(date);
  }

  static DateTime? parse(String dateStr, [String pattern = apiFormat]) {
    try {
      return DateFormat(pattern).parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  static DateTime calculateWarrantyEnd(DateTime purchaseDate, int warrantyMonths) {
    return DateTime(
      purchaseDate.year,
      purchaseDate.month + warrantyMonths,
      purchaseDate.day,
    );
  }

  static int daysUntilExpiry(DateTime warrantyEnd) {
    return warrantyEnd.difference(DateTime.now()).inDays;
  }

  static bool isExpired(DateTime warrantyEnd) {
    return DateTime.now().isAfter(warrantyEnd);
  }

  static String relativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} years ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} months ago';
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    return 'Just now';
  }

  static String warrantyStatusLabel(DateTime warrantyEnd) {
    if (isExpired(warrantyEnd)) return 'Expired';
    final days = daysUntilExpiry(warrantyEnd);
    if (days <= 30) return 'Expiring Soon';
    return 'Active';
  }
}

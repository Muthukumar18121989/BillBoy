import 'package:flutter_test/flutter_test.dart';
import 'package:billboy/core/utils/date_utils.dart';

void main() {
  group('AppDateUtils', () {
    test('formats date in display format', () {
      final date = DateTime(2026, 1, 15);
      expect(AppDateUtils.format(date), '15 Jan 2026');
    });

    test('calculates warranty end date correctly', () {
      final purchaseDate = DateTime(2026, 1, 10);
      final warrantyEnd = AppDateUtils.calculateWarrantyEnd(purchaseDate, 24);
      expect(warrantyEnd, DateTime(2028, 1, 10));
    });

    test('calculates days until expiry correctly', () {
      final future = DateTime.now().add(const Duration(days: 30));
      final days = AppDateUtils.daysUntilExpiry(future);
      expect(days, closeTo(30, 1));
    });

    test('isExpired returns true for past date', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      expect(AppDateUtils.isExpired(past), true);
    });

    test('isExpired returns false for future date', () {
      final future = DateTime.now().add(const Duration(days: 1));
      expect(AppDateUtils.isExpired(future), false);
    });

    test('warrantyStatusLabel returns correct status', () {
      expect(AppDateUtils.warrantyStatusLabel(DateTime.now().subtract(const Duration(days: 1))), 'Expired');
      expect(AppDateUtils.warrantyStatusLabel(DateTime.now().add(const Duration(days: 15))), 'Expiring Soon');
      expect(AppDateUtils.warrantyStatusLabel(DateTime.now().add(const Duration(days: 90))), 'Active');
    });
  });
}

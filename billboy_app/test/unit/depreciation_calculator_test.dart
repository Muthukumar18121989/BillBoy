import 'package:flutter_test/flutter_test.dart';
import 'package:billboy/core/utils/depreciation_calculator.dart';

void main() {
  group('DepreciationCalculator', () {
    test('returns purchase amount for brand new item', () {
      final purchaseDate = DateTime.now();
      final result = DepreciationCalculator.calculateCurrentValue(
        purchaseAmount: 50000,
        category: 'Electronics',
        purchaseDate: purchaseDate,
      );
      expect(result, closeTo(50000, 100));
    });

    test('calculates correct depreciation after 1 year for Electronics', () {
      final purchaseDate = DateTime.now().subtract(const Duration(days: 365));
      final result = DepreciationCalculator.calculateCurrentValue(
        purchaseAmount: 100000,
        category: 'Electronics',
        purchaseDate: purchaseDate,
      );
      // 20% depreciation = 80000
      expect(result, closeTo(80000, 500));
    });

    test('calculates correct depreciation after 2 years for Mobile Phones', () {
      final purchaseDate = DateTime.now().subtract(const Duration(days: 730));
      final result = DepreciationCalculator.calculateCurrentValue(
        purchaseAmount: 60000,
        category: 'Mobile Phones',
        purchaseDate: purchaseDate,
      );
      // Year 1: 25% = 45000, Year 2: 20% more = 33000
      expect(result, closeTo(33000, 1000));
    });

    test('never returns negative value', () {
      final purchaseDate = DateTime.now().subtract(const Duration(days: 3650));
      final result = DepreciationCalculator.calculateCurrentValue(
        purchaseAmount: 1000,
        category: 'Grocery',
        purchaseDate: purchaseDate,
      );
      expect(result, greaterThanOrEqualTo(0));
    });

    test('calculates value loss correctly', () {
      final loss = DepreciationCalculator.calculateValueLoss(
        purchaseAmount: 50000,
        currentValue: 35000,
      );
      expect(loss, 15000);
    });

    test('calculates depreciation percentage correctly', () {
      final pct = DepreciationCalculator.calculateDepreciationPercentage(
        purchaseAmount: 100000,
        currentValue: 80000,
      );
      expect(pct, 20.0);
    });

    test('Jewelry depreciates minimally', () {
      final purchaseDate = DateTime.now().subtract(const Duration(days: 365));
      final result = DepreciationCalculator.calculateCurrentValue(
        purchaseAmount: 100000,
        category: 'Jewelry',
        purchaseDate: purchaseDate,
      );
      // 2% per year
      expect(result, closeTo(98000, 500));
    });
  });
}

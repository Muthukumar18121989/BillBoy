import '../constants/app_constants.dart';

class DepreciationCalculator {
  static double calculateCurrentValue({
    required double purchaseAmount,
    required String category,
    required DateTime purchaseDate,
    Map<String, List<double>>? customRules,
  }) {
    final rules = customRules ?? AppConstants.depreciationRules;
    final categoryRules = rules[category] ?? rules['Others']!;

    final now = DateTime.now();
    final yearsElapsed = now.difference(purchaseDate).inDays / 365.0;

    double currentValue = purchaseAmount;
    for (int year = 0; year < yearsElapsed.floor() && year < categoryRules.length; year++) {
      currentValue -= purchaseAmount * (categoryRules[year] / 100);
    }

    // Partial year
    final partialYear = yearsElapsed - yearsElapsed.floor();
    final yearIndex = yearsElapsed.floor().clamp(0, categoryRules.length - 1);
    if (partialYear > 0 && yearIndex < categoryRules.length) {
      currentValue -= purchaseAmount * (categoryRules[yearIndex] / 100) * partialYear;
    }

    return currentValue.clamp(0.0, purchaseAmount);
  }

  static double calculateDepreciationPercentage({
    required double purchaseAmount,
    required double currentValue,
  }) {
    if (purchaseAmount <= 0) return 0;
    return ((purchaseAmount - currentValue) / purchaseAmount) * 100;
  }

  static double calculateValueLoss({
    required double purchaseAmount,
    required double currentValue,
  }) {
    return (purchaseAmount - currentValue).clamp(0.0, purchaseAmount);
  }
}

const DEFAULT_RULES = {
  'Electronics': [20, 15, 10, 8, 5],
  'Mobile Phones': [25, 20, 15, 10, 5],
  'Laptops': [20, 18, 12, 8, 5],
  'Appliances': [15, 12, 10, 8, 5],
  'Furniture': [10, 8, 6, 5, 4],
  'Fashion': [30, 20, 15, 10, 5],
  'Jewelry': [2, 2, 2, 2, 2],
  'Vehicles': [15, 12, 10, 8, 6],
  'Home Equipment': [12, 10, 8, 6, 5],
  'Insurance': [0, 0, 0, 0, 0],
  'Healthcare': [20, 15, 10, 8, 5],
  'Grocery': [100, 0, 0, 0, 0],
  'Subscription Services': [100, 0, 0, 0, 0],
  'Others': [15, 12, 10, 8, 5],
};

class DepreciationService {
  calculateCurrentValue(purchaseAmount, category, purchaseDate, customRules = null) {
    const rules = customRules?.[category] || DEFAULT_RULES[category] || DEFAULT_RULES['Others'];
    const amount = parseFloat(purchaseAmount);
    const now = new Date();
    const yearsElapsed = (now - purchaseDate) / (1000 * 60 * 60 * 24 * 365.25);

    let currentValue = amount;
    for (let year = 0; year < Math.floor(yearsElapsed) && year < rules.length; year++) {
      currentValue -= amount * (rules[year] / 100);
    }

    // Partial year
    const partialYear = yearsElapsed - Math.floor(yearsElapsed);
    const yearIndex = Math.min(Math.floor(yearsElapsed), rules.length - 1);
    if (partialYear > 0 && yearIndex < rules.length) {
      currentValue -= amount * (rules[yearIndex] / 100) * partialYear;
    }

    return Math.max(0, Math.round(currentValue * 100) / 100);
  }

  calculateDepreciationPercentage(purchaseAmount, currentValue) {
    if (purchaseAmount <= 0) return 0;
    return Math.round(((purchaseAmount - currentValue) / purchaseAmount) * 100 * 100) / 100;
  }

  getDefaultRules() {
    return DEFAULT_RULES;
  }
}

module.exports = new DepreciationService();

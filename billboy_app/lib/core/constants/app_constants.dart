class AppConstants {
  static const String appName = 'BillBoy';
  static const String appTagline = 'Never lose a bill. Never miss a warranty.';
  static const String appVersion = '1.0.0';

  // API
  static const String baseUrl = 'https://api.billboy.app/v1';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String onboardingKey = 'onboarding_complete';
  static const String columnPrefsKey = 'column_preferences';

  // Hive Boxes
  static const String billsBox = 'bills_box';
  static const String userBox = 'user_box';
  static const String settingsBox = 'settings_box';
  static const String ocrCacheBox = 'ocr_cache_box';

  // Pagination
  static const int pageSize = 20;

  // Warranty Reminder Days
  static const List<int> warrantyReminderDays = [90, 60, 30, 15, 7, 1];

  // File Limits
  static const int maxImageSizeMb = 10;
  static const int maxPdfSizeMb = 20;

  // OCR
  static const int ocrTimeoutSeconds = 30;

  // Depreciation Rules (% per year)
  static const Map<String, List<double>> depreciationRules = {
    'Electronics': [20.0, 15.0, 10.0, 8.0, 5.0],
    'Mobile Phones': [25.0, 20.0, 15.0, 10.0, 5.0],
    'Laptops': [20.0, 18.0, 12.0, 8.0, 5.0],
    'Appliances': [15.0, 12.0, 10.0, 8.0, 5.0],
    'Furniture': [10.0, 8.0, 6.0, 5.0, 4.0],
    'Fashion': [30.0, 20.0, 15.0, 10.0, 5.0],
    'Jewelry': [2.0, 2.0, 2.0, 2.0, 2.0],
    'Vehicles': [15.0, 12.0, 10.0, 8.0, 6.0],
    'Home Equipment': [12.0, 10.0, 8.0, 6.0, 5.0],
    'Insurance': [0.0, 0.0, 0.0, 0.0, 0.0],
    'Healthcare': [20.0, 15.0, 10.0, 8.0, 5.0],
    'Grocery': [100.0, 0.0, 0.0, 0.0, 0.0],
    'Subscription Services': [100.0, 0.0, 0.0, 0.0, 0.0],
    'Others': [15.0, 12.0, 10.0, 8.0, 5.0],
  };

  static const List<String> categories = [
    'Electronics',
    'Mobile Phones',
    'Laptops',
    'Appliances',
    'Furniture',
    'Fashion',
    'Jewelry',
    'Vehicles',
    'Home Equipment',
    'Insurance',
    'Healthcare',
    'Grocery',
    'Subscription Services',
    'Others',
  ];

  // Dashboard Columns
  static const List<String> dashboardColumns = [
    'Product Name',
    'Category',
    'Purchase Date',
    'Bill Number',
    'Warranty Period',
    'Warranty End Date',
    'Purchase Amount',
    'Current Value',
    'Serial Number',
    'GST Number',
    'Store Name',
    'Status',
    'Attachment',
  ];
}

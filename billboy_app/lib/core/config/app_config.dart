import 'package:flutter/foundation.dart';
import 'environment.dart';

class AppConfig {
  // AdMob IDs — test IDs for dev/staging, real IDs for production
  static String get adMobBannerUnitId {
    if (Environment.isProduction) {
      // Replace with real Ad Unit ID from AdMob console before release
      return const String.fromEnvironment('ADMOB_BANNER_ID', defaultValue: 'ca-app-pub-PLACEHOLDER/PLACEHOLDER');
    }
    // Google's official test banner ID
    return 'ca-app-pub-3940256099942544/6300978111';
  }

  static String get adMobInterstitialUnitId {
    if (Environment.isProduction) {
      return const String.fromEnvironment('ADMOB_INTERSTITIAL_ID', defaultValue: 'ca-app-pub-PLACEHOLDER/PLACEHOLDER');
    }
    // Google's official test interstitial ID
    return 'ca-app-pub-3940256099942544/1033173712';
  }

  // Google Play subscription product IDs
  static const String subscriptionMonthlyId = 'billboy_pro_monthly';
  static const String subscriptionAnnualId = 'billboy_pro_annual';

  // Free tier limits
  static const int freeBillLimit = 50;
  static const int trialDurationDays = 7;

  // Feature flags (local defaults — overridden by Firebase Remote Config)
  static bool get adsEnabled => !kDebugMode || Environment.isProduction;
  static bool get subscriptionEnabled => true;
  static bool get ocrEnabled => false; // Stubbed until ML Kit re-enabled
}

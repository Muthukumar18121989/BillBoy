import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/app_config.dart';
import 'entitlement_service.dart';

class AdMobService {
  final EntitlementService _entitlementService;

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  AdMobService(this._entitlementService);

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    debugPrint('AdMobService: initialized');
  }

  /// Returns true only when the user is on the free tier and ads are enabled.
  bool get shouldShowAds => _entitlementService.shouldShowAds();

  /// Load a banner ad. Call this before showing the banner widget.
  Future<void> loadBanner({
    required void Function() onLoaded,
    void Function(LoadAdError)? onFailed,
  }) async {
    if (!shouldShowAds) return;

    _bannerAd = BannerAd(
      adUnitId: AppConfig.adMobBannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _isBannerLoaded = true;
          onLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
          _isBannerLoaded = false;
          onFailed?.call(error);
          debugPrint('AdMobService: banner failed: $error');
        },
      ),
    );

    await _bannerAd!.load();
  }

  BannerAd? get bannerAd => _isBannerLoaded ? _bannerAd : null;

  void disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerLoaded = false;
  }
}

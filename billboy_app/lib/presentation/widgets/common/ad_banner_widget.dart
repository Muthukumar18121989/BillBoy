import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/services/admob_service.dart';

/// Shows a banner ad for free-tier users only.
/// Renders nothing for Trial/Pro users — the AdMobService gates this.
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  final _adMobService = sl<AdMobService>();
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    if (_adMobService.shouldShowAds) {
      _adMobService.loadBanner(
        onLoaded: () {
          if (mounted) setState(() => _isLoaded = true);
        },
      );
    }
  }

  @override
  void dispose() {
    _adMobService.disposeBanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _adMobService.bannerAd;
    if (!_isLoaded || ad == null) return const SizedBox.shrink();

    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}

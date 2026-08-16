import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../config/app_config.dart';

/// Wraps in_app_purchase. Purchase validation (receipt → Firestore subscription)
/// is handled server-side by a Firebase Cloud Function that listens to
/// Google Play Real-Time Developer Notifications. This class only initiates
/// the purchase flow and surfaces results to the UI.
class PurchaseService {
  static final _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  static const Set<String> _productIds = {
    AppConfig.subscriptionMonthlyId,
    AppConfig.subscriptionAnnualId,
  };

  /// Must be called once at app startup (after DI init).
  Future<void> initialize() async {
    final available = await _iap.isAvailable();
    if (!available) {
      debugPrint('PurchaseService: Store not available');
      return;
    }

    _purchaseSubscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (error) => debugPrint('PurchaseService stream error: $error'),
    );
  }

  /// Load product details from the Play Store.
  Future<List<ProductDetails>> loadProducts() async {
    final response = await _iap.queryProductDetails(_productIds);
    if (response.error != null) {
      debugPrint('PurchaseService: product query error: ${response.error}');
    }
    return response.productDetails;
  }

  /// Initiate a subscription purchase for the given [productId].
  Future<bool> purchase(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Restore previously purchased subscriptions (required by Play Store policy).
  Future<void> restorePurchases() => _iap.restorePurchases();

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Complete the purchase on the client.
        // The server-side Cloud Function handles Firestore subscription update
        // via Google Play RTDN — no client-side Firestore write needed.
        _iap.completePurchase(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('PurchaseService: purchase error: ${purchase.error}');
      }
    }
  }

  void dispose() {
    _purchaseSubscription?.cancel();
  }
}

import '../../domain/entities/subscription_entity.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../config/app_config.dart';

class EntitlementService {
  final SubscriptionRepository _repository;

  SubscriptionEntity? _cached;

  EntitlementService(this._repository);

  void updateCache(SubscriptionEntity subscription) {
    _cached = subscription;
  }

  /// Returns true if the user can add another bill.
  Future<bool> canAddBill(String userId) async {
    final sub = _cached;
    if (sub != null && sub.hasUnlimitedAccess) return true;

    // Re-fetch to ensure fresh state (not manipulable on client)
    final subResult = await _repository.getSubscription(userId);
    final subscription = subResult.fold((_) => null, (s) => s);
    if (subscription == null) return false;

    _cached = subscription;
    if (subscription.hasUnlimitedAccess) return true;

    // Free tier: check bill count
    final countResult = await _repository.getBillCount(userId);
    return countResult.fold(
      (_) => false,
      (count) => count < AppConfig.freeBillLimit,
    );
  }

  /// Returns true if ads should be shown to this user.
  bool shouldShowAds() {
    final sub = _cached;
    if (sub == null) return AppConfig.adsEnabled;
    return AppConfig.adsEnabled && !sub.hasUnlimitedAccess;
  }

  bool get hasUnlimitedAccess => _cached?.hasUnlimitedAccess ?? false;
  bool get isTrialActive => _cached?.isTrialActive ?? false;
  bool get isPro => _cached?.isPro ?? false;
  int? get trialDaysRemaining => _cached?.trialDaysRemaining;
}

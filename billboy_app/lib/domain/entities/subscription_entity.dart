enum SubscriptionPlan { free, trial, pro }

enum SubscriptionStatus { active, expired, cancelled, paused }

class SubscriptionEntity {
  final String userId;
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime? trialStart;
  final DateTime? trialEnd;
  final DateTime? currentPeriodEnd;
  final String? googlePlayToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubscriptionEntity({
    required this.userId,
    required this.plan,
    required this.status,
    this.trialStart,
    this.trialEnd,
    this.currentPeriodEnd,
    this.googlePlayToken,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isTrialActive =>
      plan == SubscriptionPlan.trial &&
      status == SubscriptionStatus.active &&
      trialEnd != null &&
      DateTime.now().isBefore(trialEnd!);

  bool get isPro =>
      plan == SubscriptionPlan.pro && status == SubscriptionStatus.active;

  bool get hasUnlimitedAccess => isTrialActive || isPro;

  int? get trialDaysRemaining {
    if (trialEnd == null) return null;
    final remaining = trialEnd!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }
}

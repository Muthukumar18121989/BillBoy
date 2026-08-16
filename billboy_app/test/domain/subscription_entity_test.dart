import 'package:flutter_test/flutter_test.dart';
import 'package:billboy/domain/entities/subscription_entity.dart';

void main() {
  group('SubscriptionEntity', () {
    test('isTrialActive returns true when trial is in the future', () {
      final sub = SubscriptionEntity(
        userId: 'u1',
        plan: SubscriptionPlan.trial,
        status: SubscriptionStatus.active,
        trialEnd: DateTime.now().add(const Duration(days: 3)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(sub.isTrialActive, isTrue);
    });

    test('isTrialActive returns false when trialEnd is in the past', () {
      final sub = SubscriptionEntity(
        userId: 'u1',
        plan: SubscriptionPlan.trial,
        status: SubscriptionStatus.active,
        trialEnd: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(sub.isTrialActive, isFalse);
    });

    test('isPro returns true for active pro plan', () {
      final sub = SubscriptionEntity(
        userId: 'u1',
        plan: SubscriptionPlan.pro,
        status: SubscriptionStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(sub.isPro, isTrue);
    });

    test('isPro returns false for cancelled pro plan', () {
      final sub = SubscriptionEntity(
        userId: 'u1',
        plan: SubscriptionPlan.pro,
        status: SubscriptionStatus.cancelled,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(sub.isPro, isFalse);
    });

    test('hasUnlimitedAccess is true for active trial', () {
      final sub = SubscriptionEntity(
        userId: 'u1',
        plan: SubscriptionPlan.trial,
        status: SubscriptionStatus.active,
        trialEnd: DateTime.now().add(const Duration(days: 5)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(sub.hasUnlimitedAccess, isTrue);
    });

    test('trialDaysRemaining calculates correctly', () {
      final sub = SubscriptionEntity(
        userId: 'u1',
        plan: SubscriptionPlan.trial,
        status: SubscriptionStatus.active,
        trialEnd: DateTime.now().add(const Duration(days: 5)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(sub.trialDaysRemaining, inInclusiveRange(4, 5));
    });
  });
}

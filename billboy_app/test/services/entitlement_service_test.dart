import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:billboy/core/services/entitlement_service.dart';
import 'package:billboy/core/utils/either.dart';
import 'package:billboy/domain/entities/subscription_entity.dart';
import 'package:billboy/domain/repositories/subscription_repository.dart';

class MockSubscriptionRepository extends Mock implements SubscriptionRepository {}

SubscriptionEntity _makeSub({
  SubscriptionPlan plan = SubscriptionPlan.free,
  SubscriptionStatus status = SubscriptionStatus.active,
  DateTime? trialEnd,
}) {
  final now = DateTime.now();
  return SubscriptionEntity(
    userId: 'user-1',
    plan: plan,
    status: status,
    trialEnd: trialEnd,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late MockSubscriptionRepository repo;
  late EntitlementService service;

  setUp(() {
    repo = MockSubscriptionRepository();
    service = EntitlementService(repo);
  });

  group('EntitlementService', () {
    test('free user under 50 bills can add a bill', () async {
      service.updateCache(_makeSub());
      when(() => repo.getSubscription('user-1'))
          .thenAnswer((_) async => Right(_makeSub()));
      when(() => repo.getBillCount('user-1'))
          .thenAnswer((_) async => const Right(10));

      expect(await service.canAddBill('user-1'), isTrue);
    });

    test('free user at 50 bills cannot add a bill', () async {
      service.updateCache(_makeSub());
      when(() => repo.getSubscription('user-1'))
          .thenAnswer((_) async => Right(_makeSub()));
      when(() => repo.getBillCount('user-1'))
          .thenAnswer((_) async => const Right(50));

      expect(await service.canAddBill('user-1'), isFalse);
    });

    test('pro user can always add a bill without checking count', () async {
      service.updateCache(_makeSub(plan: SubscriptionPlan.pro));

      // getBillCount should NOT be called for pro users
      verifyNever(() => repo.getBillCount(any()));

      expect(await service.canAddBill('user-1'), isTrue);
    });

    test('active trial user can add a bill', () async {
      final trialEnd = DateTime.now().add(const Duration(days: 3));
      service.updateCache(_makeSub(plan: SubscriptionPlan.trial, trialEnd: trialEnd));

      expect(await service.canAddBill('user-1'), isTrue);
    });

    test('expired trial user is treated as free', () async {
      final trialEnd = DateTime.now().subtract(const Duration(days: 1));
      final expiredSub = _makeSub(plan: SubscriptionPlan.trial, trialEnd: trialEnd);
      service.updateCache(expiredSub);
      when(() => repo.getSubscription('user-1'))
          .thenAnswer((_) async => Right(expiredSub));
      when(() => repo.getBillCount('user-1'))
          .thenAnswer((_) async => const Right(50));

      expect(await service.canAddBill('user-1'), isFalse);
    });

    test('shouldShowAds returns false for pro user regardless of debug mode', () {
      // Pro users never see ads, even if adsEnabled flag is on
      service.updateCache(_makeSub(plan: SubscriptionPlan.pro));
      expect(service.shouldShowAds(), isFalse);
    });

    test('shouldShowAds returns false for active trial user', () {
      final trialEnd = DateTime.now().add(const Duration(days: 3));
      service.updateCache(_makeSub(plan: SubscriptionPlan.trial, trialEnd: trialEnd));
      expect(service.shouldShowAds(), isFalse);
    });
  });
}

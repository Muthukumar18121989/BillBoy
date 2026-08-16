import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:billboy/core/errors/failures.dart';
import 'package:billboy/core/services/entitlement_service.dart';
import 'package:billboy/core/utils/either.dart';
import 'package:billboy/domain/entities/subscription_entity.dart';
import 'package:billboy/domain/repositories/subscription_repository.dart';
import 'package:billboy/presentation/blocs/subscription/subscription_bloc.dart';
import 'package:billboy/presentation/blocs/subscription/subscription_event.dart';
import 'package:billboy/presentation/blocs/subscription/subscription_state.dart';

class MockSubscriptionRepository extends Mock implements SubscriptionRepository {}
class MockEntitlementService extends Mock implements EntitlementService {}

SubscriptionEntity _makeSub({
  SubscriptionPlan plan = SubscriptionPlan.free,
  SubscriptionStatus status = SubscriptionStatus.active,
}) {
  final now = DateTime.now();
  return SubscriptionEntity(
    userId: 'user-1',
    plan: plan,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late MockSubscriptionRepository repo;
  late MockEntitlementService entitlement;

  setUpAll(() {
    registerFallbackValue(SubscriptionEntity(
      userId: 'fallback',
      plan: SubscriptionPlan.free,
      status: SubscriptionStatus.active,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ));
  });

  setUp(() {
    repo = MockSubscriptionRepository();
    entitlement = MockEntitlementService();
    when(() => entitlement.updateCache(any())).thenReturn(null);
    when(() => repo.watchSubscription(any())).thenAnswer((_) => const Stream.empty());
  });

  group('SubscriptionBloc', () {
    blocTest<SubscriptionBloc, SubscriptionState>(
      'emits [Loading, Loaded] when subscription fetch succeeds',
      build: () {
        when(() => repo.getSubscription('user-1'))
            .thenAnswer((_) async => Right(_makeSub()));
        return SubscriptionBloc(repo, entitlement);
      },
      act: (bloc) => bloc.add(const SubscriptionLoadEvent('user-1')),
      expect: () => [
        isA<SubscriptionLoadingState>(),
        isA<SubscriptionLoadedState>(),
      ],
    );

    blocTest<SubscriptionBloc, SubscriptionState>(
      'emits [Loading, Error] when subscription fetch fails',
      build: () {
        when(() => repo.getSubscription('user-1'))
            .thenAnswer((_) async => Left(ServerFailure('Network error')));
        return SubscriptionBloc(repo, entitlement);
      },
      act: (bloc) => bloc.add(const SubscriptionLoadEvent('user-1')),
      expect: () => [
        isA<SubscriptionLoadingState>(),
        isA<SubscriptionErrorState>(),
      ],
    );

    blocTest<SubscriptionBloc, SubscriptionState>(
      'loaded subscription has correct plan on Pro',
      build: () {
        when(() => repo.getSubscription('user-1'))
            .thenAnswer((_) async => Right(_makeSub(plan: SubscriptionPlan.pro)));
        return SubscriptionBloc(repo, entitlement);
      },
      act: (bloc) => bloc.add(const SubscriptionLoadEvent('user-1')),
      verify: (bloc) {
        final state = bloc.state as SubscriptionLoadedState;
        expect(state.subscription.plan, SubscriptionPlan.pro);
        expect(state.subscription.isPro, isTrue);
      },
    );
  });
}

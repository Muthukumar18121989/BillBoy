import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/subscription_entity.dart';
import '../../../domain/repositories/subscription_repository.dart';
import '../../../core/services/entitlement_service.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionRepository _repository;
  final EntitlementService _entitlementService;
  StreamSubscription<SubscriptionEntity>? _subscription;

  SubscriptionBloc(this._repository, this._entitlementService)
      : super(SubscriptionInitialState()) {
    on<SubscriptionLoadEvent>(_onLoad);
    on<SubscriptionWatchEvent>(_onWatch);
    on<SubscriptionUpdatedEvent>(_onUpdated);
  }

  Future<void> _onLoad(SubscriptionLoadEvent event, Emitter<SubscriptionState> emit) async {
    emit(SubscriptionLoadingState());
    final result = await _repository.getSubscription(event.userId);
    result.fold(
      (failure) => emit(SubscriptionErrorState(failure.message)),
      (sub) {
        _entitlementService.updateCache(sub);
        emit(SubscriptionLoadedState(sub));
      },
    );
  }

  Future<void> _onWatch(SubscriptionWatchEvent event, Emitter<SubscriptionState> emit) async {
    await _subscription?.cancel();
    _subscription = _repository.watchSubscription(event.userId).listen(
      (sub) => add(SubscriptionUpdatedEvent(sub)),
    );
  }

  Future<void> _onUpdated(SubscriptionUpdatedEvent event, Emitter<SubscriptionState> emit) async {
    final sub = event.subscription as SubscriptionEntity;
    _entitlementService.updateCache(sub);
    emit(SubscriptionLoadedState(sub));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

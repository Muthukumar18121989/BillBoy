import 'package:equatable/equatable.dart';
import '../../../domain/entities/subscription_entity.dart';

abstract class SubscriptionState extends Equatable {
  const SubscriptionState();
  @override
  List<Object?> get props => [];
}

class SubscriptionInitialState extends SubscriptionState {}

class SubscriptionLoadingState extends SubscriptionState {}

class SubscriptionLoadedState extends SubscriptionState {
  final SubscriptionEntity subscription;
  const SubscriptionLoadedState(this.subscription);
  @override
  List<Object?> get props => [subscription];
}

class SubscriptionErrorState extends SubscriptionState {
  final String message;
  const SubscriptionErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();
  @override
  List<Object?> get props => [];
}

class SubscriptionLoadEvent extends SubscriptionEvent {
  final String userId;
  const SubscriptionLoadEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}

class SubscriptionWatchEvent extends SubscriptionEvent {
  final String userId;
  const SubscriptionWatchEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}

class SubscriptionUpdatedEvent extends SubscriptionEvent {
  // Fired internally when the stream emits a new value
  final dynamic subscription;
  const SubscriptionUpdatedEvent(this.subscription);
  @override
  List<Object?> get props => [subscription];
}

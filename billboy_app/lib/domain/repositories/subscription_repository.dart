import '../entities/subscription_entity.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';

abstract class SubscriptionRepository {
  /// Fetch the current user's subscription. Returns a default Free subscription
  /// if none exists in Firestore yet.
  Future<Either<Failure, SubscriptionEntity>> getSubscription(String userId);

  /// Stream live subscription updates so the UI reacts instantly.
  Stream<SubscriptionEntity> watchSubscription(String userId);

  /// Count bills for a user — used to enforce the 50-bill free limit.
  Future<Either<Failure, int>> getBillCount(String userId);
}

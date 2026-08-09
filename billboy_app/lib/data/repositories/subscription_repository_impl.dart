import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/remote/subscription_remote_datasource.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource _remote;

  SubscriptionRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, SubscriptionEntity>> getSubscription(String userId) async {
    try {
      final result = await _remote.getSubscription(userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Failed to load subscription: $e'));
    }
  }

  @override
  Stream<SubscriptionEntity> watchSubscription(String userId) =>
      _remote.watchSubscription(userId);

  @override
  Future<Either<Failure, int>> getBillCount(String userId) async {
    try {
      final count = await _remote.getBillCount(userId);
      return Right(count);
    } catch (e) {
      return Left(ServerFailure('Failed to count bills: $e'));
    }
  }
}

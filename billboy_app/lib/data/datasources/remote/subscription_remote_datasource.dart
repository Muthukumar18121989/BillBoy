import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/subscription_entity.dart';
import '../../models/subscription_model.dart';

abstract class SubscriptionRemoteDataSource {
  Future<SubscriptionModel> getSubscription(String userId);
  Stream<SubscriptionModel> watchSubscription(String userId);
  Future<int> getBillCount(String userId);
}

class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  final FirebaseFirestore _firestore;

  SubscriptionRemoteDataSourceImpl(this._firestore);

  @override
  Future<SubscriptionModel> getSubscription(String userId) async {
    final doc = await _firestore.collection('subscriptions').doc(userId).get();
    if (!doc.exists) return SubscriptionModel.defaultFree(userId);
    return SubscriptionModel.fromFirestore(doc);
  }

  @override
  Stream<SubscriptionModel> watchSubscription(String userId) {
    return _firestore
        .collection('subscriptions')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists
            ? SubscriptionModel.fromFirestore(doc)
            : SubscriptionModel.defaultFree(userId));
  }

  @override
  Future<int> getBillCount(String userId) async {
    // Use count() aggregation — does not download documents
    final snapshot = await _firestore
        .collection('bills')
        .where('userId', isEqualTo: userId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/subscription_entity.dart';

class SubscriptionModel extends SubscriptionEntity {
  const SubscriptionModel({
    required super.userId,
    required super.plan,
    required super.status,
    super.trialStart,
    super.trialEnd,
    super.currentPeriodEnd,
    super.googlePlayToken,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionModel(
      userId: doc.id,
      plan: _parsePlan(data['plan'] as String? ?? 'free'),
      status: _parseStatus(data['status'] as String? ?? 'active'),
      trialStart: (data['trialStart'] as Timestamp?)?.toDate(),
      trialEnd: (data['trialEnd'] as Timestamp?)?.toDate(),
      currentPeriodEnd: (data['currentPeriodEnd'] as Timestamp?)?.toDate(),
      googlePlayToken: data['googlePlayToken'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Default Free subscription — returned when no Firestore document exists yet.
  factory SubscriptionModel.defaultFree(String userId) {
    final now = DateTime.now();
    return SubscriptionModel(
      userId: userId,
      plan: SubscriptionPlan.free,
      status: SubscriptionStatus.active,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'plan': plan.name,
        'status': status.name,
        'trialStart': trialStart != null ? Timestamp.fromDate(trialStart!) : null,
        'trialEnd': trialEnd != null ? Timestamp.fromDate(trialEnd!) : null,
        'currentPeriodEnd': currentPeriodEnd != null ? Timestamp.fromDate(currentPeriodEnd!) : null,
        'googlePlayToken': googlePlayToken,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static SubscriptionPlan _parsePlan(String value) {
    return SubscriptionPlan.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SubscriptionPlan.free,
    );
  }

  static SubscriptionStatus _parseStatus(String value) {
    return SubscriptionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SubscriptionStatus.active,
    );
  }
}

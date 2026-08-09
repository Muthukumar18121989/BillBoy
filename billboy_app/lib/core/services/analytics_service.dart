import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logLogin(String method) =>
      _analytics.logLogin(loginMethod: method);

  Future<void> logSignUp(String method) =>
      _analytics.logSignUp(signUpMethod: method);

  Future<void> logBillCreated(String category) =>
      _analytics.logEvent(name: 'bill_created', parameters: {'category': category});

  Future<void> logBillDeleted() =>
      _analytics.logEvent(name: 'bill_deleted');

  Future<void> logSubscriptionStarted(String planId) =>
      _analytics.logEvent(name: 'subscription_started', parameters: {'plan_id': planId});

  Future<void> logPaywallViewed(String trigger) =>
      _analytics.logEvent(name: 'paywall_viewed', parameters: {'trigger': trigger});

  Future<void> logTrialStarted() =>
      _analytics.logEvent(name: 'trial_started');

  Future<void> logTrialExpired() =>
      _analytics.logEvent(name: 'trial_expired');

  Future<void> setUserId(String userId) =>
      _analytics.setUserId(id: userId);

  Future<void> setUserProperty({required String name, required String value}) =>
      _analytics.setUserProperty(name: name, value: value);
}

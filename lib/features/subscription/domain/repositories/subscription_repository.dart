import '../entities/subscription_entitlement.dart';

abstract interface class SubscriptionRepository {
  Future<SubscriptionEntitlement> getCurrentEntitlement();
}

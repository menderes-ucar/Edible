import '../entities/purchase_option.dart';
import '../entities/subscription_entitlement.dart';

abstract interface class PurchaseRepository {
  Stream<SubscriptionEntitlement> get entitlementChanges;

  Future<SubscriptionEntitlement?> identify(String userId);
  Future<void> logOut();

  Future<List<PurchaseOption>> getOptions();

  Future<SubscriptionEntitlement> purchase(
    String packageIdentifier,
  );

  Future<SubscriptionEntitlement> restore();
}

import '../../domain/entities/purchase_option.dart';
import '../../domain/entities/subscription_entitlement.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../services/revenuecat_service.dart';

class PurchaseRepositoryImpl implements PurchaseRepository {
  PurchaseRepositoryImpl({
    required RevenueCatService revenueCatService,
  }) : _revenueCatService = revenueCatService;

  final RevenueCatService _revenueCatService;

  @override
  Stream<SubscriptionEntitlement> get entitlementChanges =>
      _revenueCatService.entitlementChanges;

  @override
  Future<SubscriptionEntitlement?> identify(String userId) {
    return _revenueCatService.identify(userId);
  }

  @override
  Future<void> logOut() {
    return _revenueCatService.logOut();
  }

  @override
  Future<List<PurchaseOption>> getOptions() {
    return _revenueCatService.getPurchaseOptions();
  }

  @override
  Future<SubscriptionEntitlement> purchase(
    String packageIdentifier,
  ) {
    return _revenueCatService.purchase(packageIdentifier);
  }

  @override
  Future<SubscriptionEntitlement> restore() {
    return _revenueCatService.restore();
  }
}

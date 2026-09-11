import '../../domain/entities/subscription_entitlement.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_remote_data_source.dart';
import '../services/revenuecat_service.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl({
    required SubscriptionRemoteDataSource remoteDataSource,
    required RevenueCatService revenueCatService,
  })  : _remoteDataSource = remoteDataSource,
        _revenueCatService = revenueCatService;

  final SubscriptionRemoteDataSource _remoteDataSource;
  final RevenueCatService _revenueCatService;

  @override
  Future<SubscriptionEntitlement> getCurrentEntitlement() async {
    try {
      final revenueCat = await _revenueCatService.currentEntitlement();

      if (revenueCat != null) {
        return revenueCat;
      }
    } catch (_) {
      // Supabase remains the server-side fallback.
    }

    try {
      return await _remoteDataSource.getCurrentEntitlement();
    } catch (_) {
      return SubscriptionEntitlement.free;
    }
  }
}

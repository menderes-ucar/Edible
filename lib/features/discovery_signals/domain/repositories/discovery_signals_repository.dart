import '../entities/discovery_affinity.dart';
import '../entities/content_exposure.dart';
import '../entities/discovery_event.dart';

abstract interface class DiscoverySignalsRepository {
  Future<void> record(DiscoveryEvent event);

  Future<List<DiscoveryAffinity>> loadAffinities({int days = 90});

  Future<List<ContentExposure>> loadContentExposure({
    int days = 90,
    int limit = 500,
  });
}

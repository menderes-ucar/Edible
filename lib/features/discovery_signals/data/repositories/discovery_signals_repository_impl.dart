import '../../domain/entities/discovery_affinity.dart';
import '../../domain/entities/content_exposure.dart';
import '../../domain/entities/discovery_event.dart';
import '../../domain/repositories/discovery_signals_repository.dart';
import '../datasources/discovery_signals_remote_datasource.dart';

class DiscoverySignalsRepositoryImpl implements DiscoverySignalsRepository {
  const DiscoverySignalsRepositoryImpl(this._remote);

  final DiscoverySignalsRemoteDataSource _remote;

  @override
  Future<void> record(DiscoveryEvent event) => _remote.record(event);

  @override
  Future<List<DiscoveryAffinity>> loadAffinities({int days = 90}) {
    return _remote.loadAffinities(days: days);
  }

  @override
  Future<List<ContentExposure>> loadContentExposure({
    int days = 90,
    int limit = 500,
  }) {
    return _remote.loadContentExposure(days: days, limit: limit);
  }
}

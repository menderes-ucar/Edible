import '../../domain/entities/day_route.dart';
import '../../domain/entities/saved_trip_itinerary.dart';
import '../../domain/repositories/day_route_repository.dart';
import '../datasources/day_route_remote_data_source.dart';

class DayRouteRepositoryImpl implements DayRouteRepository {
  const DayRouteRepositoryImpl({
    required DayRouteRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final DayRouteRemoteDataSource _remoteDataSource;

  @override
  Future<DayRoute> getWalkingRoute(
    List<SavedTripItineraryStop> orderedStops,
  ) {
    return _remoteDataSource.getWalkingRoute(orderedStops);
  }
}

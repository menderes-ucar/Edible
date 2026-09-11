import '../entities/day_route.dart';
import '../entities/saved_trip_itinerary.dart';

abstract interface class DayRouteRepository {
  Future<DayRoute> getWalkingRoute(
    List<SavedTripItineraryStop> orderedStops,
  );
}

import '../entities/saved_trip_itinerary.dart';

class DayRouteCoordinatePolicy {
  const DayRouteCoordinatePolicy._();

  static bool hasEnoughStops(
    List<SavedTripItineraryStop> stops,
  ) {
    return stops.length >= 2;
  }

  static bool hasVerifiedExactCoordinates(
    List<SavedTripItineraryStop> stops,
  ) {
    return hasEnoughStops(stops) &&
        stops.every(
          (stop) => stop.content.metadata.hasExactCoordinates,
        );
  }
}

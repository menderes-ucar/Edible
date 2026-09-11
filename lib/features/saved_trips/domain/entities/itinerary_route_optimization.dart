import 'saved_trip_itinerary.dart';

class ItineraryRouteOptimization {
  const ItineraryRouteOptimization({
    required this.orderedStops,
    required this.distanceBeforeMeters,
    required this.distanceAfterMeters,
  });

  final List<SavedTripItineraryStop> orderedStops;
  final double distanceBeforeMeters;
  final double distanceAfterMeters;

  double get savedMeters =>
      (distanceBeforeMeters - distanceAfterMeters).clamp(
        0,
        double.infinity,
      );

  double get improvementPercent {
    if (distanceBeforeMeters <= 0) return 0;

    return ((distanceBeforeMeters - distanceAfterMeters) /
            distanceBeforeMeters *
            100)
        .clamp(0, 100);
  }
}

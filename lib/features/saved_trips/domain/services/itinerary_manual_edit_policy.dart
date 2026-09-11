import '../usecases/generate_saved_trip_itinerary.dart';

class ItineraryManualEditPolicy {
  const ItineraryManualEditPolicy._();

  static bool canMoveIntoDay({
    required int targetStopCount,
    required bool movingWithinSameDay,
  }) {
    if (movingWithinSameDay) return true;
    return targetStopCount < GenerateSavedTripItinerary.maxStopsPerDay;
  }

  static int adjustedMinute({
    required int currentMinute,
    required int deltaMinutes,
  }) {
    return (currentMinute + deltaMinutes).clamp(360, 1320).toInt();
  }

  static bool wouldChangeTime({
    required int currentMinute,
    required int deltaMinutes,
  }) {
    return adjustedMinute(
          currentMinute: currentMinute,
          deltaMinutes: deltaMinutes,
        ) !=
        currentMinute;
  }
}

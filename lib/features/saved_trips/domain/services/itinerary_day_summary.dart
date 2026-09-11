import '../entities/saved_trip_itinerary.dart';

class ItineraryDaySummary {
  const ItineraryDaySummary({required this.dayIndex, required this.stopCount});
  final int dayIndex;
  final int stopCount;
  bool get isFreeDay => stopCount == 0;
}

class ItineraryDaySummaryBuilder {
  const ItineraryDaySummaryBuilder._();

  static List<ItineraryDaySummary> build({
    required int dayCount,
    required Iterable<SavedTripItineraryStop> stops,
  }) {
    if (dayCount <= 0) return const [];
    final counts = List<int>.filled(dayCount, 0);
    for (final stop in stops) {
      if (stop.dayIndex < 0 || stop.dayIndex >= dayCount) continue;
      counts[stop.dayIndex]++;
    }
    return List<ItineraryDaySummary>.unmodifiable(
      List.generate(
        dayCount,
        (index) => ItineraryDaySummary(
          dayIndex: index,
          stopCount: counts[index],
        ),
      ),
    );
  }
}

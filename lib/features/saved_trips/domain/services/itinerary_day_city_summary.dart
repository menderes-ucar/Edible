import '../entities/saved_trip_itinerary.dart';

class ItineraryDayCitySummary {
  const ItineraryDayCitySummary({
    required this.cityName,
    required this.stopCount,
  });

  final String cityName;
  final int stopCount;
}

class ItineraryDayCitySummaryBuilder {
  const ItineraryDayCitySummaryBuilder._();

  static List<ItineraryDayCitySummary> build(
    Iterable<SavedTripItineraryStop> stops,
  ) {
    final counts = <String, int>{};
    final labels = <String, String>{};

    for (final stop in stops) {
      final city = stop.content.cityName.trim();
      if (city.isEmpty) continue;
      final key = city.toLowerCase();
      labels.putIfAbsent(key, () => city);
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return labels[a.key]!.toLowerCase().compareTo(
              labels[b.key]!.toLowerCase(),
            );
      });

    return List<ItineraryDayCitySummary>.unmodifiable(
      entries.map(
        (entry) => ItineraryDayCitySummary(
          cityName: labels[entry.key]!,
          stopCount: entry.value,
        ),
      ),
    );
  }
}

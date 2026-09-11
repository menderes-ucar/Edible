import '../../../explore/domain/entities/explore_content.dart';
import '../entities/saved_trip_itinerary.dart';

class CountryPlanCitySummary {
  const CountryPlanCitySummary({
    required this.cityName,
    required this.availableCount,
    required this.savedCount,
    required this.scheduledCount,
    required this.plannedDayCount,
  });

  final String cityName;
  final int availableCount;
  final int savedCount;
  final int scheduledCount;
  final int plannedDayCount;

  bool get hasSavedDiscoveries => savedCount > 0;
}

class CountryPlanCitySummaryBuilder {
  const CountryPlanCitySummaryBuilder._();

  static List<CountryPlanCitySummary> build({
    required Iterable<ExploreContent> destinationContents,
    required Iterable<String> savedContentIds,
    required Iterable<SavedTripItineraryStop> itineraryStops,
  }) {
    final savedIds = savedContentIds.toSet();
    final stops = itineraryStops.toList(growable: false);
    final byCity = <String, List<ExploreContent>>{};

    for (final content in destinationContents) {
      final city = content.cityName.trim();
      if (city.isEmpty) continue;
      byCity.putIfAbsent(city, () => <ExploreContent>[]).add(content);
    }

    final summaries = <CountryPlanCitySummary>[];
    for (final entry in byCity.entries) {
      final contentIds = entry.value.map((item) => item.id).toSet();
      final savedInCity = contentIds.intersection(savedIds);
      final cityStops = stops
          .where((stop) => contentIds.contains(stop.contentId))
          .toList(growable: false);

      summaries.add(
        CountryPlanCitySummary(
          cityName: entry.key,
          availableCount: contentIds.length,
          savedCount: savedInCity.length,
          scheduledCount: cityStops.map((stop) => stop.contentId).toSet().length,
          plannedDayCount: cityStops.map((stop) => stop.dayIndex).toSet().length,
        ),
      );
    }

    summaries.sort((a, b) {
      final saved = b.savedCount.compareTo(a.savedCount);
      if (saved != 0) return saved;
      final scheduled = b.scheduledCount.compareTo(a.scheduledCount);
      if (scheduled != 0) return scheduled;
      return a.cityName.toLowerCase().compareTo(b.cityName.toLowerCase());
    });

    return List<CountryPlanCitySummary>.unmodifiable(summaries);
  }
}

import '../../../explore/domain/entities/explore_content.dart';
import '../entities/saved_trip_itinerary.dart';

enum VacationDiscoveryPlanFilter {
  all,
  saved,
  unscheduled,
}

class VacationDiscoveryPlanFilterPolicy {
  const VacationDiscoveryPlanFilterPolicy._();

  static List<ExploreContent> apply({
    required Iterable<ExploreContent> contents,
    required Iterable<String> savedContentIds,
    required Iterable<SavedTripItineraryStop> itineraryStops,
    required VacationDiscoveryPlanFilter filter,
  }) {
    if (filter == VacationDiscoveryPlanFilter.all) {
      return List<ExploreContent>.unmodifiable(contents);
    }

    final savedIds = savedContentIds.toSet();
    final scheduledIds = itineraryStops
        .map((stop) => stop.contentId)
        .toSet();

    return List<ExploreContent>.unmodifiable(
      contents.where((item) {
        final saved = savedIds.contains(item.id);
        switch (filter) {
          case VacationDiscoveryPlanFilter.all:
            return true;
          case VacationDiscoveryPlanFilter.saved:
            return saved;
          case VacationDiscoveryPlanFilter.unscheduled:
            return saved && !scheduledIds.contains(item.id);
        }
      }),
    );
  }
}

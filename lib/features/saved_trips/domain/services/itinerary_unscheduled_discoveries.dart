import '../../../explore/domain/entities/explore_content.dart';
import '../entities/saved_trip_itinerary.dart';

class ItineraryUnscheduledDiscoveries {
  const ItineraryUnscheduledDiscoveries._();

  static List<ExploreContent> build({
    required Iterable<ExploreContent> destinationContents,
    required Iterable<String> savedContentIds,
    required Iterable<SavedTripItineraryStop> itineraryStops,
  }) {
    final savedIds = savedContentIds.toSet();
    final scheduledIds =
        itineraryStops.map((stop) => stop.contentId).toSet();

    final seen = <String>{};
    return List<ExploreContent>.unmodifiable(
      destinationContents.where((content) {
        if (!seen.add(content.id)) return false;
        return savedIds.contains(content.id) &&
            !scheduledIds.contains(content.id);
      }),
    );
  }
}

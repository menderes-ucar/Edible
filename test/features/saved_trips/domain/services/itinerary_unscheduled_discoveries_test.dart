import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/explore/domain/entities/explore_category.dart';
import 'package:edible/features/explore/domain/entities/explore_content.dart';
import 'package:edible/features/explore/domain/entities/explore_metadata.dart';
import 'package:edible/features/saved_trips/domain/entities/saved_trip_itinerary.dart';
import 'package:edible/features/saved_trips/domain/services/itinerary_unscheduled_discoveries.dart';

void main() {
  test('returns saved discoveries missing from persisted itinerary', () {
    final result = ItineraryUnscheduledDiscoveries.build(
      destinationContents: [_content('a'), _content('b'), _content('c')],
      savedContentIds: const ['a', 'b'],
      itineraryStops: [_stop('a')],
    );
    expect(result.map((item) => item.id), ['b']);
  });

  test('does not expose discoveries that are not saved to the trip', () {
    final result = ItineraryUnscheduledDiscoveries.build(
      destinationContents: [_content('a')],
      savedContentIds: const [],
      itineraryStops: const [],
    );
    expect(result, isEmpty);
  });

  test('deduplicates repeated catalog ids', () {
    final result = ItineraryUnscheduledDiscoveries.build(
      destinationContents: [_content('a'), _content('a')],
      savedContentIds: const ['a'],
      itineraryStops: const [],
    );
    expect(result, hasLength(1));
  });
}

ExploreContent _content(String id) => ExploreContent(
  id: id, countryCode: 'IT', countryName: 'Italy', cityName: 'Rome',
  category: ExploreCategory.place, title: id, shortDescription: '',
  description: '', latitude: 1, longitude: 1, tags: const [],
  metadata: const ExploreMetadata(), galleryImageUrls: const [],
);

SavedTripItineraryStop _stop(String id) => SavedTripItineraryStop(
  id: 'stop-$id', tripId: 'trip', contentId: id, dayIndex: 0,
  startMinute: 600, sortOrder: 0, content: _content(id),
);

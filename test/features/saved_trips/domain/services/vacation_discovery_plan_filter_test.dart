import 'package:flutter_test/flutter_test.dart';

import 'package:edible/features/explore/domain/entities/explore_category.dart';
import 'package:edible/features/explore/domain/entities/explore_content.dart';
import 'package:edible/features/explore/domain/entities/explore_metadata.dart';
import 'package:edible/features/saved_trips/domain/entities/saved_trip_itinerary.dart';
import 'package:edible/features/saved_trips/domain/services/vacation_discovery_plan_filter.dart';

void main() {
  final contents = [
    _content('saved-scheduled'),
    _content('saved-open'),
    _content('not-saved'),
  ];

  test('all keeps the complete discovery view', () {
    final result = VacationDiscoveryPlanFilterPolicy.apply(
      contents: contents,
      savedContentIds: const ['saved-scheduled', 'saved-open'],
      itineraryStops: [_stop('saved-scheduled')],
      filter: VacationDiscoveryPlanFilter.all,
    );
    expect(result, hasLength(3));
  });

  test('saved returns only discoveries saved to the vacation', () {
    final result = VacationDiscoveryPlanFilterPolicy.apply(
      contents: contents,
      savedContentIds: const ['saved-scheduled', 'saved-open'],
      itineraryStops: [_stop('saved-scheduled')],
      filter: VacationDiscoveryPlanFilter.saved,
    );
    expect(
      result.map((item) => item.id).toSet(),
      {'saved-scheduled', 'saved-open'},
    );
  });

  test('unscheduled returns saved discoveries missing from itinerary', () {
    final result = VacationDiscoveryPlanFilterPolicy.apply(
      contents: contents,
      savedContentIds: const ['saved-scheduled', 'saved-open'],
      itineraryStops: [_stop('saved-scheduled')],
      filter: VacationDiscoveryPlanFilter.unscheduled,
    );
    expect(result.map((item) => item.id), ['saved-open']);
  });
}

ExploreContent _content(String id) => ExploreContent(
      id: id,
      countryCode: 'IT',
      countryName: 'Italy',
      cityName: 'Rome',
      category: ExploreCategory.place,
      title: id,
      shortDescription: '',
      description: '',
      latitude: 1,
      longitude: 1,
      tags: const [],
      metadata: const ExploreMetadata(),
      galleryImageUrls: const [],
    );

SavedTripItineraryStop _stop(String id) => SavedTripItineraryStop(
      id: 'stop-$id',
      tripId: 'trip',
      contentId: id,
      dayIndex: 0,
      startMinute: 600,
      sortOrder: 0,
      content: _content(id),
    );

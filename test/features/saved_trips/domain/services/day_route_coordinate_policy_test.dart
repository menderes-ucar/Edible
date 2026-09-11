import 'package:flutter_test/flutter_test.dart';

import 'package:edible/features/explore/domain/entities/explore_category.dart';
import 'package:edible/features/explore/domain/entities/explore_content.dart';
import 'package:edible/features/explore/domain/entities/explore_metadata.dart';
import 'package:edible/features/saved_trips/domain/entities/saved_trip_itinerary.dart';
import 'package:edible/features/saved_trips/domain/services/day_route_coordinate_policy.dart';

void main() {
  test('route needs at least two stops', () {
    expect(
      DayRouteCoordinatePolicy.hasEnoughStops([_stop('1', exact: true)]),
      isFalse,
    );
  });

  test('all stops must have exact coordinates', () {
    expect(
      DayRouteCoordinatePolicy.hasVerifiedExactCoordinates([
        _stop('1', exact: true),
        _stop('2', exact: true),
      ]),
      isTrue,
    );

    expect(
      DayRouteCoordinatePolicy.hasVerifiedExactCoordinates([
        _stop('1', exact: true),
        _stop('2', exact: false),
      ]),
      isFalse,
    );
  });
}

SavedTripItineraryStop _stop(
  String id, {
  required bool exact,
}) {
  final content = ExploreContent(
    id: id,
    countryCode: 'IT',
    countryName: 'Italy',
    cityName: 'Rome',
    category: ExploreCategory.place,
    title: id,
    shortDescription: '',
    description: '',
    latitude: 41.9,
    longitude: 12.5,
    tags: const [],
    metadata: ExploreMetadata(
      coordinatePrecision: exact ? 'exact' : 'city_area',
    ),
    galleryImageUrls: const [],
  );

  return SavedTripItineraryStop(
    id: 'stop-$id',
    tripId: 'trip',
    contentId: id,
    dayIndex: 0,
    startMinute: 600,
    sortOrder: 0,
    content: content,
  );
}

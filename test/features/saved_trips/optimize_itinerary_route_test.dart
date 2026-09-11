import 'package:edible/features/explore/domain/entities/explore_category.dart';
import 'package:edible/features/explore/domain/entities/explore_content.dart';
import 'package:edible/features/explore/domain/entities/explore_metadata.dart';
import 'package:edible/features/saved_trips/domain/entities/saved_trip_itinerary.dart';
import 'package:edible/features/saved_trips/domain/usecases/optimize_itinerary_route.dart';
import 'package:flutter_test/flutter_test.dart';

SavedTripItineraryStop stop(
  String id,
  double latitude,
  double longitude,
  int order,
) {
  return SavedTripItineraryStop(
    id: id,
    tripId: 'trip',
    contentId: id,
    dayIndex: 0,
    startMinute: 570 + order * 90,
    sortOrder: order,
    content: ExploreContent(
      id: id,
      countryCode: 'JP',
      countryName: 'Japan',
      cityName: 'Tokyo',
      category: ExploreCategory.place,
      title: id,
      shortDescription: '',
      description: '',
      latitude: latitude,
      longitude: longitude,
      tags: const [],
      metadata: const ExploreMetadata(),
      galleryImageUrls: const [],
    ),
  );
}

void main() {
  test('optimizer never returns a route longer than the original', () {
    const optimizer = OptimizeItineraryRoute();

    final result = optimizer([
      stop('a', 35.68, 139.70, 0),
      stop('d', 35.74, 139.80, 1),
      stop('b', 35.69, 139.71, 2),
      stop('c', 35.70, 139.72, 3),
    ]);

    expect(
      result.distanceAfterMeters,
      lessThanOrEqualTo(result.distanceBeforeMeters),
    );
    expect(result.orderedStops.first.id, 'a');
  });
}

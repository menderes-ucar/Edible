import 'package:flutter_test/flutter_test.dart';

import 'package:edible/features/explore/domain/entities/explore_category.dart';
import 'package:edible/features/explore/domain/entities/explore_content.dart';
import 'package:edible/features/explore/domain/entities/explore_metadata.dart';
import 'package:edible/features/saved_trips/domain/entities/saved_trip_itinerary.dart';
import 'package:edible/features/saved_trips/domain/services/itinerary_day_city_summary.dart';

void main() {
  test('groups country-wide itinerary stops by city', () {
    final result = ItineraryDayCitySummaryBuilder.build([
      _stop('a', 'Rome'),
      _stop('b', 'Rome'),
      _stop('c', 'Florence'),
    ]);

    expect(result.map((item) => item.cityName), ['Rome', 'Florence']);
    expect(result.map((item) => item.stopCount), [2, 1]);
  });

  test('city grouping is case insensitive and keeps a stable label', () {
    final result = ItineraryDayCitySummaryBuilder.build([
      _stop('a', 'Rome'),
      _stop('b', 'rome'),
    ]);

    expect(result, hasLength(1));
    expect(result.single.cityName, 'Rome');
    expect(result.single.stopCount, 2);
  });

  test('blank city metadata is ignored instead of rendering empty chips', () {
    final result = ItineraryDayCitySummaryBuilder.build([
      _stop('a', ''),
      _stop('b', 'Milan'),
    ]);

    expect(result, hasLength(1));
    expect(result.single.cityName, 'Milan');
  });
}

SavedTripItineraryStop _stop(String id, String city) =>
    SavedTripItineraryStop(
      id: 'stop-$id',
      tripId: 'trip',
      contentId: id,
      dayIndex: 0,
      startMinute: 600,
      sortOrder: 0,
      content: ExploreContent(
        id: id,
        countryCode: 'IT',
        countryName: 'Italy',
        cityName: city,
        category: ExploreCategory.place,
        title: id,
        shortDescription: '',
        description: '',
        latitude: 1,
        longitude: 1,
        tags: const [],
        metadata: const ExploreMetadata(),
        galleryImageUrls: const [],
      ),
    );

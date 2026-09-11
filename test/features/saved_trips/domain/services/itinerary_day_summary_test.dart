import 'package:flutter_test/flutter_test.dart';

import 'package:edible/features/explore/domain/entities/explore_category.dart';
import 'package:edible/features/explore/domain/entities/explore_content.dart';
import 'package:edible/features/explore/domain/entities/explore_metadata.dart';
import 'package:edible/features/saved_trips/domain/entities/saved_trip_itinerary.dart';
import 'package:edible/features/saved_trips/domain/services/itinerary_day_summary.dart';

void main() {
  test('builds a summary for every vacation day including free days', () {
    final result = ItineraryDaySummaryBuilder.build(
      dayCount: 4,
      stops: [_stop('a', 0), _stop('b', 0), _stop('c', 2)],
    );

    expect(result.map((item) => item.stopCount), [2, 0, 1, 0]);
    expect(result[1].isFreeDay, isTrue);
    expect(result[2].isFreeDay, isFalse);
  });

  test('ignores persisted stops outside current trip day bounds', () {
    final result = ItineraryDaySummaryBuilder.build(
      dayCount: 2,
      stops: [_stop('valid', 1), _stop('legacy', 5)],
    );

    expect(result.map((item) => item.stopCount), [0, 1]);
  });

  test('non-positive day count produces no navigation entries', () {
    expect(
      ItineraryDaySummaryBuilder.build(dayCount: 0, stops: const []),
      isEmpty,
    );
  });
}

SavedTripItineraryStop _stop(String id, int dayIndex) =>
    SavedTripItineraryStop(
      id: 'stop-$id',
      tripId: 'trip',
      contentId: id,
      dayIndex: dayIndex,
      startMinute: 600,
      sortOrder: 0,
      content: ExploreContent(
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
      ),
    );

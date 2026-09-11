import 'package:flutter_test/flutter_test.dart';

import 'package:edible/features/explore/domain/entities/explore_category.dart';
import 'package:edible/features/explore/domain/entities/explore_content.dart';
import 'package:edible/features/explore/domain/entities/explore_metadata.dart';
import 'package:edible/features/saved_trips/domain/entities/saved_trip_itinerary.dart';
import 'package:edible/features/saved_trips/domain/services/country_plan_city_summary.dart';

void main() {
  test('groups country-wide discoveries by city', () {
    final result = CountryPlanCitySummaryBuilder.build(
      destinationContents: [
        _content('rome-a', 'Rome'),
        _content('rome-b', 'Rome'),
        _content('milan-a', 'Milan'),
      ],
      savedContentIds: const ['rome-a', 'milan-a'],
      itineraryStops: [_stop('rome-a', 'Rome', 0)],
    );

    final rome = result.firstWhere((item) => item.cityName == 'Rome');
    final milan = result.firstWhere((item) => item.cityName == 'Milan');

    expect(rome.availableCount, 2);
    expect(rome.savedCount, 1);
    expect(rome.scheduledCount, 1);
    expect(rome.plannedDayCount, 1);
    expect(milan.savedCount, 1);
    expect(milan.scheduledCount, 0);
  });

  test('cities with saved discoveries sort before untouched cities', () {
    final result = CountryPlanCitySummaryBuilder.build(
      destinationContents: [
        _content('rome', 'Rome'),
        _content('milan', 'Milan'),
      ],
      savedContentIds: const ['milan'],
      itineraryStops: const [],
    );

    expect(result.first.cityName, 'Milan');
  });

  test('duplicate catalog ids do not inflate available counts', () {
    final result = CountryPlanCitySummaryBuilder.build(
      destinationContents: [
        _content('rome', 'Rome'),
        _content('rome', 'Rome'),
      ],
      savedContentIds: const [],
      itineraryStops: const [],
    );

    expect(result.single.availableCount, 1);
  });
}

ExploreContent _content(String id, String city) {
  return ExploreContent(
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
  );
}

SavedTripItineraryStop _stop(String id, String city, int day) {
  return SavedTripItineraryStop(
    id: 'stop-$id',
    tripId: 'trip',
    contentId: id,
    dayIndex: day,
    startMinute: 600,
    sortOrder: 0,
    content: _content(id, city),
  );
}

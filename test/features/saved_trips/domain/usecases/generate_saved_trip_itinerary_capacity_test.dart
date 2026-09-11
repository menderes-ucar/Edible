import 'package:flutter_test/flutter_test.dart';

import 'package:edible/features/explore/domain/entities/explore_category.dart';
import 'package:edible/features/explore/domain/entities/explore_content.dart';
import 'package:edible/features/explore/domain/entities/explore_metadata.dart';
import 'package:edible/features/saved_trips/domain/entities/saved_trip.dart';
import 'package:edible/features/saved_trips/domain/usecases/generate_saved_trip_itinerary.dart';

void main() {
  const generator = GenerateSavedTripItinerary();

  test('rejects oversized itinerary instead of silently creating impossible times', () {
    final trip = _trip(days: 1);
    final contents = [
      for (var i = 0; i < GenerateSavedTripItinerary.maxStopsPerDay + 1; i++)
        _content('place-$i'),
    ];

    expect(
      () => generator(trip: trip, selectedContents: contents),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'itinerary_capacity_exceeded:6',
        ),
      ),
    );
  });

  test('generated days never exceed the daily stop capacity', () {
    final trip = _trip(days: 3);
    final contents = [
      for (var i = 0; i < 18; i++) _content('place-$i'),
    ];

    final result = generator(
      trip: trip,
      selectedContents: contents,
    );

    for (var day = 0; day < 3; day++) {
      expect(
        result.where((stop) => stop.dayIndex == day).length,
        lessThanOrEqualTo(GenerateSavedTripItinerary.maxStopsPerDay),
      );
    }
  });
}

SavedTrip _trip({required int days}) {
  final start = DateTime(2026, 9, 10);
  return SavedTrip(
    id: 'trip',
    name: 'Rome',
    countryCode: 'IT',
    countryName: 'Italy',
    cityName: 'Rome',
    startDate: start,
    endDate: start.add(Duration(days: days - 1)),
    notes: '',
    contentIds: const [],
    createdAt: start,
    updatedAt: start,
  );
}

ExploreContent _content(String id) {
  return ExploreContent(
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
    metadata: const ExploreMetadata(),
    galleryImageUrls: const [],
  );
}

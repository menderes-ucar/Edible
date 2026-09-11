import 'package:flutter_test/flutter_test.dart';

import 'package:edible/features/explore/domain/entities/explore_category.dart';
import 'package:edible/features/explore/domain/entities/explore_content.dart';
import 'package:edible/features/explore/domain/entities/explore_metadata.dart';
import 'package:edible/features/saved_trips/domain/entities/saved_trip.dart';
import 'package:edible/features/saved_trips/domain/usecases/generate_saved_trip_itinerary.dart';

void main() {
  const generator = GenerateSavedTripItinerary();

  test('city trip rejects cross-country and cross-city content', () {
    final trip = _trip(countryCode: 'IT', cityName: 'Rome', days: 3);

    final result = generator(
      trip: trip,
      selectedContents: [
        _content('rome', 'IT', 'Rome'),
        _content('milan', 'IT', 'Milan'),
        _content('paris', 'FR', 'Paris'),
      ],
    );

    expect(result.map((e) => e.contentId), ['rome']);
  });

  test('country-wide trip accepts cities in country but rejects other countries', () {
    final trip = _trip(countryCode: 'IT', cityName: '', days: 2);

    final result = generator(
      trip: trip,
      selectedContents: [
        _content('rome', 'IT', 'Rome'),
        _content('milan', 'IT', 'Milan'),
        _content('paris', 'FR', 'Paris'),
      ],
    );

    expect(result.map((e) => e.contentId).toSet(), {'rome', 'milan'});
  });

  test('duplicate catalog ids produce only one itinerary stop', () {
    final trip = _trip(countryCode: 'IT', cityName: 'Rome', days: 2);

    final result = generator(
      trip: trip,
      selectedContents: [
        _content('colosseum', 'IT', 'Rome'),
        _content('colosseum', 'IT', 'Rome'),
      ],
    );

    expect(result.where((e) => e.contentId == 'colosseum'), hasLength(1));
  });

  test('country-wide overflow cities are balanced instead of dumped into last day', () {
    final trip = _trip(countryCode: 'IT', cityName: '', days: 3);

    final result = generator(
      trip: trip,
      selectedContents: [
        for (var i = 0; i < 3; i++) _content('rome-$i', 'IT', 'Rome'),
        for (var i = 0; i < 3; i++) _content('milan-$i', 'IT', 'Milan'),
        for (var i = 0; i < 3; i++) _content('florence-$i', 'IT', 'Florence'),
        for (var i = 0; i < 3; i++) _content('venice-$i', 'IT', 'Venice'),
        for (var i = 0; i < 3; i++) _content('naples-$i', 'IT', 'Naples'),
      ],
    );

    final counts = List<int>.filled(3, 0);
    for (final stop in result) {
      counts[stop.dayIndex]++;
    }

    expect(counts.reduce((a, b) => a > b ? a : b), lessThanOrEqualTo(6));
    expect(counts.every((count) => count > 0), isTrue);
  });
}

SavedTrip _trip({
  required String countryCode,
  required String cityName,
  required int days,
}) {
  final start = DateTime(2026, 9, 10);
  return SavedTrip(
    id: 'trip',
    name: 'Vacation',
    countryCode: countryCode,
    countryName: countryCode == 'IT' ? 'Italy' : countryCode,
    cityName: cityName,
    startDate: start,
    endDate: start.add(Duration(days: days - 1)),
    notes: '',
    contentIds: const [],
    createdAt: start,
    updatedAt: start,
  );
}

ExploreContent _content(
  String id,
  String countryCode,
  String cityName,
) {
  return ExploreContent(
    id: id,
    countryCode: countryCode,
    countryName: countryCode == 'IT' ? 'Italy' : 'France',
    cityName: cityName,
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

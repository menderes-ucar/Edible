import 'package:flutter_test/flutter_test.dart';

import 'package:edible/features/explore/domain/entities/explore_category.dart';
import 'package:edible/features/explore/domain/entities/explore_content.dart';
import 'package:edible/features/explore/domain/entities/explore_metadata.dart';
import 'package:edible/features/saved_trips/domain/entities/saved_trip.dart';
import 'package:edible/features/saved_trips/domain/usecases/generate_saved_trip_itinerary.dart';

void main() {
  const generator = GenerateSavedTripItinerary();

  test('generated stops stay inside trip days and persistence time range', () {
    final trip = _trip(cityName: 'Rome', days: 5);
    final items = List.generate(
      12,
      (index) => _content(
        id: '00000000-0000-0000-0000-${index.toString().padLeft(12, '0')}',
        city: 'Rome',
        category: index.isEven
            ? ExploreCategory.place
            : ExploreCategory.food,
      ),
    );

    final stops = generator(
      trip: trip,
      selectedContents: items,
    );

    expect(stops, hasLength(items.length));
    expect(stops.every((stop) => stop.dayIndex >= 0), isTrue);
    expect(stops.every((stop) => stop.dayIndex < trip.dayCount), isTrue);
    expect(stops.every((stop) => stop.startMinute >= 0), isTrue);
    expect(stops.every((stop) => stop.startMinute <= 1439), isTrue);
  });

  test('country-wide plans keep same-city discoveries grouped when possible', () {
    final trip = _trip(cityName: '', days: 4);
    final items = [
      _content(id: '1', city: 'Rome', category: ExploreCategory.place),
      _content(id: '2', city: 'Rome', category: ExploreCategory.food),
      _content(id: '3', city: 'Milan', category: ExploreCategory.place),
      _content(id: '4', city: 'Milan', category: ExploreCategory.food),
    ];

    final stops = generator(
      trip: trip,
      selectedContents: items,
    );

    final cityById = {for (final item in items) item.id: item.cityName};
    final citiesPerDay = <int, Set<String>>{};
    for (final stop in stops) {
      citiesPerDay
          .putIfAbsent(stop.dayIndex, () => <String>{})
          .add(cityById[stop.contentId]!);
    }

    expect(
      citiesPerDay.values.every((cities) => cities.length <= 1),
      isTrue,
    );
  });
}

SavedTrip _trip({
  required String cityName,
  required int days,
}) {
  final start = DateTime(2026, 10, 1);
  return SavedTrip(
    id: 'trip',
    name: 'Trip',
    countryCode: 'IT',
    countryName: 'Italy',
    cityName: cityName,
    startDate: start,
    endDate: start.add(Duration(days: days - 1)),
    notes: '',
    contentIds: const [],
    createdAt: start,
    updatedAt: start,
  );
}

ExploreContent _content({
  required String id,
  required String city,
  required ExploreCategory category,
}) {
  return ExploreContent(
    id: id,
    countryCode: 'IT',
    countryName: 'Italy',
    cityName: city,
    category: category,
    title: '$city $id',
    shortDescription: 'Short',
    description: 'Long',
    latitude: 0,
    longitude: 0,
    tags: const [],
    metadata: const ExploreMetadata(),
    galleryImageUrls: const [],
  );
}

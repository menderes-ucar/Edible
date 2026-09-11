import 'package:flutter_test/flutter_test.dart';

import 'package:edible/features/explore/domain/entities/explore_category.dart';
import 'package:edible/features/explore/domain/entities/explore_content.dart';
import 'package:edible/features/explore/domain/entities/explore_metadata.dart';
import 'package:edible/features/saved_trips/domain/entities/saved_trip_itinerary.dart';
import 'package:edible/features/saved_trips/domain/services/vacation_category_progress.dart';

void main() {
  test('counts saved and scheduled discoveries per category', () {
    final result = VacationCategoryProgressBuilder.build(
      contents: [
        _content('place-a', ExploreCategory.place),
        _content('place-b', ExploreCategory.place),
        _content('food-a', ExploreCategory.food),
      ],
      savedContentIds: const ['place-a', 'place-b', 'food-a'],
      itineraryStops: [
        _stop('place-a', ExploreCategory.place),
        _stop('food-a', ExploreCategory.food),
      ],
    );

    final places =
        result.firstWhere((item) => item.category == ExploreCategory.place);
    final food =
        result.firstWhere((item) => item.category == ExploreCategory.food);

    expect(places.availableCount, 2);
    expect(places.savedCount, 2);
    expect(places.scheduledCount, 1);
    expect(places.unscheduledCount, 1);
    expect(places.isComplete, isFalse);

    expect(food.savedCount, 1);
    expect(food.scheduledCount, 1);
    expect(food.isComplete, isTrue);
  });

  test('duplicate catalog ids do not inflate category progress', () {
    final result = VacationCategoryProgressBuilder.build(
      contents: [
        _content('same', ExploreCategory.place),
        _content('same', ExploreCategory.place),
      ],
      savedContentIds: const ['same'],
      itineraryStops: const [],
    );

    expect(result.single.availableCount, 1);
    expect(result.single.savedCount, 1);
  });

  test('categories absent from current destination view are omitted', () {
    final result = VacationCategoryProgressBuilder.build(
      contents: [_content('food', ExploreCategory.food)],
      savedContentIds: const [],
      itineraryStops: const [],
    );

    expect(result, hasLength(1));
    expect(result.single.category, ExploreCategory.food);
  });
}

ExploreContent _content(String id, ExploreCategory category) => ExploreContent(
      id: id,
      countryCode: 'IT',
      countryName: 'Italy',
      cityName: 'Rome',
      category: category,
      title: id,
      shortDescription: '',
      description: '',
      latitude: 1,
      longitude: 1,
      tags: const [],
      metadata: const ExploreMetadata(),
      galleryImageUrls: const [],
    );

SavedTripItineraryStop _stop(String id, ExploreCategory category) =>
    SavedTripItineraryStop(
      id: 'stop-$id',
      tripId: 'trip',
      contentId: id,
      dayIndex: 0,
      startMinute: 600,
      sortOrder: 0,
      content: _content(id, category),
    );

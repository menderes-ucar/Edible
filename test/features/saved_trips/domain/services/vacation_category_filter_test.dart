import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/explore/domain/entities/explore_category.dart';
import 'package:edible/features/explore/domain/entities/explore_content.dart';
import 'package:edible/features/explore/domain/entities/explore_metadata.dart';
import 'package:edible/features/saved_trips/domain/services/vacation_category_filter.dart';

void main() {
  final contents = [
    _content('place', ExploreCategory.place),
    _content('food', ExploreCategory.food),
    _content('drink', ExploreCategory.drink),
  ];

  test('null category keeps current destination contents', () {
    expect(
      VacationCategoryFilter.apply(contents: contents, category: null),
      hasLength(3),
    );
  });

  test('selected category returns only matching discoveries', () {
    final result = VacationCategoryFilter.apply(
      contents: contents,
      category: ExploreCategory.food,
    );
    expect(result.map((item) => item.id), ['food']);
  });

  test('category with no destination content returns empty list', () {
    final result = VacationCategoryFilter.apply(
      contents: contents,
      category: ExploreCategory.culture,
    );
    expect(result, isEmpty);
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

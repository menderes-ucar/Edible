import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/explore/domain/entities/explore_category.dart';
import 'package:edible/features/explore/domain/entities/explore_content.dart';
import 'package:edible/features/explore/domain/entities/explore_metadata.dart';
import 'package:edible/features/explore/domain/services/city_discovery_overview.dart';

void main() {
  test('counts unique discoveries by category and featured state', () {
    final result = CityDiscoveryOverviewBuilder.build([
      _content('a', ExploreCategory.place, featured: true),
      _content('b', ExploreCategory.place),
      _content('c', ExploreCategory.food, featured: true),
    ]);

    expect(result.totalCount, 3);
    expect(result.featuredCount, 2);
    expect(result.countFor(ExploreCategory.place), 2);
    expect(result.countFor(ExploreCategory.food), 1);
  });

  test('duplicate ids never inflate city totals', () {
    final result = CityDiscoveryOverviewBuilder.build([
      _content('same', ExploreCategory.place, featured: true),
      _content('same', ExploreCategory.place, featured: true),
    ]);

    expect(result.totalCount, 1);
    expect(result.featuredCount, 1);
  });

  test('missing category returns zero', () {
    final result = CityDiscoveryOverviewBuilder.build([
      _content('a', ExploreCategory.place),
    ]);

    expect(result.countFor(ExploreCategory.culture), 0);
  });
}

ExploreContent _content(
  String id,
  ExploreCategory category, {
  bool featured = false,
}) =>
    ExploreContent(
      id: id,
      countryCode: 'FR',
      countryName: 'France',
      cityName: 'Paris',
      category: category,
      title: id,
      shortDescription: '',
      description: '',
      latitude: 0,
      longitude: 0,
      tags: const [],
      metadata: const ExploreMetadata(),
      galleryImageUrls: const [],
      isFeatured: featured,
    );

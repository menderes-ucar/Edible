import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/explore/domain/entities/explore_category.dart';
import 'package:edible/features/explore/domain/entities/explore_content.dart';
import 'package:edible/features/explore/domain/entities/explore_metadata.dart';
import 'package:edible/features/explore/domain/services/country_discovery_overview.dart';

void main() {
  test('deduplicates content ids before country counts', () {
    final result = CountryDiscoveryOverviewBuilder.build([
      _content('a', 'Paris', ExploreCategory.place, featured: true),
      _content('a', 'Paris', ExploreCategory.place, featured: true),
      _content('b', 'Lyon', ExploreCategory.food),
    ]);

    expect(result.totalCount, 2);
    expect(result.cityCount, 2);
    expect(result.featuredCount, 1);
  });

  test('counts categories and sorts stronger cities first', () {
    final result = CountryDiscoveryOverviewBuilder.build([
      _content('a', 'Lyon', ExploreCategory.food),
      _content('b', 'Paris', ExploreCategory.place, featured: true),
      _content('c', 'Paris', ExploreCategory.culture),
    ]);

    expect(result.countFor(ExploreCategory.place), 1);
    expect(result.countFor(ExploreCategory.food), 1);
    expect(result.countFor(ExploreCategory.culture), 1);
    expect(result.cities.first.cityName, 'Paris');
    expect(result.cities.first.discoveryCount, 2);
  });
}

ExploreContent _content(
  String id,
  String city,
  ExploreCategory category, {
  bool featured = false,
}) =>
    ExploreContent(
      id: id,
      countryCode: 'FR',
      countryName: 'France',
      cityName: city,
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

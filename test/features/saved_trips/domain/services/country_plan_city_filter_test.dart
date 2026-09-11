import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/explore/domain/entities/explore_category.dart';
import 'package:edible/features/explore/domain/entities/explore_content.dart';
import 'package:edible/features/explore/domain/entities/explore_metadata.dart';
import 'package:edible/features/saved_trips/domain/services/country_plan_city_filter.dart';

void main() {
  test('null city keeps whole country catalog', () {
    final contents = [_content('r', 'Rome'), _content('m', 'Milan')];
    expect(
      CountryPlanCityFilter.apply(contents: contents, cityName: null),
      hasLength(2),
    );
  });

  test('selected city filters country catalog case-insensitively', () {
    final contents = [_content('r', 'Rome'), _content('m', 'Milan')];
    final result = CountryPlanCityFilter.apply(
      contents: contents,
      cityName: '  ROME ',
    );
    expect(result.map((item) => item.id), ['r']);
  });
}

ExploreContent _content(String id, String city) => ExploreContent(
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

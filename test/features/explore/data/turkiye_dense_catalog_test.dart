import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/explore/data/datasources/turkiye_dense_catalog.dart';
import 'package:edible/features/explore/domain/entities/explore_category.dart';

void main() {
  test('covers all 81 provinces with at least five places each', () {
    final items = buildTurkiyeDenseCatalog();
    final cities = <String, int>{};
    for (final item in items.where((e) => e.category == ExploreCategory.place)) {
      cities[item.cityName] = (cities[item.cityName] ?? 0) + 1;
    }
    expect(cities.length, 81);
    expect(cities.values.every((count) => count >= 5), isTrue);
  });

  test('every province has all six discovery categories', () {
    final items = buildTurkiyeDenseCatalog();
    final cities = items.map((e) => e.cityName).toSet();
    for (final city in cities) {
      final categories = items.where((e) => e.cityName == city).map((e) => e.category).toSet();
      expect(categories.containsAll(ExploreCategory.values), isTrue, reason: city);
    }
  });

  test('dense catalog never claims exact coordinates', () {
    expect(buildTurkiyeDenseCatalog().every((e) => !e.metadata.hasExactCoordinates), isTrue);
  });
  test('every dense catalog id is a valid UUID for Supabase contents.id', () {
    final uuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    );
    expect(
      buildTurkiyeDenseCatalog().every((item) => uuid.hasMatch(item.id)),
      isTrue,
    );
  });

}

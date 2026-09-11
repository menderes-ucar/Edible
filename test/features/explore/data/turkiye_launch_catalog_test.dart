import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/explore/data/datasources/turkiye_launch_catalog.dart';

void main() {
  test('Türkiye launch catalog has broad city coverage', () {
    final items = getTurkiyeLaunchCatalog('tr');
    final cities = items.map((item) => item.cityName).toSet();

    expect(items.length, 144);
    expect(cities.length, 24);
    expect(cities, containsAll(<String>[
      'İstanbul',
      'Ankara',
      'İzmir',
      'Antalya',
      'Gaziantep',
      'Şanlıurfa',
      'Mardin',
      'Trabzon',
      'Muğla',
      'Van',
      'Adana',
      'Mersin',
    ]));
  });

  test('every launch city covers all six discovery categories', () {
    final items = getTurkiyeLaunchCatalog('en');
    final byCity = <String, Set<String>>{};

    for (final item in items) {
      byCity.putIfAbsent(item.cityName, () => <String>{}).add(item.category.value);
    }

    for (final categories in byCity.values) {
      expect(categories.length, 6);
    }
  });

  test('launch pins stay editorially marked as approximate', () {
    final items = getTurkiyeLaunchCatalog('en');

    expect(
      items.every(
        (item) =>
            item.metadata.coordinatePrecision == 'city_area' &&
            item.metadata.editorialStatus == 'needs_exact_pin_review',
      ),
      isTrue,
    );
  });
}

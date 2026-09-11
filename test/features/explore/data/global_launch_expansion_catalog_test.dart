import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/explore/data/datasources/global_launch_expansion_catalog.dart';

void main() {
  test('global expansion adds 59 cities and 354 discoveries', () {
    final items = getGlobalLaunchExpansionCatalog('en');
    expect(items.length, 354);
    expect(items.map((item) => '${item.countryCode}:${item.cityName}').toSet().length, 59);
  });

  test('every expansion city has all six discovery categories', () {
    final items = getGlobalLaunchExpansionCatalog('en');
    final byCity = <String, Set<String>>{};
    for (final item in items) {
      byCity
          .putIfAbsent('${item.countryCode}:${item.cityName}', () => <String>{})
          .add(item.category.value);
    }
    expect(byCity.length, 59);
    expect(byCity.values.every((categories) => categories.length == 6), isTrue);
  });

  test('all expansion pins remain approximate until editorial verification', () {
    final items = getGlobalLaunchExpansionCatalog('tr');
    expect(
      items.every(
        (item) =>
            item.metadata.coordinatePrecision == 'city_area' &&
            item.metadata.editorialStatus == 'needs_exact_pin_review',
      ),
      isTrue,
    );
  });

  test('all 19 non-Türkiye launch countries receive additional coverage', () {
    final items = getGlobalLaunchExpansionCatalog('en');
    expect(items.map((item) => item.countryCode).toSet().length, 19);
  });
}

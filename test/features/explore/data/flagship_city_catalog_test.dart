import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/explore/data/datasources/flagship_city_catalog.dart';

void main() {
  test('flagship catalog adds 114 unique discoveries across 11 cities', () {
    final items = getFlagshipCityCatalog('en');
    expect(items.length, 114);
    expect(
      items.map((item) => '${item.countryCode}:${item.cityName}').toSet().length,
      11,
    );
    expect(items.map((item) => item.id).toSet().length, 114);
  });

  test('flagship city pins never claim exact coordinates', () {
    final items = getFlagshipCityCatalog('tr');
    expect(
      items.every(
        (item) =>
            item.metadata.coordinatePrecision == 'city_area' &&
            item.metadata.editorialStatus == 'needs_exact_pin_review',
      ),
      isTrue,
    );
  });

  test('flagship catalog keeps every discovery category represented', () {
    final categories =
        getFlagshipCityCatalog('en').map((item) => item.category.value).toSet();
    expect(
      categories,
      containsAll(<String>[
        'place',
        'food',
        'snack',
        'culture',
        'drink',
        'fruit',
      ]),
    );
  });
}

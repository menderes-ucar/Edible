import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/tours/data/datasources/tour_local_data_source.dart';

void main() {
  test('covers every launch country', () {
    final packages = const TourLocalDataSource().getPackages();
    expect(packages.map((e) => e.countryCode).toSet().length, 20);
    expect(packages.length, greaterThanOrEqualTo(20));
  });

  test('every package combines places with local experience categories', () {
    for (final package in const TourLocalDataSource().getPackages()) {
      expect(package.stops.length, greaterThanOrEqualTo(6), reason: package.id);
      expect(package.stops.any((e) => e.kind.name == 'place'), isTrue);
      expect(package.stops.any((e) => e.kind.name != 'place'), isTrue);
    }
  });

  test('tour image fields never contain Wikimedia search pages', () {
    final packages = const TourLocalDataSource().getPackages();
    final urls = [...packages.map((e) => e.coverImageUrl), ...packages.expand((e) => e.stops).map((e) => e.imageUrl)];
    expect(urls.every((u) => u.startsWith('https://')), isTrue);
    expect(urls.every((u) => !u.contains('MediaSearch')), isTrue);
  });
}

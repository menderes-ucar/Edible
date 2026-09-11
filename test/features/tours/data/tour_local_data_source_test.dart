import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/tours/data/datasources/tour_local_data_source.dart';

void main() {
  test('ships multiple curated tour packages', () {
    final packages = const TourLocalDataSource().getPackages();
    expect(packages.length, greaterThanOrEqualTo(8));
    expect(packages.map((e) => e.cityName).toSet().length, greaterThanOrEqualTo(8));
    expect(packages.every((e) => e.stops.length >= 3), isTrue);
  });

  test('tour imagery uses direct URLs, never media-search pages', () {
    final packages = const TourLocalDataSource().getPackages();
    final urls = [
      ...packages.map((e) => e.coverImageUrl),
      ...packages.expand((e) => e.stops).map((e) => e.imageUrl),
    ];
    expect(urls.every((url) => !url.contains('MediaSearch')), isTrue);
    expect(urls.every((url) => url.startsWith('https://')), isTrue);
  });
}

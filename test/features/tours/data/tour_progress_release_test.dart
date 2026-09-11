import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/tours/data/datasources/tour_local_data_source.dart';

void main() {
  test('all release tours have unique stop ids', () {
    for (final package in const TourLocalDataSource().getPackages()) {
      final ids = package.stops.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length, reason: package.id);
    }
  });

  test('all release tour images have attribution', () {
    final packages = const TourLocalDataSource().getPackages();
    expect(packages.every((p) => p.coverAttribution.trim().isNotEmpty), isTrue);
    expect(packages.expand((p) => p.stops).every((s) => s.imageAttribution.trim().isNotEmpty), isTrue);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/explore/domain/entities/explore_metadata.dart';

void main() {
  test('only explicit exact precision is route-safe', () {
    expect(const ExploreMetadata(coordinatePrecision: 'exact').hasExactCoordinates, isTrue);
    expect(const ExploreMetadata(coordinatePrecision: 'city_area').hasExactCoordinates, isFalse);
    expect(const ExploreMetadata().hasExactCoordinates, isFalse);
  });
}

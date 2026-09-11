import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/explore/domain/entities/explore_metadata.dart';

void main() {
  test('editorial status is part of ExploreMetadata', () {
    const metadata = ExploreMetadata(
      coordinatePrecision: 'city_area',
      editorialStatus: 'needs_exact_pin_review',
    );

    expect(metadata.editorialStatus, 'needs_exact_pin_review');
    expect(metadata.isEmpty, isFalse);
  });
}

import 'package:edible/features/explore/domain/entities/explore_category.dart';
import 'package:edible/features/explore/domain/entities/explore_content.dart';
import 'package:edible/features/explore/domain/entities/explore_metadata.dart';
import 'package:edible/features/location/domain/usecases/find_nearby_discoveries.dart';
import 'package:flutter_test/flutter_test.dart';

ExploreContent item(String id, double distanceValue) {
  return ExploreContent(
    id: id,
    countryCode: 'TR',
    countryName: 'Türkiye',
    cityName: 'Istanbul',
    category: ExploreCategory.place,
    title: id,
    shortDescription: '',
    description: '',
    latitude: distanceValue,
    longitude: 29,
    tags: const [],
    metadata: const ExploreMetadata(),
    galleryImageUrls: const [],
  );
}

void main() {
  test('nearby results are radius filtered, sorted and limited', () {
    const useCase = FindNearbyDiscoveries(
      distanceCalculator: _fakeDistance,
    );

    final result = useCase(
      contents: [
        item('far', 4000),
        item('near-2', 200),
        item('near-1', 100),
        item('outside', 6000),
      ],
      latitude: 0,
      longitude: 0,
      radiusMeters: 5000,
      limit: 2,
    );

    expect(result.map((entry) => entry.content.id), [
      'near-1',
      'near-2',
    ]);
  });
}

double _fakeDistance({
  required double fromLatitude,
  required double fromLongitude,
  required double toLatitude,
  required double toLongitude,
}) {
  return toLatitude;
}

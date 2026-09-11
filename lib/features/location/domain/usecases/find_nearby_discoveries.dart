import '../../../explore/domain/entities/explore_content.dart';
import '../entities/nearby_discovery.dart';

typedef DistanceCalculator = double Function({
  required double fromLatitude,
  required double fromLongitude,
  required double toLatitude,
  required double toLongitude,
});

class FindNearbyDiscoveries {
  const FindNearbyDiscoveries({
    required DistanceCalculator distanceCalculator,
  }) : _distanceCalculator = distanceCalculator;

  final DistanceCalculator _distanceCalculator;

  List<NearbyDiscovery> call({
    required Iterable<ExploreContent> contents,
    required double latitude,
    required double longitude,
    double radiusMeters = 3000,
    int limit = 20,
  }) {
    final results = contents
        .map(
          (content) => NearbyDiscovery(
            content: content,
            distanceMeters: _distanceCalculator(
              fromLatitude: latitude,
              fromLongitude: longitude,
              toLatitude: content.latitude,
              toLongitude: content.longitude,
            ),
          ),
        )
        .where((item) => item.distanceMeters <= radiusMeters)
        .toList(growable: false)
      ..sort(
        (a, b) => a.distanceMeters.compareTo(b.distanceMeters),
      );

    if (results.length <= limit) return results;

    return results.take(limit).toList(growable: false);
  }
}

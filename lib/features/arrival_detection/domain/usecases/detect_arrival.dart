import '../../../explore/domain/entities/explore_content.dart';
import '../entities/detected_arrival.dart';

typedef ArrivalDistanceCalculator = double Function({
  required double fromLatitude,
  required double fromLongitude,
  required double toLatitude,
  required double toLongitude,
});

class DetectArrival {
  const DetectArrival({
    required ArrivalDistanceCalculator distanceCalculator,
    this.maxDistanceMeters = 35000,
  }) : _distanceCalculator = distanceCalculator;

  final ArrivalDistanceCalculator _distanceCalculator;
  final double maxDistanceMeters;

  DetectedArrival? call({
    required double latitude,
    required double longitude,
    required List<ExploreContent> contents,
  }) {
    if (contents.isEmpty) return null;

    final nearestByCity = <String, _CityCandidate>{};

    for (final content in contents) {
      final distance = _distanceCalculator(
        fromLatitude: latitude,
        fromLongitude: longitude,
        toLatitude: content.latitude,
        toLongitude: content.longitude,
      );

      final key =
          '${content.countryCode.toLowerCase()}|${content.cityName.toLowerCase()}';

      final current = nearestByCity[key];
      if (current == null || distance < current.distanceMeters) {
        nearestByCity[key] = _CityCandidate(
          countryCode: content.countryCode,
          countryName: content.countryName,
          cityName: content.cityName,
          distanceMeters: distance,
        );
      }
    }

    if (nearestByCity.isEmpty) return null;

    final candidates = nearestByCity.values.toList()
      ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    final nearest = candidates.first;
    if (nearest.distanceMeters > maxDistanceMeters) return null;

    return DetectedArrival(
      countryCode: nearest.countryCode,
      countryName: nearest.countryName,
      cityName: nearest.cityName,
      distanceMeters: nearest.distanceMeters,
    );
  }
}

class _CityCandidate {
  const _CityCandidate({
    required this.countryCode,
    required this.countryName,
    required this.cityName,
    required this.distanceMeters,
  });

  final String countryCode;
  final String countryName;
  final String cityName;
  final double distanceMeters;
}

class CheckInVerification {
  const CheckInVerification({
    required this.allowed,
    required this.distanceMeters,
    required this.maxDistanceMeters,
  });

  final bool allowed;
  final double distanceMeters;
  final double maxDistanceMeters;
}

typedef CheckInDistanceCalculator = double Function({
  required double fromLatitude,
  required double fromLongitude,
  required double toLatitude,
  required double toLongitude,
});

class VerifyCheckIn {
  /// Radius when the stored pin is the real, verified location.
  static const exactRadiusMeters = 200.0;

  /// Radius when the pin is only a city-area approximation. Audited catalog
  /// pins can be several kilometres from the real landmark, so a 200 m rule
  /// would reject genuine visitors standing at the place. This only confirms
  /// the user is in the right part of the city; it tightens automatically once
  /// an item is marked `coordinatePrecision: exact`.
  static const cityAreaRadiusMeters = 10000.0;

  static double radiusFor({required bool hasExactCoordinates}) =>
      hasExactCoordinates ? exactRadiusMeters : cityAreaRadiusMeters;

  const VerifyCheckIn({
    required CheckInDistanceCalculator distanceCalculator,
  }) : _distanceCalculator = distanceCalculator;

  final CheckInDistanceCalculator _distanceCalculator;

  CheckInVerification call({
    required double userLatitude,
    required double userLongitude,
    required double contentLatitude,
    required double contentLongitude,
    double maxDistanceMeters = 200,
  }) {
    final distance = _distanceCalculator(
      fromLatitude: userLatitude,
      fromLongitude: userLongitude,
      toLatitude: contentLatitude,
      toLongitude: contentLongitude,
    );

    return CheckInVerification(
      allowed: distance <= maxDistanceMeters,
      distanceMeters: distance,
      maxDistanceMeters: maxDistanceMeters,
    );
  }
}

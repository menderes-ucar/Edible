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

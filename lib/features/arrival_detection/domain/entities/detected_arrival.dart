class DetectedArrival {
  const DetectedArrival({
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

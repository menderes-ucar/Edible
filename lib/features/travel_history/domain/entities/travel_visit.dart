class TravelVisit {
  const TravelVisit({
    required this.id,
    required this.countryCode,
    required this.countryName,
    required this.cityName,
    required this.visitDay,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.detectionCount,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String countryCode;
  final String countryName;
  final String cityName;
  final DateTime visitDay;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final int detectionCount;
  final double? latitude;
  final double? longitude;

  String get locationLabel => '$cityName, $countryName';
}

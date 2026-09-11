class DayRoute {
  const DayRoute({
    required this.coordinates,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.source,
    required this.isRoadRoute,
  });

  final List<RouteCoordinate> coordinates;
  final double distanceMeters;
  final double durationSeconds;
  final String source;
  final bool isRoadRoute;

  double get durationMinutes => durationSeconds / 60;
}

class RouteCoordinate {
  const RouteCoordinate({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

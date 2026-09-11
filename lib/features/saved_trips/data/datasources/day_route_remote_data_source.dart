import 'dart:convert';
import 'dart:io';

import '../../../../core/config/routing_config.dart';
import '../../domain/entities/day_route.dart';
import '../../domain/entities/saved_trip_itinerary.dart';

class DayRouteRemoteDataSource {
  const DayRouteRemoteDataSource({
    this.baseUrl = RoutingConfig.baseUrl,
    this.profile = RoutingConfig.profile,
    this.apiKey = RoutingConfig.apiKey,
    this.apiKeyHeader = RoutingConfig.apiKeyHeader,
    this.apiKeyPrefix = RoutingConfig.apiKeyPrefix,
    this.userAgent = RoutingConfig.userAgent,
  });

  final String baseUrl;
  final String profile;
  final String apiKey;
  final String apiKeyHeader;
  final String apiKeyPrefix;
  final String userAgent;

  Future<DayRoute> getWalkingRoute(
    List<SavedTripItineraryStop> stops,
  ) async {
    if (stops.length < 2) {
      return _fallback(stops);
    }

    final coordinates = stops
        .map(
          (stop) =>
              '${stop.content.longitude},${stop.content.latitude}',
        )
        .join(';');

    final base = Uri.parse(baseUrl);
    final normalizedPath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;

    final uri = base.replace(
      path: '$normalizedPath/route/v1/$profile/$coordinates',
      queryParameters: const {
        'overview': 'full',
        'geometries': 'geojson',
        'steps': 'false',
      },
    );

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 8);

    try {
      final request = await client.getUrl(uri);

      if (userAgent.trim().isNotEmpty) {
        request.headers.set(
          HttpHeaders.userAgentHeader,
          userAgent.trim(),
        );
      }

      if (apiKey.trim().isNotEmpty) {
        request.headers.set(
          apiKeyHeader,
          '$apiKeyPrefix${apiKey.trim()}',
        );
      }

      final response = await request.close().timeout(
            const Duration(seconds: 12),
          );

      if (response.statusCode != HttpStatus.ok) {
        return _fallback(stops);
      }

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body);

      if (json is! Map<String, dynamic> ||
          json['code'] != 'Ok' ||
          json['routes'] is! List ||
          (json['routes'] as List).isEmpty) {
        return _fallback(stops);
      }

      final route = (json['routes'] as List).first;
      if (route is! Map<String, dynamic>) {
        return _fallback(stops);
      }

      final geometry = route['geometry'];
      if (geometry is! Map<String, dynamic> ||
          geometry['coordinates'] is! List) {
        return _fallback(stops);
      }

      final points = <RouteCoordinate>[];

      for (final raw in geometry['coordinates'] as List) {
        if (raw is! List || raw.length < 2) continue;

        final longitude = (raw[0] as num?)?.toDouble();
        final latitude = (raw[1] as num?)?.toDouble();

        if (latitude == null || longitude == null) continue;

        points.add(
          RouteCoordinate(
            latitude: latitude,
            longitude: longitude,
          ),
        );
      }

      if (points.length < 2) {
        return _fallback(stops);
      }

      return DayRoute(
        coordinates: List.unmodifiable(points),
        distanceMeters: (route['distance'] as num?)?.toDouble() ?? 0,
        durationSeconds: (route['duration'] as num?)?.toDouble() ?? 0,
        source: base.host,
        isRoadRoute: true,
      );
    } on Object {
      return _fallback(stops);
    } finally {
      client.close(force: true);
    }
  }

  DayRoute _fallback(
    List<SavedTripItineraryStop> stops,
  ) {
    return DayRoute(
      coordinates: List.unmodifiable(
        stops.map(
          (stop) => RouteCoordinate(
            latitude: stop.content.latitude,
            longitude: stop.content.longitude,
          ),
        ),
      ),
      distanceMeters: 0,
      durationSeconds: 0,
      source: 'fallback',
      isRoadRoute: false,
    );
  }
}

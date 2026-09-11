import 'package:flutter/material.dart';
import '../../features/tours/domain/entities/tour_package.dart';
import '../utils/geo_utils.dart';

/// Service to validate and correct marker locations
class MarkerLocationValidator {
  /// Verify marker content ID matches expected location
  static bool verifyMarkerContent(
    String contentId,
    double markerLatitude,
    double markerLongitude,
    TourPackage tour,
  ) {
    // Check if tour ID matches
    if (tour.id != contentId) {
      return false;
    }

    // Verify coordinates are valid
    if (!GeoUtils.isValidCoordinate(markerLatitude, markerLongitude)) {
      return false;
    }

    return true;
  }

  /// Validate marker location against tour data
  static (bool isValid, String? issue) validateMarkerLocation(
    TourPackage tour,
    double markerLatitude,
    double markerLongitude,
  ) {
    // Check if tour has stop data with coordinates
    if (tour.stops.isEmpty) {
      return (false, 'Tour has no stops with coordinates');
    }

    // Find the first stop with valid coordinates
    TourStop? referenceStop;
    for (final stop in tour.stops) {
      if (stop.latitude != null && stop.longitude != null) {
        referenceStop = stop;
        break;
      }
    }

    if (referenceStop == null) {
      return (false, 'No reference coordinates found');
    }

    // Check if marker is close to any stop
    final isCloseToStop = GeoUtils.areCoordinatesClose(
      markerLatitude,
      markerLongitude,
      referenceStop.latitude!,
      referenceStop.longitude!,
      toleranceKm: 1.0,
    );

    if (!isCloseToStop) {
      return (false, 'Marker location does not match tour stops');
    }

    return (true, null);
  }

  /// Get corrected coordinates if available
  static (double? latitude, double? longitude) getCorrectedCoordinates(
    TourPackage tour,
  ) {
    // Find the first stop with valid coordinates
    for (final stop in tour.stops) {
      if (stop.latitude != null && stop.longitude != null) {
        return (stop.latitude, stop.longitude);
      }
    }

    return (null, null);
  }

  /// Get location description for marker
  static String getLocationDescription(TourPackage tour) {
    return '${tour.cityName}, ${tour.countryName}';
  }

  /// Normalize location name for matching
  static String normalizeLocation(String location) {
    return LocationNormalizer.normalize(location);
  }
}

/// Location name normalizer
class LocationNormalizer {
  /// Normalize location name for comparison
  static String normalize(String location) {
    return location
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '');
  }

  /// Extract city name from location string
  static String extractCityName(String location) {
    final parts = location.split(',');
    return parts[0].trim();
  }

  /// Check if two locations match (with fuzzy matching)
  static bool locationsMatch(String location1, String location2) {
    final norm1 = normalize(location1);
    final norm2 = normalize(location2);

    if (norm1 == norm2) return true;

    final city1 = normalize(extractCityName(location1));
    final city2 = normalize(extractCityName(location2));

    if (city1 == city2) return true;

    return _similarityPercentage(city1, city2) >= 0.8;
  }

  /// Calculate string similarity
  static double _similarityPercentage(String s1, String s2) {
    final distance = _levenshteinDistance(s1, s2);
    final maxLength = s1.length > s2.length ? s1.length : s2.length;
    if (maxLength == 0) return 1.0;
    return 1.0 - (distance / maxLength);
  }

  /// Levenshtein distance for fuzzy matching
  static int _levenshteinDistance(String s1, String s2) {
    final costs = List<List<int>>.generate(
      s1.length + 1,
      (i) => List<int>.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) costs[i][0] = i;
    for (int j = 0; j <= s2.length; j++) costs[0][j] = j;

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        costs[i][j] = [
          costs[i - 1][j] + 1,
          costs[i][j - 1] + 1,
          costs[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return costs[s1.length][s2.length];
  }
}

/// Cluster marker handler
class ClusterMarkerHandler {
  /// Get best representative location from cluster
  static (double latitude, double longitude) getClusterCenter(
    List<TourPackage> toursInCluster,
  ) {
    if (toursInCluster.isEmpty) {
      return (0, 0);
    }

    double totalLat = 0;
    double totalLon = 0;
    int count = 0;

    for (final tour in toursInCluster) {
      for (final stop in tour.stops) {
        if (stop.latitude != null && stop.longitude != null) {
          totalLat += stop.latitude!;
          totalLon += stop.longitude!;
          count++;
        }
      }
    }

    if (count == 0) {
      return (0, 0);
    }

    return (totalLat / count, totalLon / count);
  }

  /// Show tour selection bottom sheet for cluster
  static Future<TourPackage?> showClusterTourSelection(
    BuildContext context,
    List<TourPackage> toursInCluster,
  ) async {
    return showModalBottomSheet<TourPackage>(
      context: context,
      builder: (context) => Container(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '${toursInCluster.length} Tours in this area',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: toursInCluster.length,
                itemBuilder: (context, index) {
                  final tour = toursInCluster[index];
                  return ListTile(
                    title: Text(tour.title),
                    subtitle: Text('${tour.cityName}, ${tour.countryName}'),
                    onTap: () => Navigator.pop(context, tour),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

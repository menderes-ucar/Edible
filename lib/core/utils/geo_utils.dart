import 'dart:math' as math;

/// Geographic utilities for location validation and matching
class GeoUtils {
  /// Calculate distance between two coordinates in kilometers
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371;

    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  /// Convert degrees to radians
  static double _toRad(double degree) => degree * math.pi / 180;

  /// Check if coordinates are valid
  static bool isValidCoordinate(double latitude, double longitude) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  /// Check if two coordinates are approximately the same (within 1km)
  static bool areCoordinatesClose(
    double lat1,
    double lon1,
    double lat2,
    double lon2, {
    double toleranceKm = 1.0,
  }) {
    if (!isValidCoordinate(lat1, lon1) || !isValidCoordinate(lat2, lon2)) {
      return false;
    }

    final distance = calculateDistance(lat1, lon1, lat2, lon2);
    return distance <= toleranceKm;
  }

  /// Get center coordinate between two points
  static (double, double) getCenterCoordinate(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final centerLat = (lat1 + lat2) / 2;
    final centerLon = (lon1 + lon2) / 2;
    return (centerLat, centerLon);
  }

  /// Get bounding box for a point with radius
  static ({
    double minLat,
    double maxLat,
    double minLon,
    double maxLon,
  }) getBoundingBox(
    double latitude,
    double longitude, {
    double radiusKm = 1.0,
  }) {
    const earthRadiusKm = 6371;

    final latChange = (radiusKm / earthRadiusKm) * (180 / math.pi);
    final lonChange =
        (radiusKm / earthRadiusKm) * (180 / math.pi) / math.cos(latitude * math.pi / 180);

    return (
      minLat: latitude - latChange,
      maxLat: latitude + latChange,
      minLon: longitude - lonChange,
      maxLon: longitude + lonChange,
    );
  }

  /// Format coordinates for display
  static String formatCoordinates(double latitude, double longitude) {
    final latDir = latitude >= 0 ? 'N' : 'S';
    final lonDir = longitude >= 0 ? 'E' : 'W';

    final latAbs = latitude.abs();
    final lonAbs = longitude.abs();

    return '${latAbs.toStringAsFixed(4)}°$latDir, ${lonAbs.toStringAsFixed(4)}°$lonDir';
  }

  /// Get compass direction between two points
  static String getCompassDirection(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final bearing = math.atan2(y, x) * (180 / math.pi);
    final normalizedBearing = (bearing + 360) % 360;

    if (normalizedBearing >= 348.75 || normalizedBearing < 11.25) return 'N';
    if (normalizedBearing >= 11.25 && normalizedBearing < 33.75) return 'NNE';
    if (normalizedBearing >= 33.75 && normalizedBearing < 56.25) return 'NE';
    if (normalizedBearing >= 56.25 && normalizedBearing < 78.75) return 'ENE';
    if (normalizedBearing >= 78.75 && normalizedBearing < 101.25) return 'E';
    if (normalizedBearing >= 101.25 && normalizedBearing < 123.75) return 'ESE';
    if (normalizedBearing >= 123.75 && normalizedBearing < 146.25) return 'SE';
    if (normalizedBearing >= 146.25 && normalizedBearing < 168.75) return 'SSE';
    if (normalizedBearing >= 168.75 && normalizedBearing < 191.25) return 'S';
    if (normalizedBearing >= 191.25 && normalizedBearing < 213.75) return 'SSW';
    if (normalizedBearing >= 213.75 && normalizedBearing < 236.25) return 'SW';
    if (normalizedBearing >= 236.25 && normalizedBearing < 258.75) return 'WSW';
    if (normalizedBearing >= 258.75 && normalizedBearing < 281.25) return 'W';
    if (normalizedBearing >= 281.25 && normalizedBearing < 303.75) return 'WNW';
    if (normalizedBearing >= 303.75 && normalizedBearing < 326.25) return 'NW';
    return 'NNW';
  }
}

/// Location name normalizer for consistent matching
class LocationNormalizer {
  /// Normalize location name for comparison
  static String normalize(String location) {
    return location
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '');
  }

  /// Extract base city name (remove country/state)
  static String extractCityName(String location) {
    // "Paris, France" -> "Paris"
    // "New York, USA" -> "New York"
    // "Istanbul, Turkey" -> "Istanbul"
    final parts = location.split(',');
    return parts[0].trim();
  }

  /// Extract country name
  static String? extractCountry(String location) {
    final parts = location.split(',');
    return parts.length > 1 ? parts.last.trim() : null;
  }

  /// Check if two location names match (with fuzzy matching)
  static bool locationMatches(String location1, String location2) {
    final norm1 = normalize(location1);
    final norm2 = normalize(location2);

    // Exact match
    if (norm1 == norm2) return true;

    // Extract city names and compare
    final city1 = normalize(extractCityName(location1));
    final city2 = normalize(extractCityName(location2));

    if (city1 == city2) return true;

    // Fuzzy matching - if more than 80% similar
    return _similarityPercentage(city1, city2) >= 0.8;
  }

  /// Calculate string similarity percentage (Levenshtein distance)
  static double _similarityPercentage(String s1, String s2) {
    final distance = _levenshteinDistance(s1, s2);
    final maxLength = math.max(s1.length, s2.length);
    if (maxLength == 0) return 1.0;
    return 1.0 - (distance / maxLength);
  }

  /// Calculate Levenshtein distance
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
        costs[i][j] = math.min(
          math.min(costs[i - 1][j] + 1, costs[i][j - 1] + 1),
          costs[i - 1][j - 1] + cost,
        );
      }
    }

    return costs[s1.length][s2.length];
  }

  /// Get list of known city names for autocomplete
  static final List<String> knownCities = [
    'Istanbul',
    'Ankara',
    'Izmir',
    'Cappadocia',
    'Paris',
    'Tokyo',
    'New York',
    'Barcelona',
    'Rome',
    'Bangkok',
    'Bali',
    'Dubai',
    'London',
    'Amsterdam',
    'Berlin',
    'Seoul',
    'Hong Kong',
    'Singapore',
    'Sydney',
    'Marrakech',
  ];

  /// Find closest matching city name
  static String? findClosestCity(String input) {
    String bestMatch = '';
    double bestScore = 0;

    for (final city in knownCities) {
      final score = _similarityPercentage(normalize(input), normalize(city));
      if (score > bestScore) {
        bestScore = score;
        bestMatch = city;
      }
    }

    return bestScore >= 0.6 ? bestMatch : null;
  }
}

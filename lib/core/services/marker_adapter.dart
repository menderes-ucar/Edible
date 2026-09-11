import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../features/tours/domain/entities/tour_package.dart';

/// Adapter to correctly place markers from tours on Google Maps
class MarkerAdapter {
  /// Convert tour stops to Google Maps markers
  static Set<Marker> getMarkersFromTours(
    List<TourPackage> tours,
    Function(TourPackage) onMarkerTapped,
  ) {
    final markers = <Marker>{};

    for (final tour in tours) {
      // Get primary marker location (first stop with coordinates or city center)
      final markerPosition = _getMarkerPosition(tour);

      if (markerPosition != null) {
        final marker = Marker(
          markerId: MarkerId(tour.id),
          position: markerPosition,
          // Correct title and snippet
          infoWindow: InfoWindow(
            title: tour.cityName,
            snippet: tour.title,
          ),
          onTap: () {
            // Verify location before calling
            _verifyAndCall(tour, onMarkerTapped);
          },
        );

        markers.add(marker);
      }
    }

    return markers;
  }

  /// Get correct marker position from tour
  static LatLng? _getMarkerPosition(TourPackage tour) {
    // Try to get from first stop
    if (tour.stops.isNotEmpty) {
      final firstStop = tour.stops.first;
      if (firstStop.latitude != null && firstStop.longitude != null) {
        return LatLng(firstStop.latitude!, firstStop.longitude!);
      }
    }

    // Fallback to city coordinates
    return _getCityCoordinates(tour.cityName, tour.countryName);
  }

  /// Get known city coordinates as fallback
  static LatLng? _getCityCoordinates(String cityName, String countryName) {
    final coordinates = {
      'Istanbul': LatLng(41.0082, 28.9784),
      'Cappadocia': LatLng(38.7436, 34.5358),
      'Paris': LatLng(48.8566, 2.3522),
      'Rome': LatLng(41.9028, 12.4964),
      'Tokyo': LatLng(35.6762, 139.6503),
      'Bangkok': LatLng(13.7563, 100.5018),
      'Dubai': LatLng(25.2048, 55.2708),
      'Bali': LatLng(-8.6500, 115.2167),
      'New York': LatLng(40.7128, -74.0060),
      'Barcelona': LatLng(41.3874, 2.1686),
      'London': LatLng(51.5074, -0.1278),
      'Amsterdam': LatLng(52.3676, 4.9041),
      'Berlin': LatLng(52.5200, 13.4050),
      'Seoul': LatLng(37.5665, 126.9780),
      'Singapore': LatLng(1.3521, 103.8198),
      'Hong Kong': LatLng(22.2793, 114.1628),
      'Sydney': LatLng(-33.8688, 151.2093),
      'Marrakech': LatLng(31.6295, -8.0088),
    };

    return coordinates[cityName];
  }

  /// Verify marker location is correct before calling callback
  static void _verifyAndCall(
    TourPackage tour,
    Function(TourPackage) onMarkerTapped,
  ) {
    // Double-check coordinates are valid
    final position = _getMarkerPosition(tour);

    if (position != null &&
        position.latitude >= -90 &&
        position.latitude <= 90 &&
        position.longitude >= -180 &&
        position.longitude <= 180) {
      onMarkerTapped(tour);
    }
  }

  /// Generate camera position to show all markers
  static CameraPosition getCameraPositionForTours(List<TourPackage> tours) {
    if (tours.isEmpty) {
      // Default to Istanbul
      return CameraPosition(
        target: LatLng(41.0082, 28.9784),
        zoom: 12,
      );
    }

    // Calculate center of all markers
    double sumLat = 0;
    double sumLng = 0;
    int count = 0;

    for (final tour in tours) {
      final position = _getMarkerPosition(tour);
      if (position != null) {
        sumLat += position.latitude;
        sumLng += position.longitude;
        count++;
      }
    }

    if (count == 0) {
      return CameraPosition(
        target: LatLng(20, 0), // World center
        zoom: 2,
      );
    }

    return CameraPosition(
      target: LatLng(sumLat / count, sumLng / count),
      zoom: 6, // Zoom to see all
    );
  }

  /// Debug: Print marker positions
  static void debugPrintMarkers(List<TourPackage> tours) {
    for (final tour in tours) {
      final position = _getMarkerPosition(tour);
      print('Tour: ${tour.title}');
      print('  City: ${tour.cityName}, Country: ${tour.countryName}');
      print('  Position: ${position?.latitude}, ${position?.longitude}');
      print('  Stops: ${tour.stops.length}');
      for (final stop in tour.stops) {
        print(
          '    - ${stop.title}: (${stop.latitude}, ${stop.longitude})',
        );
      }
      print('');
    }
  }
}

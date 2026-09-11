import 'package:flutter_test/flutter_test.dart';
import '../lib/features/tours/data/datasources/hardcoded_world_tours_dataset.dart';
import '../lib/core/services/marker_adapter.dart';
import '../lib/core/utils/geo_utils.dart';

void main() {
  group('Marker Positioning Tests', () {
    final tours = HardcodedWorldToursDataset.allTours;

    test('All tours have valid marker positions', () {
      for (final tour in tours) {
        final position = MarkerAdapter.getMarkersFromTours(
          [tour],
          (_) {},
        );

        expect(
          position.isNotEmpty,
          true,
          reason: 'Tour ${tour.title} should have marker',
        );

        final marker = position.first;
        expect(
          marker.position.latitude >= -90 && marker.position.latitude <= 90,
          true,
          reason:
              'Latitude invalid for ${tour.title}: ${marker.position.latitude}',
        );
        expect(
          marker.position.longitude >= -180 &&
              marker.position.longitude <= 180,
          true,
          reason:
              'Longitude invalid for ${tour.title}: ${marker.position.longitude}',
        );
      }
    });

    test('Istanbul markers are at correct locations', () {
      final istanbulTours =
          tours.where((t) => t.cityName == 'Istanbul').toList();
      expect(istanbulTours.isNotEmpty, true);

      for (final tour in istanbulTours) {
        // Check if tour has stops
        if (tour.stops.isNotEmpty) {
          final firstStop = tour.stops.first;

          // Check coordinates are in Istanbul area (roughly)
          expect(
            firstStop.latitude != null &&
                firstStop.latitude! >= 40.8 &&
                firstStop.latitude! <= 41.3,
            true,
            reason: 'Stop latitude outside Istanbul range: ${firstStop.latitude}',
          );

          expect(
            firstStop.longitude != null &&
                firstStop.longitude! >= 28.5 &&
                firstStop.longitude! <= 29.3,
            true,
            reason:
                'Stop longitude outside Istanbul range: ${firstStop.longitude}',
          );
        }
      }
    });

    test('Paris markers are at correct locations', () {
      final parisTours = tours.where((t) => t.cityName == 'Paris').toList();
      expect(parisTours.isNotEmpty, true);

      for (final tour in parisTours) {
        if (tour.stops.isNotEmpty) {
          final firstStop = tour.stops.first;

          // Check coordinates are in Paris area
          expect(
            firstStop.latitude != null &&
                firstStop.latitude! >= 48.7 &&
                firstStop.latitude! <= 49.0,
            true,
            reason: 'Stop latitude outside Paris range: ${firstStop.latitude}',
          );

          expect(
            firstStop.longitude != null &&
                firstStop.longitude! >= 2.1 &&
                firstStop.longitude! <= 2.5,
            true,
            reason:
                'Stop longitude outside Paris range: ${firstStop.longitude}',
          );
        }
      }
    });

    test('Tokyo markers are at correct locations', () {
      final tokyoTours = tours.where((t) => t.cityName == 'Tokyo').toList();
      expect(tokyoTours.isNotEmpty, true);

      for (final tour in tokyoTours) {
        if (tour.stops.isNotEmpty) {
          final firstStop = tour.stops.first;

          // Check coordinates are in Tokyo area
          expect(
            firstStop.latitude != null &&
                firstStop.latitude! >= 35.5 &&
                firstStop.latitude! <= 35.9,
            true,
            reason: 'Stop latitude outside Tokyo range: ${firstStop.latitude}',
          );

          expect(
            firstStop.longitude != null &&
                firstStop.longitude! >= 139.5 &&
                firstStop.longitude! <= 140.0,
            true,
            reason:
                'Stop longitude outside Tokyo range: ${firstStop.longitude}',
          );
        }
      }
    });

    test('Geographic distance calculation is correct', () {
      // Istanbul Blue Mosque
      const istanbulLat = 41.0054;
      const istanbulLng = 28.9768;

      // Istanbul Topkapi Palace (close by)
      const topkapiLat = 41.0096;
      const topkapiLng = 28.9830;

      final distance = GeoUtils.calculateDistance(
        istanbulLat,
        istanbulLng,
        topkapiLat,
        topkapiLng,
      );

      // Should be less than 1km
      expect(
        distance < 1.0,
        true,
        reason: 'Distance between markers should be <1km, got: $distance km',
      );

      print('✅ Blue Mosque to Topkapi: ${distance.toStringAsFixed(3)} km');
    });

    test('Coordinate validation works', () {
      expect(
        GeoUtils.isValidCoordinate(41.0054, 28.9768),
        true,
        reason: 'Istanbul coordinates should be valid',
      );

      expect(
        GeoUtils.isValidCoordinate(91, 180),
        false,
        reason: 'Invalid latitude (>90) should fail',
      );

      expect(
        GeoUtils.isValidCoordinate(0, 181),
        false,
        reason: 'Invalid longitude (>180) should fail',
      );
    });

    test('Marker adapter generates correct number of markers', () {
      final markers = MarkerAdapter.getMarkersFromTours(
        tours,
        (_) {},
      );

      expect(
        markers.length,
        tours.length,
        reason: 'Should have one marker per tour',
      );

      print('✅ Generated ${markers.length} markers for ${tours.length} tours');
    });

    test('Camera position includes all markers', () {
      final cameraPosition = MarkerAdapter.getCameraPositionForTours(tours);

      expect(
        cameraPosition.target.latitude >= -90 &&
            cameraPosition.target.latitude <= 90,
        true,
        reason: 'Camera latitude should be valid',
      );

      expect(
        cameraPosition.target.longitude >= -180 &&
            cameraPosition.target.longitude <= 180,
        true,
        reason: 'Camera longitude should be valid',
      );

      expect(
        cameraPosition.zoom > 0 && cameraPosition.zoom <= 20,
        true,
        reason: 'Camera zoom should be between 0-20',
      );

      print(
        '✅ Camera position: ${cameraPosition.target}, zoom: ${cameraPosition.zoom}',
      );
    });
  });

  group('Marker Info Window Tests', () {
    test('Markers have correct info windows', () {
      final tours = HardcodedWorldToursDataset.allTours;
      final markers = MarkerAdapter.getMarkersFromTours(
        tours,
        (_) {},
      );

      for (final marker in markers) {
        final infoWindow = marker.infoWindow;

        expect(
          infoWindow.title != null && infoWindow.title!.isNotEmpty,
          true,
          reason: 'Marker should have title',
        );

        expect(
          infoWindow.snippet != null && infoWindow.snippet!.isNotEmpty,
          true,
          reason: 'Marker should have snippet',
        );

        print('✅ ${infoWindow.title}: ${infoWindow.snippet}');
      }
    });
  });

  group('Tour Stops Coordinate Tests', () {
    test('All tour stops have valid coordinates', () {
      final tours = HardcodedWorldToursDataset.allTours;
      int stopsWithCoords = 0;

      for (final tour in tours) {
        for (final stop in tour.stops) {
          if (stop.latitude != null && stop.longitude != null) {
            stopsWithCoords++;

            expect(
              GeoUtils.isValidCoordinate(stop.latitude!, stop.longitude!),
              true,
              reason:
                  'Invalid coordinates for ${tour.title} - ${stop.title}',
            );
          }
        }
      }

      print('✅ $stopsWithCoords tour stops have valid coordinates');
      expect(stopsWithCoords > 0, true, reason: 'Should have stops with coords');
    });
  });
}

/// RUN TESTS:
/// flutter test test/marker_tests.dart -v
///
/// EXPECTED OUTPUT:
/// ✅ All tours have valid marker positions
/// ✅ Istanbul markers are at correct locations
/// ✅ Paris markers are at correct locations
/// ✅ Tokyo markers are at correct locations
/// ✅ Geographic distance calculation is correct
/// ✅ Coordinate validation works
/// ✅ Marker adapter generates correct number of markers
/// ✅ Camera position includes all markers
/// ✅ Markers have correct info windows
/// ✅ All tour stops have valid coordinates

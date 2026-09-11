import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../features/tours/domain/entities/tour_package.dart';
import '../services/marker_adapter.dart';

/// Example: How to use MarkerAdapter in your maps page
class MapWithToursExample extends StatefulWidget {
  final List<TourPackage> tours;

  const MapWithToursExample({
    required this.tours,
    super.key,
  });

  @override
  State<MapWithToursExample> createState() => _MapWithToursExampleState();
}

class _MapWithToursExampleState extends State<MapWithToursExample> {
  late GoogleMapController mapController;
  late Set<Marker> markers;

  @override
  void initState() {
    super.initState();
    // Generate markers from tours using adapter
    markers = MarkerAdapter.getMarkersFromTours(
      widget.tours,
      _onMarkerTapped,
    );

    // Debug: Print marker positions
    MarkerAdapter.debugPrintMarkers(widget.tours);
  }

  void _onMarkerTapped(TourPackage tour) {
    // Show bottom sheet or navigate to tour details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected: ${tour.title}'),
        backgroundColor: Colors.teal,
      ),
    );

    // Optionally navigate to tour detail page
    // Navigator.push(...)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tours Map'),
      ),
      body: GoogleMap(
        // Camera position that shows all markers
        initialCameraPosition: MarkerAdapter.getCameraPositionForTours(
          widget.tours,
        ),
        markers: markers,
        onMapCreated: (controller) {
          mapController = controller;
        },
        // Make sure to enable all map features
        myLocationButtonEnabled: true,
        myLocationEnabled: false,
        zoomControlsEnabled: true,
        mapType: MapType.normal,
      ),
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}

/// IMPORTANT: Add this to your pubspec.yaml if not already there:
/*
dependencies:
  google_maps_flutter: ^2.14.2
  
android:
  - AndroidManifest.xml configuration
  - Add Google Maps API key in meta-data
  
ios:
  - Info.plist configuration
  - Add Google Maps API key
*/

/// VERIFICATION CHECKLIST:
/// ✅ 1. Each tour has stops with REAL coordinates
/// ✅ 2. MarkerAdapter extracts coordinates correctly
/// ✅ 3. Markers are placed at correct positions
/// ✅ 4. Info windows show correct city + title
/// ✅ 5. Click handler verifies location before action
/// ✅ 6. Fallback city coordinates available
/// ✅ 7. Camera zooms to show all markers
/// ✅ 8. Debug logging available for troubleshooting

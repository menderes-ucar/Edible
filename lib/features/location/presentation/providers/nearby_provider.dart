import 'package:flutter/foundation.dart';

import '../../../explore/domain/entities/explore_content.dart';
import '../../domain/entities/nearby_discovery.dart';
import '../../domain/usecases/find_nearby_discoveries.dart';
import 'location_provider.dart';

class NearbyProvider extends ChangeNotifier {
  NearbyProvider({
    required LocationProvider locationProvider,
    required FindNearbyDiscoveries findNearbyDiscoveries,
  })  : _locationProvider = locationProvider,
        _findNearbyDiscoveries = findNearbyDiscoveries {
    _locationProvider.addListener(_handleLocationChanged);
  }

  final LocationProvider _locationProvider;
  final FindNearbyDiscoveries _findNearbyDiscoveries;

  List<ExploreContent> _contents = const [];
  List<NearbyDiscovery> _nearby = const [];
  double _radiusMeters = 3000;
  bool _disposed = false;

  List<NearbyDiscovery> get nearby => _nearby;
  double get radiusMeters => _radiusMeters;

  bool get hasLocation => _locationProvider.hasLocation;

  void setContents(List<ExploreContent> contents) {
    if (_disposed || listEquals(_contents, contents)) return;
    _contents = List.unmodifiable(contents);
    _recalculate();
  }

  void setRadiusMeters(double value) {
    if (_disposed || _radiusMeters == value) return;
    _radiusMeters = value;
    _recalculate();
  }

  void _handleLocationChanged() {
    if (_disposed) return;
    _recalculate();
  }

  void _recalculate() {
    if (_disposed) return;

    final latitude = _locationProvider.latitude;
    final longitude = _locationProvider.longitude;

    if (latitude == null || longitude == null) {
      _nearby = const [];
      _notifyIfAlive();
      return;
    }

    _nearby = _findNearbyDiscoveries(
      contents: _contents,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: _radiusMeters,
    );

    _notifyIfAlive();
  }

  void _notifyIfAlive() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _nearby = const [];
    _contents = const [];
    _locationProvider.removeListener(_handleLocationChanged);
    super.dispose();
  }
}

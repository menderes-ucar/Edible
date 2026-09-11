import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  LocationProvider({
    required LocationService locationService,
  }) : _locationService = locationService;

  final LocationService _locationService;

  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  LocationFailureType? _failureType;
  Future<bool>? _inFlightLocate;
  int _requestGeneration = 0;
  bool _disposed = false;

  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get hasLocation => _latitude != null && _longitude != null;
  bool get isLoading => _isLoading;
  LocationFailureType? get failureType => _failureType;

  /// Backward-compatible safe UI message key. Raw platform errors are never
  /// exposed from this provider.
  String? get errorMessageKey {
    return switch (_failureType) {
      LocationFailureType.serviceDisabled => 'locationServiceDisabled',
      LocationFailureType.permissionDenied => 'locationPermissionDenied',
      LocationFailureType.permissionDeniedForever =>
        'locationPermissionDeniedForever',
      LocationFailureType.unavailable => 'locationUnavailable',
      null => null,
    };
  }

  Future<bool> locate() {
    if (_disposed) return Future<bool>.value(false);

    final current = _inFlightLocate;
    if (current != null) return current;

    final completer = Completer<bool>();
    _inFlightLocate = completer.future;
    _performLocate(completer);
    return completer.future;
  }

  Future<void> _performLocate(Completer<bool> completer) async {
    final generation = ++_requestGeneration;

    _isLoading = true;
    _failureType = null;
    _notifyIfAlive();

    try {
      final position = await _locationService.getCurrentPosition();

      if (!_isCurrent(generation)) {
        _completeIfNeeded(completer, false);
        return;
      }

      _latitude = position.latitude;
      _longitude = position.longitude;
      _failureType = null;
      _completeIfNeeded(completer, true);
    } on LocationFailure catch (error) {
      if (_isCurrent(generation)) {
        _failureType = error.type;
      }
      _completeIfNeeded(completer, false);
    } catch (_) {
      if (_isCurrent(generation)) {
        _failureType = LocationFailureType.unavailable;
      }
      _completeIfNeeded(completer, false);
    } finally {
      if (_isCurrent(generation)) {
        _isLoading = false;
      }

      _inFlightLocate = null;
      _notifyIfAlive();
    }
  }

  Future<bool> openRelevantSettings() async {
    return switch (_failureType) {
      LocationFailureType.serviceDisabled =>
        _locationService.openLocationSettings(),
      LocationFailureType.permissionDeniedForever =>
        _locationService.openAppSettings(),
      _ => false,
    };
  }

  void clearFailure() {
    if (_disposed || _failureType == null) return;
    _failureType = null;
    notifyListeners();
  }

  double distanceTo({
    required double latitude,
    required double longitude,
  }) {
    if (!hasLocation) return double.infinity;

    return _locationService.distanceMeters(
      fromLatitude: _latitude!,
      fromLongitude: _longitude!,
      toLatitude: latitude,
      toLongitude: longitude,
    );
  }
  bool _isCurrent(int generation) {
    return !_disposed && generation == _requestGeneration;
  }

  void _completeIfNeeded(Completer<bool> completer, bool value) {
    if (!completer.isCompleted) {
      completer.complete(value);
    }
  }

  void _notifyIfAlive() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestGeneration++;
    _isLoading = false;
    _failureType = null;
    _inFlightLocate = null;
    super.dispose();
  }

}

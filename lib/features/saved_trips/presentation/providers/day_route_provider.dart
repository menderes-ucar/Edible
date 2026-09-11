import 'package:flutter/foundation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

import '../../domain/entities/day_route.dart';
import '../../domain/entities/saved_trip_itinerary.dart';
import '../../domain/repositories/day_route_repository.dart';
import '../../domain/services/day_route_coordinate_policy.dart';

class DayRouteProvider extends ChangeNotifier {
  DayRouteProvider({
    required DayRouteRepository repository,
    required AuthProvider authProvider,
  })  : _repository = repository,
        _authProvider = authProvider {
    _authProvider.addListener(_handleAuthChanged);
    _lastIdentity = _identity;
  }

  final DayRouteRepository _repository;
  final AuthProvider _authProvider;

  final Map<String, DayRoute> _routes = {};
  final Set<String> _loadingKeys = {};
  final Map<String, String> _errors = {};
  int _requestGeneration = 0;
  bool _disposed = false;
  String? _lastIdentity;

  String _key(String tripId, int dayIndex) => '$tripId:$dayIndex';

  DayRoute? routeFor(String tripId, int dayIndex) =>
      _routes[_key(tripId, dayIndex)];

  bool isLoading(String tripId, int dayIndex) =>
      _loadingKeys.contains(_key(tripId, dayIndex));

  String? errorFor(String tripId, int dayIndex) =>
      _errors[_key(tripId, dayIndex)];

  Future<void> load({
    required String tripId,
    required int dayIndex,
    required List<SavedTripItineraryStop> stops,
    bool force = false,
  }) async {
    if (_disposed) return;

    final key = _key(tripId, dayIndex);

    if (!DayRouteCoordinatePolicy.hasEnoughStops(stops)) {
      _routes.remove(key);
      _errors.remove(key);
      _loadingKeys.remove(key);
      _notifyIfAlive();
      return;
    }

    if (!DayRouteCoordinatePolicy.hasVerifiedExactCoordinates(stops)) {
      _routes.remove(key);
      _loadingKeys.remove(key);
      _errors[key] = 'route_requires_exact_coordinates';
      _notifyIfAlive();
      return;
    }

    if (_loadingKeys.contains(key)) return;
    if (!force && _routes.containsKey(key)) return;

    final generation = _requestGeneration;
    final identity = _identity;

    _loadingKeys.add(key);
    _errors.remove(key);
    _notifyIfAlive();

    try {
      final route = await _repository.getWalkingRoute(stops);
      if (!_sameRequestSession(
        generation: generation,
        identity: identity,
      )) {
        return;
      }
      _routes[key] = route;
    } catch (error) {
      if (_sameRequestSession(
        generation: generation,
        identity: identity,
      )) {
        _errors[key] = error.toString();
      }
    } finally {
      if (_sameRequestSession(
        generation: generation,
        identity: identity,
      )) {
        _loadingKeys.remove(key);
        _notifyIfAlive();
      }
    }
  }

  void invalidate(String tripId, int dayIndex) {
    if (_disposed) return;

    final key = _key(tripId, dayIndex);
    _routes.remove(key);
    _errors.remove(key);
    _notifyIfAlive();
  }

  void clearTrip(String tripId) {
    if (_disposed) return;

    final prefix = '$tripId:';
    _routes.removeWhere((key, _) => key.startsWith(prefix));
    _errors.removeWhere((key, _) => key.startsWith(prefix));
    _loadingKeys.removeWhere((key) => key.startsWith(prefix));
    _notifyIfAlive();
  }
  String get _identity => _authProvider.user?.id ?? 'guest';

  void _handleAuthChanged() {
    if (_disposed) return;

    final identity = _identity;
    if (_lastIdentity == identity) return;

    _lastIdentity = identity;
    _requestGeneration++;
    _routes.clear();
    _errors.clear();
    _loadingKeys.clear();
    _notifyIfAlive();
  }

  bool _sameRequestSession({
    required int generation,
    required String identity,
  }) {
    return !_disposed &&
        generation == _requestGeneration &&
        identity == _identity;
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
    _routes.clear();
    _errors.clear();
    _loadingKeys.clear();
    _authProvider.removeListener(_handleAuthChanged);
    super.dispose();
  }

}

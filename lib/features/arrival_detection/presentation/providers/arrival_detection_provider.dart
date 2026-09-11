import 'package:flutter/foundation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

import '../../../explore/domain/entities/explore_content.dart';
import '../../domain/entities/detected_arrival.dart';
import '../../domain/repositories/arrival_detection_repository.dart';
import '../../domain/usecases/detect_arrival.dart';
import '../../domain/usecases/should_show_arrival_welcome.dart';
import '../../../travel_history/domain/repositories/travel_history_repository.dart';

class ArrivalDetectionProvider extends ChangeNotifier {
  ArrivalDetectionProvider({
    required ArrivalDetectionRepository repository,
    required TravelHistoryRepository travelHistoryRepository,
    required AuthProvider authProvider,
    required DetectArrival detectArrival,
    ShouldShowArrivalWelcome shouldShowArrivalWelcome =
        const ShouldShowArrivalWelcome(),
  })  : _repository = repository,
        _travelHistoryRepository = travelHistoryRepository,
        _authProvider = authProvider,
        _detectArrival = detectArrival,
        _shouldShowArrivalWelcome = shouldShowArrivalWelcome {
    _authProvider.addListener(_handleAuthChanged);
    _lastIdentity = _identity;
  }

  final ArrivalDetectionRepository _repository;
  final TravelHistoryRepository _travelHistoryRepository;
  final AuthProvider _authProvider;
  final DetectArrival _detectArrival;
  final ShouldShowArrivalWelcome _shouldShowArrivalWelcome;

  DetectedArrival? _pendingArrival;
  bool _isChecking = false;
  int _requestGeneration = 0;
  bool _disposed = false;
  String? _lastIdentity;

  DetectedArrival? get pendingArrival => _pendingArrival;
  bool get hasPendingArrival => _pendingArrival != null;
  bool get isChecking => _isChecking;

  Future<DetectedArrival?> check({
    required double latitude,
    required double longitude,
    required List<ExploreContent> contents,
  }) async {
    if (_disposed) return null;
    if (_isChecking) return _pendingArrival;

    final generation = ++_requestGeneration;
    final identity = _identity;
    _isChecking = true;
    _notifyIfAlive();

    try {
      final arrival = _detectArrival(
        latitude: latitude,
        longitude: longitude,
        contents: contents,
      );
      if (arrival == null) return null;

      try {
        await _travelHistoryRepository.recordArrival(
          arrival: arrival,
          latitude: latitude,
          longitude: longitude,
        );
      } catch (_) {
        // Welcome may continue even if travel-history persistence fails.
      }

      if (!_isCurrent(generation, identity)) return null;

      final history = await _repository.getLastWelcome();
      if (!_isCurrent(generation, identity)) return null;

      final shouldShow = _shouldShowArrivalWelcome(
        arrival: arrival,
        history: history,
        now: DateTime.now(),
      );
      if (!shouldShow) return null;

      _pendingArrival = arrival;
      _notifyIfAlive();
      return arrival;
    } finally {
      if (_isCurrent(generation, identity)) {
        _isChecking = false;
        _notifyIfAlive();
      }
    }
  }

  Future<void> markShown() async {
    if (_disposed) return;

    final arrival = _pendingArrival;
    if (arrival == null) return;

    final generation = _requestGeneration;
    final identity = _identity;

    await _repository.saveWelcome(
      countryCode: arrival.countryCode,
      cityName: arrival.cityName,
      shownAt: DateTime.now(),
    );

    if (!_isCurrent(generation, identity) || _pendingArrival != arrival) {
      return;
    }

    _pendingArrival = null;
    _notifyIfAlive();
  }

  void clear() {
    if (_disposed) return;

    _requestGeneration++;
    _pendingArrival = null;
    _isChecking = false;
    _notifyIfAlive();
  }

  String get _identity => _authProvider.user?.id ?? 'guest';

  bool _isCurrent(int generation, String identity) {
    return !_disposed &&
        generation == _requestGeneration &&
        identity == _identity;
  }

  void _handleAuthChanged() {
    if (_disposed) return;

    final identity = _identity;
    if (_lastIdentity == identity) return;

    _lastIdentity = identity;
    _requestGeneration++;
    _pendingArrival = null;
    _isChecking = false;
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
    _requestGeneration++;
    _pendingArrival = null;
    _isChecking = false;
    _authProvider.removeListener(_handleAuthChanged);
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/travel_visit.dart';
import '../../domain/repositories/travel_history_repository.dart';

class TravelHistoryProvider extends ChangeNotifier {
  TravelHistoryProvider({
    required TravelHistoryRepository repository,
    required AuthProvider authProvider,
  })  : _repository = repository,
        _authProvider = authProvider {
    _authProvider.addListener(_handleAuthChanged);
    _handleAuthChanged();
  }

  final TravelHistoryRepository _repository;
  final AuthProvider _authProvider;

  List<TravelVisit> _visits = const [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _loadedIdentity;
  int _requestGeneration = 0;
  bool _disposed = false;

  List<TravelVisit> get visits => List<TravelVisit>.unmodifiable(_visits);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get travelDayCount => _visits
      .map(
        (visit) =>
            '${visit.visitDay.year}-'
            '${visit.visitDay.month.toString().padLeft(2, '0')}-'
            '${visit.visitDay.day.toString().padLeft(2, '0')}',
      )
      .toSet()
      .length;

  int get countryCount => _visits
      .map((visit) => visit.countryCode.toUpperCase())
      .toSet()
      .length;

  int get cityCount => _visits
      .map(
        (visit) =>
            '${visit.countryCode.toUpperCase()}|${visit.cityName.toLowerCase()}',
      )
      .toSet()
      .length;

  Future<void> _handleAuthChanged() async {
    if (_disposed) return;

    final identity = _authProvider.user?.id ?? 'guest';
    if (_loadedIdentity == identity) return;

    _requestGeneration++;
    _loadedIdentity = identity;
    _visits = const [];
    _errorMessage = null;
    _isLoading = false;
    _notifyIfAlive();

    await refresh();
  }

  Future<void> refresh() async {
    if (_disposed) return;

    final identity = _authProvider.user?.id ?? 'guest';
    final requestId = ++_requestGeneration;

    _isLoading = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      final loaded = await _repository.getVisits();

      if (!_isCurrent(
        requestId: requestId,
        identity: identity,
      )) {
        return;
      }

      _visits = loaded;
    } catch (error) {
      if (_isCurrent(
        requestId: requestId,
        identity: identity,
      )) {
        _errorMessage = error.toString();
      }
    } finally {
      if (_isCurrent(
        requestId: requestId,
        identity: identity,
      )) {
        _isLoading = false;
        _notifyIfAlive();
      }
    }
  }

  bool _isCurrent({
    required int requestId,
    required String identity,
  }) {
    return !_disposed &&
        requestId == _requestGeneration &&
        identity == (_authProvider.user?.id ?? 'guest');
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
    _authProvider.removeListener(_handleAuthChanged);
    super.dispose();
  }
}

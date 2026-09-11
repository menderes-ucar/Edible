import 'package:flutter/foundation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/saved_trip.dart';
import '../../domain/entities/saved_trip_draft.dart';
import '../../domain/repositories/saved_trip_repository.dart';
import '../../domain/services/saved_trip_content_mutation_policy.dart';
import '../../domain/services/saved_trip_mutation_policy.dart';

class SavedTripsProvider extends ChangeNotifier {
  SavedTripsProvider({
    required SavedTripRepository repository,
    required AuthProvider authProvider,
  })  : _repository = repository,
        _authProvider = authProvider {
    _authProvider.addListener(_handleAuthChanged);
    _handleAuthChanged();
  }

  final SavedTripRepository _repository;
  final AuthProvider _authProvider;

  List<SavedTrip> _trips = const [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _loadedIdentity;
  int _requestGeneration = 0;
  bool _disposed = false;
  final Set<String> _pendingTripIds = <String>{};

  List<SavedTrip> get trips => _trips;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get errorCode {
    final message = _errorMessage ?? '';
    if (message.contains('content_not_synced_to_supabase')) {
      return 'content_not_synced_to_supabase';
    }
    if (message.contains('saved_trip_not_owned_or_missing')) {
      return 'saved_trip_not_owned_or_missing';
    }
    if (message.contains('Authentication required')) {
      return 'authentication_required';
    }
    if (message.contains('invalid_trip_date_range')) {
      return 'invalid_trip_date_range';
    }
    if (message.contains('saved_trip_operation_in_progress')) {
      return 'saved_trip_operation_in_progress';
    }
    return _errorMessage == null ? null : 'saved_trip_persistence_failed';
  }

  bool isPending(String tripId) {
    return SavedTripMutationPolicy.hasTripWrite(
      pendingKeys: _pendingTripIds,
      tripId: tripId,
    );
  }

  bool isContentPending({
    required String tripId,
    required String contentId,
  }) {
    return _pendingTripIds.contains('content:$tripId:$contentId');
  }

  bool isContentMutationPending(String tripId) {
    return SavedTripContentMutationPolicy.hasPendingMutation(
      pendingKeys: _pendingTripIds,
      tripId: tripId,
    );
  }

  SavedTrip? byId(String id) {
    for (final trip in _trips) {
      if (trip.id == id) return trip;
    }
    return null;
  }

  Future<void> _handleAuthChanged() async {
    if (_disposed) return;

    final identity = _authProvider.user?.id ?? 'guest';
    if (_loadedIdentity == identity) return;
    _loadedIdentity = identity;
    _requestGeneration++;
    _pendingTripIds.clear();

    if (_authProvider.isGuest) {
      _trips = const [];
      _errorMessage = null;
      _notifyIfAlive();
      return;
    }

    await refresh();
  }

  Future<void> refresh() async {
    if (_disposed) return;

    if (_authProvider.isGuest) {
      _requestGeneration++;
      _trips = const [];
      _isLoading = false;
      _notifyIfAlive();
      return;
    }

    final request = ++_requestGeneration;
    final identity = _authProvider.user?.id;
    _isLoading = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      final loaded = await _repository.getTrips();
      if (request != _requestGeneration ||
          identity != _authProvider.user?.id) {
        return;
      }
      _trips = loaded;
    } catch (error) {
      if (request == _requestGeneration) {
        _errorMessage = error.toString();
      }
    } finally {
      if (request == _requestGeneration) {
        _isLoading = false;
        _notifyIfAlive();
      }
    }
  }

  Future<SavedTrip?> create(SavedTripDraft draft) async {
    if (_disposed) return null;

    final operationUserId = _authProvider.user?.id;
    if (operationUserId == null) {
      _errorMessage = 'Authentication required.';
      _notifyIfAlive();
      return null;
    }

    final operationGeneration = _requestGeneration;
    const operationKey = '__create__';
    if (_pendingTripIds.contains(operationKey)) return null;

    _errorMessage = null;
    _pendingTripIds.add(operationKey);
    _notifyIfAlive();

    try {
      final trip = await _repository.createTrip(draft);

      if (!_sameOperationSession(
        userId: operationUserId,
        generation: operationGeneration,
      )) {
        return null;
      }

      _trips = [..._trips, trip]
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
      _notifyIfAlive();
      return trip;
    } catch (error) {
      if (_sameOperationSession(
        userId: operationUserId,
        generation: operationGeneration,
      )) {
        _errorMessage = error.toString();
        _notifyIfAlive();
      }
      return null;
    } finally {
      if (_sameOperationSession(
        userId: operationUserId,
        generation: operationGeneration,
      )) {
        _pendingTripIds.remove(operationKey);
        _notifyIfAlive();
      }
    }
  }

  Future<SavedTrip?> update({
    required String tripId,
    required SavedTripDraft draft,
  }) async {
    if (_disposed) return null;

    final operationUserId = _authProvider.user?.id;
    if (operationUserId == null) {
      _errorMessage = 'Authentication required.';
      _notifyIfAlive();
      return null;
    }

    final operationGeneration = _requestGeneration;
    final operationKey = 'update:$tripId';
    if (_rejectIfTripBusy(tripId)) return null;

    _errorMessage = null;
    _pendingTripIds.add(operationKey);
    _notifyIfAlive();

    try {
      final updated = await _repository.updateTrip(
        tripId: tripId,
        draft: draft,
      );

      if (!_sameOperationSession(
        userId: operationUserId,
        generation: operationGeneration,
      )) {
        return null;
      }

      _replace(updated);
      return updated;
    } catch (error) {
      if (_sameOperationSession(
        userId: operationUserId,
        generation: operationGeneration,
      )) {
        _errorMessage = error.toString();
        _notifyIfAlive();
      }
      return null;
    } finally {
      if (_sameOperationSession(
        userId: operationUserId,
        generation: operationGeneration,
      )) {
        _pendingTripIds.remove(operationKey);
        _notifyIfAlive();
      }
    }
  }

  Future<void> delete(String tripId) async {
    if (_disposed) return;
    await deleteSafely(tripId);
  }

  Future<bool> deleteSafely(String tripId) async {
    if (_disposed) return false;

    final operationUserId = _authProvider.user?.id;
    if (operationUserId == null) return false;

    final operationGeneration = _requestGeneration;
    final operationKey = 'delete:$tripId';
    if (_rejectIfTripBusy(tripId)) return false;

    _errorMessage = null;
    _pendingTripIds.add(operationKey);
    _notifyIfAlive();

    try {
      await _repository.deleteTrip(tripId);

      if (!_sameOperationSession(
        userId: operationUserId,
        generation: operationGeneration,
      )) {
        return false;
      }

      _trips = _trips
          .where((trip) => trip.id != tripId)
          .toList(growable: false);
      _notifyIfAlive();
      return true;
    } catch (error) {
      if (_sameOperationSession(
        userId: operationUserId,
        generation: operationGeneration,
      )) {
        _errorMessage = error.toString();
        _notifyIfAlive();
      }
      return false;
    } finally {
      if (_sameOperationSession(
        userId: operationUserId,
        generation: operationGeneration,
      )) {
        _pendingTripIds.remove(operationKey);
        _notifyIfAlive();
      }
    }
  }

  Future<bool> toggleContent({
    required String tripId,
    required String contentId,
  }) async {
    if (_disposed) return false;

    final operationUserId = _authProvider.user?.id;
    final trip = byId(tripId);
    if (operationUserId == null || trip == null) return false;

    final operationGeneration = _requestGeneration;
    final contains = trip.contentIds.contains(contentId);
    final operationKey = 'content:$tripId:$contentId';

    // Every persisted write for one trip shares one mutation lane. This
    // prevents save/remove from racing a trip update or delete as well as
    // another content mutation.
    if (_rejectIfTripBusy(tripId)) return false;

    _errorMessage = null;
    _pendingTripIds.add(operationKey);
    _notifyIfAlive();

    try {
      if (contains) {
        await _repository.removeContent(
          tripId: tripId,
          contentId: contentId,
        );
      } else {
        await _repository.addContent(
          tripId: tripId,
          contentId: contentId,
        );
      }

      if (!_sameOperationSession(
        userId: operationUserId,
        generation: operationGeneration,
      )) {
        return false;
      }

      final fresh = await _repository.getTrip(tripId);

      if (!_sameOperationSession(
        userId: operationUserId,
        generation: operationGeneration,
      )) {
        return false;
      }

      if (fresh == null) {
        _errorMessage = 'saved_trip_not_owned_or_missing';
        _notifyIfAlive();
        return false;
      }

      _replace(fresh);
      return true;
    } catch (error) {
      if (_sameOperationSession(
        userId: operationUserId,
        generation: operationGeneration,
      )) {
        _errorMessage = error.toString();
        _notifyIfAlive();
      }
      return false;
    } finally {
      if (_sameOperationSession(
        userId: operationUserId,
        generation: operationGeneration,
      )) {
        _pendingTripIds.remove(operationKey);
        _notifyIfAlive();
      }
    }
  }

  bool _rejectIfTripBusy(String tripId) {
    if (SavedTripMutationPolicy.canStartTripWrite(
      pendingKeys: _pendingTripIds,
      tripId: tripId,
    )) {
      return false;
    }

    _errorMessage = 'saved_trip_operation_in_progress';
    _notifyIfAlive();
    return true;
  }

  bool _sameOperationSession({
    required String userId,
    required int generation,
  }) {
    return !_disposed &&
        _authProvider.user?.id == userId &&
        _requestGeneration == generation;
  }

  void _replace(SavedTrip trip) {
    if (_disposed) return;

    _trips = [
      for (final current in _trips)
        if (current.id == trip.id) trip else current,
    ]..sort((a, b) => a.startDate.compareTo(b.startDate));

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
    _isLoading = false;
    _pendingTripIds.clear();
    _authProvider.removeListener(_handleAuthChanged);
    super.dispose();
  }
}

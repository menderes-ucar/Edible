import 'package:flutter/foundation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

import '../../../explore/domain/entities/explore_content.dart';
import '../../domain/entities/saved_trip.dart';
import '../../domain/entities/saved_trip_itinerary.dart';
import '../../domain/entities/itinerary_route_optimization.dart';
import '../../domain/repositories/saved_trip_itinerary_repository.dart';
import '../../domain/services/itinerary_manual_edit_policy.dart';
import '../../domain/usecases/generate_saved_trip_itinerary.dart';
import '../../domain/usecases/optimize_itinerary_route.dart';

class SavedTripItineraryProvider extends ChangeNotifier {
  SavedTripItineraryProvider({
    required SavedTripItineraryRepository repository,
    required AuthProvider authProvider,
    GenerateSavedTripItinerary generator =
        const GenerateSavedTripItinerary(),
    OptimizeItineraryRoute routeOptimizer =
        const OptimizeItineraryRoute(),
  })  : _repository = repository,
        _authProvider = authProvider,
        _generator = generator,
        _routeOptimizer = routeOptimizer {
    _authProvider.addListener(_handleAuthChanged);
    _lastIdentity = _identity;
  }

  final SavedTripItineraryRepository _repository;
  final AuthProvider _authProvider;
  final GenerateSavedTripItinerary _generator;
  final OptimizeItineraryRoute _routeOptimizer;

  List<SavedTripItineraryStop> _stops = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _loadedTripId;
  int _unresolvedStopCount = 0;
  int _loadRequestId = 0;
  int _mutationGeneration = 0;
  bool _disposed = false;
  String? _lastIdentity;
  final Map<int, ItineraryRouteOptimization> _optimizations = {};

  List<SavedTripItineraryStop> get stops => _stops;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  int get unresolvedStopCount => _unresolvedStopCount;
  bool get hasUnresolvedStops => _unresolvedStopCount > 0;

  String? get errorCode {
    final message = _errorMessage ?? '';
    if (message.contains('content_not_synced_to_supabase')) {
      return 'content_not_synced_to_supabase';
    }
    if (message.contains('route_requires_exact_coordinates')) {
      return 'route_requires_exact_coordinates';
    }
    if (message.contains('itinerary_capacity_exceeded')) {
      return 'itinerary_capacity_exceeded';
    }
    if (message.contains('itinerary_day_capacity_exceeded')) {
      return 'itinerary_day_capacity_exceeded';
    }
    if (message.contains('itinerary_time_limit_reached')) {
      return 'itinerary_time_limit_reached';
    }
    if (message.contains('saved_trip_not_owned_or_missing') ||
        message.contains('itinerary_stop_not_found')) {
      return 'saved_trip_not_owned_or_missing';
    }
    return _errorMessage == null ? null : 'itinerary_persistence_failed';
  }

  int? get itineraryCapacityLimit {
    final message = _errorMessage ?? '';
    final match = RegExp(r'itinerary_capacity_exceeded:(\d+)')
        .firstMatch(message);
    return int.tryParse(match?.group(1) ?? '');
  }

  ItineraryRouteOptimization? optimizationForDay(int dayIndex) =>
      _optimizations[dayIndex];

  bool canOptimizeDay(int dayIndex) {
    final stops = forDay(dayIndex);
    return stops.length >= 2 &&
        stops.every((stop) => stop.content.metadata.hasExactCoordinates);
  }

  List<SavedTripItineraryStop> forDay(int dayIndex) {
    final result = _stops
        .where((stop) => stop.dayIndex == dayIndex)
        .toList(growable: false);

    result.sort((a, b) {
      final time = a.startMinute.compareTo(b.startMinute);
      if (time != 0) return time;
      return a.sortOrder.compareTo(b.sortOrder);
    });

    return result;
  }

  Future<void> load({
    required String tripId,
    required Iterable<ExploreContent> cityContents,
  }) async {
    if (_disposed) return;

    final identity = _identity;
    final requestId = ++_loadRequestId;
    final switchingTrip = _loadedTripId != tripId;

    if (switchingTrip) {
      // Invalidate any mutation that started for the previous trip.
      // The network request may still finish, but it must never mutate the
      // newly loaded trip's in-memory state.
      _mutationGeneration++;
      _loadedTripId = tripId;
      _stops = const [];
      _unresolvedStopCount = 0;
      _optimizations.clear();
      _isSaving = false;
    }

    _isLoading = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      final raw = await _repository.getRawStops(tripId);
      if (!_sameLoadSession(
        requestId: requestId,
        identity: identity,
        tripId: tripId,
      )) {
        return;
      }
      final byId = {
        for (final content in cityContents) content.id: content,
      };

      final resolved = <SavedTripItineraryStop>[];
      var unresolved = 0;

      for (final row in raw) {
        final contentId = (row['content_id'] ?? '').toString();
        final content = byId[contentId];

        if (content == null) {
          unresolved++;
          continue;
        }

        resolved.add(
          SavedTripItineraryStop(
            id: (row['id'] ?? '').toString(),
            tripId: (row['trip_id'] ?? '').toString(),
            contentId: contentId,
            dayIndex:
                int.tryParse((row['day_index'] ?? '0').toString()) ?? 0,
            startMinute:
                int.tryParse((row['start_minute'] ?? '570').toString()) ??
                    570,
            sortOrder:
                int.tryParse((row['sort_order'] ?? '0').toString()) ?? 0,
            content: content,
          ),
        );
      }

      _stops = List<SavedTripItineraryStop>.unmodifiable(resolved);
      _unresolvedStopCount = unresolved;
    } catch (error) {
      if (_sameLoadSession(
        requestId: requestId,
        identity: identity,
        tripId: tripId,
      )) {
        _errorMessage = error.toString();
      }
    } finally {
      if (_sameLoadSession(
        requestId: requestId,
        identity: identity,
        tripId: tripId,
      )) {
        _isLoading = false;
        _notifyIfAlive();
      }
    }
  }

  Future<bool> generateAndSave({
    required SavedTrip trip,
    required Iterable<ExploreContent> selectedContents,
  }) async {
    if (_disposed || _isSaving) return false;
    if (_loadedTripId != null && _loadedTripId != trip.id) return false;

    final operationIdentity = _identity;
    final operationGeneration = _mutationGeneration;
    final operationTripId = trip.id;
    _isSaving = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      final generated = _generator(
        trip: trip,
        selectedContents: selectedContents,
      );

      await _repository.replaceItinerary(
        tripId: trip.id,
        stops: generated,
      );

      if (!_sameMutationSession(
        identity: operationIdentity,
        generation: operationGeneration,
        tripId: operationTripId,
      )) {
        return false;
      }

      // The persisted itinerary was replaced atomically. Any optimization
      // summary belongs to the previous stop order and must never survive.
      _optimizations.clear();

      await load(
        tripId: trip.id,
        cityContents: selectedContents,
      );

      return true;
    } catch (error) {
      if (_sameMutationSession(
        identity: operationIdentity,
        generation: operationGeneration,
        tripId: operationTripId,
      )) {
        _errorMessage = error.toString();
      }
      return false;
    } finally {
      if (_sameMutationSession(
        identity: operationIdentity,
        generation: operationGeneration,
        tripId: operationTripId,
      )) {
        _isSaving = false;
        _notifyIfAlive();
      }
    }
  }

  Future<bool> addContentToDay({
    required SavedTrip trip,
    required ExploreContent content,
    required int dayIndex,
  }) async {
    if (_disposed || _isSaving) return false;
    if (_loadedTripId != trip.id) return false;
    if (dayIndex < 0 || dayIndex >= trip.dayCount) return false;
    if (_stops.any((stop) => stop.contentId == content.id)) {
      _errorMessage = 'itinerary_content_already_scheduled';
      _notifyIfAlive();
      return false;
    }

    final targetStops = forDay(dayIndex);
    if (!ItineraryManualEditPolicy.canMoveIntoDay(
      targetStopCount: targetStops.length,
      movingWithinSameDay: false,
    )) {
      _errorMessage = 'itinerary_day_capacity_exceeded';
      _notifyIfAlive();
      return false;
    }

    final operationIdentity = _identity;
    final operationGeneration = _mutationGeneration;
    final operationTripId = trip.id;
    final sortOrder = targetStops.length;
    final startMinute = targetStops.isEmpty
        ? 570
        : (targetStops.last.startMinute + 90).clamp(570, 1260).toInt();

    _isSaving = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      final created = await _repository.addStop(
        tripId: trip.id,
        contentId: content.id,
        dayIndex: dayIndex,
        startMinute: startMinute,
        sortOrder: sortOrder,
        content: content,
      );

      if (!_sameMutationSession(
        identity: operationIdentity,
        generation: operationGeneration,
        tripId: operationTripId,
      )) {
        return false;
      }

      _stops = List<SavedTripItineraryStop>.unmodifiable([
        ..._stops,
        created,
      ]);
      _optimizations.remove(dayIndex);
      return true;
    } catch (error) {
      if (_sameMutationSession(
        identity: operationIdentity,
        generation: operationGeneration,
        tripId: operationTripId,
      )) {
        _errorMessage = error.toString();
      }
      return false;
    } finally {
      if (_sameMutationSession(
        identity: operationIdentity,
        generation: operationGeneration,
        tripId: operationTripId,
      )) {
        _isSaving = false;
        _notifyIfAlive();
      }
    }
  }

  Future<bool> moveStop({
    required SavedTripItineraryStop stop,
    required int newDayIndex,
    required int tripDayCount,
  }) async {
    if (_disposed) return false;

    final operationIdentity = _identity;
    final operationGeneration = _mutationGeneration;
    final operationTripId = stop.tripId;
    if (_loadedTripId != operationTripId) return false;
    if (newDayIndex < 0 || newDayIndex >= tripDayCount) return false;
    if (_isSaving) return false;
    if (newDayIndex == stop.dayIndex) return true;

    final targetStops = forDay(newDayIndex);
    if (!ItineraryManualEditPolicy.canMoveIntoDay(
      targetStopCount: targetStops.length,
      movingWithinSameDay: false,
    )) {
      _errorMessage = 'itinerary_day_capacity_exceeded';
      _notifyIfAlive();
      return false;
    }
    final newSortOrder = targetStops.length;
    final newStartMinute = targetStops.isEmpty
        ? 570
        : (targetStops.last.startMinute + 90).clamp(570, 1260).toInt();

    _isSaving = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      await _repository.updateStop(
        stopId: stop.id,
        dayIndex: newDayIndex,
        startMinute: newStartMinute,
        sortOrder: newSortOrder,
      );

      if (!_sameMutationSession(
        identity: operationIdentity,
        generation: operationGeneration,
        tripId: operationTripId,
      )) {
        return false;
      }

      _stops = [
        for (final current in _stops)
          if (current.id == stop.id)
            SavedTripItineraryStop(
              id: current.id,
              tripId: current.tripId,
              contentId: current.contentId,
              dayIndex: newDayIndex,
              startMinute: newStartMinute,
              sortOrder: newSortOrder,
              content: current.content,
            )
          else
            current,
      ];

      _optimizations.remove(stop.dayIndex);
      _optimizations.remove(newDayIndex);
      return true;
    } catch (error) {
      if (_sameMutationSession(
        identity: operationIdentity,
        generation: operationGeneration,
        tripId: operationTripId,
      )) {
        _errorMessage = error.toString();
      }
      return false;
    } finally {
      if (_sameMutationSession(
        identity: operationIdentity,
        generation: operationGeneration,
        tripId: operationTripId,
      )) {
        _isSaving = false;
        _notifyIfAlive();
      }
    }
  }

  Future<bool> changeTime({
    required SavedTripItineraryStop stop,
    required int deltaMinutes,
  }) async {
    if (_disposed) return false;

    final operationIdentity = _identity;
    final operationGeneration = _mutationGeneration;
    final operationTripId = stop.tripId;
    if (_loadedTripId != operationTripId) return false;
    if (_isSaving) return false;

    final minute = ItineraryManualEditPolicy.adjustedMinute(
      currentMinute: stop.startMinute,
      deltaMinutes: deltaMinutes,
    );

    if (!ItineraryManualEditPolicy.wouldChangeTime(
      currentMinute: stop.startMinute,
      deltaMinutes: deltaMinutes,
    )) {
      _errorMessage = 'itinerary_time_limit_reached';
      _notifyIfAlive();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      await _repository.updateStop(
        stopId: stop.id,
        dayIndex: stop.dayIndex,
        startMinute: minute,
        sortOrder: stop.sortOrder,
      );

      if (!_sameMutationSession(
        identity: operationIdentity,
        generation: operationGeneration,
        tripId: operationTripId,
      )) {
        return false;
      }

      _stops = [
        for (final current in _stops)
          if (current.id == stop.id)
            SavedTripItineraryStop(
              id: current.id,
              tripId: current.tripId,
              contentId: current.contentId,
              dayIndex: current.dayIndex,
              startMinute: minute,
              sortOrder: current.sortOrder,
              content: current.content,
            )
          else
            current,
      ];

      return true;
    } catch (error) {
      if (_sameMutationSession(
        identity: operationIdentity,
        generation: operationGeneration,
        tripId: operationTripId,
      )) {
        _errorMessage = error.toString();
      }
      return false;
    } finally {
      if (_sameMutationSession(
        identity: operationIdentity,
        generation: operationGeneration,
        tripId: operationTripId,
      )) {
        _isSaving = false;
        _notifyIfAlive();
      }
    }
  }


  Future<ItineraryRouteOptimization?> optimizeDay(
    int dayIndex,
  ) async {
    if (_disposed) return null;

    final operationIdentity = _identity;
    final operationGeneration = _mutationGeneration;
    if (_isSaving) return null;

    final dayStops = forDay(dayIndex);

    if (dayStops.length < 2) {
      return null;
    }

    if (!dayStops.every(
      (stop) => stop.content.metadata.hasExactCoordinates,
    )) {
      _errorMessage = 'route_requires_exact_coordinates';
      _notifyIfAlive();
      return null;
    }

    final operationTripId = dayStops.first.tripId;
    if (_loadedTripId != operationTripId) return null;

    _isSaving = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      final optimization = _routeOptimizer(dayStops);
      final ordered = optimization.orderedStops;

      if (optimization.savedMeters <= 1) {
        _optimizations[dayIndex] = optimization;
        _notifyIfAlive();
        return optimization;
      }

      // Preserve the day's existing chronological time slots while changing
      // only which stop occupies each slot.
      final timeSlots = dayStops
          .map((stop) => stop.startMinute)
          .toList(growable: false)
        ..sort();

      final replacements = <String, SavedTripItineraryStop>{};

      for (var index = 0; index < ordered.length; index++) {
        final stop = ordered[index];
        final startMinute = timeSlots[index];

        replacements[stop.id] = SavedTripItineraryStop(
          id: stop.id,
          tripId: stop.tripId,
          contentId: stop.contentId,
          dayIndex: dayIndex,
          startMinute: startMinute,
          sortOrder: index,
          content: stop.content,
        );
      }

      await _repository.updateStopsBatch(
        tripId: ordered.first.tripId,
        stops: replacements.values.toList(growable: false),
      );

      if (!_sameMutationSession(
        identity: operationIdentity,
        generation: operationGeneration,
        tripId: operationTripId,
      )) {
        return null;
      }

      _stops = [
        for (final stop in _stops)
          replacements[stop.id] ?? stop,
      ];

      _optimizations[dayIndex] = optimization;
      return optimization;
    } catch (error) {
      if (_sameMutationSession(
        identity: operationIdentity,
        generation: operationGeneration,
        tripId: operationTripId,
      )) {
        _errorMessage = error.toString();
      }
      return null;
    } finally {
      if (_sameMutationSession(
        identity: operationIdentity,
        generation: operationGeneration,
        tripId: operationTripId,
      )) {
        _isSaving = false;
        _notifyIfAlive();
      }
    }
  }

  Future<bool> remove(SavedTripItineraryStop stop) async {
    if (_disposed) return false;

    final operationIdentity = _identity;
    final operationGeneration = _mutationGeneration;
    final operationTripId = stop.tripId;
    if (_loadedTripId != operationTripId) return false;
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      await _repository.deleteStop(stop.id);

      if (!_sameMutationSession(
        identity: operationIdentity,
        generation: operationGeneration,
        tripId: operationTripId,
      )) {
        return false;
      }

      _stops = _stops
          .where((current) => current.id != stop.id)
          .toList(growable: false);
      _optimizations.remove(stop.dayIndex);
      return true;
    } catch (error) {
      if (_sameMutationSession(
        identity: operationIdentity,
        generation: operationGeneration,
        tripId: operationTripId,
      )) {
        _errorMessage = error.toString();
      }
      return false;
    } finally {
      if (_sameMutationSession(
        identity: operationIdentity,
        generation: operationGeneration,
        tripId: operationTripId,
      )) {
        _isSaving = false;
        _notifyIfAlive();
      }
    }
  }

  void clear() {
    if (_disposed) return;

    _loadRequestId++;
    _mutationGeneration++;
    _loadedTripId = null;
    _stops = const [];
    _unresolvedStopCount = 0;
    _optimizations.clear();
    _errorMessage = null;
    _isLoading = false;
    _isSaving = false;
    _notifyIfAlive();
  }
  String get _identity => _authProvider.user?.id ?? 'guest';

  void _handleAuthChanged() {
    if (_disposed) return;

    final identity = _identity;
    if (_lastIdentity == identity) return;

    _lastIdentity = identity;
    _loadRequestId++;
    _mutationGeneration++;
    _loadedTripId = null;
    _stops = const [];
    _unresolvedStopCount = 0;
    _optimizations.clear();
    _isLoading = false;
    _isSaving = false;
    _errorMessage = null;
    _notifyIfAlive();
  }

  bool _sameLoadSession({
    required int requestId,
    required String identity,
    required String tripId,
  }) {
    return !_disposed &&
        requestId == _loadRequestId &&
        identity == _identity &&
        tripId == _loadedTripId;
  }

  bool _sameMutationSession({
    required String identity,
    required int generation,
    required String tripId,
  }) {
    return !_disposed &&
        identity == _identity &&
        generation == _mutationGeneration &&
        tripId == _loadedTripId;
  }

  void _notifyIfAlive() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _loadRequestId++;
    _mutationGeneration++;
    _isLoading = false;
    _isSaving = false;
    _authProvider.removeListener(_handleAuthChanged);
    super.dispose();
  }

}

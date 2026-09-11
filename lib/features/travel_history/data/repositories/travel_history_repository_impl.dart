import '../../../../core/services/supabase_service.dart';
import '../../../arrival_detection/domain/entities/detected_arrival.dart';
import '../../domain/entities/travel_visit.dart';
import '../../domain/repositories/travel_history_repository.dart';
import '../datasources/travel_history_local_data_source.dart';
import '../datasources/travel_history_remote_data_source.dart';

class TravelHistoryRepositoryImpl implements TravelHistoryRepository {
  const TravelHistoryRepositoryImpl({
    required TravelHistoryRemoteDataSource remoteDataSource,
    required TravelHistoryLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final TravelHistoryRemoteDataSource _remoteDataSource;
  final TravelHistoryLocalDataSource _localDataSource;

  bool get _isAuthenticated =>
      SupabaseService.client?.auth.currentUser != null;

  @override
  Future<List<TravelVisit>> getVisits() async {
    if (!_isAuthenticated) {
      return _localDataSource.getVisits();
    }

    final remoteVisits = await _remoteDataSource.getVisits();
    final guestVisits = await _localDataSource.getVisits();

    if (guestVisits.isEmpty) {
      return remoteVisits;
    }

    try {
      await _remoteDataSource.importGuestVisits(guestVisits);
      await _localDataSource.clearVisits();
      return _remoteDataSource.getVisits();
    } catch (_) {
      // Never hide guest travel history just because migration is temporarily
      // unavailable. Keep the local file for the next retry and merge it into
      // the current view without duplicating same-city/same-day visits.
      return _mergeVisits(remoteVisits, guestVisits);
    }
  }

  List<TravelVisit> _mergeVisits(
    List<TravelVisit> remoteVisits,
    List<TravelVisit> guestVisits,
  ) {
    final byKey = <String, TravelVisit>{};

    for (final visit in [...remoteVisits, ...guestVisits]) {
      final key = _visitKey(visit);
      final existing = byKey[key];

      if (existing == null) {
        byKey[key] = visit;
        continue;
      }

      byKey[key] = TravelVisit(
        id: existing.id,
        countryCode: existing.countryCode,
        countryName: existing.countryName,
        cityName: existing.cityName,
        visitDay: existing.visitDay,
        firstSeenAt: existing.firstSeenAt.isBefore(visit.firstSeenAt)
            ? existing.firstSeenAt
            : visit.firstSeenAt,
        lastSeenAt: existing.lastSeenAt.isAfter(visit.lastSeenAt)
            ? existing.lastSeenAt
            : visit.lastSeenAt,
        detectionCount: existing.detectionCount + visit.detectionCount,
        latitude: visit.latitude ?? existing.latitude,
        longitude: visit.longitude ?? existing.longitude,
      );
    }

    final merged = byKey.values.toList(growable: false)
      ..sort((a, b) => b.lastSeenAt.compareTo(a.lastSeenAt));

    return merged;
  }

  String _visitKey(TravelVisit visit) {
    final day = visit.visitDay;
    return '${visit.countryCode.trim().toUpperCase()}|'
        '${visit.cityName.trim().toLowerCase()}|'
        '${day.year}-${day.month}-${day.day}';
  }

  @override
  Future<void> recordArrival({
    required DetectedArrival arrival,
    required double latitude,
    required double longitude,
  }) async {
    if (_isAuthenticated) {
      await _remoteDataSource.recordArrival(
        arrival: arrival,
        latitude: latitude,
        longitude: longitude,
      );
      return;
    }

    await _localDataSource.recordArrival(
      arrival: arrival,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

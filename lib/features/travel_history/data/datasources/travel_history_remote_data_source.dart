import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../arrival_detection/domain/entities/detected_arrival.dart';
import '../../domain/entities/travel_visit.dart';
import '../models/travel_visit_model.dart';

class TravelHistoryRemoteDataSource {
  SupabaseClient get _client {
    final client = SupabaseService.client;
    if (client == null) {
      throw StateError('Supabase is not initialized.');
    }
    return client;
  }

  bool get isAuthenticated => _client.auth.currentUser != null;

  Future<List<TravelVisitModel>> getVisits() async {
    if (!isAuthenticated) return const [];

    final rows = await _client
        .from('travel_visits')
        .select(
          'id,country_code,country_name,city_name,visit_day,'
          'first_seen_at,last_seen_at,detection_count,latitude,longitude',
        )
        .eq('user_id', _client.auth.currentUser!.id)
        .order('visit_day', ascending: false)
        .order('last_seen_at', ascending: false);

    return (rows as List<dynamic>)
        .map(
          (row) => TravelVisitModel.fromMap(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList(growable: false);
  }


  Future<void> importGuestVisits(List<TravelVisit> visits) async {
    if (!isAuthenticated || visits.isEmpty) return;

    await _client.rpc(
      'import_guest_travel_visits',
      params: {
        'p_visits': visits
            .map(
              (visit) => {
                'source_visit_id': visit.id,
                'country_code': visit.countryCode,
                'country_name': visit.countryName,
                'city_name': visit.cityName,
                'visit_day': _dateOnly(visit.visitDay),
                'first_seen_at': visit.firstSeenAt.toUtc().toIso8601String(),
                'last_seen_at': visit.lastSeenAt.toUtc().toIso8601String(),
                'detection_count': visit.detectionCount,
                'latitude': visit.latitude,
                'longitude': visit.longitude,
              },
            )
            .toList(growable: false),
      },
    );
  }

  String _dateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  Future<void> recordArrival({
    required DetectedArrival arrival,
    required double latitude,
    required double longitude,
  }) async {
    if (!isAuthenticated) return;

    await _client.rpc(
      'record_travel_visit',
      params: {
        'p_country_code': arrival.countryCode,
        'p_country_name': arrival.countryName,
        'p_city_name': arrival.cityName,
        'p_latitude': latitude,
        'p_longitude': longitude,
      },
    );
  }
}

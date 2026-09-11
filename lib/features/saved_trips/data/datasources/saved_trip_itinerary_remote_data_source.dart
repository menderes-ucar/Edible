import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../explore/domain/entities/explore_content.dart';
import '../../domain/entities/saved_trip_itinerary.dart';

class SavedTripItineraryPersistenceException implements Exception {
  const SavedTripItineraryPersistenceException(this.code);

  final String code;

  @override
  String toString() =>
      'SavedTripItineraryPersistenceException($code)';
}

class SavedTripItineraryRemoteDataSource {
  SupabaseClient get _client {
    final client = SupabaseService.client;
    if (client == null) {
      throw StateError('Supabase is not initialized.');
    }
    return client;
  }

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Authentication required.');
    }
    return user.id;
  }

  Future<List<Map<String, dynamic>>> getRawStops(
    String tripId,
  ) async {
    await _requireOwnedTrip(tripId);

    final rows = await _client
        .from('saved_trip_itinerary_stops')
        .select(
          'id,trip_id,content_id,day_index,start_minute,sort_order',
        )
        .eq('trip_id', tripId)
        .order('day_index')
        .order('sort_order');

    return (rows as List<dynamic>)
        .map(
          (row) => Map<String, dynamic>.from(row as Map),
        )
        .toList(growable: false);
  }

  Future<void> replaceItinerary({
    required String tripId,
    required List<GeneratedItineraryStop> stops,
  }) async {
    await _requireOwnedTrip(tripId);
    await _requireCanonicalContents(
      stops.map((stop) => stop.contentId),
    );

    await _client.rpc(
      'replace_saved_trip_itinerary',
      params: {
        'p_trip_id': tripId,
        'p_stops': stops
            .map(
              (stop) => {
                'content_id': stop.contentId,
                'day_index': stop.dayIndex,
                'start_minute': stop.startMinute,
                'sort_order': stop.sortOrder,
              },
            )
            .toList(growable: false),
      },
    );
  }

  Future<SavedTripItineraryStop> addStop({
    required String tripId,
    required String contentId,
    required int dayIndex,
    required int startMinute,
    required int sortOrder,
    required ExploreContent content,
  }) async {
    await _requireOwnedTrip(tripId);
    await _requireCanonicalContents([contentId]);

    final row = await _client
        .from('saved_trip_itinerary_stops')
        .insert({
          'trip_id': tripId,
          'content_id': contentId,
          'day_index': dayIndex,
          'start_minute': startMinute,
          'sort_order': sortOrder,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select('id,trip_id,content_id,day_index,start_minute,sort_order')
        .single();

    final data = Map<String, dynamic>.from(row as Map);
    return SavedTripItineraryStop(
      id: data['id'].toString(),
      tripId: data['trip_id'].toString(),
      contentId: data['content_id'].toString(),
      dayIndex: (data['day_index'] as num).toInt(),
      startMinute: (data['start_minute'] as num).toInt(),
      sortOrder: (data['sort_order'] as num).toInt(),
      content: content,
    );
  }

  Future<void> updateStop({
    required String stopId,
    required int dayIndex,
    required int startMinute,
    required int sortOrder,
  }) async {
    await _requireOwnedStop(stopId);

    final updated = await _client
        .from('saved_trip_itinerary_stops')
        .update({
          'day_index': dayIndex,
          'start_minute': startMinute,
          'sort_order': sortOrder,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', stopId)
        .select('id')
        .maybeSingle();

    if (updated == null) {
      throw const SavedTripItineraryPersistenceException(
        'itinerary_stop_not_found',
      );
    }
  }

  Future<void> updateStopsBatch({
    required String tripId,
    required List<SavedTripItineraryStop> stops,
  }) async {
    if (stops.isEmpty) return;

    await _requireOwnedTrip(tripId);

    await _client.rpc(
      'update_saved_trip_itinerary_stops',
      params: {
        'p_trip_id': tripId,
        'p_stops': stops
            .map(
              (stop) => {
                'id': stop.id,
                'day_index': stop.dayIndex,
                'start_minute': stop.startMinute,
                'sort_order': stop.sortOrder,
              },
            )
            .toList(growable: false),
      },
    );
  }

  Future<void> deleteStop(String stopId) async {
    await _requireOwnedStop(stopId);

    final deleted = await _client
        .from('saved_trip_itinerary_stops')
        .delete()
        .eq('id', stopId)
        .select('id')
        .maybeSingle();

    if (deleted == null) {
      throw const SavedTripItineraryPersistenceException(
        'itinerary_stop_not_found',
      );
    }
  }
  Future<void> _requireOwnedTrip(String tripId) async {
    final row = await _client
        .from('saved_trips')
        .select('id')
        .eq('id', tripId)
        .eq('user_id', _userId)
        .maybeSingle();

    if (row == null) {
      throw const SavedTripItineraryPersistenceException(
        'saved_trip_not_owned_or_missing',
      );
    }
  }

  Future<void> _requireOwnedStop(String stopId) async {
    final stop = await _client
        .from('saved_trip_itinerary_stops')
        .select('trip_id')
        .eq('id', stopId)
        .maybeSingle();

    final tripId = stop?['trip_id']?.toString();
    if (tripId == null || tripId.isEmpty) {
      throw const SavedTripItineraryPersistenceException(
        'itinerary_stop_not_found',
      );
    }

    await _requireOwnedTrip(tripId);
  }

  Future<void> _requireCanonicalContents(
    Iterable<String> contentIds,
  ) async {
    final uniqueIds = contentIds
        .where((id) => id.trim().isNotEmpty)
        .toSet();

    if (uniqueIds.isEmpty) return;

    final rows = await _client
        .from('contents')
        .select('id')
        .inFilter('id', uniqueIds.toList(growable: false));

    final existing = (rows as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .map((row) => row['id']?.toString())
        .whereType<String>()
        .toSet();

    if (!existing.containsAll(uniqueIds)) {
      throw const SavedTripItineraryPersistenceException(
        'content_not_synced_to_supabase',
      );
    }
  }

}

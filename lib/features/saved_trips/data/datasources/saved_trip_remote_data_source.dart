import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/saved_trip_draft.dart';
import '../../domain/services/saved_trip_date_policy.dart';
import '../models/saved_trip_model.dart';

class SavedTripPersistenceException implements Exception {
  const SavedTripPersistenceException(this.code);

  final String code;

  @override
  String toString() => 'SavedTripPersistenceException($code)';
}

class SavedTripRemoteDataSource {
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

  Future<List<SavedTripModel>> getTrips() async {
    final rows = await _client
        .from('saved_trips')
        .select()
        .eq('user_id', _userId)
        .order('start_date', ascending: true);

    final tripRows = (rows as List<dynamic>)
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList(growable: false);

    if (tripRows.isEmpty) return const [];

    final tripIds = tripRows
        .map((row) => (row['id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    final contentIdsByTrip = await _contentIdsForTrips(tripIds);

    return tripRows
        .map(
          (map) => SavedTripModel.fromMap(
            map,
            contentIds: contentIdsByTrip[(map['id'] ?? '').toString()] ??
                const <String>[],
          ),
        )
        .toList(growable: false);
  }

  Future<SavedTripModel?> getTrip(String tripId) async {
    final row = await _client
        .from('saved_trips')
        .select()
        .eq('id', tripId)
        .eq('user_id', _userId)
        .maybeSingle();

    if (row == null) return null;

    return SavedTripModel.fromMap(
      Map<String, dynamic>.from(row),
      contentIds: await _contentIds(tripId),
    );
  }

  Future<SavedTripModel> createTrip(
    SavedTripDraft draft,
  ) async {
    SavedTripDatePolicy.requireValidRange(
      startDate: draft.startDate,
      endDate: draft.endDate,
    );

    final row = await _client
        .from('saved_trips')
        .insert({
          'user_id': _userId,
          ..._draftMap(draft),
        })
        .select()
        .single();

    return SavedTripModel.fromMap(
      Map<String, dynamic>.from(row),
    );
  }

  Future<SavedTripModel> updateTrip({
    required String tripId,
    required SavedTripDraft draft,
  }) async {
    SavedTripDatePolicy.requireValidRange(
      startDate: draft.startDate,
      endDate: draft.endDate,
    );

    await _requireOwnedTrip(tripId);

    final row = await _client
        .from('saved_trips')
        .update({
          'name': draft.name.trim(),
          'start_date': _dateOnly(draft.startDate),
          'end_date': _dateOnly(draft.endDate),
          'notes': draft.notes.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', tripId)
        .eq('user_id', _userId)
        .select()
        .single();

    return SavedTripModel.fromMap(
      Map<String, dynamic>.from(row),
      contentIds: await _contentIds(tripId),
    );
  }

  Future<void> deleteTrip(String tripId) async {
    await _requireOwnedTrip(tripId);

    final deleted = await _client
        .from('saved_trips')
        .delete()
        .eq('id', tripId)
        .eq('user_id', _userId)
        .select('id')
        .maybeSingle();

    if (deleted == null) {
      throw const SavedTripPersistenceException(
        'saved_trip_not_owned_or_missing',
      );
    }
  }

  Future<void> addContent({
    required String tripId,
    required String contentId,
  }) async {
    await _requireOwnedTrip(tripId);
    await _requireCanonicalContent(contentId);

    await _client.from('saved_trip_items').upsert(
      {
        'trip_id': tripId,
        'content_id': contentId,
      },
      onConflict: 'trip_id,content_id',
    );
  }

  Future<void> removeContent({
    required String tripId,
    required String contentId,
  }) async {
    await _requireOwnedTrip(tripId);

    await _client
        .from('saved_trip_items')
        .delete()
        .eq('trip_id', tripId)
        .eq('content_id', contentId);
  }

  Future<void> _requireCanonicalContent(String contentId) async {
    final row = await _client
        .from('contents')
        .select('id')
        .eq('id', contentId)
        .maybeSingle();

    if (row == null) {
      throw const SavedTripPersistenceException(
        'content_not_synced_to_supabase',
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
      throw const SavedTripPersistenceException(
        'saved_trip_not_owned_or_missing',
      );
    }
  }

  Future<List<String>> _contentIds(String tripId) async {
    final rows = await _client
        .from('saved_trip_items')
        .select('content_id')
        .eq('trip_id', tripId)
        .order('created_at');

    return (rows as List<dynamic>)
        .map(
          (row) => (Map<String, dynamic>.from(row as Map)['content_id'] ?? '')
              .toString(),
        )
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }

  Future<Map<String, List<String>>> _contentIdsForTrips(
    List<String> tripIds,
  ) async {
    if (tripIds.isEmpty) return const {};

    final rows = await _client
        .from('saved_trip_items')
        .select('trip_id,content_id,created_at')
        .inFilter('trip_id', tripIds)
        .order('created_at');

    final grouped = <String, List<String>>{};

    for (final raw in rows as List<dynamic>) {
      final row = Map<String, dynamic>.from(raw as Map);
      final tripId = (row['trip_id'] ?? '').toString();
      final contentId = (row['content_id'] ?? '').toString();

      if (tripId.isEmpty || contentId.isEmpty) continue;
      grouped.putIfAbsent(tripId, () => <String>[]).add(contentId);
    }

    return {
      for (final entry in grouped.entries)
        entry.key: List<String>.unmodifiable(entry.value),
    };
  }

  Map<String, dynamic> _draftMap(SavedTripDraft draft) {
    return {
      'name': draft.name.trim(),
      'country_code': draft.countryCode.trim().toUpperCase(),
      'country_name': draft.countryName.trim(),
      'city_name': draft.cityName.trim(),
      'start_date': _dateOnly(draft.startDate),
      'end_date': _dateOnly(draft.endDate),
      'notes': draft.notes.trim(),
    };
  }

  String _dateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

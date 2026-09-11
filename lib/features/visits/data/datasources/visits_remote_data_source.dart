import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';

class VisitsRemoteDataSource {
  static const _travelMemoryBucket = 'travel-memory-photos';

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




  Future<List<Map<String, dynamic>>> getCountryMastery() async {
    final rows = await _client.rpc('get_country_mastery');

    return (rows as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> getTravelDna() async {
    final row = await _client.rpc('get_travel_dna').maybeSingle();

    if (row == null) {
      return <String, dynamic>{
        'visited_count': 0,
        'tried_count': 0,
        'category_counts': <String, int>{},
      };
    }

    return Map<String, dynamic>.from(row as Map);
  }

  Future<Map<String, dynamic>> getYearSummary(int year) async {
    if (year < 2000 || year > 2200) {
      throw ArgumentError.value(year, 'year', 'Invalid travel summary year.');
    }

    final row = await _client.rpc(
      'get_travel_year_summary',
      params: {'p_year': year},
    ).maybeSingle();

    if (row == null) {
      return <String, dynamic>{
        'year': year,
        'country_count': 0,
        'city_count': 0,
        'travel_day_count': 0,
        'photo_count': 0,
        'active_years': const <int>[],
      };
    }

    return Map<String, dynamic>.from(row as Map);
  }

  Future<List<Map<String, dynamic>>> getCountryQuests(
    String languageCode,
  ) async {
    final rows = await _client.rpc(
      'get_country_quests',
      params: {'p_locale': languageCode},
    );

    return (rows as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> getCountryBadges() async {
    final client = _client;
    final userId = _userId;
    final rows = await client.rpc('get_country_visit_badges');

    final mapped = (rows as List<dynamic>)
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList(growable: false);

    return Future.wait(
      mapped.map((row) async {
        final path = row['cover_photo_path']?.toString().trim();

        if (path == null ||
            path.isEmpty ||
            !path.startsWith('$userId/')) {
          row['cover_photo_path'] = null;
          row['cover_photo_url'] = null;
          return row;
        }

        try {
          row['cover_photo_url'] = await client.storage
              .from(_travelMemoryBucket)
              .createSignedUrl(path, 3600);
        } catch (_) {
          // A deleted/private/broken image must not block the Visits page.
          // Keep photo_count from the database, but render the badge fallback.
          row['cover_photo_url'] = null;
        }

        return row;
      }),
    );
  }
}

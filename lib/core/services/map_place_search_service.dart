import 'dart:convert';
import 'dart:io';

class MapPlaceSearchResult {
  const MapPlaceSearchResult({
    required this.title,
    required this.latitude,
    required this.longitude,
  });

  final String title;
  final double latitude;
  final double longitude;
}

/// Global fallback for map search when the requested place is not in Edible's
/// curated catalog. It uses Wikipedia's public search/coordinate data, so a
/// traveler can type Beijing, Riyadh, Tokyo, etc. even when the current
/// catalog/category filter has no matching discovery.
class MapPlaceSearchService {
  MapPlaceSearchService._();

  static final instance = MapPlaceSearchService._();

  Future<MapPlaceSearchResult?> search({
    required String query,
    required String locale,
  }) async {
    final requested = query.trim();
    if (requested.length < 2) return null;

    final languages = <String>[
      _language(locale),
      if (_language(locale) != 'en') 'en',
    ];

    for (final language in languages) {
      final result = await _searchWikipedia(
        query: requested,
        language: language,
      );
      if (result != null) return result;
    }
    return null;
  }

  Future<MapPlaceSearchResult?> _searchWikipedia({
    required String query,
    required String language,
  }) async {
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
      final searchUri = Uri.https('$language.wikipedia.org', '/w/api.php', {
        'action': 'query',
        'list': 'search',
        'srsearch': query,
        'srnamespace': '0',
        'srlimit': '5',
        'format': 'json',
        'origin': '*',
      });
      final searchReq = await client.getUrl(searchUri);
      searchReq.headers.set(HttpHeaders.userAgentHeader, 'Edible/1.0');
      final searchRes = await searchReq.close().timeout(const Duration(seconds: 7));
      if (searchRes.statusCode != 200) return null;
      final searchJson = jsonDecode(await utf8.decoder.bind(searchRes).join());
      final rows = (searchJson['query']?['search'] as List?) ?? const [];
      if (rows.isEmpty) return null;

      final titles = rows
          .map((row) => (row as Map)['title']?.toString())
          .whereType<String>()
          .where((title) => title.trim().isNotEmpty)
          .take(5)
          .join('|');
      if (titles.isEmpty) return null;

      final coordinateUri = Uri.https('$language.wikipedia.org', '/w/api.php', {
        'action': 'query',
        'titles': titles,
        'prop': 'coordinates',
        'format': 'json',
        'origin': '*',
      });
      final coordinateReq = await client.getUrl(coordinateUri);
      coordinateReq.headers.set(HttpHeaders.userAgentHeader, 'Edible/1.0');
      final coordinateRes =
          await coordinateReq.close().timeout(const Duration(seconds: 7));
      if (coordinateRes.statusCode != 200) return null;
      final coordinateJson =
          jsonDecode(await utf8.decoder.bind(coordinateRes).join());
      final pages =
          (coordinateJson['query']?['pages'] as Map?)?.values ?? const [];

      for (final raw in pages) {
        final page = Map<String, dynamic>.from(raw as Map);
        final coordinates = page['coordinates'] as List?;
        if (coordinates == null || coordinates.isEmpty) continue;
        final coordinate = Map<String, dynamic>.from(coordinates.first as Map);
        final lat = (coordinate['lat'] as num?)?.toDouble();
        final lon = (coordinate['lon'] as num?)?.toDouble();
        final title = page['title']?.toString().trim() ?? '';
        if (lat == null || lon == null || title.isEmpty) continue;
        return MapPlaceSearchResult(
          title: title,
          latitude: lat,
          longitude: lon,
        );
      }
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
    return null;
  }

  String _language(String raw) {
    final code = raw.trim().toLowerCase().split(RegExp('[-_]')).first;
    const supported = {
      'en', 'tr', 'de', 'fr', 'es', 'it', 'ar', 'pt', 'ja', 'ko', 'zh', 'ru', 'nl'
    };
    return supported.contains(code) ? code : 'en';
  }
}

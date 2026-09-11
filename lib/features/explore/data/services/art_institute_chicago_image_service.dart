import 'dart:convert';
import 'dart:io';

class ArtInstituteChicagoImageResult {
  const ArtInstituteChicagoImageResult({required this.imageUrl, required this.sourceUrl, required this.attribution, required this.score});
  final String imageUrl;
  final String sourceUrl;
  final String attribution;
  final double score;
}

/// Art Institute of Chicago public API. No API key is required.
class ArtInstituteChicagoImageService {
  ArtInstituteChicagoImageService._();
  static final instance = ArtInstituteChicagoImageService._();
  final Map<String, ArtInstituteChicagoImageResult?> _cache = {};

  Future<ArtInstituteChicagoImageResult?> resolve({required String title, String? city, String? country}) async {
    final query = [title, city, country].whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).join(' ');
    final key = query.toLowerCase();
    if (_cache.containsKey(key)) return _cache[key];
    HttpClient? client;
    try {
      final uri = Uri.https('api.artic.edu', '/api/v1/artworks/search', {
        'q': query,
        'limit': '20',
        'fields': 'id,title,image_id,description,thumbnail,date_display',
      });
      client = HttpClient();
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.userAgentHeader, 'Edible/1.0');
      final res = await req.close().timeout(const Duration(seconds: 3));
      if (res.statusCode != 200) return _cache[key] = null;
      final decoded = jsonDecode(await utf8.decoder.bind(res).join());
      final rows = decoded['data'];
      final config = decoded['config'];
      if (rows is! List || config is! Map) return _cache[key] = null;
      final iiif = config['iiif_url']?.toString() ?? 'https://www.artic.edu/iiif/2';
      ArtInstituteChicagoImageResult? best;
      for (final raw in rows) {
        if (raw is! Map) continue;
        final imageId = raw['image_id']?.toString() ?? '';
        if (imageId.isEmpty) continue;
        final text = '${raw['title'] ?? ''} ${raw['description'] ?? ''}';
        final score = _score(title, city, country, text);
        if (score < 0.25) continue;
        final candidate = ArtInstituteChicagoImageResult(
          imageUrl: '$iiif/$imageId/full/1200,/0/default.jpg',
          sourceUrl: 'https://www.artic.edu/artworks/${raw['id']}',
          attribution: 'Art Institute of Chicago',
          score: score + 0.28,
        );
        if (best == null || candidate.score > best.score) best = candidate;
      }
      return _cache[key] = best;
    } catch (_) {
      return _cache[key] = null;
    } finally {
      client?.close(force: true);
    }
  }

  double _score(String title, String? city, String? country, String candidate) {
    final wanted = _normalize([title, city, country].whereType<String>().join(' '));
    final text = _normalize(candidate);
    final tokens = wanted.split(' ').where((e) => e.length > 2).toSet();
    if (tokens.isEmpty) return 0;
    return tokens.where(text.contains).length / tokens.length;
  }
  String _normalize(String value) => value.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

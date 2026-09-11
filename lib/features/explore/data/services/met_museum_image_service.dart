import 'dart:convert';
import 'dart:io';

class MetMuseumImageResult {
  const MetMuseumImageResult({required this.imageUrl, required this.sourceUrl, required this.attribution, required this.score});
  final String imageUrl;
  final String sourceUrl;
  final String attribution;
  final double score;
}

/// Metropolitan Museum of Art public API. No API key is required.
class MetMuseumImageService {
  MetMuseumImageService._();
  static final instance = MetMuseumImageService._();
  final Map<String, MetMuseumImageResult?> _cache = {};

  Future<MetMuseumImageResult?> resolve({required String title, String? city, String? country}) async {
    final query = [title, city, country].whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).join(' ');
    final key = query.toLowerCase();
    if (_cache.containsKey(key)) return _cache[key];
    HttpClient? client;
    try {
      final searchUri = Uri.https('collectionapi.metmuseum.org', '/public/collection/v1/search', {'q': query, 'hasImages': 'true'});
      client = HttpClient();
      final req = await client.getUrl(searchUri);
      req.headers.set(HttpHeaders.userAgentHeader, 'Edible/1.0');
      final res = await req.close().timeout(const Duration(seconds: 3));
      if (res.statusCode != 200) return _cache[key] = null;
      final decoded = jsonDecode(await utf8.decoder.bind(res).join());
      final ids = decoded['objectIDs'];
      if (ids is! List || ids.isEmpty) return _cache[key] = null;

      MetMuseumImageResult? best;
      final max = ids.take(6);
      for (final id in max) {
        final objectId = id.toString();
        try {
          final objectUri = Uri.https('collectionapi.metmuseum.org', '/public/collection/v1/objects/$objectId');
          final objectReq = await client.getUrl(objectUri);
          objectReq.headers.set(HttpHeaders.userAgentHeader, 'Edible/1.0');
          final objectRes = await objectReq.close().timeout(const Duration(seconds: 2));
          if (objectRes.statusCode != 200) continue;
          final raw = jsonDecode(await utf8.decoder.bind(objectRes).join());
          if (raw is! Map) continue;
          final image = raw['primaryImage']?.toString() ?? '';
          if (image.isEmpty) continue;
          final text = '${raw['title'] ?? ''} ${raw['objectName'] ?? ''} ${raw['culture'] ?? ''} ${raw['city'] ?? ''} ${raw['country'] ?? ''}';
          final score = _score(title, city, country, text);
          if (score < 0.20) continue;
          final candidate = MetMuseumImageResult(
            imageUrl: image,
            sourceUrl: raw['objectURL']?.toString() ?? 'https://www.metmuseum.org/art/collection',
            attribution: 'The Metropolitan Museum of Art',
            score: score + 0.25,
          );
          if (best == null || candidate.score > best.score) best = candidate;
        } catch (_) {}
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

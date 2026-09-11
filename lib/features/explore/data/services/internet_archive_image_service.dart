import 'dart:convert';
import 'dart:io';

class InternetArchiveImageResult {
  const InternetArchiveImageResult({
    required this.imageUrl,
    required this.sourceUrl,
    required this.attribution,
    required this.score,
  });

  final String imageUrl;
  final String sourceUrl;
  final String attribution;
  final double score;
}

/// Internet Archive advanced search. No API key is required.
class InternetArchiveImageService {
  InternetArchiveImageService._();
  static final instance = InternetArchiveImageService._();

  final Map<String, InternetArchiveImageResult?> _cache = {};

  Future<InternetArchiveImageResult?> resolve({
    required String title,
    String? city,
    String? country,
  }) async {
    final queries = <String>{
      [title, city, country].whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).join(' '),
      [title, city].whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).join(' '),
      title.trim(),
    }.where((e) => e.isNotEmpty).toList();

    InternetArchiveImageResult? best;
    for (final query in queries) {
      final key = query.toLowerCase();
      if (_cache.containsKey(key)) {
        final cached = _cache[key];
        if (cached != null && (best == null || cached.score > best.score)) best = cached;
        continue;
      }

      HttpClient? client;
      try {
        final uri = Uri.https('archive.org', '/advancedsearch.php', {
          'q': 'mediatype:image AND title:($query)',
          'fl[]': 'identifier,title,description',
          'rows': '20',
          'output': 'json',
        });
        client = HttpClient();
        final req = await client.getUrl(uri);
        req.headers.set(HttpHeaders.userAgentHeader, 'Edible/1.0');
        final res = await req.close().timeout(const Duration(seconds: 3));
        if (res.statusCode != 200) {
          _cache[key] = null;
          continue;
        }
        final decoded = jsonDecode(await utf8.decoder.bind(res).join());
        final docs = decoded['response']?['docs'];
        if (docs is! List) {
          _cache[key] = null;
          continue;
        }

        InternetArchiveImageResult? localBest;
        var localScore = 0.0;
        for (final raw in docs) {
          if (raw is! Map) continue;
          final id = raw['identifier']?.toString() ?? '';
          if (id.isEmpty) continue;
          final text = '${raw['title'] ?? ''} ${raw['description'] ?? ''}';
          final score = _score(title, city, country, text);
          if (score < 0.35) continue;
          // IA item metadata exposes a predictable image endpoint for many
          // image records. We use the item page as source attribution.
          final imageUrl = 'https://archive.org/download/$id/page/n0.jpg';
          final sourceUrl = 'https://archive.org/details/$id';
          if (score > localScore) {
            localScore = score;
            localBest = InternetArchiveImageResult(
              imageUrl: imageUrl,
              sourceUrl: sourceUrl,
              attribution: 'Internet Archive',
              score: score + 0.30,
            );
          }
        }
        _cache[key] = localBest;
        if (localBest != null && (best == null || localBest.score > best.score)) best = localBest;
      } catch (_) {
        _cache[key] = null;
      } finally {
        client?.close(force: true);
      }
    }
    return best;
  }

  double _score(String title, String? city, String? country, String candidate) {
    final wanted = _normalize([title, city, country].whereType<String>().join(' '));
    final text = _normalize(candidate);
    if (wanted.isEmpty || text.isEmpty) return 0;
    final tokens = wanted.split(' ').where((e) => e.length > 2).toSet();
    if (tokens.isEmpty) return 0;
    final hits = tokens.where(text.contains).length;
    return hits / tokens.length;
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

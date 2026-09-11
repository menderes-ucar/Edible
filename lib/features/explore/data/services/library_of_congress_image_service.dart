import 'dart:convert';
import 'dart:io';

class LibraryOfCongressImageResult {
  const LibraryOfCongressImageResult({
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

/// Free public Library of Congress image search.
/// Only records whose rights metadata indicates public-domain/no-known-copyright
/// or a Creative Commons style reusable licence are accepted.
class LibraryOfCongressImageService {
  LibraryOfCongressImageService._();

  static final instance = LibraryOfCongressImageService._();
  final Map<String, Future<LibraryOfCongressImageResult?>> _cache = {};

  Future<LibraryOfCongressImageResult?> resolve({
    required String title,
    String? city,
    String? country,
  }) {
    final query = [
      title,
      city,
      country,
    ].whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).join(' ');
    if (query.isEmpty) return Future.value(null);
    return _cache.putIfAbsent(query.toLowerCase(), () => _resolve(query, title));
  }

  Future<LibraryOfCongressImageResult?> _resolve(String query, String requested) async {
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final uri = Uri.https('www.loc.gov', '/photos/', {
        'q': query,
        'fo': 'json',
        'c': '20',
      });
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.userAgentHeader, 'Edible/1.0');
      final res = await req.close().timeout(const Duration(seconds: 3));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(await utf8.decoder.bind(res).join());
      final results = json['results'];
      if (results is! List) return null;

      Map<String, dynamic>? best;
      var bestScore = 0.0;
      for (final raw in results) {
        if (raw is! Map) continue;
        final row = Map<String, dynamic>.from(raw);
        final rights = (row['rights'] ?? row['rights_summary'] ?? '').toString().toLowerCase();
        if (!_isReusable(rights)) continue;
        final images = row['image_url'];
        if (images is! List || images.isEmpty) continue;
        final imageUrl = images.map((e) => e.toString()).firstWhere(
          (e) => e.startsWith('https://'),
          orElse: () => '',
        );
        if (imageUrl.isEmpty) continue;
        final text = [row['title'], row['description'], row['date'], row['subject']]
            .map((e) => e?.toString() ?? '')
            .join(' ');
        final score = _score(requested, text);
        if (score > bestScore) {
          bestScore = score;
          best = {...row, '_imageUrl': imageUrl};
        }
      }

      if (best == null || bestScore < 0.30) return null;
      final imageUrl = best['_imageUrl'].toString();
      final source = (best['url'] ?? '').toString();
      if (source.isEmpty) return null;
      return LibraryOfCongressImageResult(
        imageUrl: imageUrl,
        sourceUrl: source,
        attribution: 'Library of Congress · public-domain/reusable record',
        score: bestScore * 0.92,
      );
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  bool _isReusable(String rights) {
    if (rights.isEmpty) return false;
    return rights.contains('public domain') ||
        rights.contains('no known copyright') ||
        rights.contains('creative commons') ||
        rights.contains('cc by') ||
        rights.contains('cc0');
  }

  double _score(String requested, String candidate) {
    final a = _normalize(requested);
    final b = _normalize(candidate);
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 1;
    if (b.contains(a)) return 0.94;
    final tokens = a.split(' ').where((e) => e.length > 2).toSet();
    if (tokens.isEmpty) return 0;
    return tokens.where(b.contains).length / tokens.length;
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

import 'dart:convert';
import 'dart:io';

class OpenverseImageResult {
  const OpenverseImageResult({
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

/// Public, licence-aware image search used only after the primary verified
/// providers fail. Openverse indexes openly licensed media from multiple
/// sources, so it is a safer fallback than generic stock-image URLs.
class OpenverseImageService {
  OpenverseImageService._();

  static final OpenverseImageService instance = OpenverseImageService._();

  final Map<String, Future<OpenverseImageResult?>> _cache =
      <String, Future<OpenverseImageResult?>>{};

  Future<OpenverseImageResult?> resolve({
    required String title,
    String? city,
    String? country,
  }) {
    final query = <String>[
      title.trim(),
      if ((city ?? '').trim().isNotEmpty) city!.trim(),
      if ((country ?? '').trim().isNotEmpty) country!.trim(),
    ].where((e) => e.isNotEmpty).join(' ');
    if (query.isEmpty) return Future.value(null);

    return _cache.putIfAbsent(
      query.toLowerCase(),
      () => _resolve(query: query, requestedTitle: title),
    );
  }

  Future<OpenverseImageResult?> _resolve({
    required String query,
    required String requestedTitle,
  }) async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);

      final uri = Uri.https(
        'api.openverse.org',
        '/v1/images/',
        <String, String>{
          'q': query,
          'page_size': '20',
          'license': 'by,by-sa,cc0,pdm',
        },
      );

      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'Edible/1.0');
      final response =
          await request.close().timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return null;

      final decoded =
          jsonDecode(await utf8.decoder.bind(response).join());
      final results = decoded['results'];
      if (results is! List || results.isEmpty) return null;

      Map<String, dynamic>? best;
      var bestScore = 0.0;

      for (final raw in results) {
        if (raw is! Map) continue;
        final row = Map<String, dynamic>.from(raw);
        final imageUrl =
            (row['url'] ?? row['thumbnail'] ?? '').toString().trim();
        final sourceUrl =
            (row['foreign_landing_url'] ?? row['url'] ?? '').toString().trim();
        if (imageUrl.isEmpty || sourceUrl.isEmpty) continue;
        if (row['watermarked'] == true) continue;
        final width = (row['width'] as num?)?.toDouble() ?? 0;
        final height = (row['height'] as num?)?.toDouble() ?? 0;
        if (width > 0 && height > 0 && (width < 500 || height < 300)) continue;

        final license = (row['license'] ?? '').toString().toLowerCase();
        final reusable = license == 'cc0' ||
            license.startsWith('by') ||
            license.startsWith('cc-by') ||
            license.startsWith('cc-by-sa') ||
            license == 'pdm' ||
            license == 'publicdomain';
        if (!reusable) continue;

        final candidateText = [
          row['title'],
          row['alt'],
          row['description'],
          row['tags'],
        ].map((value) => value?.toString() ?? '').join(' ');
        final score = _score(requestedTitle, candidateText);
        if (score > bestScore) {
          bestScore = score;
          best = row;
        }
      }

      if (best == null || bestScore < 0.35) return null;

      final creator =
          (best['creator'] ?? '').toString().trim();
      final license = (best['license'] ?? '').toString().trim();
      return OpenverseImageResult(
        imageUrl: (best['url'] ?? best['thumbnail']).toString().trim(),
        sourceUrl: (best['foreign_landing_url'] ?? best['url']).toString().trim(),
        attribution: [
          if (creator.isNotEmpty) creator,
          if (license.isNotEmpty) license,
          'Openverse',
        ].join(' · '),
        score: bestScore,
      );
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  double _score(String requested, String candidate) {
    final a = _normalize(requested);
    final b = _normalize(candidate);
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 1;
    if (b.contains(a)) return 0.9;
    if (a.contains(b)) return 0.78;

    final tokens = a.split(' ').where((e) => e.length >= 3).toSet();
    if (tokens.isEmpty) return 0;
    final matched = tokens.where(b.contains).length;
    return matched / tokens.length;
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

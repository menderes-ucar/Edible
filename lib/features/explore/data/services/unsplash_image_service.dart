import 'dart:convert';
import 'package:http/http.dart' as http;

class UnsplashImageResult {
  const UnsplashImageResult({required this.imageUrl, required this.sourceUrl, required this.attribution, required this.score});
  final String imageUrl;
  final String sourceUrl;
  final String attribution;
  final double score;
}

class UnsplashImageService {
  UnsplashImageService._();
  static final instance = UnsplashImageService._();

  static const _key = String.fromEnvironment('UNSPLASH_ACCESS_KEY');

  Future<UnsplashImageResult?> resolve({required String title, String? city, String? country}) async {
    if (_key.isEmpty || title.trim().isEmpty) return null;
    final query = [title.trim(), city?.trim(), country?.trim()].where((e) => e != null && e.isNotEmpty).join(' ');
    try {
      final uri = Uri.https('api.unsplash.com', '/search/photos', {
        'query': query, 'per_page': '20', 'content_filter': 'high', 'orientation': 'landscape',
      });
      final response = await http.get(uri, headers: {'Authorization': 'Client-ID $_key', 'Accept-Version': 'v1'}).timeout(const Duration(milliseconds: 1400));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      if (data is! Map || data['results'] is! List) return null;
      UnsplashImageResult? best;
      for (final raw in data['results']) {
        if (raw is! Map) continue;
        final urls = raw['urls'];
        if (urls is! Map) continue;
        final url = urls['regular']?.toString().trim() ?? '';
        if (url.isEmpty) continue;
        final description = '${raw['alt_description'] ?? ''} ${raw['description'] ?? ''} ${raw['user'] is Map ? raw['user']['name'] ?? '' : ''}';
        final score = _score('$title ${city ?? ''} ${country ?? ''}', description);
        final page = raw['links'] is Map ? raw['links']['html']?.toString() ?? '' : '';
        final user = raw['user'] is Map ? raw['user']['name']?.toString() ?? 'Unsplash' : 'Unsplash';
        final candidate = UnsplashImageResult(imageUrl: url, sourceUrl: page, attribution: 'Photo by $user on Unsplash', score: score + .72);
        if (best == null || candidate.score > best.score) best = candidate;
      }
      return best;
    } catch (_) { return null; }
  }

  double _score(String query, String text) {
    final q = _tokens(query);
    final t = _tokens(text);
    if (q.isEmpty || t.isEmpty) return 0;
    final overlap = q.where(t.contains).length / q.length;
    return overlap.clamp(0, 1).toDouble();
  }
  Set<String> _tokens(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9ğüşıöçİĞÜŞÖÇ ]'), ' ').split(RegExp(r'\s+')).where((e) => e.length > 2).toSet();
}

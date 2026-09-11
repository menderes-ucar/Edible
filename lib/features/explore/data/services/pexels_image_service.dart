import 'dart:convert';
import 'package:http/http.dart' as http;

class PexelsImageResult {
  const PexelsImageResult({required this.imageUrl, required this.sourceUrl, required this.attribution, required this.score});
  final String imageUrl; final String sourceUrl; final String attribution; final double score;
}

class PexelsImageService {
  PexelsImageService._();
  static final instance = PexelsImageService._();
  static const _key = String.fromEnvironment('PEXELS_API_KEY');

  Future<PexelsImageResult?> resolve({required String title, String? city, String? country}) async {
    if (_key.isEmpty || title.trim().isEmpty) return null;
    final query = [title.trim(), city?.trim(), country?.trim()].where((e) => e != null && e.isNotEmpty).join(' ');
    try {
      final uri = Uri.https('api.pexels.com', '/v1/search', {'query': query, 'per_page': '20', 'orientation': 'landscape', 'size': 'large'});
      final response = await http.get(uri, headers: {'Authorization': _key}).timeout(const Duration(milliseconds: 1400));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      if (data is! Map || data['photos'] is! List) return null;
      PexelsImageResult? best;
      for (final raw in data['photos']) {
        if (raw is! Map || raw['src'] is! Map) continue;
        final url = raw['src']['large2x']?.toString().trim() ?? raw['src']['large']?.toString().trim() ?? '';
        if (url.isEmpty) continue;
        final text = '${raw['alt'] ?? ''} ${raw['photographer'] ?? ''}';
        final score = _score('$title ${city ?? ''} ${country ?? ''}', text);
        final candidate = PexelsImageResult(imageUrl: url, sourceUrl: raw['url']?.toString() ?? 'https://www.pexels.com/', attribution: 'Photo by ${raw['photographer'] ?? 'Pexels'} on Pexels', score: score + .70);
        if (best == null || candidate.score > best.score) best = candidate;
      }
      return best;
    } catch (_) { return null; }
  }
  double _score(String query, String text) { final q = _tokens(query); final t = _tokens(text); if (q.isEmpty || t.isEmpty) return 0; return (q.where(t.contains).length / q.length).clamp(0, 1).toDouble(); }
  Set<String> _tokens(String v) => v.toLowerCase().replaceAll(RegExp(r'[^a-z0-9ğüşıöçİĞÜŞÖÇ ]'), ' ').split(RegExp(r'\s+')).where((e) => e.length > 2).toSet();
}

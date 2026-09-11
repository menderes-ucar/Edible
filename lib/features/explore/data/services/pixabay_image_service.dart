import 'dart:convert';
import 'package:http/http.dart' as http;

class PixabayImageResult {
  const PixabayImageResult({required this.imageUrl, required this.sourceUrl, required this.attribution, required this.score});
  final String imageUrl; final String sourceUrl; final String attribution; final double score;
}

class PixabayImageService {
  PixabayImageService._();
  static final instance = PixabayImageService._();
  static const _key = String.fromEnvironment('PIXABAY_API_KEY');

  Future<PixabayImageResult?> resolve({required String title, String? city, String? country}) async {
    if (_key.isEmpty || title.trim().isEmpty) return null;
    final query = [title.trim(), city?.trim(), country?.trim()].where((e) => e != null && e.isNotEmpty).join(' ');
    try {
      final uri = Uri.https('pixabay.com', '/api/', {'key': _key, 'q': query, 'image_type': 'photo', 'orientation': 'horizontal', 'safesearch': 'true', 'per_page': '20'});
      final response = await http.get(uri).timeout(const Duration(milliseconds: 1400));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      if (data is! Map || data['hits'] is! List) return null;
      PixabayImageResult? best;
      for (final raw in data['hits']) {
        if (raw is! Map) continue;
        final url = raw['largeImageURL']?.toString().trim() ?? '';
        if (url.isEmpty) continue;
        final text = '${raw['tags'] ?? ''} ${raw['user'] ?? ''}';
        final score = _score('$title ${city ?? ''} ${country ?? ''}', text);
        final candidate = PixabayImageResult(imageUrl: url, sourceUrl: raw['pageURL']?.toString() ?? 'https://pixabay.com/', attribution: 'Photo by ${raw['user'] ?? 'Pixabay'} on Pixabay', score: score + .68);
        if (best == null || candidate.score > best.score) best = candidate;
      }
      return best;
    } catch (_) { return null; }
  }

  double _score(String query, String text) {
    final q = _tokens(query); final t = _tokens(text);
    if (q.isEmpty || t.isEmpty) return 0;
    return (q.where(t.contains).length / q.length).clamp(0, 1).toDouble();
  }
  Set<String> _tokens(String v) => v.toLowerCase().replaceAll(RegExp(r'[^a-z0-9ğüşıöçİĞÜŞÖÇ ]'), ' ').split(RegExp(r'\s+')).where((e) => e.length > 2).toSet();
}

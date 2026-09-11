import 'dart:convert';
import 'package:http/http.dart' as http;

class EuropeanaImageResult {
  const EuropeanaImageResult({required this.imageUrl, required this.sourceUrl, required this.attribution, required this.score});
  final String imageUrl; final String sourceUrl; final String attribution; final double score;
}

class EuropeanaImageService {
  EuropeanaImageService._();
  static final instance = EuropeanaImageService._();
  static const _key = String.fromEnvironment('EUROPEANA_API_KEY');

  Future<EuropeanaImageResult?> resolve({required String title, String? city, String? country}) async {
    if (_key.isEmpty || title.trim().isEmpty) return null;
    final query = [title.trim(), city?.trim(), country?.trim()].where((e) => e != null && e.isNotEmpty).join(' ');
    try {
      final uri = Uri.https('api.europeana.eu', '/record/v2/search.json', {'wskey': _key, 'query': query, 'rows': '24', 'qf': 'TYPE:IMAGE'});
      final response = await http.get(uri).timeout(const Duration(milliseconds: 1500));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      final items = data is Map && data['items'] is List ? data['items'] : null;
      if (items is! List) return null;
      EuropeanaImageResult? best;
      for (final raw in items) {
        if (raw is! Map) continue;
        final previews = raw['edmPreview'];
        final url = previews is List && previews.isNotEmpty ? previews.first.toString().trim() : raw['edmIsShownBy']?.toString().trim() ?? '';
        if (url.isEmpty || !url.startsWith('http')) continue;
        final text = '${raw['title'] ?? ''} ${raw['dcDescription'] ?? ''} ${raw['edmConceptTerm'] ?? ''}';
        final score = _score('$title ${city ?? ''} ${country ?? ''}', text);
        final page = raw['guid']?.toString() ?? 'https://www.europeana.eu/';
        final candidate = EuropeanaImageResult(imageUrl: url, sourceUrl: page, attribution: 'Image via Europeana', score: score + .52);
        if (best == null || candidate.score > best.score) best = candidate;
      }
      return best;
    } catch (_) { return null; }
  }
  double _score(String query, String text) { final q = _tokens(query); final t = _tokens(text); if (q.isEmpty || t.isEmpty) return 0; return (q.where(t.contains).length / q.length).clamp(0, 1).toDouble(); }
  Set<String> _tokens(String v) => v.toLowerCase().replaceAll(RegExp(r'[^a-z0-9ğüşıöçİĞÜŞÖÇ ]'), ' ').split(RegExp(r'\s+')).where((e) => e.length > 2).toSet();
}

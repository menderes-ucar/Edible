import 'dart:convert';
import 'package:http/http.dart' as http;

class FlickrImageResult {
  const FlickrImageResult({required this.imageUrl, required this.sourceUrl, required this.attribution, required this.score});
  final String imageUrl; final String sourceUrl; final String attribution; final double score;
}

class FlickrImageService {
  FlickrImageService._();
  static final instance = FlickrImageService._();
  static const _key = String.fromEnvironment('FLICKR_API_KEY');

  Future<FlickrImageResult?> resolve({required String title, String? city, String? country}) async {
    if (_key.isEmpty || title.trim().isEmpty) return null;
    final query = [title.trim(), city?.trim(), country?.trim()].where((e) => e != null && e.isNotEmpty).join(' ');
    try {
      final uri = Uri.https('www.flickr.com', '/services/rest/', {'method': 'flickr.photos.search', 'api_key': _key, 'text': query, 'content_type': '1', 'media': 'photos', 'safe_search': '1', 'license': '1,2,3,4,5,6,7,9,10', 'extras': 'url_l,url_o,owner_name,license,tags,title', 'per_page': '30', 'format': 'json', 'nojsoncallback': '1'});
      final response = await http.get(uri).timeout(const Duration(milliseconds: 1400));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      final photos = data is Map && data['photos'] is Map ? data['photos']['photo'] : null;
      if (photos is! List) return null;
      FlickrImageResult? best;
      for (final raw in photos) {
        if (raw is! Map) continue;
        final url = (raw['url_l'] ?? raw['url_o'])?.toString().trim() ?? '';
        if (url.isEmpty) continue;
        final text = '${raw['title'] ?? ''} ${raw['tags'] ?? ''} ${raw['ownername'] ?? ''}';
        final score = _score('$title ${city ?? ''} ${country ?? ''}', text);
        final id = raw['id']?.toString() ?? '';
        final page = id.isEmpty ? 'https://www.flickr.com/' : 'https://www.flickr.com/photos/${raw['owner'] ?? ''}/$id';
        final candidate = FlickrImageResult(imageUrl: url, sourceUrl: page, attribution: 'Photo on Flickr', score: score + .62);
        if (best == null || candidate.score > best.score) best = candidate;
      }
      return best;
    } catch (_) { return null; }
  }
  double _score(String query, String text) { final q = _tokens(query); final t = _tokens(text); if (q.isEmpty || t.isEmpty) return 0; return (q.where(t.contains).length / q.length).clamp(0, 1).toDouble(); }
  Set<String> _tokens(String v) => v.toLowerCase().replaceAll(RegExp(r'[^a-z0-9ğüşıöçİĞÜŞÖÇ ]'), ' ').split(RegExp(r'\s+')).where((e) => e.length > 2).toSet();
}

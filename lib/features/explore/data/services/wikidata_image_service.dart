import 'dart:convert';
import 'dart:io';

class WikidataImageResult {
  const WikidataImageResult({
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

/// Uses Wikidata entity search/P18 as a separate discovery path. The image is
/// then checked through Wikimedia Commons metadata before it is accepted.
class WikidataImageService {
  WikidataImageService._();

  static final instance = WikidataImageService._();
  final Map<String, Future<WikidataImageResult?>> _cache = {};

  Future<WikidataImageResult?> resolve({
    required String title,
    String? city,
    String? country,
  }) {
    final key = [title, city, country].whereType<String>().join('|').toLowerCase();
    return _cache.putIfAbsent(key, () => _resolve(title, city, country));
  }

  Future<WikidataImageResult?> _resolve(String title, String? city, String? country) async {
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final search = [title, city, country]
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .join(' ');
      final searchUri = Uri.https('www.wikidata.org', '/w/api.php', {
        'action': 'wbsearchentities',
        'search': search,
        'language': 'en',
        'uselang': 'en',
        'type': 'item',
        'limit': '5',
        'format': 'json',
        'origin': '*',
      });
      final req = await client.getUrl(searchUri);
      req.headers.set(HttpHeaders.userAgentHeader, 'Edible/1.0');
      final res = await req.close().timeout(const Duration(seconds: 3));
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(await utf8.decoder.bind(res).join());
      final hits = decoded['search'];
      if (hits is! List || hits.isEmpty) return null;

      Map<String, dynamic>? bestEntity;
      var best = 0.0;
      for (final raw in hits) {
        if (raw is! Map) continue;
        final row = Map<String, dynamic>.from(raw);
        final label = (row['label'] ?? '').toString();
        final desc = (row['description'] ?? '').toString();
        final score = _score(title, '$label $desc');
        if (score > best) {
          best = score;
          bestEntity = row;
        }
      }
      if (bestEntity == null || best < 0.42) return null;
      final id = bestEntity['id']?.toString() ?? '';
      if (id.isEmpty) return null;

      final entityUri = Uri.https('www.wikidata.org', '/w/api.php', {
        'action': 'wbgetentities',
        'ids': id,
        'props': 'claims|info',
        'format': 'json',
        'origin': '*',
      });
      final entityReq = await client.getUrl(entityUri);
      entityReq.headers.set(HttpHeaders.userAgentHeader, 'Edible/1.0');
      final entityRes = await entityReq.close().timeout(const Duration(seconds: 3));
      if (entityRes.statusCode != 200) return null;
      final entityJson = jsonDecode(await utf8.decoder.bind(entityRes).join());
      final entity = entityJson['entities']?[id];
      if (entity is! Map) return null;
      final claims = entity['claims'];
      if (claims is! Map) return null;
      final p18 = claims['P18'];
      if (p18 is! List || p18.isEmpty) return null;
      final fileName = p18.first?['mainsnak']?['datavalue']?['value']?.toString() ?? '';
      if (fileName.isEmpty) return null;

      final commonsUri = Uri.https('commons.wikimedia.org', '/w/api.php', {
        'action': 'query',
        'titles': 'File:$fileName',
        'prop': 'imageinfo',
        'iiprop': 'url|extmetadata|mime|size',
        'iiurlwidth': '1200',
        'format': 'json',
        'origin': '*',
      });
      final commonsReq = await client.getUrl(commonsUri);
      commonsReq.headers.set(HttpHeaders.userAgentHeader, 'Edible/1.0');
      final commonsRes = await commonsReq.close().timeout(const Duration(seconds: 3));
      if (commonsRes.statusCode != 200) return null;
      final commonsJson = jsonDecode(await utf8.decoder.bind(commonsRes).join());
      final pages = (commonsJson['query']?['pages'] as Map?)?.values ?? const [];
      if (pages.isEmpty) return null;
      final page = Map<String, dynamic>.from(pages.first as Map);
      final infoList = page['imageinfo'] as List?;
      if (infoList == null || infoList.isEmpty) return null;
      final info = Map<String, dynamic>.from(infoList.first as Map);
      final meta = info['extmetadata'] is Map
          ? Map<String, dynamic>.from(info['extmetadata'] as Map)
          : <String, dynamic>{};
      String metaValue(String key) {
        final raw = meta[key];
        return raw is Map ? (raw['value'] ?? '').toString().replaceAll(RegExp('<[^>]*>'), '').trim() : '';
      }
      final license = metaValue('LicenseShortName').toLowerCase();
      if (!(license.contains('cc by') || license.contains('cc0') || license.contains('public domain'))) return null;
      final imageUrl = (info['thumburl'] ?? info['url'] ?? '').toString();
      final sourceUrl = (info['descriptionurl'] ?? '').toString();
      if (imageUrl.isEmpty || sourceUrl.isEmpty) return null;

      return WikidataImageResult(
        imageUrl: imageUrl,
        sourceUrl: sourceUrl,
        attribution: '${metaValue('Artist').isEmpty ? 'Wikidata / Wikimedia Commons' : metaValue('Artist')} · ${metaValue('LicenseShortName')}',
        score: (best * 0.85).clamp(0.0, 1.0),
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
    final tokens = a.split(' ').where((e) => e.length > 2).toSet();
    return tokens.isEmpty ? 0 : tokens.where(b.contains).length / tokens.length;
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

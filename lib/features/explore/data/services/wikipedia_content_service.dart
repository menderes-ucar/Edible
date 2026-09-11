import 'dart:convert';
import 'dart:io';

class WikipediaContentOverview {
  const WikipediaContentOverview({
    required this.extract,
    required this.pageUrl,
    required this.language,
  });

  final String extract;
  final String pageUrl;
  final String language;
}

/// Adds factual, source-backed context to catalog entries whose bundled copy
/// is intentionally concise. Localized Wikipedia is preferred, English is the
/// fallback when a useful localized extract is unavailable.
class WikipediaContentService {
  WikipediaContentService._();

  static final instance = WikipediaContentService._();
  final Map<String, Future<WikipediaContentOverview?>> _cache = {};

  Future<WikipediaContentOverview?> resolve({
    required String title,
    required String locale,
    String? city,
    String? country,
  }) {
    final language = _language(locale);
    final key = '$language|${title.trim().toLowerCase()}|${city ?? ''}|${country ?? ''}';
    return _cache.putIfAbsent(
      key,
      () => _resolveWithFallback(
        title: title,
        language: language,
        city: city,
        country: country,
      ),
    );
  }

  Future<WikipediaContentOverview?> _resolveWithFallback({
    required String title,
    required String language,
    String? city,
    String? country,
  }) async {
    final localized = await _resolve(
      title: title,
      language: language,
      city: city,
      country: country,
    );
    if (localized != null && localized.extract.trim().length >= 160) {
      return localized;
    }

    if (language == 'en') return localized;
    return _resolve(
      title: title,
      language: 'en',
      city: city,
      country: country,
    );
  }

  Future<WikipediaContentOverview?> _resolve({
    required String title,
    required String language,
    String? city,
    String? country,
  }) async {
    HttpClient? client;
    try {
      final requested = title.trim();
      if (requested.isEmpty) return null;

      client = HttpClient()..connectionTimeout = const Duration(seconds: 7);
      final query = [
        '"$requested"',
        if ((city ?? '').trim().isNotEmpty) city!.trim(),
        if ((country ?? '').trim().isNotEmpty) country!.trim(),
      ].join(' ');

      final searchUri = Uri.https('$language.wikipedia.org', '/w/api.php', {
        'action': 'query',
        'list': 'search',
        'srsearch': query,
        'srnamespace': '0',
        'srlimit': '6',
        'format': 'json',
        'origin': '*',
      });
      final searchReq = await client.getUrl(searchUri);
      searchReq.headers.set(HttpHeaders.userAgentHeader, 'Edible/1.0');
      final searchRes = await searchReq.close().timeout(const Duration(seconds: 8));
      if (searchRes.statusCode != 200) return null;
      final searchJson = jsonDecode(await utf8.decoder.bind(searchRes).join());
      final rows = (searchJson['query']?['search'] as List?) ?? const [];
      if (rows.isEmpty) return null;

      Map<String, dynamic>? chosen;
      var best = 0.0;
      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw as Map);
        final candidate = row['title']?.toString() ?? '';
        final score = _score(requested, candidate);
        if (score > best) {
          best = score;
          chosen = row;
        }
      }
      if (chosen == null || best < 0.70) return null;

      final pageTitle = chosen['title'].toString();
      final pageUri = Uri.https('$language.wikipedia.org', '/w/api.php', {
        'action': 'query',
        'titles': pageTitle,
        'prop': 'extracts|info',
        'exintro': '1',
        'explaintext': '1',
        'exchars': '900',
        'inprop': 'url',
        'format': 'json',
        'origin': '*',
      });
      final pageReq = await client.getUrl(pageUri);
      pageReq.headers.set(HttpHeaders.userAgentHeader, 'Edible/1.0');
      final pageRes = await pageReq.close().timeout(const Duration(seconds: 8));
      if (pageRes.statusCode != 200) return null;
      final pageJson = jsonDecode(await utf8.decoder.bind(pageRes).join());
      final pages = (pageJson['query']?['pages'] as Map?)?.values ?? const [];
      if (pages.isEmpty) return null;
      final page = Map<String, dynamic>.from(pages.first as Map);
      final extract = (page['extract'] ?? '').toString().trim();
      final pageUrl = (page['fullurl'] ?? '').toString().trim();
      if (extract.isEmpty || pageUrl.isEmpty) return null;

      return WikipediaContentOverview(
        extract: extract,
        pageUrl: pageUrl,
        language: language,
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
    if (a == b) return 1;
    if (b.startsWith('$a ')) return 0.94;
    if (b.contains(a)) return 0.86;
    if (a.contains(b)) return 0.78;
    final aw = a.split(' ').where((e) => e.isNotEmpty).toSet();
    final bw = b.split(' ').where((e) => e.isNotEmpty).toSet();
    if (aw.isEmpty || bw.isEmpty) return 0;
    return (2 * aw.intersection(bw).length) / (aw.length + bw.length);
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  String _language(String raw) {
    final code = raw.trim().toLowerCase().split(RegExp('[-_]')).first;
    const supported = {
      'en', 'tr', 'de', 'fr', 'es', 'it', 'ar', 'pt', 'ja', 'ko', 'zh', 'ru', 'nl'
    };
    return supported.contains(code) ? code : 'en';
  }
}

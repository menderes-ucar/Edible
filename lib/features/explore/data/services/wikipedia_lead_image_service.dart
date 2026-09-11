import 'dart:convert';
import 'dart:io';

class ResolvedContentImage {
  const ResolvedContentImage({
    required this.imageUrl,
    required this.sourcePageUrl,
    required this.author,
    required this.license,
    required this.licenseUrl,
    required this.score,
  });

  final String imageUrl;
  final String sourcePageUrl;
  final String author;
  final String license;
  final String licenseUrl;
  final double score;

  String get attribution {
    final who = author.trim().isEmpty ? 'Wikimedia Commons' : author.trim();
    return '$who · $license';
  }
}

class WikipediaLeadImageService {
  WikipediaLeadImageService._();

  static final WikipediaLeadImageService instance = WikipediaLeadImageService._();

  final Map<String, Future<ResolvedContentImage?>> _futureCache = {};

  Future<ResolvedContentImage?> resolve({
    required String title,
    required String locale,
    String? city,
    String? country,
  }) {
    final language = _wikiLanguage(locale);
    final key = '$language|${title.trim().toLowerCase()}|${city ?? ''}|${country ?? ''}';
    return _futureCache.putIfAbsent(
      key,
      () => _resolveWithLanguageFallback(
        title: title,
        preferredLanguage: language,
        city: city,
        country: country,
      ),
    );
  }

  Future<ResolvedContentImage?> _resolveWithLanguageFallback({
    required String title,
    required String preferredLanguage,
    String? city,
    String? country,
  }) async {
    final preferred = await _resolve(
      title: title,
      language: preferredLanguage,
      city: city,
      country: country,
    );
    if (preferred != null || preferredLanguage == 'en') return preferred;

    // English Wikipedia has the broadest landmark/city coverage. It is a
    // fallback language only; the requested locale is always tried first.
    return _resolve(
      title: title,
      language: 'en',
      city: city,
      country: country,
    );
  }

  Future<ResolvedContentImage?> _resolve({
    required String title,
    required String language,
    String? city,
    String? country,
  }) async {
    final requested = title.trim();
    if (requested.isEmpty) return null;

    final searchTerms = <String>[
      '"$requested"',
      if ((city ?? '').trim().isNotEmpty) city!.trim(),
      if ((country ?? '').trim().isNotEmpty) country!.trim(),
    ].join(' ');

    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);

      final searchUri = Uri.https(
        '$language.wikipedia.org',
        '/w/api.php',
        {
          'action': 'query',
          'list': 'search',
          'srsearch': searchTerms,
          'srnamespace': '0',
          'srlimit': '5',
          'format': 'json',
          'origin': '*',
        },
      );

      final searchReq = await client.getUrl(searchUri);
      searchReq.headers.set(HttpHeaders.userAgentHeader, 'Edible/1.0');
      final searchRes = await searchReq.close().timeout(const Duration(seconds: 4));
      if (searchRes.statusCode != 200) return null;
      final searchJson = jsonDecode(await utf8.decoder.bind(searchRes).join());
      final results = (searchJson['query']?['search'] as List?) ?? const [];
      if (results.isEmpty) return null;

      Map<String, dynamic>? chosen;
      double best = 0;
      for (final raw in results) {
        final row = Map<String, dynamic>.from(raw as Map);
        final candidate = (row['title'] ?? '').toString();
        final score = _titleScore(requested, candidate);
        if (score > best) {
          best = score;
          chosen = row;
        }
      }

      // Avoid unrelated "close enough" results.
      if (chosen == null || best < 0.62) return null;
      final pageTitle = chosen['title'].toString();

      final pageUri = Uri.https(
        '$language.wikipedia.org',
        '/w/api.php',
        {
          'action': 'query',
          'titles': pageTitle,
          'prop': 'pageimages',
          'piprop': 'name|thumbnail',
          'pithumbsize': '1200',
          'format': 'json',
          'origin': '*',
        },
      );

      final pageReq = await client.getUrl(pageUri);
      pageReq.headers.set(HttpHeaders.userAgentHeader, 'Edible/1.0');
      final pageRes = await pageReq.close().timeout(const Duration(seconds: 4));
      if (pageRes.statusCode != 200) return null;
      final pageJson = jsonDecode(await utf8.decoder.bind(pageRes).join());
      final pages = (pageJson['query']?['pages'] as Map?)?.values ?? const [];
      if (pages.isEmpty) return null;

      final page = Map<String, dynamic>.from(pages.first as Map);
      final fileName = (page['pageimage'] ?? '').toString();
      if (fileName.isEmpty) return null;

      final commonsUri = Uri.https(
        'commons.wikimedia.org',
        '/w/api.php',
        {
          'action': 'query',
          'titles': 'File:$fileName',
          'prop': 'imageinfo',
          'iiprop': 'url|extmetadata',
          'iiurlwidth': '1200',
          'format': 'json',
          'origin': '*',
        },
      );

      final commonsReq = await client.getUrl(commonsUri);
      commonsReq.headers.set(HttpHeaders.userAgentHeader, 'Edible/1.0');
      final commonsRes =
          await commonsReq.close().timeout(const Duration(seconds: 4));
      if (commonsRes.statusCode != 200) return null;

      final commonsJson = jsonDecode(await utf8.decoder.bind(commonsRes).join());
      final commonsPages =
          (commonsJson['query']?['pages'] as Map?)?.values ?? const [];
      if (commonsPages.isEmpty) return null;

      final commonsPage =
          Map<String, dynamic>.from(commonsPages.first as Map);
      final infoList = commonsPage['imageinfo'] as List?;
      if (infoList == null || infoList.isEmpty) return null;
      final info = Map<String, dynamic>.from(infoList.first as Map);
      final meta = Map<String, dynamic>.from(info['extmetadata'] as Map? ?? {});

      String value(String key) {
        final raw = meta[key];
        if (raw is! Map) return '';
        return (raw['value'] ?? '')
            .toString()
            .replaceAll(RegExp('<[^>]*>'), '')
            .trim();
      }

      final license = value('LicenseShortName');
      final lower = license.toLowerCase();
      final reusable = lower.contains('cc by') ||
          lower.contains('cc by-sa') ||
          lower.contains('cc0') ||
          lower.contains('public domain');
      if (!reusable) return null;

      final imageUrl = (info['thumburl'] ?? info['url'] ?? '').toString();
      final sourcePage = (info['descriptionurl'] ?? '').toString();
      if (imageUrl.isEmpty || sourcePage.isEmpty) return null;

      return ResolvedContentImage(
        imageUrl: imageUrl,
        sourcePageUrl: sourcePage,
        author: value('Artist'),
        license: license,
        licenseUrl: value('LicenseUrl'),
        score: best,
      );
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  double _titleScore(String requested, String candidate) {
    final a = _normalize(requested);
    final b = _normalize(candidate);
    if (a == b) return 1;
    if (b.startsWith('$a ')) return 0.94;
    if (b.contains(a)) return 0.86;
    if (a.contains(b)) return 0.78;

    final aw = a.split(' ').where((e) => e.isNotEmpty).toSet();
    final bw = b.split(' ').where((e) => e.isNotEmpty).toSet();
    if (aw.isEmpty || bw.isEmpty) return 0;
    final common = aw.intersection(bw).length;
    return (2 * common) / (aw.length + bw.length);
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  String _wikiLanguage(String raw) {
    final code = raw.trim().toLowerCase().split(RegExp('[-_]')).first;
    const supported = {
      'en',
      'tr',
      'de',
      'fr',
      'es',
      'it',
      'ar',
      'zh',
      'ko',
      'ja',
      'ru',
      'pt',
    };
    return supported.contains(code) ? code : 'en';
  }
}

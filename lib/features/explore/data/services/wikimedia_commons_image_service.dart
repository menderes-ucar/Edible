import 'dart:convert';
import 'dart:io';

class WikimediaCommonsImageResult {
  const WikimediaCommonsImageResult({
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

/// Free-first image resolver for Wikimedia Commons.
///
/// The important part is that this service ranks the actual file metadata,
/// not only the filename. Commons contains many files with generic names,
/// so title + description + categories + location are considered together.
class WikimediaCommonsImageService {
  WikimediaCommonsImageService._();

  static final WikimediaCommonsImageService instance =
      WikimediaCommonsImageService._();

  final Map<String, Future<WikimediaCommonsImageResult?>> _cache =
      <String, Future<WikimediaCommonsImageResult?>>{};

  Future<WikimediaCommonsImageResult?> resolve({
    required String title,
    String? city,
    String? country,
  }) {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return Future.value(null);

    final key = [
      cleanTitle.toLowerCase(),
      city?.trim().toLowerCase() ?? '',
      country?.trim().toLowerCase() ?? '',
    ].join('|');

    return _cache.putIfAbsent(
      key,
      () => _resolve(title: cleanTitle, city: city, country: country),
    );
  }

  Future<WikimediaCommonsImageResult?> _resolve({
    required String title,
    String? city,
    String? country,
  }) async {
    final cityValue = city?.trim() ?? '';
    final countryValue = country?.trim() ?? '';
    final queries = <String>{
      [title, cityValue, countryValue].where((e) => e.isNotEmpty).join(' '),
      [title, cityValue].where((e) => e.isNotEmpty).join(' '),
      '"$title"',
      title,
    }.where((e) => e.trim().isNotEmpty).toList(growable: false);

    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 5);

      // All free Commons searches run concurrently. We do not make the user
      // wait for query #1 to fail before query #2 starts.
      final results = await Future.wait(
        queries.take(4).map(
          (query) => _search(
            client!,
            query,
            requestedTitle: title,
            city: cityValue,
            country: countryValue,
          ).timeout(const Duration(seconds: 5), onTimeout: () => null),
        ),
      ).timeout(const Duration(seconds: 4), onTimeout: () => const []);

      WikimediaCommonsImageResult? best;
      for (final candidate in results) {
        if (candidate == null) continue;
        if (best == null || candidate.score > best.score) best = candidate;
      }
      return best;
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  Future<WikimediaCommonsImageResult?> _search(
    HttpClient client,
    String query, {
    required String requestedTitle,
    required String city,
    required String country,
  }) async {
    try {
      final uri = Uri.https(
        'commons.wikimedia.org',
        '/w/api.php',
        <String, String>{
          'action': 'query',
          'generator': 'search',
          'gsrsearch': query,
          'gsrnamespace': '6',
          'gsrlimit': '12',
          'prop': 'imageinfo',
          'iiprop': 'url|extmetadata|mime|size',
          'iiurlwidth': '1200',
          'format': 'json',
          'origin': '*',
        },
      );

      final request = await client.getUrl(uri);
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'Edible/1.0 (free image resolver)',
      );
      final response = await request.close();
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(await utf8.decoder.bind(response).join());
      final pages = decoded['query']?['pages'];
      if (pages is! Map) return null;

      WikimediaCommonsImageResult? best;
      for (final raw in pages.values) {
        if (raw is! Map) continue;
        final page = Map<String, dynamic>.from(raw);
        final infoList = page['imageinfo'];
        if (infoList is! List || infoList.isEmpty || infoList.first is! Map) {
          continue;
        }

        final info = Map<String, dynamic>.from(infoList.first as Map);
        final mime = (info['mime'] ?? '').toString().toLowerCase();
        if (!mime.startsWith('image/') || mime == 'image/svg+xml') continue;

        final width = _number(info['width']);
        final height = _number(info['height']);
        if (width < 500 || height < 300) continue;

        final metadata = info['extmetadata'] is Map
            ? Map<String, dynamic>.from(info['extmetadata'] as Map)
            : <String, dynamic>{};

        String value(String key) {
          final rawValue = metadata[key];
          if (rawValue is! Map) return '';
          return (rawValue['value'] ?? '')
              .toString()
              .replaceAll(RegExp(r'<[^>]*>'), ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
        }

        final license = value('LicenseShortName');
        if (!_isCommerciallyReusable(license)) continue;

        final pageTitle = (page['title'] ?? '')
            .toString()
            .replaceFirst(RegExp(r'^File:\s*', caseSensitive: false), '');
        final description = value('ImageDescription');
        final objectName = value('ObjectName');
        final categories = value('Categories');
        final credit = value('Credit');
        final searchable = [pageTitle, description, objectName, categories, credit]
            .where((e) => e.isNotEmpty)
            .join(' ');

        final titleScore = _similarity(requestedTitle, searchable);
        final cityScore = city.isEmpty ? 0.0 : _similarity(city, searchable);
        final countryScore = country.isEmpty ? 0.0 : _similarity(country, searchable);
        final visualBonus = _visualBonus(pageTitle, description);
        final queryBonus = query.toLowerCase().contains(city.toLowerCase()) &&
                city.isNotEmpty
            ? 0.06
            : 0.0;

        final score = (titleScore * 0.62) +
            (cityScore * 0.20) +
            (countryScore * 0.08) +
            visualBonus +
            queryBonus;

        if (score < 0.42) continue;

        final imageUrl =
            (info['thumburl'] ?? info['url'] ?? '').toString().trim();
        final sourceUrl = (info['descriptionurl'] ?? '').toString().trim();
        if (imageUrl.isEmpty || sourceUrl.isEmpty) continue;

        final author = value('Artist');
        final candidate = WikimediaCommonsImageResult(
          imageUrl: imageUrl,
          sourceUrl: sourceUrl,
          attribution: [
            if (author.isNotEmpty) author,
            if (license.isNotEmpty) license,
            'Wikimedia Commons',
          ].join(' · '),
          score: score,
        );

        if (best == null || candidate.score > best.score) best = candidate;
      }

      return best;
    } catch (_) {
      return null;
    }
  }

  bool _isCommerciallyReusable(String license) {
    final value = license.toLowerCase();
    return value.contains('cc by') ||
        value.contains('cc-by') ||
        value.contains('cc0') ||
        value.contains('public domain') ||
        value == 'pdm' ||
        value == 'publicdomain';
  }

  double _visualBonus(String title, String description) {
    final text = '$title $description'.toLowerCase();
    const bad = <String>[
      'logo',
      'icon',
      'map',
      'flag',
      'diagram',
      'chart',
      'screenshot',
      'poster',
      'coat of arms',
      'symbol',
      'locator',
    ];
    if (bad.any(text.contains)) return -0.35;
    const good = <String>[
      'view',
      'panorama',
      'exterior',
      'street',
      'landscape',
      'building',
      'mosque',
      'castle',
      'museum',
      'restaurant',
      'food',
      'dish',
      'mountain',
      'beach',
    ];
    return good.any(text.contains) ? 0.06 : 0.0;
  }

  double _similarity(String requested, String candidate) {
    final a = _normalize(requested);
    final b = _normalize(candidate);
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 1;
    if (b.contains(a)) return 0.94;
    if (a.contains(b)) return 0.84;

    final tokens = a.split(' ').where((e) => e.length >= 3).toSet();
    if (tokens.isEmpty) return 0;
    final matched = tokens.where(b.contains).length;
    return matched / tokens.length;
  }

  double _number(dynamic value) => value is num ? value.toDouble() : 0;

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

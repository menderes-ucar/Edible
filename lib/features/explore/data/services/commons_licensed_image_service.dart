import 'dart:convert';
import 'dart:io';

class CommonsLicensedImage {
  const CommonsLicensedImage({
    required this.url,
    required this.pageUrl,
    required this.artist,
    required this.license,
    required this.licenseUrl,
    required this.attributionRequired,
  });

  final String url;
  final String pageUrl;
  final String artist;
  final String license;
  final String licenseUrl;
  final bool attributionRequired;
}

class CommonsLicensedImageService {
  CommonsLicensedImageService._();

  static final instance = CommonsLicensedImageService._();

  final Map<String, CommonsLicensedImage?> _cache =
      <String, CommonsLicensedImage?>{};

  Future<CommonsLicensedImage?> find({
    required String title,
    String? city,
    String? country,
    String? category,
  }) async {
    final query = [
      title,
      city,
      country,
      category,
    ].whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).join(' ');
    final key = query.toLowerCase();
    if (_cache.containsKey(key)) return _cache[key];

    HttpClient? client;
    try {
      final uri = Uri.https('commons.wikimedia.org', '/w/api.php', {
        'action': 'query',
        'generator': 'search',
        'gsrsearch': 'filetype:bitmap $query',
        'gsrnamespace': '6',
        'gsrlimit': '10',
        'prop': 'imageinfo',
        'iiprop': 'url|extmetadata',
        'iiextmetadatafilter':
            'LicenseShortName|LicenseUrl|Artist|Credit|AttributionRequired|ImageDescription',
        'iiurlwidth': '1200',
        'format': 'json',
        'origin': '*',
      });

      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      final req = await client.getUrl(uri);
      req.headers.set(
        HttpHeaders.userAgentHeader,
        'Edible/1.0 (travel discovery app)',
      );

      final res = await req.close().timeout(const Duration(seconds: 5));
      final body = await utf8.decoder.bind(res).join();
      if (res.statusCode != 200) return _cache[key] = null;

      final decoded = jsonDecode(body);
      final pages =
          (decoded['query']?['pages'] as Map?)?.values ?? const [];

      CommonsLicensedImage? best;
      var bestScore = 0.0;

      for (final raw in pages) {
        if (raw is! Map) continue;

        final infos = raw['imageinfo'] as List?;
        if (infos == null || infos.isEmpty || infos.first is! Map) continue;

        final info = Map<String, dynamic>.from(infos.first as Map);
        final meta = info['extmetadata'] is Map
            ? Map<String, dynamic>.from(info['extmetadata'] as Map)
            : <String, dynamic>{};

        String value(String key) {
          final rawValue = meta[key];
          if (rawValue is! Map) return '';
          return (rawValue['value'] ?? '')
              .toString()
              .replaceAll(RegExp('<[^>]*>'), '')
              .trim();
        }

        final license = value('LicenseShortName');
        final licenseUrl = value('LicenseUrl');
        final lowerLicense = license.toLowerCase();
        final reusable = lowerLicense.contains('cc by') ||
            lowerLicense.contains('cc0') ||
            lowerLicense.contains('public domain');
        if (!reusable) continue;

        final url = (info['thumburl'] ?? info['url'] ?? '').toString();
        final page = (info['descriptionurl'] ?? '').toString();
        if (url.isEmpty || page.isEmpty) continue;

        final pageTitle = (raw['title'] ?? '').toString().replaceFirst(
              RegExp(r'^File:\s*', caseSensitive: false),
              '',
            );
        final description = value('ImageDescription');
        final credit = value('Credit');

        final score = _similarity(
          title,
          '$pageTitle $description $credit',
        );

        // Do not accept an unrelated Commons result merely because it has a
        // reusable license.
        if (score < 0.28) continue;

        final attr = value('AttributionRequired').toLowerCase();
        final candidate = CommonsLicensedImage(
          url: url,
          pageUrl: page,
          artist: value('Artist'),
          license: license,
          licenseUrl: licenseUrl,
          attributionRequired: attr != 'false' &&
              !lowerLicense.contains('cc0') &&
              !lowerLicense.contains('public domain'),
        );

        if (score > bestScore) {
          bestScore = score;
          best = candidate;
        }
      }

      return _cache[key] = best;
    } catch (_) {
      return _cache[key] = null;
    } finally {
      client?.close(force: true);
    }
  }

  double _similarity(String requested, String candidate) {
    final a = _normalize(requested);
    final b = _normalize(candidate);
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 1;
    if (b.contains(a)) return 0.92;
    if (a.contains(b)) return 0.82;

    final aw = a.split(' ').where((e) => e.length > 1).toSet();
    final bw = b.split(' ').where((e) => e.length > 1).toSet();
    if (aw.isEmpty || bw.isEmpty) return 0;

    final common = aw.intersection(bw).length;
    return (2 * common) / (aw.length + bw.length);
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

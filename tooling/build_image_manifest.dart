import 'dart:convert';
import 'dart:io';

const _constructorNames = <String>{
  '_TurkiyeLaunchItem',
  '_GlobalCatalogItem',
  '_LaunchItem',
  '_FlagshipItem',
  '_SeedExploreItem',
  'ExploreContentModel',
  'ExploreContent',
  '_WorldItem',
};

const _allowedLicenses = <String>{
  'cc0',
  'cc0 1.0',
  'cc by',
  'cc by 2.0',
  'cc by 2.5',
  'cc by 3.0',
  'cc by 4.0',
  'cc by-sa',
  'cc by-sa 2.0',
  'cc by-sa 2.5',
  'cc by-sa 3.0',
  'cc by-sa 4.0',
  'public domain',
  'public domain mark',
  'pdm',
  'pdm 1.0',
  'zero',
};

String _norm(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll('ı', 'i')
    .replaceAll('İ', 'i')
    .replaceAll('ğ', 'g')
    .replaceAll('ü', 'u')
    .replaceAll('ş', 's')
    .replaceAll('ö', 'o')
    .replaceAll('ç', 'c')
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String _stripHtml(String value) => value
    .replaceAll(RegExp(r'<[^>]+>'), ' ')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&amp;', '&')
    .trim();

String? _unquote(String? raw) {
  if (raw == null) return null;
  final value = raw.trim();
  if (value.length < 2) return null;
  final quote = value[0];
  if ((quote != "'" && quote != '"') || value[value.length - 1] != quote) {
    return null;
  }
  return value.substring(1, value.length - 1)
      .replaceAll(r'\"', '"')
      .replaceAll(r"\'", "'")
      .replaceAll(r'\n', ' ')
      .trim();
}

Iterable<String> _constructorBodies(String text, String name) sync* {
  final needle = '$name(';
  var from = 0;
  while (true) {
    final start = text.indexOf(needle, from);
    if (start < 0) return;
    var index = start + needle.length;
    var depth = 1;
    String? quote;
    var triple = false;
    var escaped = false;

    while (index < text.length && depth > 0) {
      final char = text[index];
      if (quote != null) {
        if (escaped) {
          escaped = false;
        } else if (char == r'\') {
          escaped = true;
        } else if (triple && text.startsWith('$quote$quote$quote', index)) {
          quote = null;
          triple = false;
          index += 2;
        } else if (!triple && char == quote) {
          quote = null;
        }
        index++;
        continue;
      }
      if (text.startsWith("'''", index)) {
        quote = "'";
        triple = true;
        index += 3;
        continue;
      }
      if (text.startsWith('"""', index)) {
        quote = '"';
        triple = true;
        index += 3;
        continue;
      }
      if (char == "'" || char == '"') {
        quote = char;
      } else if (char == '(') {
        depth++;
      } else if (char == ')') {
        depth--;
      }
      index++;
    }
    if (depth == 0) yield text.substring(start + needle.length, index - 1);
    from = index;
  }
}

String? _namedString(String body, String key) {
  final pattern = RegExp(
    r'''\b''' + RegExp.escape(key) + r'''\s*:\s*(['"])(.*?)\1''',
    dotAll: true,
  );
  return _unquote(pattern.firstMatch(body)?.group(0)?.replaceFirst(
    RegExp(r'^.*?:\s*'),
    '',
  ));
}

List<String> _topLevelArgs(String body) {
  final result = <String>[];
  var start = 0;
  var depth = 0;
  String? quote;
  var triple = false;
  var escaped = false;

  for (var i = 0; i < body.length; i++) {
    final c = body[i];
    if (quote != null) {
      if (escaped) {
        escaped = false;
      } else if (c == r'\') {
        escaped = true;
      } else if (triple && body.startsWith('$quote$quote$quote', i)) {
        quote = null;
        triple = false;
        i += 2;
      } else if (!triple && c == quote) {
        quote = null;
      }
      continue;
    }
    if (body.startsWith("'''", i)) {
      quote = "'";
      triple = true;
      i += 2;
    } else if (body.startsWith('"""', i)) {
      quote = '"';
      triple = true;
      i += 2;
    } else if (c == "'" || c == '"') {
      quote = c;
    } else if ('([{'.contains(c)) {
      depth++;
    } else if (')]}'.contains(c)) {
      depth--;
    } else if (c == ',' && depth == 0) {
      result.add(body.substring(start, i).trim());
      start = i + 1;
    }
  }
  final tail = body.substring(start).trim();
  if (tail.isNotEmpty) result.add(tail);
  return result;
}

class Record {
  Record({required this.title, required this.city, required this.country, required this.file});
  final String title;
  final String city;
  final String country;
  final String file;

  String get key => '${_norm(title)}|${_norm(city)}|${_norm(country)}';
  String get titleKey => _norm(title);
  String get assetKey => _assetKey(title, city, country);
}

String _assetKey(String title, String city, String country) {
  final input = '${_norm(title)}|${_norm(city)}|${_norm(country)}';
  // Stable FNV-1a 64-bit filename. No external package is required.
  var hash = 0xcbf29ce484222325;
  for (final codeUnit in utf8.encode(input)) {
    hash ^= codeUnit;
    hash = (hash * 0x100000001b3) & 0xffffffffffffffff;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

List<Record> _extractRecords(Directory root) {
  final records = <String, Record>{};
  for (final file in root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))) {
    final text = file.readAsStringSync();
    for (final name in _constructorNames) {
      for (final body in _constructorBodies(text, name)) {
        var city = _namedString(body, 'cityName');
        city ??= _namedString(body, 'cityEn');
        var country = _namedString(body, 'countryName');

        if (name == '_WorldItem') {
          final args = _topLevelArgs(body);
          if (args.length >= 6) {
            country = _unquote(args[2]) ?? country;
            city = _unquote(args[3]) ?? city;
          }
        }

        // IMPORTANT: title, titleEn, titleTr and contentTitle are aliases,
        // not alternatives. Every distinct title must become an exact record
        // so Turkish/English cards can resolve to the same downloaded image.
        final aliases = <String>{};
        for (final key in const ['title', 'titleEn', 'titleTr', 'contentTitle']) {
          final value = _namedString(body, key)?.trim();
          if (value != null && value.isNotEmpty) aliases.add(value);
        }

        if (name == '_WorldItem') {
          final args = _topLevelArgs(body);
          if (args.length >= 6) {
            final positionalTitle = _unquote(args[5])?.trim();
            if (positionalTitle != null && positionalTitle.isNotEmpty) {
              aliases.add(positionalTitle);
            }
          }
        }

        for (final title in aliases) {
          final record = Record(
            title: title,
            city: city?.trim() ?? '',
            country: country?.trim() ?? '',
            file: file.path.replaceAll('\\', '/'),
          );
          records.putIfAbsent(record.key, () => record);
        }
      }
    }
  }
  final list = records.values.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return list;
}

String _licenseName(Map<String, dynamic> meta) {
  final raw = meta['LicenseShortName']?['value']?.toString() ??
      meta['License']?['value']?.toString() ??
      '';
  return _stripHtml(raw);
}

bool _allowed(String license) {
  final n = license.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  if (n.isEmpty) return false;
  if (n.contains('non-commercial') || n.contains('noncommercial')) return false;
  if (RegExp(r'(^|[-\s])nd($|[-\s])').hasMatch(n)) return false;
  if (n.contains('no derivatives')) return false;
  if (_allowedLicenses.contains(n)) return true;
  return n == 'cc by 4.0 international' ||
      n == 'cc by-sa 4.0 international' ||
      n == 'creative commons attribution 4.0' ||
      n == 'creative commons attribution-sharealike 4.0';
}

Set<String> _tokens(String value) => _norm(value)
    .split(' ')
    .where((e) => e.length >= 3)
    .toSet();

int _score(Record record, String candidateTitle, String extra) {
  final title = _norm(record.title);
  final candidate = _norm('$candidateTitle $extra');
  if (title.isEmpty || candidate.isEmpty) return 0;

  final titleTokens = _tokens(record.title);
  final candidateTokens = _tokens('$candidateTitle $extra');
  final locationTokens = _tokens('${record.city} ${record.country}');

  var score = 0;
  if (_norm(candidateTitle) == title) score += 160;
  if (candidate.contains(title)) score += 70;
  if (title.contains(_norm(candidateTitle)) && _norm(candidateTitle).length >= 5) score += 35;
  score += titleTokens.intersection(candidateTokens).length * 10;
  score += locationTokens.intersection(candidateTokens).length * 6;

  final city = _norm(record.city);
  final country = _norm(record.country);
  if (city.isNotEmpty && candidate.contains(city)) score += 30;
  if (country.isNotEmpty && candidate.contains(country)) score += 15;
  return score;
}

Future<Map<String, dynamic>?> _commons(Record record, String query) async {
  final uri = Uri.https('commons.wikimedia.org', '/w/api.php', {
    'action': 'query',
    'generator': 'search',
    'gsrsearch': query,
    'gsrnamespace': '6',
    'gsrlimit': '20',
    'prop': 'imageinfo',
    'iiprop': 'url|extmetadata',
    'iiurlwidth': '1600',
    'format': 'json',
    'origin': '*',
  });
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.userAgentHeader, 'EdibleReleaseImageBuilder/3.0');
    final response = await request.close();
    if (response.statusCode != 200) return null;
    final data = jsonDecode(await response.transform(utf8.decoder).join()) as Map<String, dynamic>;
    final pages = (data['query']?['pages'] as Map?)?.values ?? const [];
    Map<String, dynamic>? best;
    var bestScore = -1;

    for (final page in pages) {
      final map = Map<String, dynamic>.from(page as Map);
      final info = ((map['imageinfo'] as List?)?.first as Map?)?.cast<String, dynamic>();
      if (info == null) continue;
      final meta = (info['extmetadata'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      final license = _licenseName(meta);
      if (!_allowed(license)) continue;

      final pageTitle = map['title']?.toString() ?? '';
      final description = _stripHtml(meta['ImageDescription']?['value']?.toString() ?? '');
      final categories = _stripHtml(meta['Categories']?['value']?.toString() ?? '');
      final score = _score(record, pageTitle, '$description $categories');
      final thumb = info['thumburl']?.toString();
      if (thumb == null || !thumb.startsWith('https://')) continue;

      if (score > bestScore) {
        bestScore = score;
        best = {
          'imageUrl': thumb,
          'sourcePage': 'https://commons.wikimedia.org/wiki/${Uri.encodeComponent(pageTitle.replaceFirst('File:', ''))}',
          'author': _stripHtml(meta['Artist']?['value']?.toString() ?? ''),
          'license': license,
          'source': 'Wikimedia Commons',
          'matchScore': '$score',
        };
      }
    }
    return bestScore >= 55 ? best : null;
  } finally {
    client.close(force: true);
  }
}

Future<Map<String, dynamic>?> _openverse(Record record, String query) async {
  final uri = Uri.https('api.openverse.org', '/v1/images/', {
    'q': query,
    'page_size': '20',
  });
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.userAgentHeader, 'EdibleReleaseImageBuilder/3.0');
    final response = await request.close();
    if (response.statusCode != 200) return null;
    final data = jsonDecode(await response.transform(utf8.decoder).join()) as Map<String, dynamic>;
    final results = (data['results'] as List?) ?? const [];
    Map<String, dynamic>? best;
    var bestScore = -1;

    for (final raw in results) {
      final item = Map<String, dynamic>.from(raw as Map);
      final license = item['license']?.toString() ?? '';
      final version = item['license_version']?.toString() ?? '';
      final licenseLabel = version.isEmpty ? license : '$license $version';
      if (!_allowed(licenseLabel)) continue;
      if (item['sensitive'] == true || item['is_sensitive'] == true) continue;

      final candidateTitle = item['title']?.toString() ?? '';
      final description = item['description']?.toString() ?? '';
      final tags = (item['tags'] as List?)?.map((e) => e.toString()).join(' ') ?? '';
      final score = _score(record, candidateTitle, '$description $tags');
      final url = item['url']?.toString();
      if (url == null || !url.startsWith('https://')) continue;

      if (score > bestScore) {
        bestScore = score;
        best = {
          'imageUrl': url,
          'sourcePage': item['foreign_landing_url']?.toString() ?? '',
          'author': item['creator']?.toString() ?? '',
          'license': licenseLabel,
          'source': 'Openverse',
          'matchScore': '$score',
        };
      }
    }
    return bestScore >= 45 ? best : null;
  } finally {
    client.close(force: true);
  }
}

Future<Map<String, dynamic>?> _search(Record record) async {
  final queries = <String>[
    [record.title, record.city, record.country].where((x) => x.trim().isNotEmpty).join(' '),
    [record.title, record.city].where((x) => x.trim().isNotEmpty).join(' '),
    record.title,
  ].where((q) => q.trim().isNotEmpty).toSet();

  for (final query in queries) {
    final commons = await _commons(record, query);
    if (commons != null) return commons;
  }
  for (final query in queries) {
    final openverse = await _openverse(record, query);
    if (openverse != null) return openverse;
  }
  return null;
}

Future<void> _download(HttpClient client, String url, File destination) async {
  final request = await client.getUrl(Uri.parse(url));
  request.headers.set(HttpHeaders.userAgentHeader, 'EdibleReleaseImageBuilder/3.0');
  final response = await request.close();
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(url));
  }
  await destination.parent.create(recursive: true);
  final sink = destination.openWrite();
  await response.pipe(sink);
}

String _extensionFromUrl(String url) {
  final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
  if (path.endsWith('.png')) return 'png';
  if (path.endsWith('.webp')) return 'webp';
  if (path.endsWith('.jpeg')) return 'jpg';
  return 'jpg';
}

String _dart(String value) => jsonEncode(value);

Future<void> main() async {
  final root = Directory.current;
  final libRoot = Directory('${root.path}/lib');
  if (!libRoot.existsSync()) {
    stderr.writeln('ERROR: Run this from the Flutter project root. lib/ was not found.');
    exitCode = 2;
    return;
  }

  final records = _extractRecords(libRoot);
  final manifestFile = File('${root.path}/lib/features/explore/data/datasources/generated_image_manifest.dart');
  final localManifestFile = File('${root.path}/lib/features/explore/data/datasources/local_image_manifest.dart');
  final missingFile = File('${root.path}/tooling/image_manifest_missing.txt');
  final assetsRoot = Directory('${root.path}/assets/explore_images');
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 20);

  stdout.writeln('Catalog records: ${records.length}');

  final resolved = <String, Map<String, String>>{};
  final missing = <Record>[];
  final downloaded = <String, String>{};

  // Work in small batches so the release builder is fast without hammering providers.
  const batchSize = 6;
  for (var start = 0; start < records.length; start += batchSize) {
    final end = start + batchSize < records.length ? start + batchSize : records.length;
    final batch = records.sublist(start, end);
    final results = await Future.wait(batch.map((record) async {
      try {
        final hit = await _search(record);
        return MapEntry(record, hit);
      } catch (e) {
        stderr.writeln('SEARCH ERROR: ${record.title}: $e');
        return MapEntry<Record, Map<String, dynamic>?>(record, null);
      }
    }));

    for (final result in results) {
      final record = result.key;
      final hit = result.value;
      if (hit == null) {
        missing.add(record);
        continue;
      }

      final url = hit['imageUrl']?.toString() ?? '';
      if (!url.startsWith('https://')) {
        missing.add(record);
        continue;
      }

      final ext = _extensionFromUrl(url);
      final assetPath = 'assets/explore_images/${record.assetKey}.$ext';
      final destination = File('${root.path}/$assetPath');

      try {
        if (!destination.existsSync() || destination.lengthSync() < 1024) {
          await _download(client, url, destination);
        }
        downloaded[record.key] = assetPath;
        resolved[record.key] = Map<String, String>.from(hit)
          ..['assetPath'] = assetPath;
      } catch (e) {
        stderr.writeln('DOWNLOAD ERROR: ${record.title}: $e');
        missing.add(record);
      }
    }

    stdout.writeln('Progress: ${((start + batch.length) / records.length * 100).toStringAsFixed(1)}% | resolved ${resolved.length} | missing ${missing.length}');
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  client.close(force: true);

  // Write aliases: every exact catalog title gets its own entry. Matching is
  // by title+city+country first, then the runtime can use a normalized title fallback.
  final manifest = StringBuffer()
    ..writeln('// GENERATED FILE. DO NOT EDIT BY HAND.')
    ..writeln('// Exact release image manifest. Images are downloaded into assets/explore_images/.')
    ..writeln("const generatedImageManifestVersion = 'release_exact_local_2026_09_08_v3';")
    ..writeln('const generatedImageManifest = <String, Map<String, String>>{');

  for (final record in records) {
    final hit = resolved[record.key];
    if (hit == null) continue;
    manifest.writeln('  ${_dart(record.title)}: {');
    for (final key in const ['imageUrl', 'assetPath', 'sourcePage', 'author', 'license', 'source', 'matchScore']) {
      final value = hit[key]?.toString() ?? '';
      if (value.isEmpty) continue;
      manifest.writeln("    '$key': ${_dart(value)},");
    }
    manifest.writeln('  },');
  }
  manifest.writeln('};');
  manifestFile.writeAsStringSync(manifest.toString());

  final local = StringBuffer()
    ..writeln('// GENERATED FILE. Maps exact catalog records to downloaded local assets.')
    ..writeln("const localImageManifestVersion = 'local_exact_2026_09_08_v3';")
    ..writeln('const localImageManifest = <String, String>{');
  for (final record in records) {
    final path = downloaded[record.key];
    if (path == null) continue;
    local.writeln('  ${_dart(record.assetKey)}: ${_dart(path)},');
  }
  local.writeln('};');
  localManifestFile.writeAsStringSync(local.toString());

  final report = StringBuffer()
    ..writeln('CATALOG IMAGE AUDIT')
    ..writeln('Generated: ${DateTime.now().toIso8601String()}')
    ..writeln('Catalog records: ${records.length}')
    ..writeln('Resolved + downloaded: ${resolved.length}')
    ..writeln('Missing/unresolved: ${missing.length}')
    ..writeln('Local assets: ${downloaded.length}')
    ..writeln('')
    ..writeln('IMPORTANT: No generic/category fallback is assigned.')
    ..writeln('')
    ..writeln('MISSING:');
  for (final item in missing) {
    report.writeln('${item.title}\t${item.city}\t${item.country}\t${item.file}');
  }
  missingFile.writeAsStringSync(report.toString());

  if (missing.isNotEmpty) {
    stderr.writeln('IMAGE PIPELINE FAILED: ${missing.length} catalog records have no downloaded exact image.');
    exitCode = 3;
  } else {
    stdout.writeln('IMAGE PIPELINE COMPLETE: ${resolved.length}/${records.length} exact images downloaded.');
  }
}

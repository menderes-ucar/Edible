import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../core/services/supabase_service.dart';
import 'wikipedia_content_service.dart';

class ContentDescriptionResult {
  const ContentDescriptionResult({
    required this.shortDescription,
    required this.description,
    this.source,
    this.sourceUrl,
  });

  final String shortDescription;
  final String description;
  final String? source;
  final String? sourceUrl;
}

/// Resolves factual, localized descriptions once and keeps the winning
/// result locally. The Edge Function also persists the same result in
/// Supabase, so repeated detail-page opens do not trigger a new search.
class ContentDescriptionResolver {
  ContentDescriptionResolver._();

  static final instance = ContentDescriptionResolver._();

  static const _cacheFileName = 'edible_content_description_cache_v1.json';
  final Map<String, ContentDescriptionResult?> _memory = {};
  final Map<String, Future<ContentDescriptionResult?>> _inFlight = {};

  Future<ContentDescriptionResult?> resolve({
    required String title,
    required String locale,
    String? city,
    String? country,
    String? category,
  }) async {
    final key = _key(
      title: title,
      locale: locale,
      city: city,
      country: country,
      category: category,
    );

    if (_memory.containsKey(key)) return _memory[key];

    final disk = await _readDisk();
    if (disk.containsKey(key)) {
      final result = _fromJson(disk[key]);
      _memory[key] = result;
      return result;
    }

    final running = _inFlight[key];
    if (running != null) return running;

    final future = _resolveRemote(
      key: key,
      title: title,
      locale: locale,
      city: city,
      country: country,
      category: category,
    );
    _inFlight[key] = future;

    try {
      final result = await future;
      _memory[key] = result;
      if (result != null) {
        disk[key] = _toJson(result);
        await _writeDisk(disk);
      }
      return result;
    } finally {
      _inFlight.remove(key);
    }
  }

  Future<ContentDescriptionResult?> _resolveRemote({
    required String key,
    required String title,
    required String locale,
    String? city,
    String? country,
    String? category,
  }) async {
    final client = SupabaseService.client;

    if (client != null) {
      try {
        final response = await client.functions.invoke(
          'resolve-content-description',
          body: {
            'cache_key': key,
            'title': title.trim(),
            'locale': locale.trim(),
            'city': city?.trim(),
            'country': country?.trim(),
            'category': category?.trim(),
          },
        );

        final data = response.data;
        if (data is Map) {
          final short = (data['short_description'] ?? '').toString().trim();
          final description = (data['description'] ?? '').toString().trim();
          if (description.isNotEmpty) {
            return ContentDescriptionResult(
              shortDescription: short,
              description: description,
              source: data['source']?.toString(),
              sourceUrl: data['source_url']?.toString(),
            );
          }
        }
      } catch (_) {
        // Fall through to the direct Wikipedia resolver below.
      }
    }

    // Keep detail pages useful even if Supabase/Edge Functions are unavailable.
    // This resolver uses localized Wikipedia first and English as a fallback;
    // it never invents a description.
    try {
      final overview = await WikipediaContentService.instance.resolve(
        title: title,
        locale: locale,
        city: city,
        country: country,
      );
      if (overview == null || overview.extract.trim().isEmpty) return null;

      return ContentDescriptionResult(
        shortDescription: overview.extract.trim(),
        description: overview.extract.trim(),
        source: 'Wikipedia (${overview.language})',
        sourceUrl: overview.pageUrl,
      );
    } catch (_) {
      return null;
    }
  }

  String _key({
    required String title,
    required String locale,
    String? city,
    String? country,
    String? category,
  }) {
    String clean(String value) => value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');

    return [
      clean(title),
      clean(city ?? ''),
      clean(country ?? ''),
      clean(category ?? ''),
      clean(locale),
    ].join('|');
  }

  Future<Map<String, dynamic>> _readDisk() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final file = File('${directory.path}/$_cacheFileName');
      if (!await file.exists()) return <String, dynamic>{};
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return <String, dynamic>{};
  }

  Future<void> _writeDisk(Map<String, dynamic> data) async {
    try {
      final directory = await getApplicationSupportDirectory();
      final file = File('${directory.path}/$_cacheFileName');
      await file.writeAsString(jsonEncode(data), flush: true);
    } catch (_) {}
  }

  Map<String, dynamic> _toJson(ContentDescriptionResult value) => {
        'short_description': value.shortDescription,
        'description': value.description,
        'source': value.source,
        'source_url': value.sourceUrl,
      };

  ContentDescriptionResult? _fromJson(dynamic value) {
    if (value is! Map) return null;
    final description = (value['description'] ?? '').toString().trim();
    if (description.isEmpty) return null;
    return ContentDescriptionResult(
      shortDescription: (value['short_description'] ?? '').toString().trim(),
      description: description,
      source: value['source']?.toString(),
      sourceUrl: value['source_url']?.toString(),
    );
  }
}

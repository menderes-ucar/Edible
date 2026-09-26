import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';

/// Resolves ONE remote image per content item and persists that choice locally.
///
/// The important rule is: once a URL is found for a content key, scrolling or
/// rebuilding the widget never performs another search for that key.
class ResolvedContentImage {
  const ResolvedContentImage({
    required this.imageUrl,
    required this.provider,
    this.sourceUrl,
    this.attribution,
    this.score = 0,
  });

  final String imageUrl;
  final String provider;
  final String? sourceUrl;
  final String? attribution;
  final double score;

  Map<String, dynamic> toJson() => {
    'imageUrl': imageUrl,
    'provider': provider,
    'sourceUrl': sourceUrl,
    'attribution': attribution,
    'score': score,
  };

  static ResolvedContentImage? fromJson(dynamic value) {
    if (value is! Map) return null;
    final url = value['imageUrl']?.toString().trim() ?? '';
    if (url.isEmpty || !url.startsWith('https://')) return null;
    return ResolvedContentImage(
      imageUrl: url,
      provider: value['provider']?.toString() ?? 'unknown',
      sourceUrl: value['sourceUrl']?.toString(),
      attribution: value['attribution']?.toString(),
      score: value['score'] is num ? (value['score'] as num).toDouble() : 0,
    );
  }
}

class ContentImageResolver {
  ContentImageResolver._();

  static final instance = ContentImageResolver._();

  static const _cacheFileName = 'edible_remote_image_cache_v2.json';
  static const _maxConcurrentSearches = 4;

  final Map<String, Future<ResolvedContentImage?>> _inFlight = {};
  final Map<String, ResolvedContentImage?> _memoryCache = {};
  final List<Future<void> Function()> _queue = [];
  int _running = 0;
  Future<Map<String, dynamic>>? _diskLoad;

  // Keep the local key identical to the Edge Function/database cache key.
  // Do not transliterate Turkish characters: image_resolutions stores the
  // original Unicode letters.
  String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  String _key({
    required String title,
    String? city,
    String? country,
  }) => '${_normalize(title)}|${_normalize(city ?? '')}|${_normalize(country ?? '')}';

  Future<Map<String, dynamic>> _loadDiskCache() async {
    if (kIsWeb) return <String, dynamic>{};
    final existing = _diskLoad;
    if (existing != null) return existing;
    final future = () async {
      try {
        final dir = await getApplicationSupportDirectory();
        final file = File('${dir.path}/$_cacheFileName');
        if (!await file.exists()) return <String, dynamic>{};
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (error) {
        debugPrint('[IMAGE_CACHE] load failed: $error');
      }
      return <String, dynamic>{};
    }();
    _diskLoad = future;
    return future;
  }

  Future<void> _saveDiskCache(String key, ResolvedContentImage value) async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationSupportDirectory();
      await dir.create(recursive: true);
      final file = File('${dir.path}/$_cacheFileName');
      final raw = await _loadDiskCache();
      raw[key] = value.toJson();
      final temp = File('${file.path}.tmp');
      await temp.writeAsString(jsonEncode(raw), flush: true);
      await temp.rename(file.path);
      _diskLoad = Future.value(raw);
    } catch (error) {
      debugPrint('[IMAGE_CACHE] save failed: $error');
    }
  }

  Future<ResolvedContentImage?> _readCached(String key) async {
    if (_memoryCache.containsKey(key)) return _memoryCache[key];
    final disk = await _loadDiskCache();
    final cached = ResolvedContentImage.fromJson(disk[key]);
    _memoryCache[key] = cached;
    return cached;
  }

  Future<T> _limited<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    _queue.add(() async {
      try {
        completer.complete(await task());
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    _drainQueue();
    return completer.future;
  }

  void _drainQueue() {
    while (_running < _maxConcurrentSearches && _queue.isNotEmpty) {
      final task = _queue.removeAt(0);
      _running++;
      task().whenComplete(() {
        _running--;
        _drainQueue();
      });
    }
  }

  Future<ResolvedContentImage?> resolve({
    required String title,
    required String locale,
    String? city,
    String? country,
    String? preferredUrl,
  }) async {
    final key = _key(title: title, city: city, country: country);

    // Anıtkabir in Ankara is manually managed in Supabase Storage.
    // Do not search Wikimedia/Unsplash/etc. and do not reuse an old cached URL.
    final isManualAnitkabir =
        title.trim().toLowerCase() == 'anıtkabir' &&
            city?.trim().toLowerCase() == 'ankara' &&
            country?.trim().toLowerCase() == 'türkiye';
    if (isManualAnitkabir) {
      const manualUrl =
          'https://lylliolgjxmbpawkriww.supabase.co/storage/v1/object/public/edible-content-images/anitkabir-night.jpeg';
      const manualResult = ResolvedContentImage(
        imageUrl: manualUrl,
        provider: 'manual',
        attribution: 'Edible',
        score: 1.5,
      );
      _memoryCache[key] = manualResult;
      await _saveDiskCache(key, manualResult);
      return manualResult;
    }

    final cached = await _readCached(key);
    if (cached != null) return cached;

    final existing = _inFlight[key];
    if (existing != null) return existing;

    final future = _limited(() async {
      // A catalog URL is only used if it is not one of the known generic
      // placeholder families. Search is still preferred because the resolver
      // verifies the title/city/country against multiple image sources.
      final remote = await _resolveFromSearch(
        title: title,
        locale: locale,
        city: city,
        country: country,
      );

      if (remote != null) {
        _memoryCache[key] = remote;
        await _saveDiskCache(key, remote);
        return remote;
      }

      final preferred = _cleanPreferredUrl(preferredUrl);
      if (preferred != null) {
        final fallback = ResolvedContentImage(
          imageUrl: preferred,
          provider: 'catalog',
          attribution: 'Catalog image',
          score: 0.35,
        );
        _memoryCache[key] = fallback;
        await _saveDiskCache(key, fallback);
        return fallback;
      }

      _memoryCache[key] = null;
      return null;
    });

    _inFlight[key] = future;
    future.whenComplete(() => _inFlight.remove(key));
    return future;
  }

  String? _cleanPreferredUrl(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty || !value.startsWith('https://')) return null;
    final lower = value.toLowerCase();
    const blocked = <String>[
      'images.unsplash.com/photo-1451187580459-43490279c0fa',
      'images.unsplash.com/photo-1497250681960-ef046c08a56e',
      'images.unsplash.com/photo-1500530855697-b586d89ba3ee',
      'images.unsplash.com/photo-1501785888041-af3ef285b470',
      'images.unsplash.com/photo-1518005020951-eccb494ad742',
      'images.unsplash.com/photo-1519681393784-d120267933ba',
      'images.unsplash.com/photo-1526772662000-3f88f10405ff',
      'images.unsplash.com/photo-1530789253388-582c481c54b0',
      'images.unsplash.com/photo-1548013146-72479768bada',
      'images.unsplash.com/photo-1564501049412-61c2a3083791',
    ];
    if (blocked.any(lower.contains)) return null;
    return value;
  }

  Future<ResolvedContentImage?> _resolveFromSearch({
    required String title,
    required String locale,
    String? city,
    String? country,
  }) async {
    final client = SupabaseService.client;
    if (client == null || title.trim().isEmpty) return null;

    try {
      final response = await client.functions
          .invoke(
        'resolve-content-image',
        body: {
          'title': title.trim(),
          'city': city?.trim(),
          'country': country?.trim(),
          'locale': _locale(locale),
        },
      )
          .timeout(const Duration(seconds: 20));

      final data = response.data;
      if (data is! Map) return null;
      final candidate = ResolvedContentImage(
        imageUrl: data['imageUrl']?.toString().trim() ?? '',
        provider: data['provider']?.toString() ?? 'unknown',
        sourceUrl: data['sourceUrl']?.toString(),
        attribution: data['attribution']?.toString(),
        score: data['score'] is num ? (data['score'] as num).toDouble() : 0,
      );
      if (!candidate.imageUrl.startsWith('https://')) return null;
      if (candidate.score < 0.42) return null;
      return candidate;
    } on FunctionException catch (error) {
      debugPrint('[IMAGE_RESOLVER] FunctionException: $error');
      return null;
    } catch (error) {
      debugPrint('[IMAGE_RESOLVER] Error: $error');
      return null;
    }
  }

  String _locale(String value) {
    switch (value.toLowerCase()) {
      case 'tr': return 'tr-TR';
      case 'de': return 'de-DE';
      case 'fr': return 'fr-FR';
      case 'es': return 'es-ES';
      case 'it': return 'it-IT';
      case 'pt': return 'pt-BR';
      case 'ja': return 'ja-JP';
      case 'ko': return 'ko-KR';
      case 'zh': return 'zh-CN';
      default: return 'en-US';
    }
  }
}

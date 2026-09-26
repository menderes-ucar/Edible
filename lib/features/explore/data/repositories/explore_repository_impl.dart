import '../../../../core/services/supabase_service.dart';
import '../../../offline/data/datasources/offline_city_pack_local_data_source.dart';
import '../../domain/entities/explore_content.dart';
import '../../domain/entities/explore_metadata.dart';
import '../../domain/repositories/explore_repository.dart';
import '../datasources/explore_local_data_source.dart';
import '../datasources/explore_remote_data_source.dart';

class ExploreRepositoryImpl implements ExploreRepository {
  static const _manualAnitkabirImage =
      'https://lylliolgjxmbpawkriww.supabase.co/storage/v1/object/public/edible-content-images/anitkabir-night.jpeg';

  ExploreRepositoryImpl({
    required ExploreRemoteDataSource remoteDataSource,
    required ExploreLocalDataSource localDataSource,
    required OfflineCityPackLocalDataSource offlineDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _offlineDataSource = offlineDataSource;

  final ExploreRemoteDataSource _remoteDataSource;
  final ExploreLocalDataSource _localDataSource;
  final OfflineCityPackLocalDataSource _offlineDataSource;

  @override
  Future<List<ExploreContent>> getContents({
    required String languageCode,
  }) async {
    final offline = await _offlineDataSource.readAllContents(
      languageCode: languageCode,
    );

    if (!SupabaseService.isInitialized) {
      return _merge(
        _localDataSource.getContents(languageCode),
        offline,
      );
    }

    try {
      final remote = await _remoteDataSource.getContents(
        languageCode: languageCode,
      );

      final bundled = _localDataSource.getContents(languageCode);
      return _mergeThree(bundled, remote, offline);
    } catch (_) {
      return _merge(
        _localDataSource.getContents(languageCode),
        offline,
      );
    }
  }


  List<ExploreContent> _mergeThree(
      List<ExploreContent> bundled,
      List<ExploreContent> remote,
      List<ExploreContent> offline,
      ) {
    final bundledById = <String, ExploreContent>{
      for (final item in bundled) item.id: item,
    };
    final byId = <String, ExploreContent>{
      ...bundledById,
      for (final item in offline) item.id: item,
    };

    for (final remoteItem in remote) {
      final bundledItem = bundledById[remoteItem.id];
      byId[remoteItem.id] = bundledItem == null
          ? remoteItem
          : _mergeRemoteWithBundledFallback(
        remote: remoteItem,
        bundled: bundledItem,
      );
    }

    return _dedupeSemantically(byId.values);
  }

  ExploreContent _mergeRemoteWithBundledFallback({
    required ExploreContent remote,
    required ExploreContent bundled,
  }) {
    return ExploreContent(
      id: remote.id,
      countryCode: remote.countryCode.isNotEmpty
          ? remote.countryCode
          : bundled.countryCode,
      countryName: remote.countryName.isNotEmpty
          ? remote.countryName
          : bundled.countryName,
      cityName: remote.cityName.isNotEmpty ? remote.cityName : bundled.cityName,
      category: remote.category,
      title: remote.title.isNotEmpty ? remote.title : bundled.title,
      shortDescription: remote.shortDescription.isNotEmpty
          ? remote.shortDescription
          : bundled.shortDescription,
      description: remote.description.isNotEmpty
          ? remote.description
          : bundled.description,
      latitude: remote.latitude != 0 ? remote.latitude : bundled.latitude,
      longitude: remote.longitude != 0 ? remote.longitude : bundled.longitude,
      tags: remote.tags.isNotEmpty ? remote.tags : bundled.tags,
      metadata: _mergeMetadata(
        remote: remote.metadata,
        bundled: bundled.metadata,
      ),
      galleryImageUrls: remote.galleryImageUrls.isNotEmpty
          ? remote.galleryImageUrls
          : bundled.galleryImageUrls,
      coverImageUrl: _forceManualAnitkabirImage(
        remote: remote.coverImageUrl,
        bundled: bundled.coverImageUrl,
        cityName: remote.cityName.isNotEmpty
            ? remote.cityName
            : bundled.cityName,
        title: remote.title.isNotEmpty ? remote.title : bundled.title,
      ),
      isFeatured: remote.isFeatured || bundled.isFeatured,
    );
  }

  String? _forceManualAnitkabirImage({
    required String? remote,
    required String? bundled,
    required String cityName,
    required String title,
  }) {
    final normalizedCity = cityName.trim().toLowerCase().replaceAll('ı', 'i');
    final normalizedTitle = title.trim().toLowerCase().replaceAll('ı', 'i');

    if (normalizedCity == 'ankara' && normalizedTitle == 'anıtkabir') {
      return _manualAnitkabirImage;
    }

    if (remote?.trim().isNotEmpty == true) return remote;
    return bundled;
  }

  ExploreMetadata _mergeMetadata({
    required ExploreMetadata remote,
    required ExploreMetadata bundled,
  }) {
    return ExploreMetadata(
      priceLevel: remote.priceLevel ?? bundled.priceLevel,
      bestTime: remote.bestTime ?? bundled.bestTime,
      localTip: remote.localTip ?? bundled.localTip,
      openingInfo: remote.openingInfo ?? bundled.openingInfo,
      estimatedVisitMinutes:
      remote.estimatedVisitMinutes ?? bundled.estimatedVisitMinutes,
      vegetarian: remote.vegetarian ?? bundled.vegetarian,
      vegan: remote.vegan ?? bundled.vegan,
      halal: remote.halal ?? bundled.halal,
      spicyLevel: remote.spicyLevel ?? bundled.spicyLevel,
      etiquette: remote.etiquette ?? bundled.etiquette,
      doText: remote.doText ?? bundled.doText,
      dontText: remote.dontText ?? bundled.dontText,
      coordinatePrecision:
      remote.coordinatePrecision ?? bundled.coordinatePrecision,
      editorialStatus: remote.editorialStatus ?? bundled.editorialStatus,
    );
  }

  List<ExploreContent> _merge(
      List<ExploreContent> primary,
      List<ExploreContent> offline,
      ) {
    final byId = <String, ExploreContent>{
      for (final item in offline) item.id: item,
      for (final item in primary) item.id: item,
    };

    return _dedupeSemantically(byId.values);
  }

  List<ExploreContent> _dedupeSemantically(Iterable<ExploreContent> items) {
    final byCanonicalKey = <String, ExploreContent>{};
    for (final item in items) {
      final key = _canonicalKey(item);
      final existing = byCanonicalKey[key];
      if (existing == null || _qualityScore(item) > _qualityScore(existing)) {
        byCanonicalKey[key] = item;
      }
    }
    return byCanonicalKey.values.toList(growable: false);
  }

  String _canonicalKey(ExploreContent item) {
    final title = _canonicalTitle(item.title);
    final city = _normalize(item.cityName);
    final country = _normalize(item.countryCode.isNotEmpty ? item.countryCode : item.countryName);
    return '${item.category.value}|$country|$city|$title';
  }

  String _canonicalTitle(String value) {
    final normalized = _normalize(value);
    if (normalized.contains('ayasofya') || normalized.contains('hagiasophia')) {
      return 'hagiasophia';
    }

    switch (normalized) {
      case 'topkapipalace':
      case 'topkapipalaceistanbul':
        return 'topkapipalace';
      case 'dolmabahcepalace':
        return 'dolmabahcepalace';
      default:
        return normalized;
    }
  }

  String _normalize(String value) {
    var result = value.trim().toLowerCase();
    const replacements = {
      'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u',
      'â': 'a', 'î': 'i', 'û': 'u', 'é': 'e', 'è': 'e', 'ê': 'e',
      'á': 'a', 'à': 'a', 'ä': 'a', 'ñ': 'n', 'ß': 'ss',
    };
    replacements.forEach((from, to) => result = result.replaceAll(from, to));
    return result.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  int _qualityScore(ExploreContent item) {
    // Image availability is the most important quality signal for Explore.
    // A remote row without an image must never replace a bundled row that
    // already has a real, directly renderable image URL.
    var score = 0;
    final hasCover = item.coverImageUrl?.trim().isNotEmpty == true;
    final galleryCount = item.galleryImageUrls.length;

    if (hasCover) score += 1000;
    score += galleryCount.clamp(0, 5) * 100;
    if (item.isFeatured) score += 100;
    if (item.latitude != 0 && item.longitude != 0) score += 20;
    score += (item.description.length / 200).floor().clamp(0, 5);
    return score;
  }

  @override
  Future<ExploreContent?> getById({
    required String id,
    required String languageCode,
  }) async {
    final items = await getContents(languageCode: languageCode);

    for (final item in items) {
      if (item.id == id) return item;
    }

    return null;
  }
}

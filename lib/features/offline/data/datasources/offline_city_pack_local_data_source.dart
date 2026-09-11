import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../culture/domain/entities/culture_guide.dart';
import '../../../explore/domain/entities/explore_category.dart';
import '../../../explore/domain/entities/explore_content.dart';
import '../../../explore/domain/entities/explore_metadata.dart';
import '../../../food/domain/entities/food_details.dart';
import '../../domain/entities/offline_city_pack.dart';

class OfflineCityPackLocalDataSource {
  const OfflineCityPackLocalDataSource();

  Future<Directory> _directory() async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/edible_offline_packs');

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  String _safe(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '_');
  }

  Future<File> _file({
    required String countryCode,
    required String cityName,
    required String languageCode,
  }) async {
    final directory = await _directory();
    final name =
        '${_safe(countryCode)}__${_safe(cityName)}__${_safe(languageCode)}.json';
    return File('${directory.path}/$name');
  }

  Future<void> save(OfflineCityPack pack) async {
    final file = await _file(
      countryCode: pack.countryCode,
      cityName: pack.cityName,
      languageCode: pack.languageCode,
    );

    final tempFile = File('${file.path}.tmp');

    try {
      await tempFile.writeAsString(
        jsonEncode(_packToMap(pack)),
        flush: true,
      );

      if (await file.exists()) {
        await file.delete();
      }

      await tempFile.rename(file.path);
    } catch (_) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    }
  }

  Future<OfflineCityPack?> read({
    required String countryCode,
    required String cityName,
    required String languageCode,
  }) async {
    final file = await _file(
      countryCode: countryCode,
      cityName: cityName,
      languageCode: languageCode,
    );

    if (!await file.exists()) return null;

    try {
      final raw = await file.readAsString();
      return _packFromMap(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      await _deleteQuietly(file);
      return null;
    }
  }

  Future<List<OfflineCityPack>> readAll() async {
    final directory = await _directory();
    final packs = <OfflineCityPack>[];

    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;

      try {
        final raw = await entity.readAsString();
        packs.add(
          _packFromMap(
            Map<String, dynamic>.from(jsonDecode(raw) as Map),
          ),
        );
      } catch (_) {
        // Remove one corrupt pack instead of retrying the same broken JSON
        // forever. Other offline packs remain available.
        await _deleteQuietly(entity);
      }
    }

    packs.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
    return packs;
  }

  Future<void> delete({
    required String countryCode,
    required String cityName,
    required String languageCode,
  }) async {
    final file = await _file(
      countryCode: countryCode,
      cityName: cityName,
      languageCode: languageCode,
    );

    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<List<ExploreContent>> readAllContents({
    required String languageCode,
  }) async {
    final packs = await readAll();
    final byId = <String, ExploreContent>{};

    for (final pack in packs) {
      if (pack.languageCode.toLowerCase() != languageCode.toLowerCase()) {
        continue;
      }

      for (final content in pack.contents) {
        byId[content.id] = content;
      }
    }

    return byId.values.toList(growable: false);
  }

  Future<FoodDetails?> findFoodDetails(String contentId) async {
    final packs = await readAll();

    for (final pack in packs) {
      final details = pack.foodDetails[contentId];
      if (details != null) return details;
    }

    return null;
  }

  Future<CultureGuide?> findCultureGuide({
    required String countryCode,
    required String cityName,
    required String languageCode,
  }) async {
    final pack = await read(
      countryCode: countryCode,
      cityName: cityName,
      languageCode: languageCode,
    );

    return pack?.cultureGuide;
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best-effort cleanup only.
    }
  }

  Map<String, dynamic> _packToMap(OfflineCityPack pack) => {
        'country_code': pack.countryCode,
        'country_name': pack.countryName,
        'city_name': pack.cityName,
        'language_code': pack.languageCode,
        'downloaded_at': pack.downloadedAt.toIso8601String(),
        'contents': pack.contents.map(_contentToMap).toList(),
        'food_details': {
          for (final entry in pack.foodDetails.entries)
            entry.key: _foodToMap(entry.value),
        },
        'culture_guide': _cultureToMap(pack.cultureGuide),
      };

  OfflineCityPack _packFromMap(Map<String, dynamic> map) {
    final rawFood = Map<String, dynamic>.from(
      (map['food_details'] as Map?) ?? const {},
    );

    return OfflineCityPack(
      countryCode: (map['country_code'] ?? '').toString(),
      countryName: (map['country_name'] ?? '').toString(),
      cityName: (map['city_name'] ?? '').toString(),
      languageCode: (map['language_code'] ?? 'en').toString(),
      downloadedAt:
          DateTime.tryParse((map['downloaded_at'] ?? '').toString()) ??
              DateTime.now(),
      contents: ((map['contents'] as List?) ?? const [])
          .map(
            (item) => _contentFromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
      foodDetails: {
        for (final entry in rawFood.entries)
          entry.key: _foodFromMap(
            Map<String, dynamic>.from(entry.value as Map),
          ),
      },
      cultureGuide: _cultureFromMap(
        Map<String, dynamic>.from(
          (map['culture_guide'] as Map?) ?? const {},
        ),
      ),
    );
  }

  Map<String, dynamic> _contentToMap(ExploreContent item) => {
        'id': item.id,
        'country_code': item.countryCode,
        'country_name': item.countryName,
        'city_name': item.cityName,
        'category': item.category.value,
        'title': item.title,
        'short_description': item.shortDescription,
        'description': item.description,
        'latitude': item.latitude,
        'longitude': item.longitude,
        'tags': item.tags,
        'cover_image_url': item.coverImageUrl,
        'gallery_image_urls': item.galleryImageUrls,
        'is_featured': item.isFeatured,
        'metadata': _metadataToMap(item.metadata),
      };

  ExploreContent _contentFromMap(Map<String, dynamic> map) {
    return ExploreContent(
      id: (map['id'] ?? '').toString(),
      countryCode: (map['country_code'] ?? '').toString(),
      countryName: (map['country_name'] ?? '').toString(),
      cityName: (map['city_name'] ?? '').toString(),
      category: ExploreCategory.fromValue(
        (map['category'] ?? 'place').toString(),
      ),
      title: (map['title'] ?? '').toString(),
      shortDescription: (map['short_description'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      latitude: _toDouble(map['latitude']) ?? 0,
      longitude: _toDouble(map['longitude']) ?? 0,
      tags: _stringList(map['tags']),
      metadata: _metadataFromMap(
        Map<String, dynamic>.from(
          (map['metadata'] as Map?) ?? const {},
        ),
      ),
      galleryImageUrls: _stringList(map['gallery_image_urls']),
      coverImageUrl: map['cover_image_url']?.toString(),
      isFeatured: map['is_featured'] == true,
    );
  }

  Map<String, dynamic> _metadataToMap(ExploreMetadata value) => {
        'price_level': value.priceLevel,
        'best_time': value.bestTime,
        'local_tip': value.localTip,
        'opening_info': value.openingInfo,
        'estimated_visit_minutes': value.estimatedVisitMinutes,
        'vegetarian': value.vegetarian,
        'vegan': value.vegan,
        'halal': value.halal,
        'spicy_level': value.spicyLevel,
        'etiquette': value.etiquette,
        'do_text': value.doText,
        'dont_text': value.dontText,
        'coordinate_precision': value.coordinatePrecision,
        'editorial_status': value.editorialStatus,
      };

  ExploreMetadata _metadataFromMap(Map<String, dynamic> map) {
    return ExploreMetadata(
      priceLevel: _toInt(map['price_level']),
      bestTime: map['best_time']?.toString(),
      localTip: map['local_tip']?.toString(),
      openingInfo: map['opening_info']?.toString(),
      estimatedVisitMinutes: _toInt(map['estimated_visit_minutes']),
      vegetarian: _toBool(map['vegetarian']),
      vegan: _toBool(map['vegan']),
      halal: _toBool(map['halal']),
      spicyLevel: _toInt(map['spicy_level']),
      etiquette: map['etiquette']?.toString(),
      doText: map['do_text']?.toString(),
      dontText: map['dont_text']?.toString(),
      coordinatePrecision: map['coordinate_precision']?.toString(),
      editorialStatus: map['editorial_status']?.toString(),
    );
  }

  Map<String, dynamic> _foodToMap(FoodDetails value) => {
        'content_id': value.contentId,
        'currency_code': value.currencyCode,
        'typical_price_min': value.typicalPriceMin,
        'typical_price_max': value.typicalPriceMax,
        'spicy_level': value.spicyLevel,
        'vegetarian': value.vegetarian,
        'vegan': value.vegan,
        'halal': value.halal,
        'contains_pork': value.containsPork,
        'contains_alcohol': value.containsAlcohol,
        'gluten_free': value.glutenFree,
        'ingredients': value.ingredients,
        'allergens': value.allergens,
        'portion_info': value.portionInfo,
        'how_locals_eat': value.howLocalsEat,
        'when_locals_eat': value.whenLocalsEat,
        'before_you_order': value.beforeYouOrder,
      };

  FoodDetails _foodFromMap(Map<String, dynamic> map) => FoodDetails(
        contentId: (map['content_id'] ?? '').toString(),
        currencyCode: map['currency_code']?.toString(),
        typicalPriceMin: _toDouble(map['typical_price_min']),
        typicalPriceMax: _toDouble(map['typical_price_max']),
        spicyLevel: _toInt(map['spicy_level']),
        vegetarian: _toBool(map['vegetarian']),
        vegan: _toBool(map['vegan']),
        halal: _toBool(map['halal']),
        containsPork: _toBool(map['contains_pork']),
        containsAlcohol: _toBool(map['contains_alcohol']),
        glutenFree: _toBool(map['gluten_free']),
        ingredients: _stringList(map['ingredients']),
        allergens: _stringList(map['allergens']),
        portionInfo: map['portion_info']?.toString(),
        howLocalsEat: map['how_locals_eat']?.toString(),
        whenLocalsEat: map['when_locals_eat']?.toString(),
        beforeYouOrder: map['before_you_order']?.toString(),
      );

  Map<String, dynamic> _cultureToMap(CultureGuide guide) => {
        'country_code': guide.countryCode,
        'country_name': guide.countryName,
        'city_name': guide.cityName,
        'items': guide.items
            .map(
              (item) => {
                'id': item.id,
                'type': item.type.name,
                'title': item.title,
                'body': item.body,
                'priority': item.priority,
                'phrase_local': item.phraseLocal,
                'phrase_pronunciation': item.phrasePronunciation,
                'phrase_translation': item.phraseTranslation,
              },
            )
            .toList(),
      };

  CultureGuide _cultureFromMap(Map<String, dynamic> map) {
    return CultureGuide(
      countryCode: (map['country_code'] ?? '').toString(),
      countryName: (map['country_name'] ?? '').toString(),
      cityName: (map['city_name'] ?? '').toString(),
      items: ((map['items'] as List?) ?? const [])
          .map((raw) {
            final item = Map<String, dynamic>.from(raw as Map);
            return CultureGuideItem(
              id: (item['id'] ?? '').toString(),
              type: CultureTipType.fromValue(
                (item['type'] ?? 'doTip').toString(),
              ),
              title: (item['title'] ?? '').toString(),
              body: (item['body'] ?? '').toString(),
              priority: _toInt(item['priority']) ?? 0,
              phraseLocal: item['phrase_local']?.toString(),
              phrasePronunciation:
                  item['phrase_pronunciation']?.toString(),
              phraseTranslation:
                  item['phrase_translation']?.toString(),
            );
          })
          .toList(growable: false),
    );
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  bool? _toBool(dynamic value) {
    if (value is bool) return value;
    if (value == null) return null;
    if (value.toString().toLowerCase() == 'true') return true;
    if (value.toString().toLowerCase() == 'false') return false;
    return null;
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList(growable: false);
  }
}

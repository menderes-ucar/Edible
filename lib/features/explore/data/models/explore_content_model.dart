import '../../domain/entities/explore_category.dart';
import '../../domain/entities/explore_content.dart';
import '../../domain/entities/explore_metadata.dart';

class ExploreContentModel extends ExploreContent {
  const ExploreContentModel({
    required super.id,
    required super.countryCode,
    required super.countryName,
    required super.cityName,
    required super.category,
    required super.title,
    required super.shortDescription,
    required super.description,
    required super.latitude,
    required super.longitude,
    required super.tags,
    required super.metadata,
    required super.galleryImageUrls,
    super.coverImageUrl,
    super.isFeatured,
  });

  factory ExploreContentModel.fromMap(
    Map<String, dynamic> map, {
    List<String> resolvedGalleryUrls = const [],
  }) {
    final rawMetadata = map['metadata'];
    final metadata = rawMetadata is Map
        ? Map<String, dynamic>.from(rawMetadata)
        : <String, dynamic>{};

    return ExploreContentModel(
      id: map['id'].toString(),
      countryCode: (map['country_code'] ?? '').toString(),
      countryName: (map['country_name'] ?? '').toString(),
      cityName: (map['city_name'] ?? '').toString(),
      category: ExploreCategory.fromValue(
        (map['category'] ?? 'place').toString(),
      ),
      title: (map['title'] ?? '').toString(),
      shortDescription: (map['short_description'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      latitude: _toDouble(map['latitude']),
      longitude: _toDouble(map['longitude']),
      coverImageUrl: map['cover_image_url']?.toString(),
      isFeatured: map['is_featured'] == true,
      tags: _toStringList(map['tags']),
      galleryImageUrls: resolvedGalleryUrls,
      metadata: ExploreMetadata(
        priceLevel: _toInt(metadata['price_level']),
        bestTime: metadata['best_time']?.toString(),
        localTip: metadata['local_tip']?.toString(),
        openingInfo: metadata['opening_info']?.toString(),
        estimatedVisitMinutes:
            _toInt(metadata['estimated_visit_minutes']),
        vegetarian: _toBool(metadata['vegetarian']),
        vegan: _toBool(metadata['vegan']),
        halal: _toBool(metadata['halal']),
        spicyLevel: _toInt(metadata['spicy_level']),
        etiquette: metadata['etiquette']?.toString(),
        doText: metadata['do']?.toString(),
        dontText: metadata['dont']?.toString(),
        coordinatePrecision: metadata['coordinate_precision']?.toString(),
        editorialStatus: metadata['editorial_status']?.toString(),
      ),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static bool? _toBool(dynamic value) {
    if (value is bool) return value;
    if (value == null) return null;

    return switch (value.toString().toLowerCase()) {
      'true' => true,
      'false' => false,
      _ => null,
    };
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    return const [];
  }
}

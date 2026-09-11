import 'explore_category.dart';
import 'explore_metadata.dart';

class ExploreContent {
  const ExploreContent({
    required this.id,
    required this.countryCode,
    required this.countryName,
    required this.cityName,
    required this.category,
    required this.title,
    required this.shortDescription,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.tags,
    required this.metadata,
    required this.galleryImageUrls,
    this.coverImageUrl,
    this.isFeatured = false,
  });

  final String id;
  final String countryCode;
  final String countryName;
  final String cityName;
  final ExploreCategory category;
  final String title;
  final String shortDescription;
  final String description;
  final double latitude;
  final double longitude;
  final List<String> tags;
  final ExploreMetadata metadata;
  final List<String> galleryImageUrls;
  final String? coverImageUrl;
  final bool isFeatured;

  String get locationLabel => '$cityName, $countryName';

  List<String> get allImageUrls {
    final values = <String>[
      if (coverImageUrl != null && coverImageUrl!.trim().isNotEmpty)
        coverImageUrl!.trim(),
      ...galleryImageUrls.where((url) => url.trim().isNotEmpty),
    ];

    return values.toSet().toList(growable: false);
  }
}

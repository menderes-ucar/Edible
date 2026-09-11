import '../../../culture/domain/entities/culture_guide.dart';
import '../../../explore/domain/entities/explore_content.dart';
import '../../../food/domain/entities/food_details.dart';

class OfflineCityPack {
  const OfflineCityPack({
    required this.countryCode,
    required this.countryName,
    required this.cityName,
    required this.languageCode,
    required this.downloadedAt,
    required this.contents,
    required this.foodDetails,
    required this.cultureGuide,
  });

  final String countryCode;
  final String countryName;
  final String cityName;
  final String languageCode;
  final DateTime downloadedAt;
  final List<ExploreContent> contents;
  final Map<String, FoodDetails> foodDetails;
  final CultureGuide cultureGuide;

  String get key =>
      '${countryCode.toLowerCase()}__${cityName.toLowerCase()}__${languageCode.toLowerCase()}';

  int get contentCount => contents.length;
}

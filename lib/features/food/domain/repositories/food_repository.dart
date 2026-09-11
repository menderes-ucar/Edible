import '../entities/food_details.dart';

abstract interface class FoodRepository {
  Future<Map<String, FoodDetails>> getDetailsForContents({
    required Iterable<String> contentIds,
    required String languageCode,
  });

  Future<FoodDetails?> getByContentId({
    required String contentId,
    required String languageCode,
  });
}

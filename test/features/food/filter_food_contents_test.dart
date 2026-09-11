import 'package:edible/features/explore/domain/entities/explore_category.dart';
import 'package:edible/features/explore/domain/entities/explore_content.dart';
import 'package:edible/features/explore/domain/entities/explore_metadata.dart';
import 'package:edible/features/food/domain/entities/food_details.dart';
import 'package:edible/features/food/domain/entities/food_filter.dart';
import 'package:edible/features/food/domain/usecases/filter_food_contents.dart';
import 'package:flutter_test/flutter_test.dart';

ExploreContent food(String id) {
  return ExploreContent(
    id: id,
    countryCode: 'JP',
    countryName: 'Japan',
    cityName: 'Tokyo',
    category: ExploreCategory.food,
    title: id,
    shortDescription: '',
    description: '',
    latitude: 35,
    longitude: 139,
    tags: const [],
    metadata: const ExploreMetadata(),
    galleryImageUrls: const [],
  );
}

void main() {
  test('all selected food filters must match', () {
    const useCase = FilterFoodContents();
    final ramen = food('ramen');
    final vegan = food('vegan');

    final result = useCase(
      contents: [ramen, vegan],
      detailsByContentId: const {
        'ramen': FoodDetails(
          contentId: 'ramen',
          halal: false,
          vegan: false,
          containsPork: true,
        ),
        'vegan': FoodDetails(
          contentId: 'vegan',
          halal: true,
          vegan: true,
          containsPork: false,
        ),
      },
      filters: const {
        FoodFilter.halal,
        FoodFilter.noPork,
      },
    );

    expect(result.map((item) => item.id), ['vegan']);
  });
}

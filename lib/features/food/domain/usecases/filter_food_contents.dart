import '../../../explore/domain/entities/explore_content.dart';
import '../entities/food_details.dart';
import '../entities/food_filter.dart';

class FilterFoodContents {
  const FilterFoodContents();

  List<ExploreContent> call({
    required Iterable<ExploreContent> contents,
    required Map<String, FoodDetails> detailsByContentId,
    required Set<FoodFilter> filters,
  }) {
    if (filters.isEmpty) {
      return contents.toList(growable: false);
    }

    return contents.where((content) {
      final details = detailsByContentId[content.id];
      if (details == null) return false;

      for (final filter in filters) {
        final matches = switch (filter) {
          FoodFilter.halal => details.halal == true,
          FoodFilter.vegan => details.vegan == true,
          FoodFilter.vegetarian => details.vegetarian == true,
          FoodFilter.noPork => details.containsPork == false,
          FoodFilter.noAlcohol => details.containsAlcohol == false,
          FoodFilter.glutenFree => details.glutenFree == true,
        };

        if (!matches) return false;
      }

      return true;
    }).toList(growable: false);
  }
}

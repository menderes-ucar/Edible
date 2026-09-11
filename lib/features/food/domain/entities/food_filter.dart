enum FoodFilter {
  halal,
  vegan,
  vegetarian,
  noPork,
  noAlcohol,
  glutenFree;

  String get localizationKey => switch (this) {
        FoodFilter.halal => 'halal',
        FoodFilter.vegan => 'vegan',
        FoodFilter.vegetarian => 'vegetarian',
        FoodFilter.noPork => 'noPork',
        FoodFilter.noAlcohol => 'noAlcohol',
        FoodFilter.glutenFree => 'glutenFree',
      };
}

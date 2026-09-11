enum ExploreCategory {
  place('place', 'places'),
  food('food', 'food'),
  snack('snack', 'snacks'),
  culture('culture', 'culture'),
  fruit('fruit', 'fruit'),
  drink('drink', 'drinks');

  const ExploreCategory(this.value, this.localizationKey);

  final String value;
  final String localizationKey;

  static ExploreCategory fromValue(String value) {
    return ExploreCategory.values.firstWhere(
      (item) => item.value == value,
      orElse: () => ExploreCategory.place,
    );
  }
}

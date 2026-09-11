class FoodDetails {
  const FoodDetails({
    required this.contentId,
    this.currencyCode,
    this.typicalPriceMin,
    this.typicalPriceMax,
    this.spicyLevel,
    this.vegetarian,
    this.vegan,
    this.halal,
    this.containsPork,
    this.containsAlcohol,
    this.glutenFree,
    this.ingredients = const [],
    this.allergens = const [],
    this.portionInfo,
    this.howLocalsEat,
    this.whenLocalsEat,
    this.beforeYouOrder,
  });

  final String contentId;
  final String? currencyCode;
  final double? typicalPriceMin;
  final double? typicalPriceMax;
  final int? spicyLevel;

  final bool? vegetarian;
  final bool? vegan;
  final bool? halal;
  final bool? containsPork;
  final bool? containsAlcohol;
  final bool? glutenFree;

  final List<String> ingredients;
  final List<String> allergens;

  final String? portionInfo;
  final String? howLocalsEat;
  final String? whenLocalsEat;
  final String? beforeYouOrder;

  bool get hasPrice =>
      typicalPriceMin != null || typicalPriceMax != null;

  bool get hasDietaryInfo =>
      vegetarian != null ||
      vegan != null ||
      halal != null ||
      containsPork != null ||
      containsAlcohol != null ||
      glutenFree != null;

  bool get isEmpty =>
      !hasPrice &&
      spicyLevel == null &&
      !hasDietaryInfo &&
      ingredients.isEmpty &&
      allergens.isEmpty &&
      (portionInfo == null || portionInfo!.trim().isEmpty) &&
      (howLocalsEat == null || howLocalsEat!.trim().isEmpty) &&
      (whenLocalsEat == null || whenLocalsEat!.trim().isEmpty) &&
      (beforeYouOrder == null || beforeYouOrder!.trim().isEmpty);
}

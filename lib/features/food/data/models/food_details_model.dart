import '../../domain/entities/food_details.dart';

class FoodDetailsModel extends FoodDetails {
  const FoodDetailsModel({
    required super.contentId,
    super.currencyCode,
    super.typicalPriceMin,
    super.typicalPriceMax,
    super.spicyLevel,
    super.vegetarian,
    super.vegan,
    super.halal,
    super.containsPork,
    super.containsAlcohol,
    super.glutenFree,
    super.ingredients,
    super.allergens,
    super.portionInfo,
    super.howLocalsEat,
    super.whenLocalsEat,
    super.beforeYouOrder,
  });

  factory FoodDetailsModel.fromMap(Map<String, dynamic> map) {
    return FoodDetailsModel(
      contentId: map['content_id'].toString(),
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
      ingredients: _toStringList(map['ingredients']),
      allergens: _toStringList(map['allergens']),
      portionInfo: map['portion_info']?.toString(),
      howLocalsEat: map['how_locals_eat']?.toString(),
      whenLocalsEat: map['when_locals_eat']?.toString(),
      beforeYouOrder: map['before_you_order']?.toString(),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
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

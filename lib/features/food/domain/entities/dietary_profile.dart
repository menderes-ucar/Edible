import 'food_details.dart';
import 'food_filter.dart';

/// Major food allergens a traveller can register in their food profile.
enum Allergen {
  peanuts,
  treeNuts,
  milk,
  eggs,
  gluten,
  soy,
  fish,
  shellfish,
  sesame;

  String get id => name;

  String get localizationKey => switch (this) {
        Allergen.peanuts => 'allergenPeanuts',
        Allergen.treeNuts => 'allergenTreeNuts',
        Allergen.milk => 'allergenMilk',
        Allergen.eggs => 'allergenEggs',
        Allergen.gluten => 'allergenGluten',
        Allergen.soy => 'allergenSoy',
        Allergen.fish => 'allergenFish',
        Allergen.shellfish => 'allergenShellfish',
        Allergen.sesame => 'allergenSesame',
      };

  /// Lower-case whole-word tokens that indicate this allergen in catalog data.
  /// Intentionally broad: a false alarm is acceptable, a missed allergen is not.
  Set<String> get tokens => switch (this) {
        Allergen.peanuts => const {'peanut', 'peanuts', 'groundnut', 'groundnuts', 'nut', 'nuts'},
        Allergen.treeNuts => const {
            'treenut', 'treenuts', 'almond', 'almonds', 'hazelnut', 'hazelnuts',
            'walnut', 'walnuts', 'cashew', 'cashews', 'pistachio', 'pistachios',
            'pecan', 'pecans', 'nut', 'nuts',
          },
        Allergen.milk => const {
            'milk', 'dairy', 'lactose', 'cheese', 'butter', 'cream', 'yogurt',
            'yoghurt', 'ghee',
          },
        Allergen.eggs => const {'egg', 'eggs'},
        Allergen.gluten => const {'gluten', 'wheat', 'barley', 'rye', 'semolina', 'bulgur', 'spelt'},
        Allergen.soy => const {'soy', 'soya', 'soybean', 'soybeans', 'tofu'},
        Allergen.fish => const {'fish', 'anchovy', 'anchovies', 'tuna', 'salmon', 'cod'},
        Allergen.shellfish => const {
            'shellfish', 'shrimp', 'prawn', 'prawns', 'crab', 'lobster',
            'mollusc', 'mollusk', 'crustacean', 'crustaceans', 'squid',
            'mussel', 'mussels', 'oyster', 'oysters', 'clam', 'clams',
          },
        Allergen.sesame => const {'sesame', 'tahini'},
      };

  static Allergen? fromId(String? value) {
    for (final allergen in Allergen.values) {
      if (allergen.id == value) return allergen;
    }
    return null;
  }
}

/// Diet / belief rules a user can register. Subset of [FoodFilter].
const supportedDietaryRules = <FoodFilter>[
  FoodFilter.vegan,
  FoodFilter.vegetarian,
  FoodFilter.halal,
  FoodFilter.noPork,
  FoodFilter.noAlcohol,
];

class DietaryProfile {
  const DietaryProfile({
    this.allergens = const {},
    this.diets = const {},
  });

  final Set<Allergen> allergens;
  final Set<FoodFilter> diets;

  bool get isEmpty => allergens.isEmpty && diets.isEmpty;

  DietaryProfile copyWith({Set<Allergen>? allergens, Set<FoodFilter>? diets}) {
    return DietaryProfile(
      allergens: allergens ?? this.allergens,
      diets: diets ?? this.diets,
    );
  }

  Map<String, dynamic> toJson() => {
        'allergens': (allergens.map((e) => e.id).toList()..sort()),
        'diets': (diets.map((e) => e.name).toList()..sort()),
      };

  factory DietaryProfile.fromJson(Map<String, dynamic> json) {
    final allergens = <Allergen>{};
    final rawAllergens = json['allergens'];
    if (rawAllergens is List) {
      for (final item in rawAllergens) {
        final parsed = Allergen.fromId(item?.toString());
        if (parsed != null) allergens.add(parsed);
      }
    }

    final diets = <FoodFilter>{};
    final rawDiets = json['diets'];
    if (rawDiets is List) {
      for (final item in rawDiets) {
        for (final rule in supportedDietaryRules) {
          if (rule.name == item?.toString()) diets.add(rule);
        }
      }
    }

    return DietaryProfile(allergens: allergens, diets: diets);
  }
}

/// Result of comparing one dish with the user's profile.
///
/// Edible never declares a dish "safe". [allergenConflicts] / [dietConflicts]
/// are known conflicts from catalog data; [needsConfirmation] means the user
/// must still ask the restaurant (always true when any allergy is registered).
class DietaryAssessment {
  const DietaryAssessment({
    this.allergenConflicts = const [],
    this.dietConflicts = const [],
    this.needsConfirmation = false,
  });

  final List<Allergen> allergenConflicts;
  final List<FoodFilter> dietConflicts;
  final bool needsConfirmation;

  bool get hasConflict => allergenConflicts.isNotEmpty || dietConflicts.isNotEmpty;
  bool get isRelevant => hasConflict || needsConfirmation;
}

abstract final class DietaryMatcher {
  static DietaryAssessment assess({
    required DietaryProfile profile,
    required FoodDetails? details,
  }) {
    if (profile.isEmpty) return const DietaryAssessment();

    final allergenConflicts = <Allergen>[];
    final dietConflicts = <FoodFilter>[];
    var needsConfirmation = false;

    if (profile.allergens.isNotEmpty) {
      // Catalog data can never prove a dish is allergen-free.
      needsConfirmation = true;
      if (details != null) {
        final listed = <String>[...details.allergens, ...details.ingredients];
        for (final allergen in Allergen.values) {
          if (profile.allergens.contains(allergen) && _mentions(listed, allergen)) {
            allergenConflicts.add(allergen);
          }
        }
      }
    }

    for (final rule in supportedDietaryRules) {
      if (!profile.diets.contains(rule)) continue;
      final verdict = _verdict(rule, details);
      if (verdict == false) {
        dietConflicts.add(rule);
      } else if (verdict == null) {
        needsConfirmation = true;
      }
    }

    return DietaryAssessment(
      allergenConflicts: allergenConflicts,
      dietConflicts: dietConflicts,
      needsConfirmation: needsConfirmation,
    );
  }

  /// true = compatible, false = known conflict, null = unknown.
  static bool? _verdict(FoodFilter rule, FoodDetails? details) {
    if (details == null) return null;
    return switch (rule) {
      FoodFilter.vegan => details.vegan,
      FoodFilter.vegetarian =>
        details.vegetarian ?? (details.vegan == true ? true : null),
      FoodFilter.halal => details.halal,
      FoodFilter.noPork =>
        details.containsPork == null ? null : !details.containsPork!,
      FoodFilter.noAlcohol =>
        details.containsAlcohol == null ? null : !details.containsAlcohol!,
      FoodFilter.glutenFree => details.glutenFree,
    };
  }

  static bool _mentions(Iterable<String> values, Allergen allergen) {
    final tokens = allergen.tokens;
    for (final raw in values) {
      final normalized = raw
          .toLowerCase()
          .replaceAll('tree nut', 'treenut')
          .replaceAll('tree-nut', 'treenut');
      for (final token in normalized.split(RegExp(r'[^a-z]+'))) {
        if (token.isNotEmpty && tokens.contains(token)) return true;
      }
    }
    return false;
  }
}

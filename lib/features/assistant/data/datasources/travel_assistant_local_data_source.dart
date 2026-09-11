import '../../../culture/domain/repositories/culture_repository.dart';
import '../../../explore/domain/entities/explore_content.dart';
import '../../../explore/domain/repositories/explore_repository.dart';
import '../../../food/domain/entities/food_details.dart';
import '../../../food/domain/repositories/food_repository.dart';
import '../../domain/entities/travel_assistant_request.dart';
import '../../domain/entities/travel_assistant_response.dart';

class TravelAssistantLocalDataSource {
  TravelAssistantLocalDataSource({
    required ExploreRepository exploreRepository,
    required FoodRepository foodRepository,
    required CultureRepository cultureRepository,
  })  : _exploreRepository = exploreRepository,
        _foodRepository = foodRepository,
        _cultureRepository = cultureRepository;

  final ExploreRepository _exploreRepository;
  final FoodRepository _foodRepository;
  final CultureRepository _cultureRepository;

  Future<TravelAssistantResponse> ask(
    TravelAssistantRequest request,
  ) async {
    final all = await _exploreRepository.getContents(
      languageCode: request.languageCode,
    );

    if (all.isEmpty) {
      return const TravelAssistantResponse(
        summary: 'No discovery data is available yet.',
        cityName: '',
        hours: 0,
        stops: [],
        tips: [],
      );
    }

    final message = _normalize(request.message);
    final cityName = _resolveCity(
      message: message,
      all: all,
      fallback: request.defaultCityName,
    );

    final hours = _resolveHours(message);
    final wantsCheap = _containsAny(
      message,
      ['cheap', 'budget', 'ucuz', 'ekonomik'],
    );
    final wantsFood = _containsAny(
      message,
      ['food', 'eat', 'restaurant', 'yemek', 'ye', 'tat', 'ramen'],
    );
    final wantsCulture = _containsAny(
      message,
      ['culture', 'historic', 'history', 'museum', 'kültür', 'tarih', 'müze'],
    );
    final wantsLowWalking = _containsAny(
      message,
      ['less walking', 'low walking', 'az yürü', 'çok yürümek istemiyorum'],
    );

    final cityItems = all
        .where(
          (item) =>
              cityName.isEmpty ||
              item.cityName.toLowerCase() == cityName.toLowerCase(),
        )
        .toList(growable: false);

    final foodDetails = await _foodRepository.getDetailsForContents(
      contentIds: cityItems.map((item) => item.id),
      languageCode: request.languageCode,
    );

    final ranked = [...cityItems]
      ..sort(
        (a, b) => _score(
          b,
          foodDetails[b.id],
          wantsCheap: wantsCheap,
          wantsFood: wantsFood,
          wantsCulture: wantsCulture,
        ).compareTo(
          _score(
            a,
            foodDetails[a.id],
            wantsCheap: wantsCheap,
            wantsFood: wantsFood,
            wantsCulture: wantsCulture,
          ),
        ),
      );

    final maxStops = hours <= 3
        ? 3
        : hours <= 5
            ? 4
            : hours <= 8
                ? 6
                : 8;

    final chosen = <ExploreContent>[];
    for (final item in ranked) {
      if (chosen.length >= maxStops) break;
      chosen.add(item);
    }

    final interval = chosen.isEmpty ? 60 : (hours * 60 ~/ chosen.length);
    var elapsed = 0;

    final stops = chosen.map((content) {
      final hour = 10 + elapsed ~/ 60;
      final minute = elapsed % 60;
      elapsed += interval;

      return TravelAssistantStop(
        timeLabel:
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
        content: content,
        reason: _reasonFor(
          content,
          foodDetails[content.id],
          wantsCheap: wantsCheap,
          wantsFood: wantsFood,
          wantsCulture: wantsCulture,
        ),
      );
    }).toList(growable: false);

    final tips = <String>[];
    if (wantsLowWalking) {
      tips.add('Keep stops in the same area and use public transport between clusters.');
    }
    if (wantsCheap) {
      tips.add('Prefer local casual food and markets over tourist-heavy areas.');
    }

    if (cityName.isNotEmpty && chosen.isNotEmpty) {
      try {
        final culture = await _cultureRepository.getGuide(
          countryCode: chosen.first.countryCode,
          cityName: cityName,
          languageCode: request.languageCode,
        );

        final safety = culture.items
            .where(
              (item) =>
                  item.type.name == 'safety' ||
                  item.type.name == 'scam' ||
                  item.type.name == 'touristMistake',
            )
            .take(2);

        tips.addAll(safety.map((item) => '${item.title}: ${item.body}'));
      } catch (_) {
        // Assistant should still produce a route if culture data is unavailable.
      }
    }

    return TravelAssistantResponse(
      summary: _summary(
        cityName: cityName,
        hours: hours,
        wantsFood: wantsFood,
        wantsCulture: wantsCulture,
      ),
      cityName: cityName,
      hours: hours,
      stops: stops,
      tips: tips,
    );
  }

  String _normalize(String input) {
    return input.trim().toLowerCase();
  }

  String _resolveCity({
    required String message,
    required List<ExploreContent> all,
    String? fallback,
  }) {
    final cities = all.map((item) => item.cityName).toSet().toList();

    for (final city in cities) {
      if (message.contains(city.toLowerCase())) return city;
    }

    if (fallback != null && fallback.trim().isNotEmpty) return fallback;
    return cities.isNotEmpty ? cities.first : '';
  }

  int _resolveHours(String message) {
    final match = RegExp(r'(\d{1,2})\s*(hour|hours|saat)')
        .firstMatch(message);

    if (match != null) {
      final value = int.tryParse(match.group(1) ?? '');
      if (value != null) return value.clamp(2, 12);
    }

    return 4;
  }

  bool _containsAny(String message, List<String> values) {
    return values.any(message.contains);
  }

  int _score(
    ExploreContent item,
    FoodDetails? food, {
    required bool wantsCheap,
    required bool wantsFood,
    required bool wantsCulture,
  }) {
    var score = item.isFeatured ? 3 : 0;
    final category = item.category.name;

    if (wantsFood &&
        (category == 'food' ||
            category == 'snack' ||
            category == 'fruit' ||
            category == 'drink')) {
      score += 8;
    }

    if (wantsCulture &&
        (category == 'culture' || category == 'place')) {
      score += 8;
    }

    if (wantsCheap && food != null) {
      final max = food.typicalPriceMax;
      if (max != null && max > 0) {
        score += 4;
      }
    }

    return score;
  }

  String _reasonFor(
    ExploreContent item,
    FoodDetails? food, {
    required bool wantsCheap,
    required bool wantsFood,
    required bool wantsCulture,
  }) {
    final category = item.category.name;

    if (wantsFood &&
        (category == 'food' ||
            category == 'snack' ||
            category == 'fruit' ||
            category == 'drink')) {
      if (wantsCheap && food?.currencyCode != null) {
        return 'Matches your food and budget preference.';
      }
      return 'Matches your local food preference.';
    }

    if (wantsCulture &&
        (category == 'culture' || category == 'place')) {
      return 'Matches your culture/history preference.';
    }

    return item.isFeatured
        ? 'One of Edible’s highlighted discoveries.'
        : 'A useful stop that fits the available time.';
  }

  String _summary({
    required String cityName,
    required int hours,
    required bool wantsFood,
    required bool wantsCulture,
  }) {
    final goals = <String>[
      if (wantsCulture) 'culture',
      if (wantsFood) 'local food',
    ];

    final focus = goals.isEmpty ? 'balanced discovery' : goals.join(' + ');

    return '$hours-hour $focus plan for $cityName.';
  }
}

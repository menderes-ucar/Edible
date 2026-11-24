import '../../../culture/domain/repositories/culture_repository.dart';
import '../../../explore/domain/entities/explore_content.dart';
import '../../../explore/domain/repositories/explore_repository.dart';
import '../../../food/domain/entities/food_details.dart';
import '../../../food/domain/repositories/food_repository.dart';
import '../../domain/entities/travel_assistant_request.dart';
import '../../domain/entities/travel_assistant_response.dart';
import '../assistant_local_strings.dart';
import '../assistant_text_utils.dart';

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
      return TravelAssistantResponse(
        summary: AssistantLocalStrings.text(request.languageCode, 'noData'),
        cityName: '',
        hours: 0,
        stops: const [],
        tips: const [],
      );
    }

    final message = _normalize(request.message);
    final cityName = _resolveCity(
      message: message,
      all: all,
      fallback: request.defaultCityName,
    );

    final hours = _resolveHours(message);
    final wantsCheap = AssistantTextUtils.wantsCheap(message);
    final wantsFood = AssistantTextUtils.wantsFood(message);
    final wantsCulture = AssistantTextUtils.wantsCulture(message);
    final wantsLowWalking = AssistantTextUtils.wantsLowWalking(message);

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
          languageCode: request.languageCode,
          wantsCheap: wantsCheap,
          wantsFood: wantsFood,
          wantsCulture: wantsCulture,
        ),
      );
    }).toList(growable: false);

    final tips = <String>[];
    if (wantsLowWalking) {
      tips.add(AssistantLocalStrings.text(request.languageCode, 'tipLowWalking'));
    }
    if (wantsCheap) {
      tips.add(AssistantLocalStrings.text(request.languageCode, 'tipCheap'));
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
        languageCode: request.languageCode,
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

  int _resolveHours(String message) => AssistantTextUtils.resolveHours(message);

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
    required String languageCode,
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
        return AssistantLocalStrings.text(languageCode, 'reasonFoodBudget');
      }
      return AssistantLocalStrings.text(languageCode, 'reasonFood');
    }

    if (wantsCulture &&
        (category == 'culture' || category == 'place')) {
      return AssistantLocalStrings.text(languageCode, 'reasonCulture');
    }

    return AssistantLocalStrings.text(
      languageCode,
      item.isFeatured ? 'reasonFeatured' : 'reasonFits',
    );
  }

  String _summary({
    required String languageCode,
    required String cityName,
    required int hours,
    required bool wantsFood,
    required bool wantsCulture,
  }) {
    final key = wantsFood && wantsCulture
        ? 'summaryFoodCulture'
        : wantsFood
            ? 'summaryFood'
            : wantsCulture
                ? 'summaryCulture'
                : 'summaryBalanced';

    return AssistantLocalStrings.text(
      languageCode,
      key,
      args: {'hours': '$hours', 'city': cityName},
    );
  }
}

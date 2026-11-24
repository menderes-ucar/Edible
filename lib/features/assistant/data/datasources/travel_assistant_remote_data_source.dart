import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../explore/domain/entities/explore_content.dart';
import '../../../explore/domain/repositories/explore_repository.dart';
import '../../../food/domain/entities/food_details.dart';
import '../../../food/domain/repositories/food_repository.dart';
import '../../domain/entities/travel_assistant_request.dart';
import '../../domain/entities/travel_assistant_response.dart';
import '../assistant_text_utils.dart';

/// The daily AI quota for this user is used up.
class AssistantQuotaExceededException implements Exception {
  const AssistantQuotaExceededException();
}

/// The AI service cannot answer now (offline, signed out, server error...).
class AssistantUnavailableException implements Exception {
  const AssistantUnavailableException();
}

/// Calls the `travel-assistant` Edge Function. The function authenticates the
/// user, enforces premium + quota on the server and only accepts places from
/// the candidate list built here, so the model cannot invent venues.
///
/// Privacy: only the typed message, language, city and public catalog items are
/// sent. The user's food profile is never included.
class TravelAssistantRemoteDataSource {
  TravelAssistantRemoteDataSource({
    required ExploreRepository exploreRepository,
    required FoodRepository foodRepository,
  })  : _exploreRepository = exploreRepository,
        _foodRepository = foodRepository;

  final ExploreRepository _exploreRepository;
  final FoodRepository _foodRepository;

  static const _maxCandidates = 60;

  Future<TravelAssistantResponse> ask(TravelAssistantRequest request) async {
    final client = SupabaseService.client;
    if (client == null || client.auth.currentSession == null) {
      throw const AssistantUnavailableException();
    }

    final all = await _exploreRepository.getContents(
      languageCode: request.languageCode,
    );
    if (all.isEmpty) throw const AssistantUnavailableException();

    final message = request.message.trim().toLowerCase();
    final cityName = AssistantTextUtils.resolveCity(
      message: message,
      all: all,
      fallback: request.defaultCityName,
    );
    final cityItems = all
        .where(
          (item) =>
              cityName.isNotEmpty &&
              item.cityName.toLowerCase() == cityName.toLowerCase(),
        )
        .toList(growable: false);
    if (cityItems.isEmpty) throw const AssistantUnavailableException();

    final selected = _selectCandidates(cityItems);

    Map<String, FoodDetails> foodDetails = const {};
    try {
      foodDetails = await _foodRepository.getDetailsForContents(
        contentIds: selected.map((item) => item.id),
        languageCode: request.languageCode,
      );
    } catch (_) {
      // Prices are optional context; plan without them.
    }

    final hours = AssistantTextUtils.resolveHours(message);

    Object? data;
    try {
      final response = await client.functions.invoke(
        'travel-assistant',
        body: {
          'message': request.message.trim(),
          'languageCode': request.languageCode,
          'cityName': cityName,
          'hours': hours,
          'candidates': [
            for (final item in selected)
              _candidateJson(item, foodDetails[item.id]),
          ],
        },
      ).timeout(const Duration(seconds: 35));
      data = response.data;
    } on FunctionException catch (error) {
      if (error.status == 429) throw const AssistantQuotaExceededException();
      throw const AssistantUnavailableException();
    } on TimeoutException {
      throw const AssistantUnavailableException();
    }

    return _parse(
      data: data,
      selected: selected,
      cityName: cityName,
      fallbackHours: hours,
    );
  }

  List<ExploreContent> _selectCandidates(List<ExploreContent> items) {
    final sorted = [...items]
      ..sort(
        (a, b) => (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0),
      );
    return sorted.take(_maxCandidates).toList(growable: false);
  }

  Map<String, Object?> _candidateJson(ExploreContent item, FoodDetails? food) {
    final num? price = food?.typicalPriceMax;
    return {
      'id': item.id,
      'title': item.title,
      'category': item.category.name,
      'lat': item.latitude,
      'lng': item.longitude,
      'featured': item.isFeatured,
      if (price != null && price > 0) 'priceMax': price,
      if (price != null && price > 0 && food?.currencyCode != null)
        'currency': food!.currencyCode,
    };
  }

  TravelAssistantResponse _parse({
    required Object? data,
    required List<ExploreContent> selected,
    required String cityName,
    required int fallbackHours,
  }) {
    if (data is! Map) throw const AssistantUnavailableException();

    final byId = {for (final item in selected) item.id: item};
    final stops = <TravelAssistantStop>[];

    final rawStops = data['stops'];
    if (rawStops is List) {
      for (final raw in rawStops) {
        if (raw is! Map) continue;
        final content = byId[raw['id']?.toString()];
        if (content == null) continue; // never trust ids outside our catalog
        stops.add(
          TravelAssistantStop(
            timeLabel: raw['time']?.toString() ?? '',
            content: content,
            reason: raw['reason']?.toString() ?? '',
          ),
        );
      }
    }

    final tips = <String>[];
    final rawTips = data['tips'];
    if (rawTips is List) {
      for (final tip in rawTips) {
        final text = tip?.toString().trim() ?? '';
        if (text.isNotEmpty) tips.add(text);
      }
    }

    final summary = data['summary']?.toString().trim() ?? '';
    if (summary.isEmpty && stops.isEmpty) {
      throw const AssistantUnavailableException();
    }

    final hours = (data['hours'] is num)
        ? (data['hours'] as num).toInt().clamp(2, 12)
        : fallbackHours;

    return TravelAssistantResponse(
      summary: summary,
      cityName: cityName,
      hours: hours,
      stops: stops,
      tips: tips,
      source: TravelAssistantSource.ai,
    );
  }
}

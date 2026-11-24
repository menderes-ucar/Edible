import '../../../explore/domain/entities/explore_content.dart';

class TravelAssistantStop {
  const TravelAssistantStop({
    required this.timeLabel,
    required this.content,
    required this.reason,
  });

  final String timeLabel;
  final ExploreContent content;
  final String reason;
}

enum TravelAssistantSource {
  /// Built by the AI service from Edible's catalog.
  ai,

  /// Built by the offline rule-based engine.
  basic,

  /// Offline engine used because today's AI quota is used up.
  basicQuotaReached,
}

class TravelAssistantResponse {
  const TravelAssistantResponse({
    required this.summary,
    required this.cityName,
    required this.hours,
    required this.stops,
    required this.tips,
    this.source = TravelAssistantSource.basic,
  });

  final String summary;
  final String cityName;
  final int hours;
  final List<TravelAssistantStop> stops;
  final List<String> tips;
  final TravelAssistantSource source;

  TravelAssistantResponse withSource(TravelAssistantSource source) {
    return TravelAssistantResponse(
      summary: summary,
      cityName: cityName,
      hours: hours,
      stops: stops,
      tips: tips,
      source: source,
    );
  }
}

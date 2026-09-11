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

class TravelAssistantResponse {
  const TravelAssistantResponse({
    required this.summary,
    required this.cityName,
    required this.hours,
    required this.stops,
    required this.tips,
  });

  final String summary;
  final String cityName;
  final int hours;
  final List<TravelAssistantStop> stops;
  final List<String> tips;
}

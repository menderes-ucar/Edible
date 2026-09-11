import '../../../explore/domain/entities/explore_content.dart';

class TripPlanStop {
  const TripPlanStop({
    required this.timeLabel,
    required this.content,
  });

  final String timeLabel;
  final ExploreContent content;
}

class TripPlan {
  const TripPlan({
    required this.cityName,
    required this.stops,
  });

  final String cityName;
  final List<TripPlanStop> stops;
}

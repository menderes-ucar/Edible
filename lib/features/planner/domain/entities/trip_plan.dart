class TripPlan {
  const TripPlan({
    required this.city,
    required this.hours,
    required this.stops,
  });

  final String city;
  final int hours;
  final List<TripStop> stops;
}

class TripStop {
  const TripStop({
    required this.title,
    required this.minutesFromStart,
    required this.category,
  });

  final String title;
  final int minutesFromStart;
  final String category;
}
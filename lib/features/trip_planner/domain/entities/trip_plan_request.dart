enum TripBudget { cheap, medium, flexible }
enum WalkingPreference { low, medium, high }

class TripPlanRequest {
  const TripPlanRequest({
    required this.cityName,
    required this.hours,
    required this.budget,
    required this.walking,
    required this.foodStops,
    required this.cultureStops,
  });

  final String cityName;
  final int hours;
  final TripBudget budget;
  final WalkingPreference walking;
  final int foodStops;
  final int cultureStops;
}

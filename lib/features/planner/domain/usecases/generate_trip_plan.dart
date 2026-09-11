import '../entities/trip_plan.dart';

class GenerateTripPlan {
  const GenerateTripPlan();

  TripPlan call({
    required String city,
    required int hours,
    required bool cheapFood,
    required bool culture,
  }) {
    final stops = <TripStop>[
      if (culture)
        const TripStop(
          title: 'Historic Landmark',
          minutesFromStart: 0,
          category: 'culture',
        ),
      const TripStop(
        title: 'Local Food Stop',
        minutesFromStart: 60,
        category: 'food',
      ),
      const TripStop(
        title: 'Neighborhood Walk',
        minutesFromStart: 120,
        category: 'place',
      ),
    ];

    return TripPlan(
      city: city,
      hours: hours,
      stops: stops,
    );
  }
}
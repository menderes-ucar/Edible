import '../../../explore/domain/entities/explore_content.dart';
import '../entities/trip_plan.dart';
import '../entities/trip_plan_request.dart';

class GenerateTripPlan {
  const GenerateTripPlan();

  TripPlan call({
    required TripPlanRequest request,
    required Iterable<ExploreContent> contents,
  }) {
    final cityItems = contents
        .where((item) => item.cityName == request.cityName)
        .toList(growable: false);

    final culture = cityItems.where((item) => item.category.name == 'culture').toList();
    final places = cityItems.where((item) => item.category.name == 'place').toList();
    final food = cityItems.where((item) {
      final category = item.category.name;
      return category == 'food' || category == 'snack' || category == 'drink';
    }).toList();

    final selected = <ExploreContent>[];

    selected.addAll(culture.take(request.cultureStops));
    if (selected.length < request.cultureStops) {
      selected.addAll(places.take(request.cultureStops - selected.length));
    }

    selected.addAll(food.take(request.foodStops));

    final maxStops = request.hours <= 3
        ? 3
        : request.hours <= 5
            ? 4
            : request.hours <= 8
                ? 6
                : 8;

    if (selected.length < maxStops) {
      for (final item in cityItems) {
        if (!selected.contains(item)) {
          selected.add(item);
          if (selected.length >= maxStops) break;
        }
      }
    }

    final intervalMinutes = request.hours * 60 ~/ (selected.isEmpty ? 1 : selected.length);
    var minute = 0;

    final stops = selected.map((item) {
      final hour = 12 + minute ~/ 60;
      final min = minute % 60;
      final label = '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
      minute += intervalMinutes;
      return TripPlanStop(timeLabel: label, content: item);
    }).toList(growable: false);

    return TripPlan(cityName: request.cityName, stops: stops);
  }
}

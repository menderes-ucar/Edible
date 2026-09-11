import '../../../explore/domain/entities/explore_content.dart';
import '../entities/saved_trip.dart';
import '../entities/saved_trip_itinerary.dart';

class GenerateSavedTripItinerary {
  const GenerateSavedTripItinerary();

  static const int maxTripDays = 30;
  static const int maxStopsPerDay = 6;

  List<GeneratedItineraryStop> call({
    required SavedTrip trip,
    required Iterable<ExploreContent> selectedContents,
  }) {
    final tripCountry = trip.countryCode.trim().toLowerCase();
    final tripCity = trip.cityName.trim().toLowerCase();
    final byId = <String, ExploreContent>{};

    for (final item in selectedContents) {
      final id = item.id.trim();
      if (id.isEmpty) continue;

      // Itinerary generation is a domain boundary, not just a presentation
      // helper. Never persist a stale/cross-trip discovery into this vacation.
      if (item.countryCode.trim().toLowerCase() != tripCountry) continue;
      if (tripCity.isNotEmpty &&
          item.cityName.trim().toLowerCase() != tripCity) {
        continue;
      }

      // Saved content ids are identity keys. A duplicated catalog row must
      // never become two persisted itinerary stops.
      byId.putIfAbsent(id, () => item);
    }

    final contents = byId.values.toList(growable: false);
    if (contents.isEmpty) return const [];

    final dayCount = trip.dayCount.clamp(1, maxTripDays).toInt();
    final capacity = dayCount * maxStopsPerDay;

    // Do not silently drop discoveries and do not manufacture overlapping or
    // late-night stops just to make an oversized plan look successful.
    if (contents.length > capacity) {
      throw StateError(
        'itinerary_capacity_exceeded:$capacity',
      );
    }

    // City plans can be balanced directly. Country-wide plans are first
    // clustered by city so a generated day does not bounce between distant
    // cities when the catalog contains multiple destinations.
    final dayBuckets = trip.cityName.trim().isEmpty
        ? _buildCountryDayBuckets(contents, dayCount)
        : _buildBalancedDayBuckets(contents, dayCount);

    if (dayBuckets.any((bucket) => bucket.length > maxStopsPerDay)) {
      throw StateError('itinerary_capacity_distribution_failed');
    }

    final result = <GeneratedItineraryStop>[];

    for (var dayIndex = 0; dayIndex < dayBuckets.length; dayIndex++) {
      final ordered = _orderForDay(dayBuckets[dayIndex]);
      final minutes = _timeSlotsFor(ordered);

      for (var index = 0; index < ordered.length; index++) {
        result.add(
          GeneratedItineraryStop(
            contentId: ordered[index].id,
            dayIndex: dayIndex,
            startMinute: minutes[index],
            sortOrder: index,
          ),
        );
      }
    }

    return result;
  }

  List<List<ExploreContent>> _buildBalancedDayBuckets(
    List<ExploreContent> contents,
    int dayCount,
  ) {
    final ordered = _variedOrder(contents);
    final buckets = List.generate(dayCount, (_) => <ExploreContent>[]);

    for (var index = 0; index < ordered.length; index++) {
      buckets[index % dayCount].add(ordered[index]);
    }

    return buckets;
  }

  List<List<ExploreContent>> _buildCountryDayBuckets(
    List<ExploreContent> contents,
    int dayCount,
  ) {
    final byCity = <String, List<ExploreContent>>{};

    for (final item in contents) {
      final cityKey = item.cityName.trim().toLowerCase();
      byCity.putIfAbsent(cityKey, () => <ExploreContent>[]).add(item);
    }

    final cityGroups = byCity.values.toList(growable: false)
      ..sort((a, b) {
        final sizeCompare = b.length.compareTo(a.length);
        if (sizeCompare != 0) return sizeCompare;
        return a.first.cityName
            .toLowerCase()
            .compareTo(b.first.cityName.toLowerCase());
      });

    final buckets = List.generate(dayCount, (_) => <ExploreContent>[]);
    final softTarget = (contents.length / dayCount)
        .ceil()
        .clamp(1, maxStopsPerDay);

    for (final cityItems in cityGroups) {
      final orderedCityItems = _variedOrder(cityItems);

      // Start each city on the least-loaded day. This avoids the old failure
      // mode where every city after dayCount was dumped into the final day.
      var dayIndex = _leastLoadedDay(buckets);

      for (final item in orderedCityItems) {
        buckets[dayIndex].add(item);

        // Keep a city's stops together where practical, but if the day has
        // reached the target and this city still has more content, continue
        // on the next least-loaded day instead of creating an overloaded day.
        if (buckets[dayIndex].length >= softTarget) {
          dayIndex = _leastLoadedDay(buckets);
        }
      }
    }

    return buckets;
  }

  int _leastLoadedDay(List<List<ExploreContent>> buckets) {
    var bestIndex = 0;
    var bestSize = buckets.first.length;

    for (var index = 1; index < buckets.length; index++) {
      final size = buckets[index].length;
      if (size < bestSize) {
        bestIndex = index;
        bestSize = size;
      }
    }

    return bestIndex;
  }

  List<ExploreContent> _variedOrder(List<ExploreContent> contents) {
    final sights = <ExploreContent>[];
    final meals = <ExploreContent>[];
    final lightFood = <ExploreContent>[];
    final other = <ExploreContent>[];

    for (final item in contents) {
      switch (item.category.name) {
        case 'place':
        case 'culture':
          sights.add(item);
        case 'food':
          meals.add(item);
        case 'drink':
        case 'snack':
        case 'fruit':
          lightFood.add(item);
        default:
          other.add(item);
      }
    }

    final result = <ExploreContent>[];
    while (sights.isNotEmpty ||
        meals.isNotEmpty ||
        lightFood.isNotEmpty ||
        other.isNotEmpty) {
      if (sights.isNotEmpty) result.add(sights.removeAt(0));
      if (meals.isNotEmpty) result.add(meals.removeAt(0));
      if (sights.isNotEmpty) result.add(sights.removeAt(0));
      if (lightFood.isNotEmpty) result.add(lightFood.removeAt(0));
      if (other.isNotEmpty) result.add(other.removeAt(0));
    }
    return result;
  }

  List<ExploreContent> _orderForDay(List<ExploreContent> items) {
    if (items.length < 2) return List.of(items, growable: false);

    // Put meal-like discoveries around meal periods while keeping sightseeing
    // content around them. This is deterministic and does not invent opening
    // hours that are not present in the catalog.
    final morning = <ExploreContent>[];
    final meals = <ExploreContent>[];
    final breaks = <ExploreContent>[];

    for (final item in items) {
      switch (item.category.name) {
        case 'food':
          meals.add(item);
        case 'drink':
        case 'snack':
        case 'fruit':
          breaks.add(item);
        default:
          morning.add(item);
      }
    }

    final ordered = <ExploreContent>[];
    if (morning.isNotEmpty) ordered.add(morning.removeAt(0));
    if (morning.isNotEmpty) ordered.add(morning.removeAt(0));
    if (meals.isNotEmpty) ordered.add(meals.removeAt(0));

    while (morning.isNotEmpty || breaks.isNotEmpty || meals.isNotEmpty) {
      if (morning.isNotEmpty) ordered.add(morning.removeAt(0));
      if (breaks.isNotEmpty) ordered.add(breaks.removeAt(0));
      if (meals.isNotEmpty) ordered.add(meals.removeAt(0));
    }

    return ordered;
  }

  List<int> _timeSlotsFor(List<ExploreContent> items) {
    if (items.isEmpty) return const [];

    final slots = <int>[];
    var cursor = 600; // 10:00
    var lunchPlaced = false;

    for (final item in items) {
      final category = item.category.name;

      if (category == 'food' && !lunchPlaced && cursor < 780) {
        cursor = 780; // 13:00
        lunchPlaced = true;
      } else if ((category == 'drink' ||
              category == 'snack' ||
              category == 'fruit') &&
          cursor < 900) {
        cursor = 900; // 15:00
      }

      // Never generate an impossible time beyond the persistence constraint.
      slots.add(cursor.clamp(0, 1439).toInt());

      final interval = items.length <= 4
          ? 120
          : items.length <= 6
              ? 90
              : 75;
      cursor += interval;
    }

    return slots;
  }
}
